import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/ocean_glass_card.dart';

class HatcheriesScreen extends StatelessWidget {
  const HatcheriesScreen({super.key});

  Future<void> _launchMap(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
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
              'Government Hatcheries',
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
                _buildHatcheryCard(
                  title: "Estuarine Fish Farm",
                  imagePath: "assets/images/estuarine.png",
                  locationText: "Location: Estuarine Fish Farm, Ela, Dhauji, Old Goa",
                  mapUrl: "https://maps.google.com/maps?vet=10CAAQoqAOahcKEwjQt42I2dWSAxUAAAAAHQAAAAAQCw..i&rlz=1C1CHBD_enIN1128IN1128&sca_esv=64c0fa1002fa5be6&udm=1&pvq=Cg0vZy8xMXg1bGY0MTh5IiAKGmdvdmVybm1lbnQgZmlzaCBoYXRjaGVyaWVzEAIYAw&lqi=CiFnb3Zlcm5tZW50IGZpc2ggaGF0Y2hlcmllcyBpbiBnb2FInYrIppa8gIAIWi8QABABEAIYARgCGAQiIWdvdmVybm1lbnQgZmlzaCBoYXRjaGVyaWVzIGluIGdvYZIBEWdvdmVybm1lbnRfb2ZmaWNl&fvr=1&cs=1&um=1&ie=UTF-8&fb=1&gl=in&sa=X&ftid=0x3bbfbf003dd39827:0x1c1bd45d6047e49d",
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                _buildHatcheryCard(
                  title: "Directorate of Fisheries",
                  imagePath: "assets/images/directorate.png",
                  locationText: "Location: Directorate of Fisheries Dayanand Bandodkar Marg. Panaji-Goa.",
                  mapUrl: "https://maps.google.com/maps?vet=10CAAQoqAOahcKEwjQt42I2dWSAxUAAAAAHQAAAAAQKw..i&rlz=1C1CHBD_enIN1128IN1128&sca_esv=64c0fa1002fa5be6&udm=1&pvq=CgsvZy8xdGhxODloYiIgChpnb3Zlcm5tZW50IGZpc2ggaGF0Y2hlcmllcxACGAM&lqi=CiFnb3Zlcm5tZW50IGZpc2ggaGF0Y2hlcmllcyBpbiBnb2FI6suQ--WAgIAIWi0QABABEAIYARgEIiFnb3Zlcm5tZW50IGZpc2ggaGF0Y2hlcmllcyBpbiBnb2GSARFnb3Zlcm5tZW50X29mZmljZZoBJENoZERTVWhOTUc5blMwVkpRMEZuU1VOQ2MxQlFRM3AzUlJBQvoBBAgAEBM&fvr=1&cs=1&um=1&ie=UTF-8&fb=1&gl=in&sa=X&ftid=0x3bbfc088fcfa0c3d:0xf782ea48537a03f6",
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHatcheryCard({
    required String title,
    required String imagePath,
    required String locationText,
    required String mapUrl,
  }) {
    return OceanGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.blue.withOpacity(0.05),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.broken_image, color: AppColors.secondary, size: 40),
                         const SizedBox(height: 8),
                         Text("Image Missing", style: TextStyle(color: AppColors.secondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _launchMap(mapUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationText,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
