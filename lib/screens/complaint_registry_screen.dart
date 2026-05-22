import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../widgets/custom_back_button.dart';
import '../services/ai_complaint_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../widgets/glass_card.dart';

class ComplaintRegistryScreen extends StatefulWidget {
  final String farmerName;
  const ComplaintRegistryScreen({Key? key, required this.farmerName}) : super(key: key);

  @override
  State<ComplaintRegistryScreen> createState() => _ComplaintRegistryScreenState();
}

class _ComplaintRegistryScreenState extends State<ComplaintRegistryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int _currentStep = 0; // 0: Classification & Contact, 1: Details & Evidence, 2: Location Review & Send
  
  bool _isAnonymous = false;
  String? _selectedVesselType;
  String? _selectedActivityType;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  Map<String, dynamic>? _selectedLocationData;
  bool _isSearchingLocation = false;
  File? _imageFile;
  Uint8List? _webImage;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _submittedComplaintId;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  String? _audioPath;
  bool _isPlaying = false;

  final List<String> _vesselTypes = [
    'Large Net Fishing Boat (Trawler)',
    'Small Local Boat',
    'Speedboat / Motorboat',
    'Large Cargo / Transfer Ship',
    'Unknown / Other Boat'
  ];

  final List<String> _activityTypes = [
    'Fishing in Banned Area (CRZ / Protected Zone)',
    'Fishing During Ban Season',
    'Using Illegal Small Nets',
    'Suspicious Night Fishing',
    'Dumping Trash or Oil'
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if(mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _listenToSpeech() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _descriptionController.text = val.recognizedWords;
            });
          },
        );
      } else {
        setState(() => _isListening = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available.'))
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final String path = kIsWeb ? '' : '${Directory.systemTemp.path}/complaint_audio.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 32000, 
            numChannels: 1,
          ), 
          path: path
        ); 
        setState(() {
          _isRecording = true;
          _audioPath = null;
        });
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } catch (e) {
      print("Error stopping record: $e");
    }
  }

  void _playAudio() async {
    if (_audioPath != null) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if(kIsWeb) {
            await _audioPlayer.play(UrlSource(_audioPath!));
        } else {
            await _audioPlayer.play(DeviceFileSource(_audioPath!));
        }
      }
    }
  }

  void _deleteAudio() {
    setState(() {
      _audioPath = null;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 15, 
      maxWidth: 450,    
      maxHeight: 450,   
    );
    if (pickedFile != null) {
      if (kIsWeb) {
        var f = await pickedFile.readAsBytes();
        setState(() {
          _webImage = f;
          _imageFile = File('a'); 
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<Iterable<Map<String, dynamic>>> _searchLocations(String query) async {
    if (query.trim().length < 3) return const Iterable<Map<String, dynamic>>.empty();
    
    setState(() => _isSearchingLocation = true);

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&countrycodes=in&viewbox=73.5,15.8,74.5,14.8&bounded=1&limit=5');
      final response = await http.get(url, headers: {'User-Agent': 'GIS_Smart_Pisciculture_App'});
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) setState(() => _isSearchingLocation = false);
        return data.map((item) {
          return {
            'name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lng': double.parse(item['lon']),
          };
        }).toList();
      }
    } catch (e) {
      print("Error fetching places: $e");
    }
    
    if (mounted) setState(() => _isSearchingLocation = false);
    return const Iterable<Map<String, dynamic>>.empty();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isSearchingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json');
      final response = await http.get(url, headers: {'User-Agent': 'GIS_Smart_Pisciculture_App'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedLocationData = {
            'name': data['display_name'] ?? "Current GPS Location",
            'lat': position.latitude,
            'lng': position.longitude,
          };
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📍 Location detected successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting location: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingLocation = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate() || _selectedLocationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields and pick a valid incident location.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String complaintId = const Uuid().v4();
      String? imageUrl;

      try {
        if (kIsWeb && _webImage != null) {
          final base64String = base64Encode(_webImage!);
          imageUrl = 'data:image/jpeg;base64,$base64String';
        } else if (!kIsWeb && _imageFile != null && _imageFile!.path != 'a') {
          final bytes = await _imageFile!.readAsBytes();
          final base64String = base64Encode(bytes);
          imageUrl = 'data:image/jpeg;base64,$base64String';
        }
      } catch (uploadError) {
        print("Image conversion failed. Continuing without image.");
      }

      String? audioUrl;
      try {
        if (_audioPath != null && _audioPath!.isNotEmpty) {
          List<int> bytes;
          if (kIsWeb) {
             final response = await http.get(Uri.parse(_audioPath!));
             bytes = response.bodyBytes;
          } else {
             bytes = await File(_audioPath!).readAsBytes();
          }
          final base64String = base64Encode(bytes);
          audioUrl = 'data:audio/mp4;base64,$base64String';
        }
      } catch (e) {
        print("Audio conversion failed. Continuing without audio.");
      }

      final aiAnalysis = await AIComplaintService.analyzeComplaint({
        'activityType': _selectedActivityType,
        'vesselType': _selectedVesselType,
        'description': _descriptionController.text,
        'location': 'Lat: ${_selectedLocationData!['lat']}, Lng: ${_selectedLocationData!['lng']} (${_selectedLocationData!['name']})',
      });

      await FirebaseFirestore.instance.collection('complaints').doc(complaintId).set({
        'id': complaintId,
        'reporterName': _isAnonymous ? 'Anonymous' : widget.farmerName,
        'originalFarmerName': widget.farmerName, 
        'isAnonymous': _isAnonymous,
        'vesselType': _selectedVesselType,
        'activityType': _selectedActivityType,
        'description': _descriptionController.text,
        'reporterPhone': _phoneController.text.trim(),
        'location': GeoPoint(_selectedLocationData!['lat'], _selectedLocationData!['lng']),
        'locationName': _selectedLocationData!['name'],
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'status': 'Pending', 
        'timestamp': FieldValue.serverTimestamp(),
        if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
      });

      if (mounted) {
        setState(() {
          _isSuccess = true;
          _submittedComplaintId = complaintId;
        });
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
      backgroundColor: const Color(0xFF090D16), // Premium dark mode background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: CustomBackButton(onPressed: () {
          if (_isSuccess) {
            setState(() {
              _isSuccess = false;
              _isAnonymous = false;
              _selectedVesselType = null;
              _selectedActivityType = null;
              _descriptionController.clear();
              _phoneController.clear();
              _imageFile = null;
              _webImage = null;
              _currentStep = 0;
            });
          } else {
            Navigator.pop(context);
          }
        }),
        leadingWidth: 80,
        title: const Text(
          'Incident Command',
          style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49.0),
          child: Column(
            children: [
              const TabBar(
                labelColor: Color(0xFFEF4444),
                unselectedLabelColor: Color(0xFF64748B),
                indicatorColor: Color(0xFFEF4444),
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: Icon(Icons.edit_note, size: 20), text: "New Report"),
                  Tab(icon: Icon(Icons.history, size: 20), text: "My Reports"),
                ],
              ),
              Container(
                color: Colors.white.withOpacity(0.08),
                height: 1.0,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        children: [
          // Tab 1: New Report Form Wizard
          _isSuccess 
            ? _buildSuccessScreen()
            : (_isSubmitting 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
              : Column(
                  children: [
                    // Step Progress Indicator Bar
                    _buildStepIndicator(),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_currentStep == 0) _buildStep1(),
                              if (_currentStep == 1) _buildStep2(),
                              if (_currentStep == 2) _buildStep3(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Progressive Navigation Panel
                    _buildNavigationButtons(),
                  ],
                )),
          // Tab 2: My Reports List
          _buildMyReports(),
        ],
      ),
    ),
  );
}

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: const Color(0xFF0F172A).withOpacity(0.4),
      child: Row(
        children: [
          _buildStepDot(0, "Classification"),
          _buildStepLine(0),
          _buildStepDot(1, "Evidence"),
          _buildStepLine(1),
          _buildStepDot(2, "Location"),
        ],
      ),
    );
  }

  Widget _buildStepDot(int stepIndex, String label) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;
    final Color dotColor = isCompleted 
        ? const Color(0xFF10B981) // Green for complete
        : (isActive ? const Color(0xFFEF4444) : const Color(0xFF64748B));
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor.withOpacity(0.12),
            border: Border.all(color: dotColor, width: 2),
            boxShadow: isActive ? [
              BoxShadow(color: dotColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
            ] : null,
          ),
          alignment: Alignment.center,
          child: isCompleted 
              ? const Icon(Icons.check, size: 12, color: Color(0xFF10B981))
              : Text(
                  "${stepIndex + 1}", 
                  style: TextStyle(color: dotColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 9, 
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isPassed = _currentStep > afterStep;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 2,
          color: isPassed ? const Color(0xFF10B981) : Colors.white.withOpacity(0.08),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWarningBanner(),
        const SizedBox(height: 20),
        
        GlassCard(
          borderRadius: 16,
          blur: 10,
          backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
          borderColor: Colors.white.withOpacity(0.06),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Anonymity Settings",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Submit Anonymously', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                subtitle: const Text(
                  'Your name & details will be entirely hidden from authorities.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                contentPadding: EdgeInsets.zero,
                value: _isAnonymous,
                activeColor: const Color(0xFFEF4444),
                onChanged: (bool value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
                secondary: const Icon(Icons.privacy_tip, color: Color(0xFF06B6D4)),
              ),
              if (!_isAnonymous) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    labelStyle: const TextStyle(color: Color(0xFF64748B)),
                    hintText: 'e.g., 9876543210',
                    hintStyle: const TextStyle(color: Color(0xFF334155)),
                    filled: true,
                    fillColor: const Color(0xFF090D16),
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFF6366F1), size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        GlassCard(
          borderRadius: 16,
          blur: 10,
          backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
          borderColor: Colors.white.withOpacity(0.06),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Vessel & Activity Category",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                   labelText: 'Vessel Type',
                   labelStyle: const TextStyle(color: Color(0xFF64748B)),
                   filled: true,
                   fillColor: const Color(0xFF090D16),
                   prefixIcon: const Icon(Icons.directions_boat, color: Color(0xFF06B6D4), size: 20),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                   enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
                ),
                value: _selectedVesselType,
                items: _vesselTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedVesselType = newValue),
                validator: (value) => value == null ? 'Please select a vessel type' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                   labelText: 'Suspicious Activity Type',
                   labelStyle: const TextStyle(color: Color(0xFF64748B)),
                   filled: true,
                   fillColor: const Color(0xFF090D16),
                   prefixIcon: const Icon(Icons.warning_amber, color: Color(0xFFEF4444), size: 20),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                   enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
                ),
                value: _selectedActivityType,
                items: _activityTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedActivityType = newValue),
                validator: (value) => value == null ? 'Please select an activity type' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderRadius: 16,
          blur: 10,
          backgroundColor: const Color(0xFF1E293B).withOpacity(0.45),
          borderColor: Colors.white.withOpacity(0.06),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Incident Narrative",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                decoration: InputDecoration(
                  labelText: 'Narrative Description',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: const Color(0xFF090D16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
                  suffixIcon: Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: BoxDecoration(
                      color: _isListening ? const Color(0xFFEF4444).withOpacity(0.15) : Colors.white.withOpacity(0.03),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
                        size: 20,
                      ),
                      onPressed: _listenToSpeech,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty && (_audioPath == null || _audioPath!.isEmpty)) {
                    return 'Please provide a description or record voice evidence';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Custom Glass Polaroid Card for image evidence
        const Text(
          "Photo Evidence (Polaroid Capture)",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        
        Center(
          child: InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFF090D16),
                    child: (_imageFile != null || _webImage != null)
                        ? kIsWeb
                            ? Image.memory(_webImage!, fit: BoxFit.cover)
                            : Image.file(_imageFile!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, size: 40, color: Color(0xFF64748B)),
                              SizedBox(height: 8),
                              Text(
                                'Tap to take picture', 
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "EVIDENCE PHOTO",
                    style: TextStyle(
                      fontFamily: 'Courier', 
                      fontWeight: FontWeight.bold, 
                      fontSize: 11, 
                      color: Colors.black54,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        const Text("Voice Audio Evidence", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        
        GlassCard(
          borderRadius: 16,
          blur: 10,
          backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
          borderColor: Colors.white.withOpacity(0.06),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop_circle : Icons.mic, 
                  color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF3B82F6), 
                  size: 34,
                ),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecording ? "Recording Audio..." : (_audioPath != null ? "Voice Evidence Captured!" : "Secure Voice Memo"),
                      style: TextStyle(
                        color: _isRecording ? const Color(0xFFEF4444) : Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isRecording ? "Authorities are listening..." : "Tap to speak and record raw narrative details",
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (_audioPath != null) ...[
                 IconButton(
                   icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, color: const Color(0xFF10B981), size: 32),
                   onPressed: _playAudio,
                 ),
                 IconButton(
                   icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 30),
                   onPressed: _deleteAudio,
                 ),
              ]
            ]
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderRadius: 16,
          blur: 10,
          backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
          borderColor: Colors.white.withOpacity(0.06),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Incident Geofencing",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 14),
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (option) => option['name'] as String,
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  return await _searchLocations(textEditingValue.text);
                },
                onSelected: (Map<String, dynamic> selection) {
                  setState(() {
                    _selectedLocationData = selection;
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  if (_selectedLocationData != null && textEditingController.text != _selectedLocationData!['name']) {
                     textEditingController.text = _selectedLocationData!['name'];
                  }

                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onEditingComplete: onFieldSubmitted,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Search Location Coordinates',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFF090D16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
                      prefixIcon: const Icon(Icons.location_on, color: Color(0xFF06B6D4), size: 20),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedLocationData != null) 
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                          if (_isSearchingLocation)
                             const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4)))),
                          IconButton(
                            icon: Icon(Icons.my_location, color: _isSearchingLocation ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8), size: 20),
                            onPressed: _isSearchingLocation ? null : _detectCurrentLocation,
                            tooltip: 'Use current location',
                          ),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                       if (_selectedLocationData != null && value != _selectedLocationData!['name']) {
                          setState(() {
                             _selectedLocationData = null; 
                          });
                       }
                    },
                    validator: (value) => _selectedLocationData == null ? 'Please select a predefined location' : null,
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        const Text("Review Summary", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        
        GlassCard(
          borderRadius: 16,
          blur: 10,
          backgroundColor: const Color(0xFF1E293B).withOpacity(0.2),
          borderColor: Colors.white.withOpacity(0.04),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildReviewRow("Submission type:", _isAnonymous ? "Anonymous Report" : "Standard Profile"),
              _buildReviewRow("Activity Type:", _selectedActivityType ?? "Not Specified"),
              _buildReviewRow("Vessel Identified:", _selectedVesselType ?? "Not Specified"),
              _buildReviewRow("Narrative Info:", _descriptionController.text.isNotEmpty ? "Provided (${_descriptionController.text.length} chars)" : "Audio Evidence Only"),
              _buildReviewRow("GPS Lock:", _selectedLocationData != null ? "VALID COORDINATES" : "NOT SELECTED", isAccent: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isAccent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                color: isAccent ? const Color(0xFF10B981) : Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          if (_currentStep > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    side: BorderSide(color: Colors.white.withOpacity(0.08)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Previous", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          else
            const Spacer(),
            
          // Next / Submit Button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: _currentStep == 2 
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentStep < 2) {
                    if (_formKey.currentState!.validate() || _currentStep == 1) {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  } else {
                    _submitComplaint();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _currentStep == 2 ? "File Complaint" : "Continue", 
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReports() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('originalFarmerName', isEqualTo: widget.farmerName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.white.withOpacity(0.12)),
                const SizedBox(height: 16),
                const Text(
                  'No reports recorded yet.', 
                  style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); 
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildAcknowledgementCard(data);
          },
        );
      },
    );
  }

  Widget _buildAcknowledgementCard(Map<String, dynamic> data) {
    String status = data['status'] ?? 'Pending';
    Color statusColor = status == 'Action Taken' 
        ? const Color(0xFF10B981) // Emerald
        : (status == 'Dismissed' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
    DateTime? date = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null;

    return GlassCard(
      borderRadius: 16,
      blur: 10,
      backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
      borderColor: statusColor.withOpacity(0.2),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['activityType'] ?? 'Unknown Activity',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (date != null)
            Text(
              "Submitted: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}",
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          const Divider(height: 24, color: Colors.white10),
          if (data['acknowledgementMessage'] != null) ...[
            const Text(
              "Message from Authority:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF090D16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Text(
                data['acknowledgementMessage'],
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
            ),
          ] else ...[
            const Row(
              children: [
                 Icon(Icons.hourglass_empty, size: 14, color: Color(0xFF64748B)),
                 SizedBox(width: 8),
                 Text("Pending official review...", style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic, fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your safety is our priority. If you feel threatened, please submit the report anonymously. Do not approach suspicious vessels directly.',
              style: TextStyle(color: Color(0xFFF59E0B), height: 1.4, fontSize: 11),
            ),
          )
        ],
      )
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: GlassCard(
          borderRadius: 24,
          blur: 15,
          backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
          borderColor: Colors.white.withOpacity(0.08),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 76),
              const SizedBox(height: 20),
              const Text(
                'Report Filed Successfully',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your complaint has been encrypted and recorded securely. Authorities have been alerted on their GIS dashboard. Monitor status in the history tab.',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04))
                ),
                child: Column(
                  children: [
                    const Text('Incident Identifier:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SelectableText(
                      _submittedComplaintId ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF06B6D4), fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 24, color: Colors.white10),
                    const Text('Initial Status:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      'PENDING EXECUTIVE REVIEW',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFF59E0B), letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
