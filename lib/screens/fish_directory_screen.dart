import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/fish_item.dart';
import '../services/weather_service.dart';
import '../services/fish_price_service.dart';
import 'fish_detail_screen.dart';
import '../widgets/ocean_glass_card.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FishDirectoryScreen extends StatefulWidget {
  const FishDirectoryScreen({super.key});

  @override
  State<FishDirectoryScreen> createState() => _FishDirectoryScreenState();
}

class _FishDirectoryScreenState extends State<FishDirectoryScreen> {
  List<FishItem> _filteredFishes = [];
  bool _pricesLoading = true;
  DateTime? _pricesLastUpdated;

  final List<FishItem> _allFishes = [
    FishItem(
      name: "Silver Pomfret",
      konkani: "Paplet",
      marathi: "Pamplet",
      icon: "🐟",
      imageUrl: "assets/images/pomfret.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 850,
      season: "Winter",
      demand: 5,
      description: "The most prized fish in Goa, known for its buttery texture and delicate flavor.",
      location: "Goa Coastline",
      catchingTime: "04:00 AM - 07:00 AM",
      trend: "up",
      uses: "Premium Curry / Pan Fry",
    ),
    FishItem(
      name: "Kingfish",
      konkani: "Viswon",
      marathi: "Surmai",
      icon: "🐟",
      imageUrl: "assets/images/kingfish.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 750,
      season: "Year-round",
      demand: 5,
      description: "A meaty, firm fish widely used for the famous Goan fish fry and recheado.",
      location: "Offshore Goa",
      catchingTime: "Pre-dawn",
      trend: "flat",
      uses: "Fish Fry / Curry",
    ),
    FishItem(
      name: "Mackerel",
      konkani: "Bangda",
      marathi: "Bangda",
      icon: "🐟",
      imageUrl: "assets/images/mackerel.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 200,
      season: "Year-round",
      demand: 5,
      description: "A staple in the Goan diet, usually pan-fried with spicy Recheado masala.",
      location: "Shallow Coastal Waters",
      catchingTime: "Early Morning",
      trend: "flat",
      uses: "Grilled / Recheado Fry",
    ),
    FishItem(
      name: "Sardines",
      konkani: "Tarle",
      marathi: "Tarle",
      icon: "🐟",
      imageUrl: "assets/images/sardine.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 120,
      season: "Monsoon / Post-Monsoon",
      demand: 4,
      description: "Small oily fish, extremely popular in Goa for its affordable price and rich taste.",
      location: "Coastal Goa",
      catchingTime: "Dawn",
      trend: "flat",
      uses: "Fried / Curry / Dried",
    ),
    FishItem(
      name: "Tuna",
      konkani: "Kupa",
      marathi: "Kupa",
      icon: "🐟",
      imageUrl: "assets/images/tuna.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 500,
      season: "Summer",
      demand: 4,
      description: "Powerful deep-sea fish, excellent for steaks and curry.",
      location: "Deep Offshore Goa",
      catchingTime: "Early Morning",
      trend: "flat",
      uses: "Fish Steaks / Export",
    ),
    FishItem(
      name: "Ladyfish",
      konkani: "Kane",
      marathi: "Kane",
      icon: "🐟",
      imageUrl: "assets/images/ladyfish.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 180,
      season: "Year-round",
      demand: 3,
      description: "A slender, silvery fish popular in Goa for its use in sol kadhi accompaniments.",
      location: "Coastal Waters",
      catchingTime: "Morning",
      trend: "flat",
      uses: "Rava Fry / Curry",
    ),
    FishItem(
      name: "Bombay Duck",
      konkani: "Bombil",
      marathi: "Bombil",
      icon: "🐟",
      imageUrl: "assets/images/bombil.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 150,
      season: "Monsoon",
      demand: 4,
      description: "A unique gelatinous fish dried and used as a condiment across coastal Maharashtra and Goa.",
      location: "Coastal Estuary",
      catchingTime: "Pre-dawn",
      trend: "flat",
      uses: "Rava Fry / Dried / Pickle",
    ),
    FishItem(
      name: "Red Snapper",
      konkani: "Tamso",
      marathi: "Tamso",
      icon: "🐟",
      imageUrl: "assets/images/red_snapper.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 650,
      season: "Post-Monsoon",
      demand: 4,
      description: "Prized for its firm, mild white flesh, popular in Goan curry and grilled preparations.",
      location: "Rocky Reefs, Goa",
      catchingTime: "Pre-dawn",
      trend: "up",
      uses: "Curry / Grilled",
    ),
    FishItem(
      name: "Asian Seabass",
      konkani: "Chonak",
      marathi: "Chonak",
      icon: "🐟",
      imageUrl: "assets/images/chonak.png",
      type: "Fish",
      water: "Brackish",
      avgPrice: 700,
      season: "Year-round",
      demand: 4,
      description: "A premium fish found in Goan estuaries, farmed in khazan lands and wild-caught.",
      location: "Mandovi & Zuari Rivers",
      catchingTime: "Early Morning",
      trend: "up",
      uses: "Curry / Steamed / Grilled",
    ),
    FishItem(
      name: "Shark",
      konkani: "Mori",
      marathi: "Mori",
      icon: "🦈",
      imageUrl: "assets/images/shark.png",
      type: "Fish",
      water: "Sea",
      avgPrice: 350,
      season: "Summer",
      demand: 3,
      description: "Locally caught shark (Mori) is a traditional delicacy in Goan cuisine.",
      location: "Offshore Arabian Sea",
      catchingTime: "Deep Sea",
      trend: "down",
      uses: "Curry / Dried",
    ),
    FishItem(
      name: "Tiger Prawns",
      konkani: "Sungta",
      marathi: "Kolambi",
      icon: "🦐",
      imageUrl: "assets/images/prawns.png",
      type: "Prawn",
      water: "Brackish",
      avgPrice: 950,
      season: "Summer",
      demand: 5,
      description: "Premium large prawns found in Goan estuaries and khazan lands.",
      location: "Mandovi / Zuari Estuaries",
      catchingTime: "Low Tide",
      trend: "up",
      uses: "Prawn Balchao / Butter Garlic",
    ),
    FishItem(
      name: "Mud Crab",
      konkani: "Kurlli",
      marathi: "Chimbori",
      icon: "🦀",
      imageUrl: "assets/images/crab.png",
      type: "Crab",
      water: "Brackish",
      avgPrice: 1200,
      season: "Post-Monsoon",
      demand: 5,
      description: "Large, meaty crabs from Goan mangroves, prized for their sweet, dense flesh.",
      location: "Zuari / Mandovi Mangroves",
      catchingTime: "Night",
      trend: "up",
      uses: "Crab Xacuti / Butter Garlic",
    ),
    FishItem(
      name: "Lobster",
      konkani: "Shevandi",
      marathi: "Shevand",
      icon: "🦞",
      imageUrl: "assets/images/lobster.png",
      type: "Crustacean",
      water: "Sea",
      avgPrice: 2500,
      season: "Post-Monsoon",
      demand: 5,
      description: "A luxury seafood prized in starred restaurants and tourist eateries across Goa.",
      location: "Rocky Offshore, North Goa",
      catchingTime: "Night",
      trend: "up",
      uses: "Grilled / Thermidor",
    ),
    FishItem(
      name: "Mussels",
      konkani: "Xinaneto",
      marathi: "Shilgya",
      icon: "🦪",
      imageUrl: "assets/images/mussels.png",
      type: "Shellfish",
      water: "Brackish",
      avgPrice: 250,
      season: "Post-Monsoon",
      demand: 4,
      description: "Black-shelled bivalves farmed and wild-caught in Goan estuaries.",
      location: "Zuari Estuary & Backwaters",
      catchingTime: "Low Tide",
      trend: "flat",
      uses: "Tisreo Sukhem / Curry",
    ),
    FishItem(
      name: "Oysters",
      konkani: "Kalva",
      marathi: "Kalva",
      icon: "🦪",
      imageUrl: "assets/images/oysters.png",
      type: "Shellfish",
      water: "Brackish",
      avgPrice: 600,
      season: "Post-Monsoon",
      demand: 4,
      description: "Rich coastal shellfish farmed in Goan river beds and rocky shores.",
      location: "Zuari Estuary",
      catchingTime: "Low Tide",
      trend: "up",
      uses: "Rava Fry / Curry",
    ),
    FishItem(
      name: "Squid",
      konkani: "Mankios",
      marathi: "Mankios",
      icon: "🦑",
      imageUrl: "assets/images/squid.png",
      type: "Cephalopod",
      water: "Sea",
      avgPrice: 400,
      season: "Post-Monsoon",
      demand: 4,
      description: "Tender squid, popular in Goan xacuti and cafreal preparations.",
      location: "Coastal Goa",
      catchingTime: "Night",
      trend: "flat",
      uses: "Squid Xacuti / Fried Rings",
    ),
  ];


  @override
  void initState() {
    super.initState();
    _filteredFishes = _allFishes;
    _loadLivePrices();
  }

  Future<void> _loadLivePrices() async {
    // Trigger Firebase refresh (Gemini generates if stale)
    await FishPriceService.ensurePricesAreFresh();
    // Subscribe to live stream
    FishPriceService.getPricesStream().listen((prices) {
      if (!mounted) return;
      setState(() {
        for (final fish in _allFishes) {
          final live = prices[fish.name];
          if (live != null) {
            fish.livePrice = live.price;
            fish.liveTrend = live.trend;
            fish.liveChangePct = live.changePct;
            fish.priceLastUpdated = live.lastUpdated;
          }
        }
        _filteredFishes = _allFishes;
        _pricesLoading = false;
        _pricesLastUpdated = prices.values.isNotEmpty
            ? prices.values.first.lastUpdated
            : DateTime.now();
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildTopRecommendations(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Available in Goa',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: _filteredFishes.isEmpty 
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 150),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: 320,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: _filteredFishes.length,
                  itemBuilder: (context, index) {
                    final fish = _filteredFishes[index];
                    return _buildProductCard(fish);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRecommendations() {
    final recommended = _allFishes.take(5).toList(); 
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
          child: Text(
            'TODAY\'S BEST CATCH',
            style: GoogleFonts.inter(
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
            ),
          ),
        ),
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recommended.length,
            itemBuilder: (context, index) {
              final fish = recommended[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SizedBox(
                  width: 150,
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: fish.imageUrl != null 
                            ? Image.asset(fish.imageUrl!, fit: BoxFit.contain)
                            : Text(fish.icon, style: const TextStyle(fontSize: 60)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              fish.name,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₹${fish.currentPrice.toInt()}/kg',
                              style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(FishItem fish) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        children: [
          // Title at top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              fish.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Large Fish Icon in middle
          Expanded(
            child: Center(
              child: fish.imageUrl != null 
                ? Image.asset(fish.imageUrl!, fit: BoxFit.contain)
                : Text(fish.icon, style: const TextStyle(fontSize: 80)),
            ),
          ),
          // See Details Button at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => FishDetailScreen(fish: fish))
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    'See Details >',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool banned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: banned ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 2, backgroundColor: banned ? Colors.red : Colors.green),
          const SizedBox(width: 4),
          Text(
            banned ? 'BANNED' : 'LIVE', 
            style: TextStyle(color: banned ? Colors.red : Colors.green, fontSize: 8, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No match found',
        style: GoogleFonts.inter(color: Colors.white),
      ),
    );
  }

}
