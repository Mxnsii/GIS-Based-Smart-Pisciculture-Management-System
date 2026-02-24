import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'farm_details_screen.dart';

class FarmRegistryScreen extends StatefulWidget {
  final bool isAuthority;
  const FarmRegistryScreen({super.key, this.isAuthority = false});

  @override
  State<FarmRegistryScreen> createState() => _FarmRegistryScreenState();
}

class _FarmRegistryScreenState extends State<FarmRegistryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  // Mock Data (Shared with Map)
  final List<Map<String, dynamic>> _allFarms = [
    {
      "id": "FRM-2024-001",
      "name": "Goa Smart Prawn Farm",
      "owner": "Rajesh Sharma",
      "contact": "+91 98765 43210",
      "email": "rajesh.sharma@example.com",
      "address": "Plot 42, Coastal Road, Calangute",
      "district": "North Goa",
      "taluka": "Bardez",
      "village": "Calangute",
      "totalArea": "2.5 ha",
      "pondCount": 4,
      "regDate": "2023-01-15",
      "license": "LIC-2023-001",
      "status": "Active",
      
      // GIS & Location
      "lat": 15.5406,
      "lng": 73.7562,
      "geofenceRadius": "500m",
      "soilType": "Clay Loam",
      "landCategory": "Coastal",
      "floodZone": "Moderate Risk",
      "waterSource": "Estuary & Borewell",
      "elevation": "4m",
      
      // Water Quality (IoT)
      "ph": 7.8,
      "temp": 28.5,
      "turbidity": "12 NTU",
      "do": "6.5 mg/L",
      "salinity": "15 ppt",
      "lastUpdate": "10 mins ago",
      "riskStatus": "Normal",
      "alarmCount": 0,
      
      // Fish Stock
      "species": "Vannamei Shrimp",
      "quantity": "50,000",
      "stockDate": "2023-11-01",
      "harvestDate": "2024-03-15",
      "feedType": "Growel Feeds - Starter",
      "feedSupplier": "Goa Feeds Ltd",
      "growthStage": "Growth Phase",
      "diseaseHistory": "None",
      
      // Risk & Alerts
      "diseaseAlerts": "None",
      "floodAlertHistory": "Oct 2023 - Minor",
      "pollutionScore": "Low (12/100)",
      "insuranceClaims": "None",
      
      // Financials
      "scheme": "PMMSY - Biofloc Support",
      "subsidyStatus": "Approved - 40%",
      "insuranceDetails": "Oriental Insurance - Valid till Dec 2024",
      "revenueEst": "₹ 12,00,000",
      "lossHistory": "Nil",
      
      // Documents
      "docs": {
        "License": "Verified",
        "Land Ownership": "Verified",
        "Pollution Cert": "Verified",
        "Bank Details": "Verified",
        "ID Proof": "Verified"
      },
      
      // Analytics
      "productivity": "4.2 tons/ha",
      "mortalityRate": "5%",
      "sustainabilityScore": "85/100",
      
      // Workflow
      "inspector": "Dr. V. Naik",
      "inspectionDate": "2023-12-10",
      "remarks": "Excellent adherence to biosecurity protocols.",
      "approvalTime": "2023-12-12 10:00 AM",
    },
    {
      "id": "FRM-2024-002",
      "name": "Khazan Traditional Farm",
      "owner": "Sandeep Naik",
      "contact": "+91 91234 56789",
      "email": "s.naik@example.com",
      "address": "H.No 12, Riverside, Divar Island",
      "district": "North Goa",
      "taluka": "Tiswadi",
      "village": "Divar",
      "totalArea": "5.0 ha",
      "pondCount": 1,
      "regDate": "2024-02-01",
      "license": "Pending",
      "status": "Pending Approval",
      
      // GIS & Location
      "lat": 15.51,
      "lng": 73.91,
      "geofenceRadius": "1000m",
      "soilType": "Saline Alluvial",
      "landCategory": "Khazan Land",
      "floodZone": "High Risk",
      "waterSource": "River Mandovi",
      "elevation": "1m",
      
      // Water Quality (IoT)
      "ph": 7.2,
      "temp": 29.1,
      "turbidity": "45 NTU (High)",
      "do": "5.1 mg/L",
      "salinity": "22 ppt",
      "lastUpdate": "1 hour ago",
      "riskStatus": "Warning",
      "alarmCount": 2,
      
       // Fish Stock
      "species": "Local Mullet & Pearl Spot",
      "quantity": "Natural Stocking",
      "stockDate": "N/A",
      "harvestDate": "April 2024",
      "feedType": "Natural Algae",
      "feedSupplier": "N/A",
      "growthStage": "Maturation",
      "diseaseHistory": "Minor Gill Rot in 2022",
      
      // Risk & Alerts
      "diseaseAlerts": "Watch for fungal infection",
      "floodAlertHistory": "High Tide Breach - Aug 2023",
      "pollutionScore": "Moderate (45/100)",
      "insuranceClaims": "Claim #4421 - Pending",
      
      // Financials
      "scheme": "State Khazan Revival",
      "subsidyStatus": "Application Submitted",
      "insuranceDetails": "Not yet insured",
      "revenueEst": "₹ 5,00,000",
      "lossHistory": "₹ 50,000 (Monsoon 2023)",
      
      // Documents
      "docs": {
        "License": "In Process",
        "Land Ownership": "Verified",
        "Pollution Cert": "Pending",
        "Bank Details": "Verified",
        "ID Proof": "Verified"
      },
      
      // Analytics
      "productivity": "1.5 tons/ha",
      "mortalityRate": "Unknown",
      "sustainabilityScore": "92/100",
      
      // Workflow
      "inspector": "Pending Assignment",
      "inspectionDate": "Scheduled: 2024-02-25",
      "remarks": "Waiting for site visit.",
      "approvalTime": "N/A",
    },
    {
      "id": "FRM-2023-089",
      "name": "Mandovi Cage Culture",
      "owner": "Anthony Fernandes",
      "contact": "+91 98221 55555",
      "email": "a.fernandes@example.com",
      "address": "Jetty Road, Panjim",
      "district": "North Goa",
      "taluka": "Tiswadi",
      "village": "Panjim",
      "totalArea": "10 Cages",
      "pondCount": 10,
      "regDate": "2023-05-10",
      "license": "LIC-CAGE-003",
      "status": "Inactive",
      
      // GIS & Location
      "lat": 15.5000,
      "lng": 73.8300,
      "geofenceRadius": "200m",
      "soilType": "River Bed",
      "landCategory": "Estuarine",
      "floodZone": "Moderate",
      "waterSource": "River Mandovi",
      "elevation": "0m",
      
      // Water Quality
      "ph": "N/A",
      "temp": "N/A",
      "turbidity": "N/A", 
      "do": "N/A",
      "salinity": "N/A",
      "lastUpdate": "Offline (30 days)",
      "riskStatus": "Critical", // Offline
      "alarmCount": 0,
       
      // Stock
      "species": "Asian Seabass",
      "quantity": "0",
      "stockDate": "Harvested Dec 2023",
      "harvestDate": "N/A",
      "feedType": "Floating Pellets",
      "feedSupplier": "Cargill",
      "growthStage": "Fallow",
      "diseaseHistory": "None",
      
      // Risk
      "diseaseAlerts": "None",
      "floodAlertHistory": "None",
      "pollutionScore": "High (Traffic)",
      "insuranceClaims": "None",
      
      // Financials
      "scheme": "Blue Revolution",
      "subsidyStatus": "Received",
      "insuranceDetails": "Expired Jan 2024",
      "revenueEst": "₹ 0",
      "lossHistory": "Nil",
      
       // Docs
      "docs": {
        "License": "Expired",
        "NOC": "Valid",
      },
      
      "productivity": "Total 5 tons (2023)",
      "mortalityRate": "2%",
      "sustainabilityScore": "70/100",
      
      "inspector": "Dr. V. Naik",
      "inspectionDate": "2023-11-20",
      "remarks": "Operations temporarily suspended.",
      "approvalTime": "2023-05-15",
    },
    {
      "id": "FRM-2024-005",
      "name": "Zuari Biofloc Unit",
      "owner": "Preeti Singh",
      "contact": "+91 77777 88888",
      "email": "p.singh@example.com",
      "address": "Ind. Estate, Cortalim",
      "district": "South Goa",
      "taluka": "Mormugao",
      "village": "Cortalim",
      "totalArea": "0.5 ha",
      "pondCount": 6,
      "regDate": "2024-01-10",
      "license": "Rejected",
      "status": "Rejected",
      
      // GIS
      "lat": 15.4000,
      "lng": 73.9500,
      "geofenceRadius": "100m",
      "soilType": "Laterite",
      "landCategory": "Industrial",
      "floodZone": "Low",
      "waterSource": "Municipal Supply",
      "elevation": "15m",
      
      // Water
      "ph": "-",
      "temp": "-",
      "turbidity": "-",
      "do": "-",
      "salinity": "-",
      "lastUpdate": "Never",
      "riskStatus": "Unknown",
      "alarmCount": 0,
      
      // Stock
      "species": "Tilapia",
      "quantity": "0",
      "stockDate": "N/A",
      "harvestDate": "N/A",
      "feedType": "N/A",
      "feedSupplier": "N/A",
      "growthStage": "N/A",
      "diseaseHistory": "N/A",
      
      // Risk
      "diseaseAlerts": "N/A",
      "floodAlertHistory": "N/A",
      "pollutionScore": "High (Ind. Waste)",
      "insuranceClaims": "N/A",
      
      // Financials
      "scheme": "PMMSY",
      "subsidyStatus": "Rejected",
      "insuranceDetails": "N/A",
      "revenueEst": "0",
      "lossHistory": "N/A",
      
      // Docs
      "docs": {
        "License": "Rejected",
        "Land Doc": "Disputed",
      },
      
      "productivity": "N/A",
      "mortalityRate": "N/A",
      "sustainabilityScore": "20/100",
      
      "inspector": "Official #42",
      "inspectionDate": "2024-01-20",
      "remarks": "Land use mismatch. Industrial zone not improved for aquaculture.",
      "approvalTime": "N/A",
      "rejectionReason": "Land Use Violation",
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _showFarmDetails(Map<String, dynamic> farm) {
    final String status = (farm['status'] ?? '').toString();
    if (status == 'Inactive') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This farm is inactive. Details are disabled.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FarmDetailsScreen(farmData: farm, isAuthority: true),
      ),
    );
  }

  void _showAddFarmDialog() {
    final nameController = TextEditingController();
    final ownerController = TextEditingController();
    final locationController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    String status = 'Pending Approval';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Material(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 24,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    final _formKey = GlobalKey<FormState>();
                    return SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Add Farm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(labelText: 'Farm Name', border: OutlineInputBorder()),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: ownerController,
                              decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder()),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: locationController,
                              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: latController,
                                    decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return null;
                                      return double.tryParse(v) == null ? 'Invalid' : null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: lngController,
                                    decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return null;
                                      return double.tryParse(v) == null ? 'Invalid' : null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: status,
                              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Status'),
                              items: ['Active', 'Pending Approval', 'Inactive', 'Rejected']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) { if (v != null) setModalState(() => status = v); },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                onPressed: () async {
                                      if (!_formKey.currentState!.validate()) return;
                                      final name = nameController.text.trim();
                                      final owner = ownerController.text.trim();
                                      final location = locationController.text.trim();
                                      final lat = double.tryParse(latController.text.trim()) ?? 0.0;
                                      final lng = double.tryParse(lngController.text.trim()) ?? 0.0;

                                      final newId = 'FRM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                                      final Map<String, dynamic> newFarm = {
                                        'id': newId,
                                        'name': name,
                                        'owner': owner,
                                        'contact': 'N/A',
                                        'email': 'N/A',
                                        'address': location,
                                        'district': 'N/A',
                                        'taluka': 'N/A',
                                        'village': location,
                                        'totalArea': 'N/A',
                                        'pondCount': 0,
                                        'regDate': DateTime.now().toIso8601String(),
                                        'license': 'N/A',
                                        'status': status,
                                        'lat': lat,
                                        'lng': lng,
                                        'docs': {},
                                        'productivity': '-',
                                        'sustainabilityScore': '-',
                                        'inspector': 'N/A',
                                        'inspectionDate': 'N/A',
                                        'remarks': '',
                                      };

                                  try {
                                    // Save to Firebase Firestore
                                    await FirebaseFirestore.instance.collection('farms').doc(newId).set(newFarm);

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Farm added to database')));
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding farm: $e')));
                                  }
                                    },
                                    child: const Text('Add Farm'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Farm Registry',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by Name or Owner...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Active'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending Mirror'),
              _buildFilterChip('Inactive'),
              const SizedBox(width: 12),
              if (widget.isAuthority)
                ElevatedButton.icon(
                  onPressed: _showAddFarmDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Farm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // List Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Farm Name', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40), // For Action Icon
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('farms').snapshots(),
              builder: (context, snapshot) {
                // Combine Mock Data + Firestore Data
                List<Map<String, dynamic>> combinedFarms = List.from(_allFarms);

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Filter out farms with missing or invalid names
                    if (data['name'] == null || data['name'].toString().trim().isEmpty || data['name'] == 'Unknown Farm') {
                      continue;
                    }
                    
                    // Avoid duplicates if IDs match
                    if (!combinedFarms.any((f) => f['id'] == data['id'])) {
                      combinedFarms.insert(0, data);
                    }
                  }
                }

                // Filter
                final query = _searchController.text.toLowerCase();
                final filteredFarms = combinedFarms.where((farm) {
                  final matchesQuery = (farm['name'] ?? '').toLowerCase().contains(query) ||
                      (farm['owner'] ?? '').toLowerCase().contains(query);
                  final matchesFilter = _selectedFilter == 'All' || farm['status'] == _selectedFilter;
                  return matchesQuery && matchesFilter;
                }).toList();

                if (filteredFarms.isEmpty) {
                  return const Center(child: Text('No farms found'));
                }

                return ListView.separated(
                  itemCount: filteredFarms.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final farm = filteredFarms[index];
                    return InkWell(
                      onTap: () => _showFarmDetails(farm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(farm['name'] ?? 'Unknown Farm', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Expanded(flex: 2, child: Text(farm['owner'] ?? 'Unknown')),
                            // Formatting location as seen in extension details: Address/Village, Taluka, etc.
// The Builder widget correctly extracts evaluation outside of list definition
                            Builder(
                              builder: (context) {
                                String displayedLocation = 'Unknown';
                                if (farm['village'] != null && farm['taluka'] != null) {
                                  displayedLocation = '${farm['village']}, ${farm['taluka']}';
                                } else if (farm['address'] != null && farm['address'].toString().trim().isNotEmpty) {
                                  displayedLocation = farm['address'];
                                } else if (farm['district'] != null) {
                                  displayedLocation = farm['district'];
                                }
                                return Expanded(flex: 2, child: Text(displayedLocation));
                              },
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildStatusBadge(farm['status'] ?? 'Draft'),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    // Map short label to actual status string if needed, or keeping simple
    final valueToCheck = label == 'Pending Mirror' ? 'Pending Approval' : label;
    final displayLabel = label == 'Pending Mirror' ? 'Pending' : label;
    
    final isSelected = _selectedFilter == valueToCheck;
    return FilterChip(
      label: Text(displayLabel),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          _onFilterChanged(valueToCheck);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade900 : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
