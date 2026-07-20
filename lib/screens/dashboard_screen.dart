import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'gis_map_view.dart';
import 'farm_registry_screen.dart';
import 'login_screen.dart';
import 'farm_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/weather_widget.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/app_card.dart';
import '../widgets/animated_wave_header.dart';
import '../widgets/master_ocean_background.dart';
import '../theme/app_theme.dart';
import 'authority_complaints_screen.dart';
import 'chatbot_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  const DashboardScreen({super.key, required this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

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
      backgroundColor: Colors.transparent,
      body: MasterOceanBackground(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedIndex),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
      ),
      floatingActionButton: _buildFAB(context),
      extendBody: true,
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildAppBar() {
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
                if (_selectedIndex != 0)
                  CustomBackButton(onPressed: () => _onItemTapped(0)),
                if (_selectedIndex == 0)
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
                    'Authority Dashboard',
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
                        widget.userName,
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
          destinations: [
            _buildNavDest(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard', 0),
            _buildNavDest(Icons.map_outlined, Icons.map_rounded, 'GIS Map View', 1),
            _buildNavDest(Icons.list_alt_outlined, Icons.list_alt_rounded, 'Farm Registry', 2),
            _buildNavDest(Icons.warning_amber_outlined, Icons.warning_amber_rounded, 'Incident Logs', 3),
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

// ─────────────────────────────────────────────────────────────────────────────
class DashboardHomeView extends StatelessWidget {
  final Function(int) onTabChange;
  const DashboardHomeView({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image banner
            _buildImageBanner().animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weather
                  const WeatherWidget().animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),

                  // Section label
                  _sectionLabel('Quick Stats').animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 14),

                  // Symmetrical Stat Cards Layout
                  Builder(
                    builder: (context) {
                      final registeredFarmsCard = StatCard(
                        title: 'REGISTERED FARMS',
                        valueWidget: Text('4',
                            style: GoogleFonts.inter(
                                color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w800)),
                        icon: Icons.agriculture_rounded,
                        accentColor: AppColors.primary,
                        subtitle: 'Active aquaculture sites',
                        onTap: () => onTabChange(2),
                      );

                      final crzFarmsCard = StatCard(
                        title: 'FARMS IN CRZ ZONE',
                        valueWidget: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('8',
                                style: GoogleFonts.inter(
                                    color: AppColors.danger,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: _badge('Mock', AppColors.warning),
                            ),
                          ],
                        ),
                        icon: Icons.location_on_rounded,
                        accentColor: AppColors.danger,
                        subtitle: 'Coastal regulation zone',
                        onTap: () => onTabChange(1),
                      );

                      final totalComplaintsCard = StatCard(
                        title: 'TOTAL COMPLAINTS',
                        valueWidget: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
                          builder: (ctx, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const SizedBox(width: 32, height: 32,
                                  child: CircularProgressIndicator(strokeWidth: 2));
                            }
                            final count = snap.data?.docs.length ?? 0;
                            return Text('$count',
                                style: GoogleFonts.inter(
                                    color: AppColors.warning,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800));
                          },
                        ),
                        icon: Icons.report_problem_rounded,
                        accentColor: AppColors.warning,
                        subtitle: 'Pending review',
                        onTap: () => onTabChange(3),
                      );

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 600) {
                            return Row(
                              children: [
                                registeredFarmsCard,
                                const SizedBox(width: 14),
                                crzFarmsCard,
                                const SizedBox(width: 14),
                                totalComplaintsCard,
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    registeredFarmsCard,
                                    const SizedBox(width: 14),
                                    crzFarmsCard,
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    totalComplaintsCard,
                                  ],
                                ),
                              ],
                            );
                          }
                        },
                      );
                    }
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 150),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: AppColors.oceanGradient
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildImageBanner() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.asset(
              'assets/images/dashboard_hero.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.oceanGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.primary.withOpacity(0.85)],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.waves_rounded, color: Colors.white, size: 24),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white54),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pisciculture Dashboard',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          shadows: [const Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideX(),
                      Text(
                        'Smart monitoring and management',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          shadows: [const Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
