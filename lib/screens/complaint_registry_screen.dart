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
// Note: Bypassing Firebase Storage by using Base64 encoding

class ComplaintRegistryScreen extends StatefulWidget {
  final String farmerName;
  const ComplaintRegistryScreen({Key? key, required this.farmerName}) : super(key: key);

  @override
  State<ComplaintRegistryScreen> createState() => _ComplaintRegistryScreenState();
}

class _ComplaintRegistryScreenState extends State<ComplaintRegistryScreen> {
  final _formKey = GlobalKey<FormState>();
  
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
        // Optimize for size: 32kbps mono is plenty for voice and keeps Firestore doc under 1MB
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
      imageQuality: 15, // Aggressive compression (15%) to stay under 1MB Firestore limit
      maxWidth: 450,    // Reduced width for smaller Base64 payload
      maxHeight: 450,   // Reduced height
    );
    if (pickedFile != null) {
      if (kIsWeb) {
        var f = await pickedFile.readAsBytes();
        setState(() {
          _webImage = f;
          _imageFile = File('a'); // Dummy file to satisfy null check
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
      // Using OpenStreetMap Nominatim API (Free, no API key required)
      // Bounded roughly to Goa region for better relevance
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
      // Reverse geocode using Nominatim
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
        // Success feedback
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
      print("Starting complaint submission...");
      final String complaintId = const Uuid().v4();
      String? imageUrl;

      // 1. Convert Image to Base64 (Bypass Storage)
      print("Converting image to Base64...");
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
        print("Image conversion failed: $uploadError. Continuing without image.");
      }
      print("Image URL: $imageUrl");

      // 1b. Convert Audio to Base64 (Bypass Storage)
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
        print("Audio conversion failed: $e. Continuing without audio.");
      }

      // 2. Add AI Analysis
      print("Analyzing complaint with AI...");
      final aiAnalysis = await AIComplaintService.analyzeComplaint({
        'activityType': _selectedActivityType,
        'vesselType': _selectedVesselType,
        'description': _descriptionController.text,
        'location': 'Lat: ${_selectedLocationData!['lat']}, Lng: ${_selectedLocationData!['lng']} (${_selectedLocationData!['name']})',
      });

      // 3. Save data to Firestore
      print("Saving to Firestore...");
      await FirebaseFirestore.instance.collection('complaints').doc(complaintId).set({
        'id': complaintId,
        'reporterName': _isAnonymous ? 'Anonymous' : widget.farmerName,
        'originalFarmerName': widget.farmerName, // Always link to original farmer id/name
        'isAnonymous': _isAnonymous,
        'vesselType': _selectedVesselType,
        'activityType': _selectedActivityType,
        'description': _descriptionController.text,
        'reporterPhone': _phoneController.text.trim(),
        'location': GeoPoint(_selectedLocationData!['lat'], _selectedLocationData!['lng']),
        'locationName': _selectedLocationData!['name'],
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'status': 'Pending', // Pending, Reviewed, Action Taken
        'timestamp': FieldValue.serverTimestamp(),
        if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
      });

      if (mounted) {
        print("Firestore save complete. Showing success message.");
        setState(() {
          _isSuccess = true;
          _submittedComplaintId = complaintId;
        });
      }
    } catch (e) {
       print("ERROR CAUGHT DURING SUBMISSION: $e");
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
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            });
          } else {
            Navigator.pop(context);
          }
        }),
        leadingWidth: 80,
        title: const Text(
          'Report Incident',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        bottom: const TabBar(
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.redAccent,
          tabs: [
            Tab(icon: Icon(Icons.edit_note), text: "New Report"),
            Tab(icon: Icon(Icons.history), text: "My Reports"),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          // Tab 1: New Report Form
          _isSuccess 
            ? _buildSuccessScreen()
            : (_isSubmitting 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWarningBanner(),
                        const SizedBox(height: 24),
                        // ... (form content continues)
                    
                    // Anonymity Toggle
                    SwitchListTile(
                      title: const Text('Submit Anonymously', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Your name will be hidden from the authorities.'),
                      value: _isAnonymous,
                      activeColor: Colors.red,
                      onChanged: (bool value) {
                        setState(() {
                          _isAnonymous = value;
                        });
                      },
                      secondary: const Icon(Icons.privacy_tip, color: Colors.grey),
                    ),
                    const Divider(),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        hintText: 'e.g., 9876543210',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Vessel Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                         labelText: 'Vessel Type',
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                         prefixIcon: const Icon(Icons.directions_boat)
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
                      decoration: InputDecoration(
                         labelText: 'Type of Suspicious Activity',
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                         prefixIcon: const Icon(Icons.warning_amber)
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
  
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Additional Details / Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : Colors.grey,
                          ),
                          onPressed: _listenToSpeech,
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty && (_audioPath == null || _audioPath!.isEmpty)) {
                          return 'Please provide a description or record voice evidence';
                        }
                        return null;
                      },
                    ),
  
                    const SizedBox(height: 24),
                    const Text('Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    // Image Picker
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: (_imageFile != null || _webImage != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.memory(_webImage!, fit: BoxFit.cover)
                                    : Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text('Tap to take a photo of the vessel', style: TextStyle(color: Colors.grey.shade600))
                                ],
                              ),
                      ),
                    ),
  
                    const SizedBox(height: 24),
                    const Text('Voice Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, color: _isRecording ? Colors.red : Colors.blue, size: 36),
                            onPressed: _isRecording ? _stopRecording : _startRecording,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isRecording ? "Recording..." : (_audioPath != null ? "Voice Evidence Recorded!" : "Tap to record voice evidence"),
                              style: TextStyle(color: _isRecording ? Colors.red : Colors.grey.shade800, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_audioPath != null) ...[
                             IconButton(
                               icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.green, size: 36),
                               onPressed: _playAudio,
                             ),
                             IconButton(
                               icon: Icon(Icons.delete, color: Colors.red, size: 36),
                               onPressed: _deleteAudio,
                             ),
                          ]
                        ]
                      )
                    ),

                    const SizedBox(height: 24),
                    const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
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
                        // Sync controller if external selection happens (like Detect Location)
                        if (_selectedLocationData != null && textEditingController.text != _selectedLocationData!['name']) {
                           textEditingController.text = _selectedLocationData!['name'];
                        }

                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onEditingComplete: onFieldSubmitted,
                          decoration: InputDecoration(
                            labelText: 'Search Location',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.location_on),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selectedLocationData != null) 
                                  const Icon(Icons.check_circle, color: Colors.green),
                                if (_isSearchingLocation)
                                   const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                IconButton(
                                  icon: Icon(Icons.my_location, color: _isSearchingLocation ? Colors.blue : Colors.blueGrey),
                                  onPressed: _isSearchingLocation ? null : _detectCurrentLocation,
                                  tooltip: 'Use current location',
                                ),
                              ],
                            ),
                          ),
                          onChanged: (value) {
                             if (_selectedLocationData != null && value != _selectedLocationData!['name']) {
                                setState(() {
                                   _selectedLocationData = null; // Reset if they alter the selected text
                                });
                             }
                          },
                          validator: (value) => _selectedLocationData == null ? 'Please select a predefined location' : null,
                        );
                      },
                    ),
  
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _submitComplaint,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Report to Authorities', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                      ),
                    ),
                  ],
                ),
              ))),
          // Tab 2: My Reports List
          _buildMyReports(),
        ],
      ),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('You haven\'t submitted any reports yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Sort in-memory to avoid requiring a composite index
        final docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending
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
    Color statusColor = status == 'Action Taken' ? Colors.green : (status == 'Dismissed' ? Colors.red : Colors.orange);
    DateTime? date = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['activityType'] ?? 'Unknown Activity',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (date != null)
              Text(
                "Submitted on: ${date.day}/${date.month}/${date.year}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            const Divider(height: 24),
            if (data['acknowledgementMessage'] != null) ...[
              const Text(
                "Message from Authority:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['acknowledgementMessage'],
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ] else ...[
              const Row(
                children: [
                   Icon(Icons.hourglass_empty, size: 16, color: Colors.grey),
                   SizedBox(width: 8),
                   Text("Waiting for authority response...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
// ... existing banner widget ...
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Colors.amber.shade700, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your safety is our priority. If you feel threatened, please submit the report anonymously. Do not approach suspicious vessels directly.',
              style: TextStyle(height: 1.4),
            ),
          )
        ],
      )
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Thank you for reporting.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your complaint has been recorded and will be reviewed by the authorities. You can track progress in the "My Reports" tab.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: Column(
                children: [
                  Text('Complaint ID:', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(
                    _submittedComplaintId ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(height: 24),
                  Text('Status:', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  const Text(
                    'Pending Review',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

