import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Government Schemes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSchemeCard(
              title: 'Financial Assistance for setting up of Crab farming Unit in Goa',
              onTap: _launchURL,
            ),
            const SizedBox(height: 12),
            _buildSchemeCard(
              title: 'Financial Assistance to Brackish Water Aquaculture Farms',
              onTap: _launchURL,
            ),
            const SizedBox(height: 12),
            _buildSchemeCard(
              title: 'Financial Assistance to Fresh Water Aquaculture Farm',
              onTap: _launchURL,
            ),
            const SizedBox(height: 12),
            _buildSchemeCard(
              title: 'Financial Assistance to Mussel Culture and Oyster Farming in Goa',
              onTap: _launchURL,
            ),
            const SizedBox(height: 12),
            _buildSchemeCard(
              title: 'Financial Assistance for setting up of Ornamental Fish Unit in Goa',
              onTap: _launchURL,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCard({required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
