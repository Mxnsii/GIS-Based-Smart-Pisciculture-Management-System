import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/fish_item.dart';
import '../theme/app_theme.dart';
import '../widgets/master_ocean_background.dart';
import '../widgets/ocean_glass_card.dart';
import '../widgets/custom_back_button.dart';
import '../services/tts_service.dart';

class FishDetailScreen extends StatelessWidget {
  final FishItem fish;

  const FishDetailScreen({super.key, required this.fish});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        TtsService.stop();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Allow MasterOceanBackground to show
        body: MasterOceanBackground(
          showFishes: true, // Float animated fishes in the background for theme immersion
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 140), // Large bottom padding for floating feel
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageCard(context),
                        const SizedBox(height: 24),
                        _buildHeaderInfo(context),
                        const SizedBox(height: 24),
                        _buildDescriptionCard(context),
                        const SizedBox(height: 24),
                        _buildMetricDashboard(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Redesigned themed BACK button (consistent with authority side)
          SizedBox(
            width: 80,
            height: 48,
            child: CustomBackButton(
              onPressed: () {
                TtsService.stop();
                Navigator.pop(context);
              },
            ),
          ),
          
          Text(
            'Fish Profile',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),

          // Category Pill Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Text(
              fish.type.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildImageCard(BuildContext context) {
    return Stack(
      children: [
        OceanGlassCard(
          borderRadius: 28,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, // Blends perfectly with fish image white background
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Hero(
              tag: 'fish_${fish.name}',
              child: Center(
                child: fish.imageUrl != null
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          fish.imageUrl!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Text(
                        fish.icon,
                        style: const TextStyle(fontSize: 120),
                      ),
              ),
            ),
          ),
        ).animate().fade(duration: 400.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
        
        // Monsoon Ban Badge
        if (fish.isBanned)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'BANNED (MONSOON)',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 200.ms).fadeIn().scale(curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildHeaderInfo(BuildContext context) {
    final bool isUp = fish.currentTrend == 'up';
    final bool isDown = fish.currentTrend == 'down';
    
    Color trendBg;
    Color trendText;
    IconData trendIcon;
    String trendLabel;

    if (isUp) {
      trendBg = AppColors.successLight;
      trendText = AppColors.success;
      trendIcon = Icons.trending_up;
      trendLabel = fish.liveChangePct != null 
          ? '+${fish.liveChangePct!.toStringAsFixed(1)}%' 
          : 'PRICE UP';
    } else if (isDown) {
      trendBg = AppColors.dangerLight;
      trendText = AppColors.danger;
      trendIcon = Icons.trending_down;
      trendLabel = fish.liveChangePct != null 
          ? '${fish.liveChangePct!.toStringAsFixed(1)}%' 
          : 'PRICE DOWN';
    } else {
      trendBg = AppColors.info.withOpacity(0.1);
      trendText = AppColors.info;
      trendIcon = Icons.trending_flat;
      trendLabel = 'STABLE';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fish.name,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildLocalNamePill(
                    "Konkani", 
                    fish.konkani, 
                    AppColors.primary, 
                    () => TtsService.speakKonkani(fish.konkani),
                  ),
                  _buildLocalNamePill(
                    "Marathi", 
                    fish.marathi, 
                    AppColors.textSecondary, 
                    () => TtsService.speakMarathi(fish.marathi),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Redesigned Trend Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: trendBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: trendText.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: trendText.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trendIcon, color: trendText, size: 20),
              const SizedBox(height: 2),
              Text(
                trendLabel,
                style: GoogleFonts.inter(
                  color: trendText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildLocalNamePill(String language, String name, Color color, VoidCallback onSpeak) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSpeak,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$language: ',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.7),
                ),
              ),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.volume_up_rounded,
                size: 14,
                color: color.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return OceanGlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fish.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMetricDashboard(BuildContext context) {
    return OceanGlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Market Details & Parameters',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetricRow(Icons.currency_rupee, "Market Price", "₹${fish.currentPrice.toInt()}/kg", Colors.green),
          const Divider(height: 24),
          _buildMetricRow(Icons.waves, "Habitat", fish.water, Colors.blue),
          const Divider(height: 24),
          _buildMetricRow(Icons.calendar_month, "Best Season", fish.season, Colors.orange),
          const Divider(height: 24),
          _buildMetricRow(Icons.location_on, "Common Area", fish.location, Colors.red),
          const Divider(height: 24),
          _buildMetricRow(Icons.access_time, "Catch Time", fish.catchingTime, Colors.purple),
          const Divider(height: 24),
          _buildMetricRow(Icons.restaurant, "Culinary Uses", fish.uses, Colors.teal),
          const Divider(height: 24),
          _buildDemandRow("Demand Level", fish.demand),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMetricRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 13, 
              color: AppColors.textSecondary, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Text(
            value, 
            textAlign: TextAlign.left,
            style: GoogleFonts.inter(
              fontSize: 13, 
              fontWeight: FontWeight.bold, 
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemandRow(String label, int rating) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Icon(Icons.star_outline_rounded, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 13, 
              color: AppColors.textSecondary, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final bool isActive = index < rating;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: isActive ? Colors.amber : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
