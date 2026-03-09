import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'gis_map_view.dart';
import 'farm_registry_screen.dart';
import 'login_screen.dart';
import 'farm_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/weather_widget.dart';
import '../widgets/custom_back_button.dart';
import 'authority_complaints_screen.dart'; // Implemented Authority Complaints Tab

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, required this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHomeView(onTabChange: _onItemTapped),
      GisMapView(showBackButton: false, isAuthority: true),
      FarmRegistryScreen(isAuthority: true),
      const AuthorityComplaintsScreen(),
    ];
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
        automaticallyImplyLeading: false,
        leading: _selectedIndex != 0
            ? CustomBackButton(
                onPressed: () => _onItemTapped(0),
              )
            : (Navigator.canPop(context) 
                ? CustomBackButton(onPressed: () => Navigator.pop(context)) 
                : null),
        leadingWidth: 80,
        actions: [
          Center(
            child: Text(
              'Welcome, ${widget.userName}',
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
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'GIS Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Farm Registry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning, color: Colors.orange),
            label: 'Complaints',
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

class DashboardHomeView extends StatelessWidget {
  final Function(int) onTabChange;

  const DashboardHomeView({super.key, required this.onTabChange});

  // Mock data for pending farms, matching GisMapView data
  final List<Map<String, dynamic>> _pendingFarms = const [
// ... [Keep pending farms list]
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              color: const Color(0xFFF8FAFC), // Light grey background
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Authority Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const WeatherWidget(), // Add Weather Widget
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(
                title: 'Total Registered Farms',
                valueWidget: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('farms').snapshots(),
                  builder: (context, snapshot) {
                     int mockFarmsCount = 4; // The predefined farms length
                     int firebaseFarmsCount = 0;
                     if (snapshot.hasData) {
                       for (var doc in snapshot.data!.docs) {
                         final data = doc.data() as Map<String, dynamic>;
                         // Filter out unnamed farms just like registry
                         if (data['name'] == null || data['name'].toString().trim().isEmpty || data['name'] == 'Unknown Farm') {
                           continue;
                         }
                         firebaseFarmsCount++;
                       }
                     }
                     return Text(
                       '${mockFarmsCount + firebaseFarmsCount}',
                       style: const TextStyle(color: Colors.blue, fontSize: 32, fontWeight: FontWeight.bold),
                     );
                  },
                ),
                color: Colors.blue,
                onTap: () => onTabChange(2), // Index 2: Farm Registry
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                title: 'Farms in CRZ (Mock)',
                valueWidget: const Text(
                  '8',
                  style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                color: Colors.red,
                onTap: () => onTabChange(1), // Index 1: GIS Map
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard(
                title: 'Total Complaints',
                valueWidget: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Text('Error', style: TextStyle(color: Colors.red, fontSize: 16));
                    }
                    final count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      '$count',
                      style: const TextStyle(color: Colors.orange, fontSize: 32, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                color: Colors.orange,
                onTap: () => onTabChange(3), // Index 3: Authority Complaints Screen
              ),
              const SizedBox(width: 24),
              Expanded(child: Container()), // Empty placeholder to keep card sizing consistent
            ],
          ),
// ...
                ],
              ),
            ),
          ),
        ),
        const _AnimatedFishFooter(),
      ],
    );
  }


  Widget _buildStatCard({required String title, required Widget valueWidget, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              valueWidget,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmCard({required BuildContext context, required Map<String, dynamic> farm}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Owner: ${farm['owner']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
               final String status = (farm['status'] ?? '').toString();
               if (status == 'Inactive') {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This farm is inactive. Details are disabled.')));
                 return;
               }

               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmDetailsScreen(farmData: farm, isAuthority: true),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// NATIVE ANIMATED FISH FOOTER
// -----------------------------------------------------------------------------
class _AnimatedFishFooter extends StatefulWidget {
  const _AnimatedFishFooter();

  @override
  __AnimatedFishFooterState createState() => __AnimatedFishFooterState();
}

class __AnimatedFishFooterState extends State<_AnimatedFishFooter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Fixed footer height
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5AB9EA), Color(0xFF1E88E5)], // Nice ocean blue
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            // Background Wave 1
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: CustomPaint(painter: _WavePainter(offset: 0, amp: 10, freq: 2)),
              ),
            ),
            // Background Wave 2
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: CustomPaint(painter: _WavePainter(offset: 3.14, amp: 15, freq: 1.5)),
              ),
            ),
            // Swimming Fish Animations
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double w = MediaQuery.of(context).size.width;
                return Stack(
                  children: [
                    // Little fast fish
                    Positioned(
                      top: 15,
                      left: w - ((_controller.value * 1.5) % 1.0 * (w + 100)),
                      child: const Text('🐠', style: TextStyle(fontSize: 20)),
                    ),
                    // Medium standard fish
                    Positioned(
                      top: 40,
                      left: w - ((_controller.value) * (w + 100)),
                      child: const Text('🐟', style: TextStyle(fontSize: 32)),
                    ),
                    // Big slow puffer
                    Positioned(
                      top: 60,
                      left: w - ((_controller.value * 0.7) % 1.0 * (w + 100)),
                      child: const Text('🐡', style: TextStyle(fontSize: 24)),
                    ),
                    // Opposite direction fast fish!
                    Positioned(
                      top: 75,
                      right: w - ((_controller.value * 1.2) % 1.0 * (w + 100)),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.14159), // Flip horizontally
                        child: const Text('🐠', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Minimalist sandy bottom overlay (no text)
            Positioned(
              left: 0, right: 0, bottom: 0, height: 12,
              child: Container(color: const Color(0xFF0D47A1).withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double offset;
  final double amp;
  final double freq;

  _WavePainter({required this.offset, required this.amp, required this.freq});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height * 0.4);
    
    for (double x = 0; x <= size.width; x++) {
      double y = math.sin((x / size.width * math.pi * freq) + offset) * amp + (size.height * 0.4);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
