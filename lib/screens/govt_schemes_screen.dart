import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/ocean_glass_card.dart';

class GovtSchemesScreen extends StatelessWidget {
  const GovtSchemesScreen({super.key});

  final String _schemesUrl = 'https://fisheries.goa.gov.in/schemes-services/aquaculture/';

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(_schemesUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_schemesUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Text(
              'Government Schemes',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 150),
              children: [
                _buildSchemeCard(
                  title: 'Financial Assistance for setting up of Crab farming Unit in Goa',
                  onTap: _launchURL,
                  delay: 100,
                ),
                const SizedBox(height: 16),
                _buildSchemeCard(
                  title: 'Financial Assistance to Brackish Water Aquaculture Farms',
                  onTap: _launchURL,
                  delay: 150,
                ),
                const SizedBox(height: 16),
                _buildSchemeCard(
                  title: 'Financial Assistance to Fresh Water Aquaculture Farm',
                  onTap: _launchURL,
                  delay: 200,
                ),
                const SizedBox(height: 16),
                _buildSchemeCard(
                  title: 'Financial Assistance to Mussel Culture and Oyster Farming in Goa',
                  onTap: _launchURL,
                  delay: 250,
                ),
                const SizedBox(height: 16),
                _buildSchemeCard(
                  title: 'Financial Assistance for setting up of Ornamental Fish Unit in Goa',
                  onTap: _launchURL,
                  delay: 300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeCard({required String title, required VoidCallback onTap, required int delay}) {
    return OceanGlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.article_rounded, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.secondary, size: 16),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }
}
