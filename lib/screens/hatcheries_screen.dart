import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Government Hatcheries',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          children: [
            _buildHatcheryCard(
              title: "Estuarine Fish Farm",
              imagePath: "assets/images/estuarine.png",
              locationText: "Location: Estuarine Fish Farm, Ela, Dhauji, Old Goa",
              mapUrl: "https://maps.google.com/maps?vet=10CAAQoqAOahcKEwjQt42I2dWSAxUAAAAAHQAAAAAQCw..i&rlz=1C1CHBD_enIN1128IN1128&sca_esv=64c0fa1002fa5be6&udm=1&pvq=Cg0vZy8xMXg1bGY0MTh5IiAKGmdvdmVybm1lbnQgZmlzaCBoYXRjaGVyaWVzEAIYAw&lqi=CiFnb3Zlcm5tZW50IGZpc2ggaGF0Y2hlcmllcyBpbiBnb2FInYrIppa8gIAIWi8QABABEAIYARgCGAQiIWdvdmVybm1lbnQgZmlzaCBoYXRjaGVyaWVzIGluIGdvYZIBEWdvdmVybm1lbnRfb2ZmaWNl&fvr=1&cs=1&um=1&ie=UTF-8&fb=1&gl=in&sa=X&ftid=0x3bbfbf003dd39827:0x1c1bd45d6047e49d",
            ),
            const SizedBox(height: 20),
            _buildHatcheryCard(
              title: "Directorate of Fisheries",
              imagePath: "assets/images/directorate.png",
              locationText: "Location: Directorate of Fisheries Dayanand Bandodkar Marg. Panaji-Goa.",
              mapUrl: "https://maps.google.com/maps?vet=10CAAQoqAOahcKEwjQt42I2dWSAxUAAAAAHQAAAAAQKw..i&rlz=1C1CHBD_enIN1128IN1128&sca_esv=64c0fa1002fa5be6&udm=1&pvq=CgsvZy8xdGhxODloYiIgChpnb3Zlcm5tZW50IGZpc2ggaGF0Y2hlcmllcxACGAM&lqi=CiFnb3Zlcm5tZW50IGZpc2ggaGF0Y2hlcmllcyBpbiBnb2FI6suQ--WAgIAIWi0QABABEAIYARgEIiFnb3Zlcm5tZW50IGZpc2ggaGF0Y2hlcmllcyBpbiBnb2GSARFnb3Zlcm5tZW50X29mZmljZZoBJENoZERTVWhOTUc5blMwVkpRMEZuU1VOQ2MxQlFRM3AzUlJBQvoBBAgAEBM&fvr=1&cs=1&um=1&ie=UTF-8&fb=1&gl=in&sa=X&ftid=0x3bbfc088fcfa0c3d:0xf782ea48537a03f6",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHatcheryCard({
    required String title,
    required String imagePath,
    required String locationText,
    required String mapUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          SizedBox(
            height: 200,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(Icons.broken_image, color: Colors.grey, size: 40),
                       Text("Image Missing", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _launchMap(mapUrl),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
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
}
