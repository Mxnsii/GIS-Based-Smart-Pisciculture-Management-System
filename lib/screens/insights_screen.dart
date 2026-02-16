import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedMetric = 'Temperature'; // Default metric
  final List<String> _metrics = ['Temperature', 'pH', 'Turbidity'];
  String _selectedFarm = 'Farm A'; // Default farm
  final List<String> _farms = ['Farm A'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Insights & Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // Farm Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFarm,
                        icon: const Icon(Icons.arrow_drop_down),
                        elevation: 16,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedFarm = value;
                            });
                          }
                        },
                        items: _farms.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Metric Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMetric,
                        icon: const Icon(Icons.arrow_drop_down),
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedMetric = value;
                            });
                          }
                        },
                        items: _metrics.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Charts
          Expanded(
            child: ListView(
              children: [
                _buildRealtimeChartCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
         boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedMetric Trends (Real-time)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 2.5,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('water_parameters')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                List<FlSpot> spots = [];
                List<String> timestamps = []; // To store formatted timestamps for tooltips/axis
                
                int index = 0;
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Check if field exists
                   double? value;
                   if (_selectedMetric == 'Temperature') {
                     value = (data['temperature'] as num?)?.toDouble();
                   } else if (_selectedMetric == 'pH') {
                     value = (data['pH'] as num?)?.toDouble();
                   } else if (_selectedMetric == 'Turbidity') {
                     value = (data['turbidity'] as num?)?.toDouble();
                   }
                  
                  if (value != null) {
                    spots.add(FlSpot(index.toDouble(), value));
                    
                    // Format timestamp if available
                    if (data['timestamp'] != null) {
                         Timestamp ts = data['timestamp'] as Timestamp;
                         DateTime dt = ts.toDate();
                         timestamps.add(DateFormat('MM/dd HH:mm').format(dt));
                    } else {
                        timestamps.add('Start + $index');
                    }

                    index++;
                  }
                }
                
                if (spots.isEmpty) {
                   return const Center(child: Text('No valid data for selected metric'));
                }

                // Calculate Min/Max Y with padding
                double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
                double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
                
                // Custom logic for specific metrics
                // SIMPLIFIED: Force 0 start for anything that isn't Temperature
                if (_selectedMetric == 'Temperature') {
                    double range = maxY - minY;
                    if (range == 0) range = 1;
                    minY -= range * 0.5; // More padding for Temp
                    maxY += range * 0.5;
                } else {
                   minY = 0; // pH and Turbidity start at 0
                   if (maxY < 10) maxY = 10;
                   if (_selectedMetric == 'pH') maxY = 14;
                }

                return Column(
                  children: [
                   // Debug Text to ensure we know what logic is running
                    Text(
                      'Debug: $_selectedMetric | Range: ${minY.toStringAsFixed(1)} - ${maxY.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          clipData: FlClipData.all(), // Prevent drawing outside
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < timestamps.length) {
                                      if (value.toInt() % 5 == 0) {
                                           return Padding(
                                             padding: const EdgeInsets.only(top: 8.0),
                                             child: Text(
                                               timestamps[value.toInt()].split(' ').last,
                                               style: const TextStyle(fontSize: 10),
                                             ),
                                           );
                                      }
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: spots.length.toDouble() > 0 ? spots.length.toDouble() - 1 : 0,
                          minY: minY,
                          maxY: maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              preventCurveOverShooting: true, // Prevent dipping below data points
                              color: _getMetricColor(),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: _getMetricColor().withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getMetricColor() {
    switch (_selectedMetric) {
      case 'Temperature': return Colors.orange;
      case 'pH': return Colors.green;
      case 'Turbidity': return Colors.brown;
      default: return Colors.blue;
    }
  }
}
