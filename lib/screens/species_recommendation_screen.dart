import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/species_prediction_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ocean_glass_card.dart';

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
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Text(
              'AI Species Prediction',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(currentTemp, currentPh, currentSalinity, currentTurbidity).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),
                  Center(
                    child: InkWell(
                      onTap: _isLoading ? null : () => _getPredictions(currentTemp, currentPh, currentSalinity, currentTurbidity),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoading)
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            else
                              const Icon(Icons.analytics, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              _isLoading ? 'Analyzing...' : 'Predict Best Species',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(delay: 200.ms),
                  ),
                  const SizedBox(height: 32),
                  if (_recommendations.isNotEmpty) ...[
                    Text(
                      'Recommended Species',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 16),
                    ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
                  ],
                  const SizedBox(height: 150),
                ],
              ),
            );
          },
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildInputSection(double temp, double ph, double salinity, double turbidity) {
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live IoT Parameters',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi, size: 14, color: Colors.green),
                    SizedBox(width: 6),
                    Text("Live", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These values are streaming live from your farm\'s sensors via Firebase.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildReadonlySlider('Temperature (°C)', temp, 15, 45),
          const SizedBox(height: 12),
          _buildReadonlySlider('pH Level', ph, 0, 14),
          const SizedBox(height: 12),
          _buildReadonlySlider('Salinity (ppt)', salinity, 0, 40),
          const SizedBox(height: 12),
          _buildReadonlySlider('Turbidity (NTU)', turbidity, 0, 100),
        ],
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
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            Text(value.toStringAsFixed(1), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.15),
            onChanged: null,
          ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: OceanGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rec['species'],
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Score: ${rec['score'].toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    rec['status'],
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
                if (rec['isLocalFallback'] == true) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.offline_bolt, size: 20, color: Colors.orange),
                ]
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _getImageForSpecies(rec['species']),
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                     Container(
                       height: 180, 
                       color: Colors.blue.withOpacity(0.05), 
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.broken_image, size: 40, color: AppColors.secondary),
                           const SizedBox(height: 8),
                           Text('Image not found', style: TextStyle(color: AppColors.secondary)),
                         ],
                       ),
                     ),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }
}
