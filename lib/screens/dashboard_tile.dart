import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final String userName;
  final List<Widget> menuItems;
  final Widget body;

  const AppShell({
    super.key,
    required this.userName,
    required this.menuItems,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 240,
            color: const Color(0xFF1F2937),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                ...menuItems,
              ],
            ),
          ),

          // MAIN AREA
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'GIS Smart Pisciculture Management',
                        style: TextStyle(fontSize: 18),
                      ),
                      Row(
                        children: [
                          Text('Welcome, $userName'),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // PAGE CONTENT
                Expanded(child: body),
              ],
            ),
          )
        ],
      ),
    );
  }
}
