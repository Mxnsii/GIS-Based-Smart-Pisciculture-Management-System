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
  
  Position? _currentPosition;
  File? _imageFile;
  Uint8List? _webImage;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _submittedComplaintId;

  final List<String> _vesselTypes = [
    'Big Net Fishing Boat (Trawler)',
    'Boat Surrounding Fish with Net (Purse Seiner)',
    'Boat Using Long Hooks Line (Longliner)',
    'Small / Unknown Boat',
    'Other Boat'
  ];

  final List<String> _activityTypes = [
    'Fishing in No-Fishing Area (Restricted)',
    'Using Illegal Fishing Nets / Gear',
    'Boat Without Fishing License',
    'Two Boats Exchanging Fish in Sea',
    'Other Suspicious Activity'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      }
      return;
    } 

    final position = await Geolocator.getCurrentPosition();
    if(mounted){
        setState(() {
          _currentPosition = position;
        });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 30, // Compress image to 30% quality to stay under 1MB Firestore limit
      maxWidth: 600,    // Resize width
      maxHeight: 600,   // Resize height
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

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate() || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields and wait for location.')),
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

      // 2. Add AI Analysis
      print("Analyzing complaint with AI...");
      final aiAnalysis = await AIComplaintService.analyzeComplaint({
        'activityType': _selectedActivityType,
        'vesselType': _selectedVesselType,
        'description': _descriptionController.text,
        'location': _currentPosition,
      });

      // 3. Save data to Firestore
      print("Saving to Firestore...");
      await FirebaseFirestore.instance.collection('complaints').doc(complaintId).set({
        'id': complaintId,
        'reporterName': _isAnonymous ? 'Anonymous' : widget.farmerName,
        'isAnonymous': _isAnonymous,
        'vesselType': _selectedVesselType,
        'activityType': _selectedActivityType,
        'description': _descriptionController.text,
        'location': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        'imageUrl': imageUrl,
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
    return Scaffold(
      appBar: AppBar(
        // ... (appbar remains same but conditionally hiding back button on success is handled in body, lets keep back button to close)
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
      ),
      body: _isSuccess 
        ? _buildSuccessScreen()
        : (_isSubmitting 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  // ... forms remain same until end of Column
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWarningBanner(),
                    const SizedBox(height: 24),
                    
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
                    const Text('Vessel Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                         labelText: 'Vessel Type',
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                         prefixIcon: const Icon(Icons.directions_boat)
                      ),
                      value: _selectedVesselType,
                      items: _vesselTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) => setState(() => _selectedVesselType = newValue),
                      validator: (value) => value == null ? 'Please select a vessel type' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                         labelText: 'Type of Suspicious Activity',
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                         prefixIcon: const Icon(Icons.warning_amber)
                      ),
                      value: _selectedActivityType,
                      items: _activityTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
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
                      ),
                      validator: (value) => value!.isEmpty ? 'Please provide a brief description' : null,
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
                    const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // Location Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _currentPosition != null ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _currentPosition != null ? Colors.green.shade200 : Colors.red.shade200)
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _currentPosition != null ? Icons.check_circle : Icons.gps_fixed, 
                            color: _currentPosition != null ? Colors.green : Colors.red
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                               _currentPosition != null 
                                ? 'Location captured: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                : 'Fetching GPS Location...',
                               style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 color: _currentPosition != null ? Colors.green.shade700 : Colors.red.shade700
                               ),
                            ),
                          )
                        ],
                      ),
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
                    )
                  ],
                ),
              ),
            )),
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
              'Your complaint has been recorded and will be reviewed by the authorities.',
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

