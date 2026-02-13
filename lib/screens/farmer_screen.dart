import 'package:flutter/material.dart';
import 'iot_monitoring_screen.dart';
import 'alerts_screen.dart';
import 'hatcheries_screen.dart';
import 'login_screen.dart';

import 'govt_schemes_screen.dart';

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
    AlertsScreen(),
    HatcheriesScreen(),
    GovtSchemesScreen(),
  ];

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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'IoT Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Hatcheries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.policy),
            label: 'Govt Schemes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
