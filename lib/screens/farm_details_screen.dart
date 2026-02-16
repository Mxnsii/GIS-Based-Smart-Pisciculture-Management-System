import 'package:flutter/material.dart';
import 'gis_map_view.dart';

class FarmDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> farmData;

  const FarmDetailsScreen({super.key, required this.farmData});

  @override
  Widget build(BuildContext context) {
    // Extract coordinates, defaulting to 0.0 if not present
    final double lat = farmData['lat'] ?? 0.0;
    final double lng = farmData['lng'] ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: Navigator.canPop(context) 
          ? TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'BACK',
                style: TextStyle(
                  color: Colors.green, // Requested Green color
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          : null,
        title: Text(
          farmData['name'] ?? 'Farm Details',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Status Badge centered
            Center(child: _buildStatusBadge(farmData['status'] ?? 'Unknown')),
            const SizedBox(height: 32),
            
            // Main Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Farm Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow('Applicant Name', farmData['owner'] ?? 'N/A'),
                   const SizedBox(height: 16),
                  _buildDetailRow('Culture Type', farmData['culture_type'] ?? 'N/A'),
                   const SizedBox(height: 16),
                  _buildDetailRow('Total Area', farmData['area'] ?? 'N/A'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Location Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Address',
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GisMapView(
                            initialLat: lat,
                            initialLng: lng,
                            initialZoom: 15.0,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            farmData['location'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Coordinates',
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                   Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '$lat, $lng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Active':
        color = Colors.green;
        break;
      case 'Pending Approval':
        color = Colors.orange;
        break;
      case 'Inactive':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
