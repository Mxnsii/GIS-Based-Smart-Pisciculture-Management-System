import 'package:flutter/material.dart';

class FarmRegistryScreen extends StatefulWidget {
  const FarmRegistryScreen({super.key});

  @override
  State<FarmRegistryScreen> createState() => _FarmRegistryScreenState();
}

class _FarmRegistryScreenState extends State<FarmRegistryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  // Mock Data (Shared with Map)
  final List<Map<String, dynamic>> _allFarms = [
    {
      "id": 1,
      "name": "Goa Prawn Farm 1 (Mock)",
      "location": "North Goa, Sector 4",
      "status": "Active",
      "owner": "R. Sharma",
      "type": "Prawn Culture",
      "area": "2.5 ha",
      "license": "LIC-2023-001"
    },
    {
      "id": 2,
      "name": "Khazan Farm (Mock)",
      "location": "Tiswadi, Goa",
      "status": "Pending Approval",
      "owner": "S. Naik",
      "type": "Khazan Traditional",
      "area": "5.0 ha",
      "license": "Pending"
    },
    {
      "id": 3,
      "name": "Sea Cage Site 3 (Mock)",
      "location": "Offshore Zone B",
      "status": "Inactive",
      "owner": "A. Fernandes",
      "type": "Sea Cage",
      "area": "N/A",
      "license": "EXP-2022-098"
    },
    {
      "id": 4,
      "name": "New Venture Biofloc",
      "location": "South Goa",
      "status": "Pending Approval",
      "owner": "P. Singh",
      "type": "Biofloc Tank",
      "area": "0.5 ha",
      "license": "APP-2024-112"
    },
  ];

  List<Map<String, dynamic>> _filteredFarms = [];

  @override
  void initState() {
    super.initState();
    _filteredFarms = _allFarms;
    _searchController.addListener(_filterFarms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFarms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFarms = _allFarms.where((farm) {
        final matchesQuery = farm['name'].toLowerCase().contains(query) ||
            farm['owner'].toLowerCase().contains(query);
        final matchesFilter = _selectedFilter == 'All' || farm['status'] == _selectedFilter;
        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterFarms();
    });
  }

  void _showFarmDetails(Map<String, dynamic> farm) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      farm['name'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusBadge(farm['status']),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow(Icons.person, 'Owner', farm['owner']),
              _buildDetailRow(Icons.location_on, 'Location', farm['location']),
              _buildDetailRow(Icons.water, 'Culture Type', farm['type']),
              _buildDetailRow(Icons.aspect_ratio, 'Total Area', farm['area']),
              _buildDetailRow(Icons.badge, 'License Number', farm['license']),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {}, // Would navigate to Edit or Map
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Manage'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
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
              _buildFilterChip('Pending Mirror'), // Using 'Pending Approval' in logic but short text here if needed, sticking to full string in logic
              _buildFilterChip('Inactive'),
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
            child: ListView.separated(
              itemCount: _filteredFarms.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final farm = _filteredFarms[index];
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
                              Text(farm['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(farm['license'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Text(farm['owner'])),
                        Expanded(flex: 2, child: Text(farm['location'])),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildStatusBadge(farm['status']),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
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
