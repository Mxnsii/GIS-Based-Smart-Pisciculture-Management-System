import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../widgets/custom_back_button.dart';
import '../services/ai_complaint_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/ocean_glass_card.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_wave_header.dart';
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
  Uint8List? _imageBytes;
  bool _hasImage = false;
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
          RecordConfig(
            encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
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

  void _deleteImage() {
    setState(() {
      _imageBytes = null;
      _hasImage = false;
    });
  }

  Future<Uint8List> _fallbackCompress(Uint8List bytes) async {
    try {
      final ui.Codec metadataCodec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo metadataFrame = await metadataCodec.getNextFrame();
      final int originalWidth = metadataFrame.image.width;
      final int originalHeight = metadataFrame.image.height;
      metadataFrame.image.dispose();
      
      const int maxDim = 250;
      int? targetWidth;
      int? targetHeight;
      if (originalWidth > originalHeight) {
        if (originalWidth > maxDim) {
          targetWidth = maxDim;
        }
      } else {
        if (originalHeight > maxDim) {
          targetHeight = maxDim;
        }
      }
      
      final ui.Codec resizeCodec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final ui.FrameInfo resizeFrame = await resizeCodec.getNextFrame();
      final ui.Image resizedImage = resizeFrame.image;
      
      final ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List result = bytes;
      if (byteData != null) {
        result = byteData.buffer.asUint8List();
      }
      resizedImage.dispose();
      return result;
    } catch (e) {
      print("Fallback compression error: $e");
    }
    return bytes;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 30, // Compress to ensure Base64 string is well under the 1MB Firestore limit
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _hasImage = true;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text('Take a Photo', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text('Choose from Gallery', style: GoogleFonts.inter(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
      final String complaintId = const Uuid().v4().substring(0, 8).toUpperCase();
      String? imageUrl;

      // 1. Upload Image to Firebase Storage
      if (_imageBytes != null) {
        print("Uploading image to Firebase Storage...");
        try {
          final ref = FirebaseStorage.instance.ref().child('complaints/$complaintId/image.jpg');
          final uploadTask = ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
          final snapshot = await uploadTask.timeout(const Duration(seconds: 4));
          imageUrl = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 4));
          print("Uploaded image successfully: $imageUrl");
        } catch (storageError) {
          print("Storage upload failed or timed out: $storageError. Falling back to Base64...");
          try {
            final compressedBytes = await _fallbackCompress(_imageBytes!);
            final base64String = base64Encode(compressedBytes);
            imageUrl = 'data:image/jpeg;base64,$base64String';
          } catch (e) {
            print("Fallback base64 conversion failed: $e");
          }
        }
      }

      // 1b. Upload Audio to Firebase Storage
      String? audioUrl;
      if (_audioPath != null && _audioPath!.isNotEmpty) {
        print("Uploading audio to Firebase Storage...");
        try {
          final ref = FirebaseStorage.instance.ref().child('complaints/$complaintId/audio.m4a');
          if (kIsWeb) {
             final response = await http.get(Uri.parse(_audioPath!));
             final bytes = response.bodyBytes;
             final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'audio/mp4'));
             final snapshot = await uploadTask.timeout(const Duration(seconds: 4));
             audioUrl = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 4));
          } else {
             final uploadTask = ref.putFile(File(_audioPath!), SettableMetadata(contentType: 'audio/mp4'));
             final snapshot = await uploadTask.timeout(const Duration(seconds: 4));
             audioUrl = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 4));
          }
          print("Uploaded audio successfully: $audioUrl");
        } catch (e) {
          print("Audio Storage upload failed or timed out: $e. Falling back to Base64...");
          try {
            List<int> bytes;
            if (kIsWeb) {
               final response = await http.get(Uri.parse(_audioPath!));
               bytes = response.bodyBytes;
            } else {
               bytes = await File(_audioPath!).readAsBytes();
            }
            final base64String = base64Encode(bytes);
            audioUrl = 'data:audio/mp4;base64,$base64String';
          } catch (audioErr) {
            print("Audio fallback failed: $audioErr");
          }
        }
      }

      // 2. Add AI Analysis
      print("Analyzing complaint with AI...");
      final aiAnalysis = await AIComplaintService.analyzeComplaint({
        'activityType': _selectedActivityType,
        'vesselType': _selectedVesselType,
        'description': _descriptionController.text,
        'location': 'Lat: ${_selectedLocationData!['lat']}, Lng: ${_selectedLocationData!['lng']} (${_selectedLocationData!['name']})',
      }).timeout(const Duration(seconds: 5), onTimeout: () => null);

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
      child: Builder(
        builder: (context) {
          return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: AnimatedWaveHeader(
          height: 130,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'Report Incident',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ),
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(icon: Icon(Icons.edit_note_rounded), text: "New Report"),
                  Tab(icon: Icon(Icons.history_rounded), text: "My Reports"),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        children: [
          // Tab 1: New Report Form
          _isSuccess 
            ? _buildSuccessScreen(context)
            : (_isSubmitting 
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWarningBanner(),
                        const SizedBox(height: 12),
                        OceanGlassCard(
                          child: SwitchListTile(
                            title: Text('Submit Anonymously', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            subtitle: Text('Your name will be hidden from the authorities.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                            value: _isAnonymous,
                            activeColor: AppColors.primary,
                            onChanged: (bool value) {
                              setState(() {
                                _isAnonymous = value;
                              });
                            },
                            secondary: Icon(Icons.privacy_tip_rounded, color: AppColors.primary),
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 8),
                        OceanGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Contact Number',
                                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                hintText: 'e.g., 9876543210',
                                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                                border: InputBorder.none,
                                filled: false,
                                prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
                              ),
                              validator: (value) {
                                if (!_isAnonymous && (value == null || value.isEmpty)) {
                                  return 'Please enter a contact number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        Text('Vessel Information', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 12),
                        
                        OceanGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: InputDecoration(
                                 labelText: 'Vessel Type',
                                 labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                 border: InputBorder.none,
                                 filled: false,
                                 prefixIcon: Icon(Icons.directions_boat_rounded, color: AppColors.primary)
                              ),
                              value: _selectedVesselType,
                              items: _vesselTypes.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter()),
                                );
                              }).toList(),
                              onChanged: (newValue) => setState(() => _selectedVesselType = newValue),
                              validator: (value) => value == null ? 'Please select a vessel type' : null,
                            ),
                          ),
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 8),
                        
                        OceanGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: InputDecoration(
                                 labelText: 'Type of Suspicious Activity',
                                 labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                 border: InputBorder.none,
                                 filled: false,
                                 prefixIcon: Icon(Icons.warning_amber_rounded, color: AppColors.warning)
                              ),
                              value: _selectedActivityType,
                              items: _activityTypes.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter()),
                                );
                              }).toList(),
                              onChanged: (newValue) => setState(() => _selectedActivityType = newValue),
                              validator: (value) => value == null ? 'Please select an activity type' : null,
                            ),
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      
                        const SizedBox(height: 8),
                        
                        OceanGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Additional Details / Description',
                                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                alignLabelWithHint: true,
                                border: InputBorder.none,
                                filled: false,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none_rounded,
                                    color: _isListening ? AppColors.danger : AppColors.textMuted,
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
                          ),
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
      
                        const SizedBox(height: 12),
                        Text('Evidence', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 12),
                        
                        // Image Picker
                        OceanGlassCard(
                          onTap: _showImageSourceDialog,
                          padding: EdgeInsets.zero,
                          child: SizedBox(
                            height: 100,
                            width: double.infinity,
                            child: _hasImage && _imageBytes != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                                      ),
                                      Positioned(
                                        right: 8, top: 8,
                                        child: IconButton(
                                          icon: const Icon(Icons.close_rounded, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                                          onPressed: _deleteImage,
                                        ),
                                      )
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_rounded, size: 48, color: AppColors.primary.withOpacity(0.5)),
                                      const SizedBox(height: 8),
                                      Text('Tap to take a photo of the vessel', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600))
                                    ],
                                  ),
                          ),
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
      
                        const SizedBox(height: 12),
                        Text('Voice Evidence', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: 12),
                        
                        OceanGlassCard(
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRecording ? AppColors.dangerLight : AppColors.primary.withOpacity(0.1),
                                ),
                                child: IconButton(
                                  icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: _isRecording ? AppColors.danger : AppColors.primary, size: 32),
                                  onPressed: _isRecording ? _stopRecording : _startRecording,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isRecording ? "Recording..." : (_audioPath != null ? "Voice Evidence Recorded!" : "Tap to record voice evidence"),
                                  style: GoogleFonts.inter(color: _isRecording ? AppColors.danger : AppColors.textPrimary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (_audioPath != null) ...[
                                 IconButton(
                                   icon: Icon(_isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: AppColors.success, size: 32),
                                   onPressed: _playAudio,
                                 ),
                                 IconButton(
                                   icon: Icon(Icons.delete_rounded, color: AppColors.danger, size: 32),
                                   onPressed: _deleteAudio,
                                 ),
                              ]
                            ]
                          )
                        ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 12),
                        Text('Location', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 8),
                        
                        OceanGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Autocomplete<Map<String, dynamic>>(
                              displayStringForOption: (option) => option['name'] as String,
                              optionsBuilder: (TextEditingValue textEditingValue) async {
                                return await _searchLocations(textEditingValue.text);
                              },
                              onSelected: (Map<String, dynamic> selection) {
                                setState(() {
                                  _selectedLocationData = selection;
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  onEditingComplete: onEditingComplete,
                                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: 'Search Location (Village / Landmark)',
                                    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                    border: InputBorder.none,
                                    filled: false,
                                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                                    suffixIcon: _isSearchingLocation
                                        ? Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.my_location_rounded, color: AppColors.secondary),
                                            onPressed: () async {
                                               await _detectCurrentLocation();
                                               if (_selectedLocationData != null) {
                                                 controller.text = _selectedLocationData!['name'];
                                               }
                                            },
                                          ),
                                  ),
                                  validator: (value) => _selectedLocationData == null ? 'Please provide the location' : null,
                                );
                              },
                            ),
                          ),
                        ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: AppColors.oceanGradient),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _submitComplaint,
                            child: Text(
                              'Submit Report Securely',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                        const SizedBox(height: 120), // Extra space to clear the bottom navigation bar
                      ],
                    ),
                  ))),
          // Tab 2: My Reports List
          _buildMyReports(),
        ],
      ),
    );
        },
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
    Color statusColor = status == 'Action Taken' ? AppColors.success : (status == 'Dismissed' ? AppColors.danger : AppColors.warning);
    DateTime? date = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null;

    return OceanGlassCard(
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
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (date != null)
            Text(
              "Submitted on: ${date.day}/${date.month}/${date.year}",
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 12),
          if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
            Text(
              data['description'],
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: !_isNetworkUrl(data['imageUrl']?.toString())
                  ? (_getBytesFromBase64(data['imageUrl']?.toString()) != null
                      ? Image.memory(
                          _getBytesFromBase64(data['imageUrl']!.toString())!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 150,
                          color: AppColors.primary.withOpacity(0.05),
                          child: Center(child: Icon(Icons.broken_image, size: 40, color: AppColors.textMuted)),
                        ))
                  : Image.network(
                      data['imageUrl'].toString(),
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: AppColors.primary.withOpacity(0.05),
                        child: Center(child: Icon(Icons.broken_image, size: 40, color: AppColors.textMuted)),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
          ],
          if (data['audioUrl'] != null && data['audioUrl'].toString().isNotEmpty) ...[
            _AudioPlayerWidget(audioData: data['audioUrl']),
            const SizedBox(height: 12),
          ],
          Divider(height: 16, color: AppColors.border),
          const SizedBox(height: 8),
          if (data['acknowledgementMessage'] != null) ...[
            Text(
              "Message from Authority:",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Text(
                data['acknowledgementMessage'],
                style: GoogleFonts.inter(height: 1.5, fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
          ] else ...[
            Row(
              children: [
                 Icon(Icons.hourglass_empty_rounded, size: 16, color: AppColors.textMuted),
                 const SizedBox(width: 8),
                 Text("Waiting for authority response...", style: GoogleFonts.inter(color: AppColors.textMuted, fontStyle: FontStyle.italic, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildWarningBanner() {
    return OceanGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dangerLight.withOpacity(0.3),
          border: Border(left: BorderSide(color: AppColors.danger, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Strict Action Guaranteed", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.danger)),
                  const SizedBox(height: 4),
                  Text(
                    "Any false reporting will lead to penalty. Please provide accurate evidence.",
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSuccessScreen(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0, bottom: 100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated glowing checkmark
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.1),
                border: Border.all(color: AppColors.success.withOpacity(0.2), width: 2),
              ),
              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            
            Text(
              'Thank You for Reporting',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            
            Text(
              'Your incident report has been securely submitted and logged. Our team is reviewing the evidence. You can track progress under the "My Reports" tab.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),
            
            // Glassmorphic status card
            OceanGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Complaint ID',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _submittedComplaintId ?? 'UNKNOWN',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Report Status',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Pending Review',
                          style: GoogleFonts.inter(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            
            // Done Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.oceanGradient),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Switch tab to "My Reports" (index 1)
                  DefaultTabController.of(context).animateTo(1);
                  setState(() {
                    _isSuccess = false;
                    _isAnonymous = false;
                    _selectedVesselType = null;
                    _selectedActivityType = null;
                    _descriptionController.clear();
                    _phoneController.clear();
                    _imageBytes = null;
                    _hasImage = false;
                  });
                },
                child: Text(
                  'Track My Reports',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final String audioData;
  const _AudioPlayerWidget({Key? key, required this.audioData}) : super(key: key);

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        if (widget.audioData.startsWith('data:audio')) {
           final String base64Str = widget.audioData.split(',').last.replaceAll(RegExp(r'\s+'), '');
           final bytes = base64Decode(base64Str);
           await _audioPlayer.play(BytesSource(bytes));
        } else {
           await _audioPlayer.play(UrlSource(widget.audioData));
        }
      } catch (e) {
        print("Error playing audio evidence: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: _togglePlay,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPlaying ? 'Playing Audio...' : 'Voice Evidence Attached',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Tap to listen to your recording.',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isNetworkUrl(String? url) {
  if (url == null) return false;
  return url.startsWith('http://') || url.startsWith('https://');
}

Uint8List? _getBytesFromBase64(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty) return null;
  try {
    String cleanStr = base64Str.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleanStr.startsWith('data:')) {
      cleanStr = cleanStr.split(',').last;
    }
    return base64Decode(cleanStr);
  } catch (e) {
    print("Error decoding base64 image: $e");
    return null;
  }
}

