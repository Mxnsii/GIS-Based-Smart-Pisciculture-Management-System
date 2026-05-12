import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/species_prediction_service.dart';

class SpeciesRecommendationScreen extends StatefulWidget {
  const SpeciesRecommendationScreen({super.key});

  @override
  State<SpeciesRecommendationScreen> createState() => _SpeciesRecommendationScreenState();
}

class _SpeciesRecommendationScreenState extends State<SpeciesRecommendationScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _recommendations = [];

  // Helper mapping species to image paths
  String _getImageForSpecies(String species) {
    switch (species.toLowerCase()) {
      case 'whiteleg shrimp':
        return 'assets/images/whiteleg_shrimp.png';
      case 'tiger shrimp':
        return 'assets/images/tiger_shrimp.png';
      case 'tilapia':
        return 'assets/images/tilapia.png'; // Updated to user's specified image
      case 'catfish':
        return 'assets/images/catfish.png';
      case 'milkfish':
        return 'assets/images/milkfish.png';
      default:
        return 'assets/images/logo.png'; // Fallback
    }
  }

  void _getPredictions(double temp, double ph, double salinity, double turbidity) async {
    setState(() {
      _isLoading = true;
    });

    final results = await SpeciesPredictionService.getSpeciesRecommendations(
      temperature: temp,
      ph: ph,
      salinity: salinity,
      turbidity: turbidity,
    );

    setState(() {
      _recommendations = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AI Species Prediction', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('water_parameters').doc('2pBQE1SbutGXrRT6NjjA').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          double currentTemp = 28.0;
          double currentPh = 7.5;
          double currentSalinity = 10.0;
          double currentTurbidity = 25.0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            currentTemp = double.tryParse(data['temperature']?.toString() ?? '28.0') ?? 28.0;
            currentPh = double.tryParse((data['pH'] ?? data['ph'])?.toString() ?? '7.5') ?? 7.5;
            currentSalinity = double.tryParse(data['salinity']?.toString() ?? '10.0') ?? 10.0;
            currentTurbidity = double.tryParse(data['turbidity']?.toString() ?? '25.0') ?? 25.0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputSection(currentTemp, currentPh, currentSalinity, currentTurbidity),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _getPredictions(currentTemp, currentPh, currentSalinity, currentTurbidity),
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.analytics),
                    label: Text(_isLoading ? 'Analyzing...' : 'Predict Best Species'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_recommendations.isNotEmpty) ...[
                  const Text(
                    'Recommended Species',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
                ]
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildInputSection(double temp, double ph, double salinity, double turbidity) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live IoT Parameters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text("Live", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These values are streaming live from your farm\'s sensors via Firebase.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildReadonlySlider('Temperature (°C)', temp, 15, 45),
            _buildReadonlySlider('pH Level', ph, 0, 14),
            _buildReadonlySlider('Salinity (ppt)', salinity, 0, 40),
            _buildReadonlySlider('Turbidity (NTU)', turbidity, 0, 100),
          ],
        ),
      ),
    );
  }

  Widget _buildReadonlySlider(String label, double value, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: const Color(0xFF2563EB),
          inactiveColor: Colors.blue.withOpacity(0.2),
          onChanged: null, // Read-only
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    Color badgeColor;
    switch (rec['status']) {
      case 'Highly Suitable':
        badgeColor = Colors.green;
        break;
      case 'Suitable':
        badgeColor = Colors.lightGreen;
        break;
      case 'Moderately Suitable':
        badgeColor = Colors.orange;
        break;
      default:
        badgeColor = Colors.red;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rec['species'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Score: ${rec['score'].toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(
                    rec['status'],
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
                if (rec['isLocalFallback'] == true) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.offline_bolt, size: 20, color: Colors.orange),
                ]
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _getImageForSpecies(rec['species']),
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                     Container(
                       height: 180, 
                       color: Colors.grey.shade300, 
                       child: const Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                           SizedBox(height: 8),
                           Text('Image not found', style: TextStyle(color: Colors.grey)),
                         ],
                       ),
                     ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
