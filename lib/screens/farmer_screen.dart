import 'package:flutter/material.dart';
import 'iot_monitoring_screen.dart';
import 'alerts_screen.dart';
import 'hatcheries_screen.dart';
import 'login_screen.dart';
import 'govt_schemes_screen.dart';
import 'complaint_registry_screen.dart'; // Import for illegal fishing reporting
import 'chatbot_screen.dart';
import 'fish_directory_screen.dart'; // Import for fish directory
import 'species_recommendation_screen.dart';

class FarmerScreen extends StatefulWidget {
  final String farmerName;

  const FarmerScreen({super.key, required this.farmerName});

  @override
  State<FarmerScreen> createState() => _FarmerScreenState();
}

class _FarmerScreenState extends State<FarmerScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    IotMonitoringScreen(),
    FishDirectoryScreen(), // Index 1
    AlertsScreen(), // Index 2
    SpeciesRecommendationScreen(), // Index 3
    HatcheriesScreen(), // Index 4
    GovtSchemesScreen(), // Index 5
  ];

  late final Widget _complaintTab;

  @override
  void initState() {
    super.initState();
    _complaintTab = ComplaintRegistryScreen(farmerName: widget.farmerName);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'GIS Smart Pisciculture Management',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Text(
              'Welcome, ${widget.farmerName}',
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
          IconButton(
            tooltip: 'Open GIS Agent',
            icon: const Icon(Icons.support_agent, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatbotScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.grey.shade300,
              height: 1.0,
            )),
      ),
      body: _selectedIndex == 6 ? _complaintTab : _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotScreen(),
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: const Text(
          'GIS Agent',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'IoT Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Market Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'AI Species',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Hatcheries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.policy),
            label: 'Govt Schemes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem, color: Colors.redAccent),
            label: 'Report Incident',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.shifting,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
    );
  }
}
