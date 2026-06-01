import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../services/notification_service.dart';
import '../services/ml_prediction_service.dart';
import '../widgets/weather_widget.dart';
import '../widgets/ocean_glass_card.dart';
import '../widgets/app_card.dart';
import '../theme/app_theme.dart';

class IotMonitoringScreen extends StatefulWidget {
  const IotMonitoringScreen({super.key});
  @override
  State<IotMonitoringScreen> createState() => _IotMonitoringScreenState();
}

class _IotMonitoringScreenState extends State<IotMonitoringScreen> {
  Map<String, String> _lastAlertedIssues = {
    "Whiteleg Shrimp": "",
    "Tiger Shrimp": "",
    "Tilapia": "",
    "Catfish": "",
    "Milkfish": "",
  };
  static final Set<String> _acknowledgedAlerts = {};

  void _checkAndAlert(int riskLevel, BuildContext context, String species, String disease) {
    final alertKey = "$species-$disease";
    if (riskLevel > 0 && !_acknowledgedAlerts.contains(alertKey) && _lastAlertedIssues[species] != disease) {
      _lastAlertedIssues[species] = disease;
      NotificationService.showNotification(
        id: species.hashCode,
        title: riskLevel == 2 ? '⚠️ High AI Alert: $species' : '⚠️ AI Warning: $species',
        body: 'Disease Predicted: $disease',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false, // Ensure acknowledgement action
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (riskLevel == 2 ? AppColors.danger : AppColors.warning).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: riskLevel == 2 ? AppColors.danger : AppColors.warning, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    riskLevel == 2 ? 'HIGH RISK DETECTED' : 'MEDIUM RISK WARNING',
                    style: GoogleFonts.inter(
                      color: riskLevel == 2 ? AppColors.danger : AppColors.warning,
                      fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Text(
              'ML model detected risk for $species:\n\n• Predicted: $disease\n\nCheck water conditions and log visual symptoms.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: riskLevel == 2 ? AppColors.danger : AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _acknowledgedAlerts.add(alertKey);
                  });
                  Navigator.of(ctx).pop();
                },
                child: const Text('Acknowledge'),
              ),
            ],
          ),
        );
      });
    } else if (riskLevel == 0) {
      _lastAlertedIssues[species] = "";
      // Reset acknowledgment when returning to healthy state
      _acknowledgedAlerts.removeWhere((key) => key.startsWith("$species-"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Image banner
            _buildImageBanner().animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WeatherWidget().animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                  const SizedBox(height: 24),
                  _buildSectionHeader().animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('water_parameters')
                        .doc('2pBQE1SbutGXrRT6NjjA')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }
                      if (snapshot.hasError) return _buildError('${snapshot.error}');
                      if (!snapshot.hasData || !snapshot.data!.exists)
                        return _buildError('No sensor data found');

                      final values = snapshot.data!.data() as Map<String, dynamic>;
                      final sensorData = {
                        "turbidity": double.tryParse(values['turbidity']?.toString() ?? '0') ?? 0.0,
                        "temperature": double.tryParse(values['temperature']?.toString() ?? '0') ?? 0.0,
                        "ph": double.tryParse((values['pH'] ?? values['ph'])?.toString() ?? '0') ?? 0.0,
                        "salinity": double.tryParse(values['salinity']?.toString() ?? '0') ?? 0.0,
                      };
                      return _buildSensorCard(sensorData).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
                    },
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBanner() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.asset(
              'assets/images/iot_sensor.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.oceanGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.primary.withOpacity(0.8)],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 24),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white54),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IoT Water Monitoring',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
                    Text('Live sensor data feed',
                        style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9), fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.6), blurRadius: 5)],
                        ),
                      ).animate(onPlay: (controller) => controller.repeat()).fadeIn(duration: 800.ms).fadeOut(duration: 800.ms, delay: 200.ms),
                      const SizedBox(width: 6),
                      Text('Live', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.oceanGradient),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text('Sensor Readings',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const Spacer(),
        Text('Updated just now',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildError(String message) {
    return OceanGlassCard(
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 12),
          Text(message, style: GoogleFonts.inter(color: AppColors.danger)),
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic> data) {
    final double turbidityVal = data['turbidity'];
    final double tempVal = data['temperature'];
    final double phVal = data['ph'];
    final double salinityVal = data['salinity'];

    return Column(
      children: [
        // Gauge card
        OceanGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.waves_rounded, color: AppColors.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Water Parameters',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Real-time',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double cardWidth = constraints.maxWidth;
                  if (cardWidth >= 520) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ModernRadialGauge(
                            title: 'Turbidity', value: turbidityVal,
                            min: 0, max: 40, unit: ' NTU',
                          ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
                        ),
                        Expanded(
                          child: ModernRadialGauge(
                            title: 'Temperature', value: tempVal,
                            min: 15, max: 45, unit: '°C',
                          ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack),
                        ),
                        Expanded(
                          child: ModernRadialGauge(
                            title: 'pH Level', value: phVal,
                            min: 0, max: 14, unit: '',
                          ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack),
                        ),
                        Expanded(
                          child: ModernRadialGauge(
                            title: 'Salinity', value: salinityVal,
                            min: 0, max: 40, unit: ' ppt',
                          ).animate().scale(delay: 700.ms, duration: 400.ms, curve: Curves.easeOutBack),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ModernRadialGauge(
                                title: 'Turbidity', value: turbidityVal,
                                min: 0, max: 40, unit: ' NTU',
                              ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
                            ),
                            Expanded(
                              child: ModernRadialGauge(
                                title: 'Temperature', value: tempVal,
                                min: 15, max: 45, unit: '°C',
                              ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ModernRadialGauge(
                                title: 'pH Level', value: phVal,
                                min: 0, max: 14, unit: '',
                              ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack),
                            ),
                            Expanded(
                              child: ModernRadialGauge(
                                title: 'Salinity', value: salinityVal,
                                min: 0, max: 40, unit: ' ppt',
                              ).animate().scale(delay: 700.ms, duration: 400.ms, curve: Curves.easeOutBack),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // AI Risk card
        OceanGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('AI Disease Risk Analysis',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              _buildRiskProfile("Whiteleg Shrimp", tempVal, phVal, turbidityVal, salinityVal).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
              const SizedBox(height: 16),
              _buildRiskProfile("Tiger Shrimp", tempVal, phVal, turbidityVal, salinityVal).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
              const SizedBox(height: 16),
              _buildRiskProfile("Tilapia", tempVal, phVal, turbidityVal, salinityVal).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1),
              const SizedBox(height: 16),
              _buildRiskProfile("Catfish", tempVal, phVal, turbidityVal, salinityVal).animate().fadeIn(delay: 800.ms).slideX(begin: 0.1),
              const SizedBox(height: 16),
              _buildRiskProfile("Milkfish", tempVal, phVal, turbidityVal, salinityVal).animate().fadeIn(delay: 900.ms).slideX(begin: 0.1),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRiskProfile(String species, double tempVal, double phVal, double turbidityVal, double salinityVal) {
    return FutureBuilder<String>(
      future: MlPredictionService.getPrediction(
        species: species,
        temperature: tempVal,
        ph: phVal,
        turbidity: turbidityVal,
        salinity: salinityVal,
      ),
      builder: (context, snapshot) {
        bool isWaiting = snapshot.connectionState == ConnectionState.waiting;
        String status = "Analyzing...";
        Color statusColor = AppColors.textMuted;
        int riskLevel = 0;

        if (snapshot.hasError) {
          status = "ML Server Offline";
          statusColor = AppColors.warning;
        } else if (snapshot.hasData) {
          status = snapshot.data!;
          final lower = status.toLowerCase();
          if (lower.contains("healthy") || lower.contains("safe") || status.trim().isEmpty) {
            status = "Healthy";
            statusColor = AppColors.success;
            riskLevel = 0;
          } else if (lower.contains("mild")) {
            statusColor = AppColors.warning;
            riskLevel = 1;
          } else {
            statusColor = AppColors.danger;
            riskLevel = 2;
          }
        }

        if (!isWaiting && snapshot.hasData) _checkAndAlert(riskLevel, context, species, status);

        final Color accent = riskLevel == 2 ? AppColors.danger
            : riskLevel == 1 ? AppColors.warning
            : (isWaiting ? AppColors.textMuted : AppColors.success);

        final Color bgColor = riskLevel == 2 ? AppColors.dangerLight
            : riskLevel == 1 ? AppColors.warningLight
            : (isWaiting ? AppColors.cardLight : AppColors.successLight);

        return Container(
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(species,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    IconButton(
                      icon: Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Safe Ranges',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => _showSafeRangeInfo(context, species),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _riskRow(Icons.psychology_rounded, AppColors.primary, 'ML Prediction',
                    isWaiting
                        ? SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : Text(status,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800, color: statusColor, fontSize: 13))),
                const SizedBox(height: 10),
                _riskRow(Icons.health_and_safety_rounded, AppColors.secondary, 'Risk Level',
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withOpacity(0.4)),
                      ),
                      child: Text(
                        riskLevel == 2 ? 'High Risk'
                            : riskLevel == 1 ? 'Medium Risk'
                            : isWaiting ? 'Computing...' : 'Safe',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: accent, fontSize: 11),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _riskRow(IconData icon, Color iconColor, String label, Widget child) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 1.0),
          child: Text('$label: ', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }

  void _showSafeRangeInfo(BuildContext context, String species) {
    final bool isTilapia = species == "Tilapia";
    final rows = [
      ['Temperature', isTilapia ? '24–30°C' : '26–32°C'],
      ['pH', isTilapia ? '6.5 – 9.0' : '7.0 – 8.5'],
      ['Turbidity', isTilapia ? '< 25 NTU' : '< 20 NTU'],
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safe Ranges',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text(species.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(child: Text('Parameter', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
              Expanded(child: Text('Safe Zone', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
            ]),
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.divider),
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Text(row[0], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary))),
                  Expanded(child: Text(row[1],
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success))),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEEDOMETER GAUGE
// ─────────────────────────────────────────────────────────────────────────────
class ModernRadialGauge extends StatelessWidget {
  final double value, min, max;
  final String title, unit;

  const ModernRadialGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.title,
    required this.unit,
  });

  Map<String, dynamic> _getSensorStatus(String title, double value) {
    final String lowerTitle = title.toLowerCase();
    String status = "OPTIMAL";
    Color statusColor = AppColors.success;
    List<Color> gradient = [const Color(0xFF10B981), const Color(0xFF06B6D4)]; // Emerald to Cyan
    IconData icon = Icons.info_outline_rounded;

    if (lowerTitle.contains("temp")) {
      icon = Icons.thermostat_rounded;
      if (value < 20.0 || value > 35.0) {
        status = "CRITICAL";
        statusColor = AppColors.danger;
        gradient = [AppColors.danger, const Color(0xFFF87171)];
      } else if (value < 24.0 || value > 30.0) {
        status = "WARNING";
        statusColor = AppColors.warning;
        gradient = [AppColors.warning, const Color(0xFFFBBF24)];
      }
    } else if (lowerTitle.contains("ph")) {
      icon = Icons.science_rounded;
      if (value < 5.5 || value > 9.5) {
        status = "CRITICAL";
        statusColor = AppColors.danger;
        gradient = [AppColors.danger, const Color(0xFFF87171)];
      } else if (value < 6.5 || value > 8.5) {
        status = "WARNING";
        statusColor = AppColors.warning;
        gradient = [AppColors.warning, const Color(0xFFFBBF24)];
      }
    } else if (lowerTitle.contains("turb")) {
      icon = Icons.opacity_rounded;
      if (value > 30.0) {
        status = "CRITICAL";
        statusColor = AppColors.danger;
        gradient = [AppColors.danger, const Color(0xFFF87171)];
      } else if (value > 20.0 || value < 2.0) {
        status = "WARNING";
        statusColor = AppColors.warning;
        gradient = [AppColors.warning, const Color(0xFFFBBF24)];
      }
    } else if (lowerTitle.contains("salin")) {
      icon = Icons.water_drop_rounded;
      if (value > 35.0) {
        status = "CRITICAL";
        statusColor = AppColors.danger;
        gradient = [AppColors.danger, const Color(0xFFF87171)];
      } else if (value > 30.0) {
        status = "WARNING";
        statusColor = AppColors.warning;
        gradient = [AppColors.warning, const Color(0xFFFBBF24)];
      }
    }

    return {
      "status": status,
      "color": statusColor,
      "gradient": gradient,
      "icon": icon,
    };
  }

  void _showSensorSafeRangeDialog(BuildContext context, String sensorTitle) {
    String displayTitle = sensorTitle;
    String safeRangeText = '';
    String description = '';
    IconData icon = Icons.info_outline_rounded;
    Color iconColor = AppColors.primary;
    
    if (sensorTitle.toLowerCase().contains('temp')) {
      displayTitle = 'Water Temperature';
      safeRangeText = '24.0°C – 30.0°C';
      description = 'Maintaining optimal temperature is vital for metabolism, feeding rate, and growth of aquatic species. Extreme temperatures can lead to thermal stress and low oxygen levels.';
      icon = Icons.thermostat_rounded;
      iconColor = AppColors.danger;
    } else if (sensorTitle.toLowerCase().contains('ph')) {
      displayTitle = 'pH Level';
      safeRangeText = '6.5 – 8.5';
      description = 'pH measures the acidity of water. Aquatic life thrives in a neutral to slightly alkaline environment. A low pH (< 6.5) can cause gill damage, while a high pH (> 8.5) increases toxic ammonia levels.';
      icon = Icons.science_rounded;
      iconColor = AppColors.success;
    } else if (sensorTitle.toLowerCase().contains('turb')) {
      displayTitle = 'Water Turbidity';
      safeRangeText = '2.0 – 20.0 NTU';
      description = 'Turbidity measures water clarity. Good turbidity indicates optimal plankton density for feeding. Extremely high turbidity (> 20 NTU) blocks sunlight, hindering plant photosynthesis and clogging fish gills.';
      icon = Icons.opacity_rounded;
      iconColor = AppColors.secondary;
    } else if (sensorTitle.toLowerCase().contains('salin')) {
      displayTitle = 'Water Salinity';
      safeRangeText = '0.0 – 35.0 ppt';
      description = 'Salinity measures the concentration of dissolved salts. Proper salinity is essential for maintaining osmotic balance. High salinity (> 35 ppt) causes dehydration and stress in freshwater-loving species.';
      icon = Icons.water_drop_rounded;
      iconColor = AppColors.info;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayTitle,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Safe Range',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.2)),
              ),
              child: Text(
                safeRangeText,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Importance & Impact',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getSensorStatus(title, value);
    final String status = statusInfo["status"];
    final Color statusColor = statusInfo["color"];
    final List<Color> gradient = statusInfo["gradient"];
    final IconData sensorIcon = statusInfo["icon"];

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(AppColors.isDark ? 0.35 : 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(AppColors.isDark ? 0.25 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient Radial Gradient glow at the top-left to give depth
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      statusColor.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Row with custom indicator icon, Title and Info Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Icon(sensorIcon, color: statusColor, size: 16),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'View Ranges & Impact',
                        child: InkWell(
                          onTap: () => _showSensorSafeRangeDialog(context, title),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Radial Gauge Dial
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RadialGaugePainter(
                              value: value,
                              min: min,
                              max: max,
                              gradientColors: gradient,
                              statusColor: statusColor,
                            ),
                          ),
                        ),
                        // Centered Value & Unit
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              value.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                height: 1.0,
                              ),
                            ),
                            if (unit.isNotEmpty)
                              Text(
                                unit.trim(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  height: 1.2,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Clean status badge at the bottom
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dynamic beating indicator dot
                        _BeatingIndicatorDot(color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
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

class _BeatingIndicatorDot extends StatefulWidget {
  final Color color;
  const _BeatingIndicatorDot({required this.color});

  @override
  State<_BeatingIndicatorDot> createState() => _BeatingIndicatorDotState();
}

class _BeatingIndicatorDotState extends State<_BeatingIndicatorDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6 * _animation.value),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double value, min, max;
  final List<Color> gradientColors;
  final Color statusColor;

  _RadialGaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.gradientColors,
    required this.statusColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 8.0;
    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // 270 degree circular gauge
    final double startAngle = 0.75 * math.pi; // 135 degrees
    final double totalSweep = 1.5 * math.pi;  // 270 degrees

    // 1. Background Track
    final Paint bgPaint = Paint()
      ..color = AppColors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(rect, startAngle, totalSweep, false, bgPaint);

    // 2. Active Progress Arc
    final double clampedVal = value.clamp(min, max);
    final double progress = (clampedVal - min) / (max - min);
    final double activeSweep = totalSweep * progress;

    if (activeSweep > 0) {
      final Paint activePaint = Paint()
        ..shader = SweepGradient(
          colors: gradientColors,
          stops: const [0.0, 1.0],
          transform: GradientRotation(startAngle),
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, activeSweep, false, activePaint);

      // 3. Glowing Pointer Tip
      final double tipAngle = startAngle + activeSweep;
      final Offset tipOffset = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );

      // Glowing outer shadow ring
      final Paint thumbGlow = Paint()
        ..color = statusColor.withOpacity(0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(tipOffset, 7.5, thumbGlow);

      // Solid white center core
      final Paint thumbCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipOffset, 3.5, thumbCore);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.statusColor != statusColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}
