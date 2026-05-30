import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/ocean_glass_card.dart';
import '../widgets/animated_wave_header.dart';
import '../theme/app_theme.dart';

enum AlertSeverity { critical, warning, info }

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

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
                  Text(
                    'System Alerts',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(),
                  Text(
                    'Real-time IoT & environmental warnings',
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('water_parameters')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("No sensor data found", style: GoogleFonts.inter(color: AppColors.textMuted)),
                    );
                  }

                  var doc = snapshot.data!.docs.first;

                  double temp = double.tryParse(doc['temperature']?.toString() ?? '0') ?? 0.0;
                  double ph = double.tryParse((doc['pH'] ?? doc['ph'])?.toString() ?? '0') ?? 0.0;
                  double turbidity = double.tryParse(doc['turbidity']?.toString() ?? '0') ?? 0.0;
                  double salinity = double.tryParse(doc['salinity']?.toString() ?? '0') ?? 0.0;

                  List<Widget> alerts = [];

                  if (salinity > 35) {
                    alerts.add(_buildAlertCard(
                      title: "High Salinity Level",
                      description: "Salinity is above safe range (≤ 35 ppt). Current: $salinity ppt. Unsafe range: > 35 ppt.",
                      severity: AlertSeverity.critical,
                      type: "IoT Monitor",
                      time: "Just now",
                      recommendations: [
                        "Add fresh water to reduce salt concentration",
                        "Ensure proper shading to limit evaporation",
                        "Monitor species closely for osmotic stress",
                      ],
                    ));
                  }

                  if (ph < 6.5) {
                    alerts.add(_buildAlertCard(
                      title: "Low pH Level",
                      description: "pH is below safe range (6.5–8.5). Current: $ph. Unsafe range: < 6.5.",
                      severity: AlertSeverity.critical,
                      type: "IoT Monitor",
                      time: "Just now",
                      recommendations: [
                        "Add Agricultural Lime (Calcium carbonate)",
                        "Use Dolomite",
                        "Partial water exchange",
                      ],
                    ));
                  } else if (ph > 8.5) {
                    alerts.add(_buildAlertCard(
                      title: "High pH Level",
                      description: "pH is above safe range (6.5–8.5). Current: $ph. Unsafe range: > 8.5.",
                      severity: AlertSeverity.critical,
                      type: "IoT Monitor",
                      time: "Just now",
                      recommendations: [
                        "Partial water change",
                        "Add organic matter (cow dung compost in traditional farming)",
                        "Reduce excessive algae growth",
                        "Use aerators",
                      ],
                    ));
                  }

                  if (temp < 24) {
                    alerts.add(_buildAlertCard(
                      title: "Low Temperature",
                      description: "Temperature is too low for most species (safe 24–30°C). Current: $temp°C. Unsafe range: < 24°C.",
                      severity: AlertSeverity.warning,
                      type: "IoT Monitor",
                      time: "Just now",
                      recommendations: [
                        "Cover pond with plastic sheets (temporary greenhouse)",
                        "Increase water depth",
                        "Reduce feeding",
                        "Use aerators",
                      ],
                    ));
                  } else if (temp > 30) {
                    alerts.add(_buildAlertCard(
                      title: "High Temperature",
                      description: "Temperature exceeded safe range (24–30°C). Current: $temp°C. Unsafe range: > 30°C.",
                      severity: AlertSeverity.warning,
                      type: "IoT Monitor",
                      time: "Just now",
                      recommendations: [
                        "Install aerators",
                        "Add shade nets",
                        "Add fresh water",
                        "Maintain proper water depth",
                      ],
                    ));
                  }

                  if (turbidity < 2) {
                    alerts.add(_buildAlertCard(
                      title: "Low Turbidity",
                      description: "Turbidity is very low for plankton growth (safe 2–20 NTU). Current: $turbidity. Unsafe range: < 2 NTU.",
                      severity: AlertSeverity.warning,
                      type: "IoT Monitor",
                      time: "Just now",
                      recommendations: [
                        "Add organic fertilizers (cow dung / compost)",
                        "Promote plankton growth",
                      ],
                    ));
                  } else if (turbidity > 20) {
                    alerts.add(_buildAlertCard(
                      title: "High Turbidity",
                      description: "Turbidity is above safe range (2–20 NTU). Current: $turbidity. Unsafe range: > 20 NTU.",
                      severity: AlertSeverity.critical,
                      type: "IoT Monitor",
                      time: "Just now",
                      recommendations: [
                        "Add Alum (Aluminium sulfate)",
                        "Let particles settle (sedimentation)",
                        "Reduce runoff entering pond",
                        "Control excess feeding",
                      ],
                    ));
                  }

                  if (alerts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 150.0),
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
                              "All parameters within safe range",
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ).animate().fadeIn(delay: 200.ms),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 10, bottom: 150),
                    itemCount: alerts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return alerts[index].animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1);
                    },
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
    required String title,
    required String description,
    required AlertSeverity severity,
    required String type,
    required String time,
    required List<String> recommendations,
  }) {
    Color color;
    IconData icon;
    Color bgColor;

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
                        Text(
                          title,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
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
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Builder(
                        builder: (context) {
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
