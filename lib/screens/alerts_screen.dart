import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/ocean_glass_card.dart';
import '../widgets/animated_wave_header.dart';
import '../theme/app_theme.dart';
import '../services/alert_state.dart';
import '../services/ml_prediction_service.dart';

enum AlertSeverity { critical, warning, info }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  StreamSubscription<DocumentSnapshot>? _subscription;
  double? _temp;
  double? _ph;
  double? _salinity;
  double? _turbidity;
  
  List<Map<String, dynamic>> _aiAlerts = [];
  bool _loadingAi = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription = FirebaseFirestore.instance
        .collection('water_parameters')
        .doc('2pBQE1SbutGXrRT6NjjA')
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'No sensor data found';
          });
        }
        return;
      }
      
      final doc = snapshot.data() as Map<String, dynamic>;
      final temp = double.tryParse(doc['temperature']?.toString() ?? '0') ?? 0.0;
      final ph = double.tryParse((doc['pH'] ?? doc['ph'])?.toString() ?? '0') ?? 0.0;
      final turbidity = double.tryParse(doc['turbidity']?.toString() ?? '0') ?? 0.0;
      final salinity = double.tryParse(doc['salinity']?.toString() ?? '0') ?? 0.0;

      if (_temp != temp || _ph != ph || _salinity != salinity || _turbidity != turbidity) {
        if (mounted) {
          setState(() {
            _temp = temp;
            _ph = ph;
            _salinity = salinity;
            _turbidity = turbidity;
          });
        }
        _fetchAiAlerts(temp, ph, salinity, turbidity);
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    });
  }

  Future<void> _fetchAiAlerts(double temp, double ph, double salinity, double turbidity) async {
    if (!mounted) return;
    setState(() {
      _loadingAi = true;
    });

    final speciesList = ["Whiteleg Shrimp", "Tiger Shrimp", "Tilapia", "Catfish", "Milkfish"];
    final List<Map<String, dynamic>> results = [];

    try {
      await Future.wait(speciesList.map((species) async {
        final prediction = await MlPredictionService.getPrediction(
          species: species,
          temperature: temp,
          ph: ph,
          salinity: salinity,
          turbidity: turbidity,
        );
        final lower = prediction.toLowerCase();
        int riskLevel = 0;
        if (lower.contains("healthy") || lower.contains("safe") || prediction.trim().isEmpty) {
          riskLevel = 0;
        } else if (lower.contains("mild")) {
          riskLevel = 1;
        } else {
          riskLevel = 2;
        }

        if (riskLevel > 0) {
          results.add({
            'species': species,
            'prediction': prediction,
            'riskLevel': riskLevel,
          });
        }
      }));
    } catch (e) {
      debugPrint("Error fetching AI alerts: $e");
    }

    if (mounted) {
      setState(() {
        _aiAlerts = results;
        _loadingAi = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedWaveHeader(
            height: 110,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'System Alerts',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideX(),
                      if (_loadingAi)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ).animate().fadeIn(),
                    ],
                  ),
                  Text(
                    'Real-time IoT & AI warnings',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ValueListenableBuilder<int>(
                valueListenable: AlertState.alertNotifier,
                builder: (context, _, __) {
                  if (_hasError) {
                    return Center(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.inter(color: AppColors.danger),
                      ),
                    );
                  }

                  if (_temp == null) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  // 1. Gather all compiled alerts
                  final List<Map<String, dynamic>> allAlerts = [];

                  final double temp = _temp!;
                  final double ph = _ph!;
                  final double salinity = _salinity!;
                  final double turbidity = _turbidity!;

                  // Check Salinity
                  if (salinity > 35) {
                    final key = "parameter-salinity-high";
                    allAlerts.add({
                      'key': key,
                      'title': "High Salinity Level",
                      'description': "Salinity is above safe range (≤ 35 ppt). Current: $salinity ppt. Unsafe range: > 35 ppt.",
                      'severity': AlertSeverity.critical,
                      'type': "IoT Monitor",
                      'recommendations': [
                        "Add fresh water to reduce salt concentration",
                        "Ensure proper shading to limit evaporation",
                        "Monitor species closely for osmotic stress",
                      ],
                    });
                  }

                  // Check pH
                  if (ph < 6.5) {
                    final key = "parameter-ph-low";
                    allAlerts.add({
                      'key': key,
                      'title': "Low pH Level",
                      'description': "pH is below safe range (6.5–8.5). Current: $ph. Unsafe range: < 6.5.",
                      'severity': AlertSeverity.critical,
                      'type': "IoT Monitor",
                      'recommendations': [
                        "Add Agricultural Lime (Calcium carbonate)",
                        "Use Dolomite",
                        "Partial water exchange",
                      ],
                    });
                  } else if (ph > 8.5) {
                    final key = "parameter-ph-high";
                    allAlerts.add({
                      'key': key,
                      'title': "High pH Level",
                      'description': "pH is above safe range (6.5–8.5). Current: $ph. Unsafe range: > 8.5.",
                      'severity': AlertSeverity.critical,
                      'type': "IoT Monitor",
                      'recommendations': [
                        "Partial water change",
                        "Add organic matter (cow dung compost in traditional farming)",
                        "Reduce excessive algae growth",
                        "Use aerators",
                      ],
                    });
                  }

                  // Check Temperature
                  if (temp < 24) {
                    final key = "parameter-temp-low";
                    allAlerts.add({
                      'key': key,
                      'title': "Low Temperature",
                      'description': "Temperature is too low for most species (safe 24–30°C). Current: $temp°C. Unsafe range: < 24°C.",
                      'severity': AlertSeverity.warning,
                      'type': "IoT Monitor",
                      'recommendations': [
                        "Cover pond with plastic sheets (temporary greenhouse)",
                        "Increase water depth",
                        "Reduce feeding",
                        "Use aerators",
                      ],
                    });
                  } else if (temp > 30) {
                    final key = "parameter-temp-high";
                    allAlerts.add({
                      'key': key,
                      'title': "High Temperature",
                      'description': "Temperature exceeded safe range (24–30°C). Current: $temp°C. Unsafe range: > 30°C.",
                      'severity': AlertSeverity.warning,
                      'type': "IoT Monitor",
                      'recommendations': [
                        "Install aerators",
                        "Add shade nets",
                        "Add fresh water",
                        "Maintain proper water depth",
                      ],
                    });
                  }

                  // Check Turbidity
                  if (turbidity < 2) {
                    final key = "parameter-turbidity-low";
                    allAlerts.add({
                      'key': key,
                      'title': "Low Turbidity",
                      'description': "Turbidity is very low for plankton growth (safe 2–20 NTU). Current: $turbidity. Unsafe range: < 2 NTU.",
                      'severity': AlertSeverity.warning,
                      'type': "IoT Monitor",
                      'recommendations': [
                        "Add organic fertilizers (cow dung / compost)",
                        "Promote plankton growth",
                      ],
                    });
                  } else if (turbidity > 20) {
                    final key = "parameter-turbidity-high";
                    allAlerts.add({
                      'key': key,
                      'title': "High Turbidity",
                      'description': "Turbidity is above safe range (2–20 NTU). Current: $turbidity. Unsafe range: > 20 NTU.",
                      'severity': AlertSeverity.critical,
                      'type': "IoT Monitor",
                      'recommendations': [
                        "Add Alum (Aluminium sulfate)",
                        "Let particles settle (sedimentation)",
                        "Reduce runoff entering pond",
                        "Control excess feeding",
                      ],
                    });
                  }

                  // Add AI alerts
                  for (var ai in _aiAlerts) {
                    final species = ai['species'] as String;
                    final prediction = ai['prediction'] as String;
                    final riskLevel = ai['riskLevel'] as int;
                    final key = "$species-risk";

                    allAlerts.add({
                      'key': key,
                      'title': "AI Disease Risk: $species",
                      'description': "ML analysis predicted: $prediction",
                      'severity': riskLevel == 2 ? AlertSeverity.critical : AlertSeverity.warning,
                      'type': "AI Prediction",
                      'recommendations': [
                        "Isolate the affected pond ecosystem immediately.",
                        "Increase oxygenation and run aeration systems 24/7.",
                        "Ensure water parameters (pH, temp, salinity) match safe ranges.",
                        "Report visual symptoms via the Report Incident tab if needed.",
                      ],
                    });
                  }

                  // Separation into Active vs. Acknowledged
                  final List<Map<String, dynamic>> activeAlerts = [];
                  final List<Map<String, dynamic>> acknowledgedAlerts = [];

                  for (var alert in allAlerts) {
                    final key = alert['key'] as String;
                    if (AlertState.isAcknowledged(key)) {
                      acknowledgedAlerts.add(alert);
                    } else {
                      activeAlerts.add(alert);
                    }
                  }

                  if (activeAlerts.isEmpty && acknowledgedAlerts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 120.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 16),
                            Text(
                              "All parameters and AI models stable",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(top: 10, bottom: 150),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (activeAlerts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0, left: 4),
                          child: Text(
                            "ACTIVE ISSUES (${activeAlerts.length})",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...activeAlerts.map((alert) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildAlertCard(
                              alertKey: alert['key'],
                              title: alert['title'],
                              description: alert['description'],
                              severity: alert['severity'],
                              type: alert['type'],
                              time: "Just now",
                              recommendations: List<String>.from(alert['recommendations']),
                              isAcknowledged: false,
                            ),
                          );
                        }),
                      ],
                      if (acknowledgedAlerts.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0, left: 4),
                          child: Text(
                            "ACKNOWLEDGED ALERTS (${acknowledgedAlerts.length})",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...acknowledgedAlerts.map((alert) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Opacity(
                              opacity: 0.75,
                              child: _buildAlertCard(
                                alertKey: alert['key'],
                                title: alert['title'],
                                description: alert['description'],
                                severity: alert['severity'],
                                type: alert['type'],
                                time: "Resolved",
                                recommendations: List<String>.from(alert['recommendations']),
                                isAcknowledged: true,
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String alertKey,
    required String title,
    required String description,
    required AlertSeverity severity,
    required String type,
    required String time,
    required List<String> recommendations,
    required bool isAcknowledged,
  }) {
    Color color;
    IconData icon;
    Color bgColor;

    if (isAcknowledged) {
      color = AppColors.success;
      bgColor = AppColors.successLight;
      icon = Icons.check_circle_outline_rounded;
    } else {
      switch (severity) {
        case AlertSeverity.critical:
          color = AppColors.danger;
          bgColor = AppColors.dangerLight;
          icon = Icons.warning_amber_rounded;
          break;
        case AlertSeverity.warning:
          color = AppColors.warning;
          bgColor = AppColors.warningLight;
          icon = Icons.error_outline_rounded;
          break;
        case AlertSeverity.info:
          color = AppColors.info;
          bgColor = AppColors.info.withOpacity(0.1);
          icon = Icons.info_outline_rounded;
          break;
      }
    }

    return OceanGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          color: bgColor.withOpacity(0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Builder(
                        builder: (context) {
                          if (isAcknowledged) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: AppColors.success, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "ACKNOWLEDGED",
                                  style: GoogleFonts.inter(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            );
                          }

                          return OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline_rounded, color: color),
                                      const SizedBox(width: 8),
                                      Text('Recommendations', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: recommendations
                                          .map((rec) => Padding(
                                                padding: const EdgeInsets.only(bottom: 12.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.check_circle_outline, size: 18, color: color),
                                                    const SizedBox(width: 10),
                                                    Expanded(child: Text(rec, style: GoogleFonts.inter(fontSize: 14))),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        AlertState.acknowledge(alertKey);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Alert acknowledged', style: GoogleFonts.inter())),
                                        );
                                      },
                                      child: Text('Acknowledge', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.shield_rounded, size: 16),
                            label: Text('Resolve', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: color,
                              side: BorderSide(color: color.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        }
                      ),
                    )
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
