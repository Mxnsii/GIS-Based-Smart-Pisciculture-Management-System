import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'iot_monitoring_screen.dart';
import 'alerts_screen.dart';
import 'hatcheries_screen.dart';
import 'login_screen.dart';
import 'govt_schemes_screen.dart';
import 'complaint_registry_screen.dart';
import 'chatbot_screen.dart';
import 'fish_directory_screen.dart';
import 'species_recommendation_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_bubbles_bg.dart';
import '../widgets/master_ocean_background.dart';

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
    FishDirectoryScreen(),
    AlertsScreen(),
    SpeciesRecommendationScreen(),
    HatcheriesScreen(),
    GovtSchemesScreen(),
  ];

  late final Widget _complaintTab;

  @override
  void initState() {
    super.initState();
    _complaintTab = ComplaintRegistryScreen(farmerName: widget.farmerName);
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MasterOceanBackground(
        child: Column(
          children: [
              _buildAppBar(context),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedIndex),
                    child: _selectedIndex == 6 ? _complaintTab : _pages[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
      ),
      floatingActionButton: _buildFAB(context),
      extendBody: true, // Allows content behind bottom nav bar
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 10
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85),
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.oceanGradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))
                    ]
                  ),
                  child: const Icon(Icons.waves_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Farmer Dashboard',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  AppTheme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    AppTheme.toggleTheme();
                  });
                },
              ),
              const SizedBox(width: 4),
              Container(
                constraints: const BoxConstraints(maxWidth: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.farmerName,
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
                onPressed: () => Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
        label: Text('GIS Agent',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    ).animate().scale(duration: 300.ms, delay: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.shadowBlue.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _buildNavDest(Icons.sensors_outlined, Icons.sensors_rounded, 'Monitor', 0),
            _buildNavDest(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Market', 1),
            _buildNavDest(Icons.notifications_outlined, Icons.notifications_rounded, 'Alerts', 2),
            _buildNavDest(Icons.analytics_outlined, Icons.analytics_rounded, 'Species', 3),
            _buildNavDest(Icons.water_drop_outlined, Icons.water_drop_rounded, 'Hatcheries', 4),
            _buildNavDest(Icons.policy_outlined, Icons.policy_rounded, 'Schemes', 5),
            _buildNavDest(Icons.report_problem_outlined, Icons.report_problem_rounded, 'Report', 6),
          ],
        ),
      ),
    ).animate().slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
  
  NavigationDestination _buildNavDest(IconData icon, IconData selectedIcon, String label, int index) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textMuted),
      selectedIcon: Icon(selectedIcon, color: AppColors.primary).animate().shake(hz: 3),
      label: label,
    );
  }
}
