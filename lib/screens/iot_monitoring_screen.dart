import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../services/notification_service.dart';
import '../widgets/weather_widget.dart';

class IotMonitoringScreen extends StatefulWidget {
  const IotMonitoringScreen({super.key});

  @override
  State<IotMonitoringScreen> createState() => _IotMonitoringScreenState();
}

class _IotMonitoringScreenState extends State<IotMonitoringScreen> {
  // A tracking map to prevent spamming notifications for each species.
  // We keep track of the last alerted stress level and last alerted white spot risk.
  // Key format: "$species_stress" or "$species_whitespot"
  final Map<String, String> _lastAlertedLevels = {};

  void _checkAndAlert({
    required BuildContext context,
    required String species,
    required String stressLevel,
    String? whiteSpotRisk,
  }) {
    // Determine if we need to alert for High Stress
    final bool isHighStress = stressLevel == "High Stress";
    final bool isElevatedWhiteSpot = whiteSpotRisk == "Elevated";

    // 1. Check for High Stress Alert
    final String stressKey = "${species}_stress";
    if (isHighStress && _lastAlertedLevels[stressKey] != "High Stress") {
      _lastAlertedLevels[stressKey] = "High Stress";

      final recommendations = _getStressRecommendations(species);

      NotificationService.showNotification(
        id: (species + "Stress").hashCode,
        title: '⚠️ High Stress Alert: $species',
        body: 'Urgent: High Environmental Stress detected! View recommendations.',
      );

      _showAlertDialog(
        context: context,
        title: 'HIGH STRESS ALERT - $species',
        message: 'The AI model has detected HIGH environmental stress for $species. Immediate action is required to restore safe water parameters.',
        recommendations: recommendations,
        color: Colors.red,
      );
    } else if (!isHighStress) {
      _lastAlertedLevels[stressKey] = stressLevel; // Update state without alerting
    }

    // 2. Check for Elevated White Spot Risk (Shrimp only)
    if (whiteSpotRisk != null) {
      final String wsKey = "${species}_whitespot";
      if (isElevatedWhiteSpot && _lastAlertedLevels[wsKey] != "Elevated") {
        _lastAlertedLevels[wsKey] = "Elevated";

        final recommendations = [
          "Maintain temperature above 28°C if possible (White Spot Virus replicates faster below 27°C)",
          "Keep salinity stable (> 15 ppt) to minimize osmotic stress",
          "Ensure high aeration and paddlewheel operation",
          "Isolate the pond and restrict water exchange to prevent spread",
        ];

        NotificationService.showNotification(
          id: (species + "WS").hashCode,
          title: '⚠️ White Spot Risk Alert: $species',
          body: 'Critical: Elevated White Spot Disease Risk detected!',
        );

        _showAlertDialog(
          context: context,
          title: 'WHITE SPOT RISK ALERT - $species',
          message: 'The AI model has detected ELEVATED risk of White Spot Disease for $species. This is highly contagious and requires biosecurity measures.',
          recommendations: recommendations,
          color: Colors.red.shade800,
        );
      } else if (!isElevatedWhiteSpot) {
        _lastAlertedLevels[wsKey] = whiteSpotRisk;
      }
    }
  }

  List<String> _getStressRecommendations(String species) {
    switch (species) {
      case 'Whiteleg Shrimp':
        return [
          "Check salinity is within 15–30 ppt; adjust water exchange",
          "Ensure pH is between 7.5–8.5; apply dolomite if low",
          "Keep temperature within 26–32°C; run paddlewheel aerators to prevent temperature stratification",
        ];
      case 'Tiger Shrimp':
        return [
          "Maintain high salinity (15–25 ppt) and high temperature (28–33°C)",
          "Check and stabilize pH between 7.5–8.5",
          "Increase aeration immediately; tiger shrimp are highly sensitive to low oxygen and organic buildup",
        ];
      case 'Tilapia':
        return [
          "If salinity > 10 ppt, reduce it with fresh water",
          "Check if pH is outside 6.5–9.0; use agriculture lime if too acidic",
          "Verify temperature is between 24–30°C",
        ];
      case 'Catfish':
        return [
          "Check if pH is between 6.5–8.0; catfish prefer slightly acidic to neutral water",
          "If salinity is above 5 ppt, execute water exchange to introduce fresh water",
          "Maintain high water quality; siphon organic waste from the bottom",
        ];
      case 'Milkfish':
        return [
          "Maintain salinity between 10–30 ppt",
          "Ensure temperature is within 26–32°C; milkfish thrive in warm water",
          "Check pH is stable between 7.0–8.5",
        ];
      default:
        return [
          "Check all water parameters and verify sensor operations",
          "Consult with an aquaculturist",
        ];
    }
  }

  Map<String, String> _getSpeciesParameters(String species) {
    switch (species) {
      case 'Whiteleg Shrimp':
        return {
          'temp': '26–32°C',
          'ph': '7.5–8.5',
          'salinity': '15–30 ppt',
          'turbidity': '< 15 NTU',
        };
      case 'Tiger Shrimp':
        return {
          'temp': '28–33°C',
          'ph': '7.5–8.5',
          'salinity': '15–25 ppt',
          'turbidity': '< 10 NTU',
        };
      case 'Tilapia':
        return {
          'temp': '24–30°C',
          'ph': '6.5–9.0',
          'salinity': '0–10 ppt',
          'turbidity': '< 25 NTU',
        };
      case 'Catfish':
        return {
          'temp': '24–32°C',
          'ph': '6.5–8.0',
          'salinity': '0–5 ppt',
          'turbidity': '< 30 NTU',
        };
      case 'Milkfish':
        return {
          'temp': '26–32°C',
          'ph': '7.0–8.5',
          'salinity': '10–30 ppt',
          'turbidity': '< 20 NTU',
        };
      default:
        return {
          'temp': 'N/A',
          'ph': 'N/A',
          'salinity': 'N/A',
          'turbidity': 'N/A',
        };
    }
  }

  void _showAlertDialog({
    required BuildContext context,
    required String title,
    required String message,
    required List<String> recommendations,
    required Color color,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFF0F172A),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color, 
                      fontWeight: FontWeight.w800, 
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'RECOMMENDED ACTIONS:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 12, 
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right_alt, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(
                              fontSize: 14, 
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Acknowledged alert for $title'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: color,
                    ),
                  );
                },
                child: const Text('Acknowledge', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF090D16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WeatherWidget(),
          const SizedBox(height: 24),
          const Text(
            'IoT Real-time Monitoring',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('water_parameters').doc('2pBQE1SbutGXrRT6NjjA').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No sensor data found", style: TextStyle(color: Colors.white)));
                }

                final Map<String, dynamic> values =
                    snapshot.data!.data() as Map<String, dynamic>;

                final sensorData = {
                  "turbidity": double.tryParse(values['turbidity']?.toString() ?? '0') ?? 0.0,
                  "temperature": double.tryParse(values['temperature']?.toString() ?? '0') ?? 0.0,
                  "ph": double.tryParse((values['pH'] ?? values['ph'])?.toString() ?? '0') ?? 0.0,
                  "salinity": double.tryParse(values['salinity']?.toString() ?? '0') ?? 0.0,
                };

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSensorCard(sensorData),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Icon(Icons.psychology_outlined, color: Colors.blueAccent, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AI Species Risk Profiles',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w800, 
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Text(
                                  'Real-time multi-species bio-analytics powered by ML',
                                  style: TextStyle(
                                    fontSize: 11, 
                                    fontWeight: FontWeight.w500, 
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('results').doc('latest').snapshots(),
                        builder: (context, predSnapshot) {
                          if (predSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (predSnapshot.hasError) {
                            return Center(child: Text("AI Stream Error: ${predSnapshot.error}", style: const TextStyle(color: Colors.white)));
                          }

                          final Map<String, dynamic> predData = predSnapshot.hasData && predSnapshot.data!.exists
                              ? predSnapshot.data!.data() as Map<String, dynamic>
                              : {};

                          final speciesList = [
                            "Whiteleg Shrimp",
                            "Tiger Shrimp",
                            "Tilapia",
                            "Catfish",
                            "Milkfish"
                          ];

                          return Column(
                            children: speciesList.map((species) {
                              final speciesData = predData[species] as Map<String, dynamic>? ?? {
                                "stress_level": "Low Stress",
                                if (species == "Whiteleg Shrimp" || species == "Tiger Shrimp") "white_spot_risk": "Low"
                              };

                              final String stressLevel = speciesData["stress_level"] ?? "Low Stress";
                              final String? whiteSpotRisk = speciesData["white_spot_risk"];

                              // Trigger alerts on background notifications safely
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _checkAndAlert(
                                  context: context,
                                  species: species,
                                  stressLevel: stressLevel,
                                  whiteSpotRisk: whiteSpotRisk,
                                );
                              });

                              return _buildSpeciesCard(
                                context: context,
                                species: species,
                                stressLevel: stressLevel,
                                whiteSpotRisk: whiteSpotRisk,
                              );
                            }).toList(),
                          );
                        },
                      ),
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

  Widget _buildSensorCard(Map<String, dynamic> data) {
    final double turbidityVal = data['turbidity'];
    final double tempVal = data['temperature'];
    final double phVal = data['ph'];
    final double salinityVal = data['salinity'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 110,
            child: SpeedometerGauge(
              title: 'Turbidity',
              value: turbidityVal,
              min: 0,
              max: 40,
              unit: ' NTU',
              gradientColors: const [Colors.red, Colors.green, Colors.green, Colors.yellow, Colors.orange, Colors.red],
              gradientStops: const [0.0, 0.49, 0.5, 0.75, 0.8125, 1.0],
            ),
          ),
          SizedBox(
            width: 110,
            child: SpeedometerGauge(
              title: 'Temp',
              value: tempVal,
              min: 15,
              max: 45,
              unit: '°C',
              gradientColors: const [Colors.red, Colors.red, Colors.red, Colors.yellow, Colors.green, Colors.green, Colors.yellow, Colors.red],
              gradientStops: const [0.0, 0.49, 0.5, 0.6, 0.65, 0.78, 0.83, 1.0],
            ),
          ),
          SizedBox(
            width: 110,
            child: SpeedometerGauge(
              title: 'pH',
              value: phVal,
              min: 0,
              max: 14,
              unit: '',
              gradientColors: const [Colors.red, Colors.red, Colors.red, Colors.yellow, Colors.green, Colors.green, Colors.yellow, Colors.red],
              gradientStops: const [0.0, 0.49, 0.5, 0.675, 0.73, 0.82, 0.875, 1.0],
            ),
          ),
          SizedBox(
            width: 110,
            child: SpeedometerGauge(
              title: 'Salinity',
              value: salinityVal,
              min: 0,
              max: 40,
              unit: ' ppt',
              gradientColors: const [Colors.red, Colors.green, Colors.green, Colors.yellow, Colors.orange, Colors.red],
              gradientStops: const [0.0, 0.49, 0.5, 0.75, 0.8125, 1.0],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesCard({
    required BuildContext context,
    required String species,
    required String stressLevel,
    String? whiteSpotRisk,
  }) {
    // Colors for Stress Level
    Color stressBgColor;
    Color stressTextColor;
    Color stressBorderColor;
    IconData stressIcon;

    switch (stressLevel) {
      case 'High Stress':
        stressBgColor = Colors.red.withOpacity(0.15);
        stressTextColor = Colors.redAccent;
        stressBorderColor = Colors.redAccent.withOpacity(0.3);
        stressIcon = Icons.error_outline;
        break;
      case 'Moderate Stress':
        stressBgColor = Colors.orange.withOpacity(0.15);
        stressTextColor = Colors.orangeAccent;
        stressBorderColor = Colors.orangeAccent.withOpacity(0.3);
        stressIcon = Icons.warning_amber_rounded;
        break;
      case 'Mild Stress':
        stressBgColor = Colors.amber.withOpacity(0.15);
        stressTextColor = Colors.amberAccent;
        stressBorderColor = Colors.amberAccent.withOpacity(0.3);
        stressIcon = Icons.info_outline;
        break;
      case 'Low Stress':
      default:
        stressBgColor = Colors.teal.withOpacity(0.15);
        stressTextColor = Colors.tealAccent;
        stressBorderColor = Colors.tealAccent.withOpacity(0.3);
        stressIcon = Icons.check_circle_outline;
        break;
    }

    // Colors for White Spot Risk
    Color? wsBgColor;
    Color? wsTextColor;
    Color? wsBorderColor;
    IconData? wsIcon;

    if (whiteSpotRisk != null) {
      switch (whiteSpotRisk) {
        case 'Elevated':
          wsBgColor = Colors.red.withOpacity(0.15);
          wsTextColor = Colors.redAccent;
          wsBorderColor = Colors.redAccent.withOpacity(0.3);
          wsIcon = Icons.gpp_bad_outlined;
          break;
        case 'Moderate':
          wsBgColor = Colors.orange.withOpacity(0.15);
          wsTextColor = Colors.orangeAccent;
          wsBorderColor = Colors.orangeAccent.withOpacity(0.3);
          wsIcon = Icons.shield_outlined;
          break;
        case 'Low':
        default:
          wsBgColor = Colors.teal.withOpacity(0.15);
          wsTextColor = Colors.tealAccent;
          wsBorderColor = Colors.tealAccent.withOpacity(0.3);
          wsIcon = Icons.verified_user_outlined;
          break;
      }
    }

    // Species specific icon and description
    IconData speciesIcon = Icons.set_meal;
    String speciesDescription = '';
    if (species.contains('Shrimp')) {
      speciesIcon = Icons.waves_outlined;
      speciesDescription = 'Crustacean Species';
    } else {
      speciesIcon = Icons.set_meal_outlined;
      speciesDescription = 'Finfish Species';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          unselectedWidgetColor: Colors.white70,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Colors.blueAccent,
          ),
        ),
        child: ExpansionTile(
          key: PageStorageKey<String>(species),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(speciesIcon, color: Colors.blueAccent, size: 24),
          ),
          title: Text(
            species,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            speciesDescription,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
                tooltip: 'View Safe Ranges',
                onPressed: () => _showSafeRangeInfo(context, species),
              ),
              const Icon(Icons.expand_more, color: Colors.white70),
            ],
          ),
          initiallyExpanded: species.contains('Shrimp'), // Expand shrimp species by default since they have white spot risk!
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 16, color: Colors.white12),
            const SizedBox(height: 8),
            
            // Stress level title and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Environmental Stress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: stressBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stressBorderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stressIcon, color: stressTextColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        stressLevel,
                        style: TextStyle(
                          color: stressTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (whiteSpotRisk != null) ...[
              const SizedBox(height: 12),
              // White spot risk title and badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'White Spot Disease Risk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: wsBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: wsBorderColor!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(wsIcon, color: wsTextColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$whiteSpotRisk Risk',
                          style: TextStyle(
                            color: wsTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            // Interactive Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lightbulb_outline, size: 16),
                label: const Text('View Species Guidelines'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: BorderSide(color: Colors.blueAccent.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  final recs = _getStressRecommendations(species);
                  _showAlertDialog(
                    context: context,
                    title: '$species Guidelines',
                    message: 'Here are the recommended biosecurity and maintenance steps for $species based on current water parameters:',
                    recommendations: recs,
                    color: Colors.blueAccent,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSafeRangeInfo(BuildContext context, String species) {
    final ranges = _getSpeciesParameters(species);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF0F172A),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SAFE RANGES\n$species',
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white12, width: 1.5)),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Parameter',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Ideal Range',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Text('Temperature', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(ranges['temp']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ),
                    ],
                  ),
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Text('pH', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(ranges['ph']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ),
                    ],
                  ),
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Text('Turbidity', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(ranges['turbidity']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Text('Salinity', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(ranges['salinity']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }
}

class SpeedometerGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String title;
  final String unit;
  final List<Color> gradientColors;
  final List<double> gradientStops;

  const SpeedometerGauge({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.title,
    required this.unit,
    required this.gradientColors,
    required this.gradientStops,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 76.0;
        final double gaugeSize = maxWidth.clamp(64.0, 100.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: gaugeSize,
              height: gaugeSize * 0.65,
              child: CustomPaint(
                painter: _SpeedometerPainter(
                  value: value,
                  min: min,
                  max: max,
                  gradientColors: gradientColors,
                  gradientStops: gradientStops,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final List<Color> gradientColors;
  final List<double> gradientStops;

  _SpeedometerPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.gradientColors,
    required this.gradientStops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height);
    double radius = size.width / 2;
    Rect rect = Rect.fromCircle(center: center, radius: radius);

    Paint gradientPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        colors: gradientColors,
        stops: gradientStops,
      ).createShader(rect)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background track (so we see the full semi-circle clearly)
    Paint bgTrackPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, bgTrackPaint);

    // Draw full gauge gradient arc over the background
    canvas.drawArc(rect, math.pi, math.pi, false, gradientPaint);

    // Draw needle
    double clampedValue = value.clamp(min, max);
    double sweepAngle = math.pi * ((clampedValue - min) / (max - min));
    double needleAngle = math.pi + sweepAngle;
    
    Paint needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    Offset needleTip = Offset(
      center.dx + (radius - 5) * math.cos(needleAngle),
      center.dy + (radius - 5) * math.sin(needleAngle),
    );

    canvas.drawLine(center, needleTip, needlePaint);

    // Draw center pivot
    Paint pivotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 5, pivotPaint);
    Paint innerPivotPaint = Paint()..color = Colors.indigoAccent;
    canvas.drawCircle(center, 2, innerPivotPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
