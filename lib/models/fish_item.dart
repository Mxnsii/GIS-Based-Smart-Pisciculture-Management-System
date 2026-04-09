class FishItem {
  final String name;
  final String konkani;
  final String marathi;
  final String icon;
  final String type; // Fish, Crab, Prawn, Shellfish
  final String water; // Sea, River, Brackish
  final double avgPrice;
  final String season;
  final int demand; // 1-5
  final String description;
  final String location; // North Goa, etc.
  final String catchingTime;
  final String trend; // up, down, flat
  final String uses; // Export, Local Food, Premium Curry
  final bool isBanned; // True during monsoon for sea fish
  final String? imageUrl; // Added for 'real fish pics'

  // Live price data from Firebase/Gemini (injected externally)
  double? livePrice;
  String? liveTrend;
  double? liveChangePct;
  DateTime? priceLastUpdated;

  FishItem({
    required this.name,
    required this.konkani,
    required this.marathi,
    required this.icon,
    required this.type,
    required this.water,
    required this.avgPrice,
    required this.season,
    required this.demand,
    required this.description,
    required this.location,
    required this.catchingTime,
    required this.trend,
    required this.uses,
    this.isBanned = false,
    this.imageUrl,
  });

  // Returns live price if available, otherwise falls back to daily-simulated price
  double get currentPrice {
    if (livePrice != null) return livePrice!;
    // Fallback: daily-varying simulation
    final now = DateTime.now();
    final seed = (now.year * 366 + now.day) ^ name.hashCode;
    final jitter = (seed % 21 - 10) / 100.0;
    return avgPrice * (1 + jitter);
  }

  // Returns live trend or static trend
  String get currentTrend => liveTrend ?? trend;
}
