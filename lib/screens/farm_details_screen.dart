import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'gis_map_view.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/glass_card.dart';

class FarmDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> farmData;
  final bool isAuthority;

  const FarmDetailsScreen({super.key, required this.farmData, this.isAuthority = false});

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  String _selectedMetric = 'Temperature'; // Default metric
  final List<String> _metrics = ['Temperature', 'pH', 'Turbidity', 'Salinity'];

  @override
  Widget build(BuildContext context) {
    final String status = (widget.farmData['status'] ?? '').toString();
    final bool hideSections = status == 'Active' || status == 'Pending Approval' || status == 'Rejected';
    final bool isInactive = status == 'Inactive';

    // If the current viewer is NOT an authority and the farm is marked Inactive,
    // show a restricted screen (users should not see the farm details).
    if (!widget.isAuthority && isInactive) {
      return Scaffold(
        backgroundColor: const Color(0xFF090D16), // Premium dark mode background
        appBar: AppBar(
          title: const Text(
            'Farm Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassCard(
              borderRadius: 20,
              blur: 15,
              backgroundColor: const Color(0xFF1E293B).withOpacity(0.4),
              borderColor: Colors.redAccent.withOpacity(0.2),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.block, size: 72, color: Colors.redAccent),
                  SizedBox(height: 20),
                  Text(
                    'Access Restricted',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This farm is currently inactive. Details are restricted to authorized personnel only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090D16), // Premium dark mode background
      appBar: AppBar(
        title: Text(
          widget.farmData['name'] ?? 'Farm Details',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: CustomBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withOpacity(0.08),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('📍 GIS & Location'),
            _buildGisSection(context),
            const SizedBox(height: 24),
            // Updated Section Title
            _buildSectionTitle('📈 Real-Time Diagnostics'),
            _buildInsightsSection(), // Replaces _buildWaterQualitySection
            const SizedBox(height: 24),

            // Conditionally show extended sections.
            if (!hideSections) ...[
              _buildSectionTitle('🐠 Fish Stock Details'),
              _buildStockSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('⚠️ Biosecurity Risk & Alerts'),
              _buildRiskSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('💰 Financials & Operations'),
              _buildFinancialSection(),
              const SizedBox(height: 24),
            ],

            // Documents should be shown in all cases but with certain sensitive
            // entries removed for Active/Pending/Rejected as requested.
            _buildSectionTitle('📑 Documentation & Verification'),
            _buildDocumentsSection(excludeSensitive: hideSections),
            const SizedBox(height: 24),

            if (!hideSections) ...[
              _buildSectionTitle('📊 Performance Analytics'),
              _buildAnalyticsSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('🔐 Compliance & Approvals'),
              _buildWorkflowSection(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF6366F1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, Color? color}) {
    return GlassCard(
      borderRadius: 16.0,
      blur: 12.0,
      backgroundColor: color ?? const Color(0xFF1E293B).withOpacity(0.45),
      borderColor: Colors.white.withOpacity(0.08),
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 4),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm ID: ${widget.farmData['id'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Color(0xFF06B6D4), 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.farmData['owner'] ?? 'Unknown Owner',
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(widget.farmData['status'] ?? 'Unknown'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone, widget.farmData['contact'] ?? 'N/A'),
          _buildInfoRow(Icons.email, widget.farmData['email'] ?? 'N/A'),
          Builder(
            builder: (context) {
              String displayedLocation = 'N/A';
              final farm = widget.farmData;
              if (farm['village'] != null && farm['taluka'] != null && farm['taluka'] != 'N/A' && farm['village'] != 'N/A') {
                displayedLocation = '${farm['village']}, ${farm['taluka']}';
              } else if (farm['village'] != null && farm['village'] != 'N/A') {
                displayedLocation = farm['village'];
              } else if (farm['address'] != null && farm['address'].toString().trim().isNotEmpty && farm['address'] != 'N/A') {
                displayedLocation = farm['address'];
              } else if (farm['district'] != null && farm['district'] != 'N/A') {
                displayedLocation = farm['district'];
              }
              
              return _buildInfoRow(Icons.location_on, displayedLocation);
            }
          ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem('Latitude', '${widget.farmData['lat'] ?? 0.0}'),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    _buildDetailItem('Longitude', '${widget.farmData['lng'] ?? 0.0}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // If farm is inactive we do not show extension navigation (e.g. map)
          finalStatusMapButton(context),
        ],
      ),
    );
  }

  Widget finalStatusMapButton(BuildContext context) {
    final String status = (widget.farmData['status'] ?? '').toString();
    final bool isInactive = status == 'Inactive';
    if (isInactive) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          if (widget.farmData['lat'] != null && widget.farmData['lng'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GisMapView(
                  initialLat: widget.farmData['lat'] is String ? double.tryParse(widget.farmData['lat']) : widget.farmData['lat'].toDouble(),
                  initialLng: widget.farmData['lng'] is String ? double.tryParse(widget.farmData['lng']) : widget.farmData['lng'].toDouble(),
                  initialZoom: 16,
                  isAuthority: widget.isAuthority,
                  farms: [widget.farmData],
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.map, size: 18),
        label: const Text(
          'View on GIS Map',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String _getMetricUnit() {
    switch (_selectedMetric) {
      case 'Temperature': return '°C';
      case 'pH': return '';
      case 'Turbidity': return 'NTU';
      case 'Salinity': return 'ppt';
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              // Metric Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF0F172A),
                    value: _selectedMetric,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF06B6D4)),
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
                        child: Text(
                          value, 
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${_selectedMetric.toUpperCase()} ${_getMetricUnit().isNotEmpty ? '(${_getMetricUnit()})' : ''}',
              style: const TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.5,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 2.2, // Wider aspect ratio for better detail
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('water_parameters')
                  .orderBy('timestamp', descending: false)
                  .limit(20) // Limit to relevant recent data for clarity
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No data available', style: TextStyle(color: Color(0xFF94A3B8))));
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
                  } else if (_selectedMetric == 'Salinity') {
                    value = (data['salinity'] as num?)?.toDouble();
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
                  return const Center(child: Text('No valid data for selected metric', style: TextStyle(color: Color(0xFF94A3B8))));
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

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, animValue, child) {
                    return Opacity(
                      opacity: animValue,
                      child: Transform.translate(
                        offset: Offset(0, (1 - animValue) * 15),
                        child: child,
                      ),
                    );
                  },
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yRange / 5, // Approx 5 lines
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.04),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
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
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.left,
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
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
                                radius: 4.5,
                                color: Colors.white,
                                strokeWidth: 2.5,
                                strokeColor: primaryColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.35),
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
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${flSpot.y} $unit',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                          tooltipRoundedRadius: 10,
                          tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
                          getTooltipColor: (LineBarSpot touchedSpot) => const Color(0xFF0F172A).withOpacity(0.95),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                        ),
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
      case 'Temperature': return const Color(0xFFF97316); // Premium orange
      case 'pH': return const Color(0xFF10B981); // Emerald green
      case 'Turbidity': return const Color(0xFFF59E0B); // Golden amber
      case 'Salinity': return const Color(0xFF06B6D4); // Cyan
      default: return const Color(0xFF6366F1);
    }
  }

  Widget _buildStockSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildDetailRow('Species', widget.farmData['species'] ?? 'N/A'),
          _buildDetailRow('Quantity', widget.farmData['quantity'] ?? 'N/A'),
          const Divider(height: 20, color: Colors.white10),
          _buildDetailRow('Stock Date', widget.farmData['stockDate'] ?? 'N/A'),
          _buildDetailRow('Harvest Date', widget.farmData['harvestDate'] ?? 'N/A'),
          const Divider(height: 20, color: Colors.white10),
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
          _buildAlertRow(Icons.coronavirus, 'Disease Alerts', widget.farmData['diseaseAlerts'] ?? 'None', Colors.redAccent),
          const SizedBox(height: 8),
          _buildAlertRow(Icons.flood, 'Flood History', widget.farmData['floodAlertHistory'] ?? 'None', Colors.orangeAccent),
          const SizedBox(height: 8),
          _buildAlertRow(Icons.factory, 'Pollution Score', widget.farmData['pollutionScore'] ?? 'N/A', Colors.lightBlueAccent),
        ],
      ),
    );
  }
  
  Widget _buildAlertRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
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
          const Divider(height: 20, color: Colors.white10),
          _buildDetailRow('Est. Revenue', widget.farmData['revenueEst'] ?? 'N/A', isBold: true),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection({bool excludeSensitive = false}) {
    final docs = widget.farmData['docs'] as Map<String, dynamic>? ?? {};
    final filtered = Map<String, dynamic>.from(docs);

    if (excludeSensitive) {
      filtered.remove('Bank Details');
      filtered.remove('ID Proof');
    }

    if (filtered.isEmpty) {
      return _buildCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No documents found.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        ),
      );
    }

    return _buildCard(
      child: Column(
        children: filtered.entries.map((e) {
          final isVerified = e.value.toString().toLowerCase() == 'verified';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, color: Color(0xFF06B6D4), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      e.key == 'Pollution Cert' ? 'Pollution Certificate' : e.key,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFF10B981).withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isVerified ? const Color(0xFF10B981).withOpacity(0.3) : Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    e.value.toString().toUpperCase(), 
                    style: TextStyle(
                      fontSize: 9, 
                      color: isVerified ? const Color(0xFF10B981) : Colors.amber, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.03),
                const Color(0xFF06B6D4).withOpacity(0.08),
              ],
            ),
            border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              value, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildWorkflowSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isAuthority) ...[
            _buildStatusEditor(),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 16),
          ],
          _buildDetailRow('Last Inspector', widget.farmData['inspector'] ?? 'N/A'),
          _buildDetailRow('Inspection Date', widget.farmData['inspectionDate'] ?? 'N/A'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withOpacity(0.15)),
            ),
            child: Text(
              'Remarks: ${widget.farmData['remarks'] ?? 'None'}', 
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.amberAccent, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusEditor() {
    final List<String> statuses = ['Active', 'Pending Approval', 'Inactive', 'Rejected'];
    final String current = (widget.farmData['status'] ?? 'Pending Approval').toString();

    return Row(
      children: [
        const Text('Status Action:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF0F172A),
                value: current,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF06B6D4)),
                items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (String? newValue) async {
                  if (newValue == null) return;

                  // If switching to Inactive, confirm the action
                  if (newValue == 'Inactive') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Confirm Inactivate', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Marking this farm Inactive will restrict access to its details for non-authority users. Continue?',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false), 
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true), 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;
                  }

                  setState(() {
                    widget.farmData['status'] = newValue;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status updated to $newValue'),
                      backgroundColor: Colors.indigoAccent,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helpers ---

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF06B6D4)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text, 
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
            ),
          ),
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
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          Text(
            value, 
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.white : const Color(0xFFE2E8F0),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            value, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Active' 
        ? const Color(0xFF10B981) // Emerald
        : (status == 'Pending Approval' ? const Color(0xFFF59E0B) : const Color(0xFF64748B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}
