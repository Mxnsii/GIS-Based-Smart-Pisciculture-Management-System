import 'package:flutter/material.dart';
import 'gis_map_view.dart';
import '../widgets/custom_back_button.dart';

class FarmDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> farmData;

  const FarmDetailsScreen({super.key, required this.farmData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      appBar: AppBar(
        title: Text(farmData['name'] ?? 'Farm Details'),
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
            _buildSectionTitle('🌊 Water Quality (IoT)'),
            _buildWaterQualitySection(),
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
                    'Farm ID: ${farmData['id'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    farmData['owner'] ?? 'Unknown Owner',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              _buildStatusBadge(farmData['status'] ?? 'Unknown'),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone, farmData['contact'] ?? 'N/A'),
          _buildInfoRow(Icons.email, farmData['email'] ?? 'N/A'),
          _buildInfoRow(Icons.location_on, '${farmData['village']}, ${farmData['taluka']}'),
          _buildInfoRow(Icons.landscape, 'Area: ${farmData['totalArea']} • Ponds: ${farmData['pondCount']}'),
          _buildInfoRow(Icons.calendar_today, 'Reg: ${farmData['regDate']} • Lic: ${farmData['license']}'),
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
                    _buildDetailItem('Latitude', '${farmData['lat'] ?? 0.0}'),
                    _buildDetailItem('Longitude', '${farmData['lng'] ?? 0.0}'),
                    _buildDetailItem('Elevation', farmData['elevation'] ?? 'N/A'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                   children: [
                    _buildDetailItem('Soil Type', farmData['soilType'] ?? 'N/A'),
                    _buildDetailItem('Zone', farmData['landCategory'] ?? 'N/A'),
                    _buildDetailItem('Water Src', farmData['waterSource'] ?? 'N/A'),
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
                 if (farmData['lat'] != null && farmData['lng'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GisMapView(
                          initialLat: farmData['lat'],
                          initialLng: farmData['lng'],
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

  Widget _buildWaterQualitySection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last Update: ${farmData['lastUpdate'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (farmData['riskStatus'] == 'Normal') ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  farmData['riskStatus'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: (farmData['riskStatus'] == 'Normal') ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              _buildSensorTile('pH', farmData['ph']?.toString() ?? '-', Colors.blue),
              _buildSensorTile('Temp', '${farmData['temp']}°C', Colors.orange),
              _buildSensorTile('DO', farmData['do'] ?? '-', Colors.lightBlue),
              _buildSensorTile('Salinity', farmData['salinity'] ?? '-', Colors.teal),
              _buildSensorTile('Turbidity', farmData['turbidity'] ?? '-', Colors.brown),
              _buildSensorTile('Alarms', '${farmData['alarmCount'] ?? 0}', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorTile(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildStockSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildDetailRow('Species', farmData['species'] ?? 'N/A'),
          _buildDetailRow('Quantity', farmData['quantity'] ?? 'N/A'),
          const Divider(),
          _buildDetailRow('Stock Date', farmData['stockDate'] ?? 'N/A'),
          _buildDetailRow('Harvest Date', farmData['harvestDate'] ?? 'N/A'),
          const Divider(),
          _buildDetailRow('Feed Type', farmData['feedType'] ?? 'N/A'),
          _buildDetailRow('Growth Stage', farmData['growthStage'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildRiskSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildAlertRow(Icons.coronavirus, 'Disease Alerts', farmData['diseaseAlerts'] ?? 'None', Colors.red),
          _buildAlertRow(Icons.flood, 'Flood History', farmData['floodAlertHistory'] ?? 'None', Colors.orange),
          _buildAlertRow(Icons.factory, 'Pollution Score', farmData['pollutionScore'] ?? 'N/A', Colors.grey),
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
          _buildDetailRow('Scheme Support', farmData['scheme'] ?? 'N/A'),
          _buildDetailRow('Subsidy Info', farmData['subsidyStatus'] ?? 'N/A'),
          _buildDetailRow('Insurance', farmData['insuranceDetails'] ?? 'N/A'),
          const Divider(),
          _buildDetailRow('Est. Revenue', farmData['revenueEst'] ?? 'N/A', isBold: true),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final docs = farmData['docs'] as Map<String, dynamic>? ?? {};
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
          _buildStatCircle('Productivity', farmData['productivity'] ?? '-'),
          _buildStatCircle('Sustainability', farmData['sustainabilityScore'] ?? '-'),
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
          _buildDetailRow('Last Inspector', farmData['inspector'] ?? 'N/A'),
          _buildDetailRow('Inspection Date', farmData['inspectionDate'] ?? 'N/A'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.yellow.shade50,
            child: Text('Remarks: ${farmData['remarks'] ?? 'None'}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.brown.shade700)),
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
