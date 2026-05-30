import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gis_map_view.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/ocean_glass_card.dart';
import '../widgets/master_ocean_background.dart';
import '../theme/app_theme.dart';

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
        backgroundColor: Colors.transparent, // Allow MasterOceanBackground to show
        appBar: AppBar(
          title: Text(
            'Farm Details',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: MasterOceanBackground(
          showFishes: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: OceanGlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 72, color: AppColors.danger),
                    const SizedBox(height: 20),
                    Text(
                      'Access Restricted',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This farm is currently inactive. Details are restricted to authorized personnel only.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow MasterOceanBackground to show
      appBar: AppBar(
        title: Text(
          widget.farmData['name'] ?? 'Farm Details',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
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
            color: AppColors.divider,
            height: 1.0,
          ),
        ),
      ),
      body: MasterOceanBackground(
        showFishes: true,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
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

                // Documents should be shown in all cases
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
              gradient: LinearGradient(
                colors: AppColors.oceanGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return OceanGlassCard(
      borderRadius: 16.0,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
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
                      style: GoogleFonts.inter(
                        color: AppColors.primary, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.farmData['owner'] ?? 'Unknown Owner',
                      style: GoogleFonts.inter(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.textPrimary,
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
            color: AppColors.divider,
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
                      color: AppColors.divider,
                    ),
                    _buildDetailItem('Longitude', '${widget.farmData['lng'] ?? 0.0}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
        gradient: LinearGradient(
          colors: AppColors.oceanGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
              Text(
                'Real-time Trends',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              // Metric Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.surface,
                    value: _selectedMetric,
                    isDense: true,
                    icon: Icon(Icons.arrow_drop_down, size: 20, color: AppColors.primary),
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
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
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
              style: GoogleFonts.inter(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1.5,
                color: AppColors.textSecondary,
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
                  return Center(child: CircularProgressIndicator(color: AppColors.secondary));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.danger)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No data available', style: GoogleFonts.inter(color: AppColors.textSecondary)));
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
                  return Center(child: Text('No valid data for selected metric', style: GoogleFonts.inter(color: AppColors.textSecondary)));
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
                            color: AppColors.divider.withOpacity(0.4),
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
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
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
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
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
                                GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${flSpot.y} $unit',
                                    style: GoogleFonts.inter(
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
                          tooltipBorder: BorderSide(color: AppColors.border, width: 1),
                          getTooltipColor: (LineBarSpot touchedSpot) => AppColors.surface.withOpacity(0.95),
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
          Divider(height: 20, color: AppColors.divider),
          _buildDetailRow('Stock Date', widget.farmData['stockDate'] ?? 'N/A'),
          _buildDetailRow('Harvest Date', widget.farmData['harvestDate'] ?? 'N/A'),
          Divider(height: 20, color: AppColors.divider),
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
        color: AppColors.cardLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
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
                Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
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
          Divider(height: 20, color: AppColors.divider),
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No documents found.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
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
                    Icon(Icons.description_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      e.key == 'Pollution Cert' ? 'Pollution Certificate' : e.key,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isVerified ? AppColors.success.withOpacity(0.3) : AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    e.value.toString().toUpperCase(), 
                    style: GoogleFonts.inter(
                      fontSize: 9, 
                      color: isVerified ? AppColors.success : AppColors.warning, 
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
                AppColors.secondary.withOpacity(0.05),
                AppColors.primary.withOpacity(0.12),
              ],
            ),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowBlue.withOpacity(0.05),
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
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
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
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
          ],
          _buildDetailRow('Last Inspector', widget.farmData['inspector'] ?? 'N/A'),
          _buildDetailRow('Inspection Date', widget.farmData['inspectionDate'] ?? 'N/A'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Text(
              'Remarks: ${widget.farmData['remarks'] ?? 'None'}', 
              style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: AppColors.warning, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
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
        Text('Status Action:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: AppColors.surface,
                value: current,
                isExpanded: true,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(color: AppColors.textPrimary)))).toList(),
                onChanged: (String? newValue) async {
                  if (newValue == null) return;

                  // If switching to Inactive, confirm the action
                  if (newValue == 'Inactive') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Confirm Inactivate', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        content: Text(
                          'Marking this farm Inactive will restrict access to its details for non-authority users. Continue?',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false), 
                            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true), 
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                            child: Text('Confirm', style: GoogleFonts.inter(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;
                  }

                  setState(() {
                    widget.farmData['status'] = newValue;
                  });

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status updated to $newValue'),
                      backgroundColor: AppColors.oceanDeep,
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
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text, 
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
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
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value, 
            style: GoogleFonts.inter(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
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
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            value, 
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Active' 
        ? AppColors.success 
        : (status == 'Pending Approval' ? AppColors.warning : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}
