import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'gis_map_view.dart';
import '../widgets/custom_back_button.dart';

class FarmDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> farmData;

  const FarmDetailsScreen({super.key, required this.farmData});

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  String _selectedMetric = 'Temperature'; // Default metric
  final List<String> _metrics = ['Temperature', 'pH', 'Turbidity'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      appBar: AppBar(
        title: Text(widget.farmData['name'] ?? 'Farm Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: CustomBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 80,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildSectionTitle('📍 GIS & Location'),
            _buildGisSection(context),
            const SizedBox(height: 16),
            // Updated Section Title
            _buildSectionTitle('📈 Insights'),
            _buildInsightsSection(), // Replaces _buildWaterQualitySection
            const SizedBox(height: 16),
            _buildSectionTitle('🐠 Fish Stock'),
            _buildStockSection(),
            const SizedBox(height: 16),
            _buildSectionTitle('⚠️ Risk & Alerts'),
            _buildRiskSection(),
            const SizedBox(height: 16),
            _buildSectionTitle('💰 Financials & Operations'),
            _buildFinancialSection(),
            const SizedBox(height: 16),
            _buildSectionTitle('📑 Documents'),
            _buildDocumentsSection(),
            const SizedBox(height: 16),
            _buildSectionTitle('📊 Performance Analytics'),
            _buildAnalyticsSection(),
            const SizedBox(height: 16),
            _buildSectionTitle('🔐 Approval Workflow'),
            _buildWorkflowSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A), // Slate 900
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm ID: ${widget.farmData['id'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.farmData['owner'] ?? 'Unknown Owner',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              _buildStatusBadge(widget.farmData['status'] ?? 'Unknown'),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone, widget.farmData['contact'] ?? 'N/A'),
          _buildInfoRow(Icons.email, widget.farmData['email'] ?? 'N/A'),
          _buildInfoRow(Icons.location_on, '${widget.farmData['village']}, ${widget.farmData['taluka']}'),
          _buildInfoRow(Icons.landscape, 'Area: ${widget.farmData['totalArea']} • Ponds: ${widget.farmData['pondCount']}'),
          _buildInfoRow(Icons.calendar_today, 'Reg: ${widget.farmData['regDate']} • Lic: ${widget.farmData['license']}'),
        ],
      ),
    );
  }

  Widget _buildGisSection(BuildContext context) {
    return _buildCard(
      child: Column(
        children: [
           Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildDetailItem('Latitude', '${widget.farmData['lat'] ?? 0.0}'),
                    _buildDetailItem('Longitude', '${widget.farmData['lng'] ?? 0.0}'),
                    _buildDetailItem('Elevation', widget.farmData['elevation'] ?? 'N/A'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildDetailItem('Soil Type', widget.farmData['soilType'] ?? 'N/A'),
                    _buildDetailItem('Zone', widget.farmData['landCategory'] ?? 'N/A'),
                    _buildDetailItem('Water Src', widget.farmData['waterSource'] ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                 if (widget.farmData['lat'] != null && widget.farmData['lng'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GisMapView(
                          initialLat: widget.farmData['lat'],
                          initialLng: widget.farmData['lng'],
                          initialZoom: 16,
                        ),
                      ),
                    );
                 }
              },
              icon: const Icon(Icons.map),
              label: const Text('View on GIS Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMetricUnit() {
    switch (_selectedMetric) {
      case 'Temperature': return '°C';
      case 'pH': return '';
      case 'Turbidity': return 'NTU';
      default: return '';
    }
  }

  Widget _buildInsightsSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text(
                'Real-time Trends',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              // Metric Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMetric,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
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
                        child: Text(value, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${_selectedMetric.toUpperCase()} ${_getMetricUnit().isNotEmpty ? '(${_getMetricUnit()})' : ''}',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.2,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 2.5, // Wider aspect ratio for better detail
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('water_parameters')
                  .orderBy('timestamp', descending: false)
                  .limit(20) // Limit to relevant recent data for clarity
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

                // 1. Process Data
                List<Map<String, dynamic>> chartData = [];
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  double? value;
                  if (_selectedMetric == 'Temperature') {
                    value = (data['temperature'] as num?)?.toDouble();
                  } else if (_selectedMetric == 'pH') {
                    value = (data['pH'] as num?)?.toDouble();
                  } else if (_selectedMetric == 'Turbidity') {
                    value = (data['turbidity'] as num?)?.toDouble();
                  }

                  if (value != null) {
                    DateTime? date;
                    if (data['timestamp'] != null) {
                      if (data['timestamp'] is Timestamp) {
                         date = (data['timestamp'] as Timestamp).toDate();
                      } else if (data['timestamp'] is String) {
                         date = DateTime.tryParse(data['timestamp']);
                      }
                    }
                    chartData.add({
                      'value': value,
                      'date': date ?? DateTime.now(),
                    });
                  }
                }

                if (chartData.isEmpty) {
                   return const Center(child: Text('No valid data for selected metric'));
                }

                // 2. Prepare Spots and Min/Max
                List<FlSpot> spots = [];
                for (int i = 0; i < chartData.length; i++) {
                   spots.add(FlSpot(i.toDouble(), chartData[i]['value']));
                }

                double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
                double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
                
                // Add padding to Y axis
                double yRange = maxY - minY;
                if (yRange == 0) yRange = 1;
                minY -= yRange * 0.2;
                maxY += yRange * 0.2;

                // Color Setup
                Color primaryColor = _getMetricColor();
                List<Color> gradientColors = [
                  primaryColor,
                  primaryColor.withOpacity(0.5),
                ];

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yRange / 5, // Approx 5 lines
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (spots.length / 5).ceilToDouble(), // Dynamic interval
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              DateTime date = chartData[index]['date'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MM/dd').format(date), // e.g. 10/24
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: yRange / 5, // Match grid
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.left,
                            );
                          },
                          reservedSize: 35,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble(),
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        preventCurveOverShooting: true,
                        color: primaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: primaryColor,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.3),
                              primaryColor.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final flSpot = barSpot;
                            if (flSpot.x < 0 || flSpot.x >= chartData.length) {
                              return null;
                            }
                            DateTime date = chartData[flSpot.x.toInt()]['date'];
                            String unit = _getMetricUnit();
                            return LineTooltipItem(
                              '${DateFormat('MMM d, h:mm a').format(date)}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              children: [
                                TextSpan(
                                  text: '${flSpot.y} $unit',
                                  style: TextStyle(
                                    color: Colors.white, // primaryColor, // Tooltip background is dark usually
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                      ),
                    ),
                  ),
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



  Widget _buildStockSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildDetailRow('Species', widget.farmData['species'] ?? 'N/A'),
          _buildDetailRow('Quantity', widget.farmData['quantity'] ?? 'N/A'),
          const Divider(),
          _buildDetailRow('Stock Date', widget.farmData['stockDate'] ?? 'N/A'),
          _buildDetailRow('Harvest Date', widget.farmData['harvestDate'] ?? 'N/A'),
          const Divider(),
          _buildDetailRow('Feed Type', widget.farmData['feedType'] ?? 'N/A'),
          _buildDetailRow('Growth Stage', widget.farmData['growthStage'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildRiskSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildAlertRow(Icons.coronavirus, 'Disease Alerts', widget.farmData['diseaseAlerts'] ?? 'None', Colors.red),
          _buildAlertRow(Icons.flood, 'Flood History', widget.farmData['floodAlertHistory'] ?? 'None', Colors.orange),
          _buildAlertRow(Icons.factory, 'Pollution Score', widget.farmData['pollutionScore'] ?? 'N/A', Colors.grey),
        ],
      ),
    );
  }
  
  Widget _buildAlertRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildDetailRow('Scheme Support', widget.farmData['scheme'] ?? 'N/A'),
          _buildDetailRow('Subsidy Info', widget.farmData['subsidyStatus'] ?? 'N/A'),
          _buildDetailRow('Insurance', widget.farmData['insuranceDetails'] ?? 'N/A'),
          const Divider(),
          _buildDetailRow('Est. Revenue', widget.farmData['revenueEst'] ?? 'N/A', isBold: true),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final docs = widget.farmData['docs'] as Map<String, dynamic>? ?? {};
    if (docs.isEmpty) return const Text('No documents found.');
    
    return _buildCard(
      child: Column(
        children: docs.entries.map((e) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.description, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(e.key),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(e.value.toString(), style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        ).toList(),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return _buildCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCircle('Productivity', widget.farmData['productivity'] ?? '-'),
          _buildStatCircle('Sustainability', widget.farmData['sustainabilityScore'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String label, String value) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.05),
            border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
          ),
          alignment: Alignment.center,
          child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWorkflowSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildDetailRow('Last Inspector', widget.farmData['inspector'] ?? 'N/A'),
          _buildDetailRow('Inspection Date', widget.farmData['inspectionDate'] ?? 'N/A'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.yellow.shade50,
            child: Text('Remarks: ${widget.farmData['remarks'] ?? 'None'}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.brown.shade700)),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Active' ? Colors.green : (status == 'Pending Approval' ? Colors.orange : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
