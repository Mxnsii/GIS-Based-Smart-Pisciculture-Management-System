import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

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
      backgroundColor: const Color(0xFF090D16),
      body: Row(
        children: [
          // ================= SIDEBAR =================
          Container(
            width: 240,
            color: const Color(0xFF090D16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'AquaSync Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                ...menuItems,
              ],
            ),
          ),

          // ================= MAIN AREA =================
          Expanded(
            child: Column(
              children: [
                // -------- TOP BAR --------
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1E293B)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'GIS Smart Pisciculture Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Welcome, $userName',
                            style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                            label: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                            onPressed: () {
                              // ✅ Proper logout → LoginScreen
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // -------- PAGE CONTENT --------
                Expanded(
                  child: body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
