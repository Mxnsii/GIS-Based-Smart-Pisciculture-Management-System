import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fish_item.dart';
import '../services/ai_species_service.dart';
import '../services/weather_service.dart';
import 'fish_detail_screen.dart';

class FishDirectoryScreen extends StatefulWidget {
  const FishDirectoryScreen({super.key});

  @override
  State<FishDirectoryScreen> createState() => _FishDirectoryScreenState();
}

class _FishDirectoryScreenState extends State<FishDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FishItem> _filteredFishes = [];
  String _selectedType = 'All';
  String _selectedWater = 'All';
  List<Map<String, dynamic>> _aiRecommendations = [];
  bool _isAILoading = true;

  final List<FishItem> _allFishes = [
    FishItem(
      name: "Silver Pomfret",
      konkani: "Paplet",
      marathi: "Pamplet",
      icon: "🐟",
      type: "Fish",
      water: "Sea",
      avgPrice: 850,
      season: "Winter",
      demand: 5,
      description: "The most prized fish in Goa, known for its buttery texture.",
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
      type: "Fish",
      water: "Sea",
      avgPrice: 750,
      season: "Year-round",
      demand: 5,
      description: "A meaty fish widely used for the famous Goan fish fry.",
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
      type: "Fish",
      water: "Sea",
      avgPrice: 200,
      season: "Year-round",
      demand: 5,
      description: "A staple in the Goan diet, usually pan-fried with spicy Recheado masala.",
      location: "Shallow Coastal Waters",
      catchingTime: "Early Morning",
      trend: "flat",
      uses: "Grilled / Curry",
    ),
    FishItem(
      name: "Sardines",
      konkani: "Tarle",
      marathi: "Pedve",
      icon: "🐟",
      type: "Fish",
      water: "Sea",
      avgPrice: 120,
      season: "Monsoon",
      demand: 4,
      description: "Nutrient-rich small fish, highly affordable and consumed daily.",
      location: "Nearshore",
      catchingTime: "Daybreak",
      trend: "up",
      uses: "Daily Curry / Deep Fry",
    ),
    FishItem(
      name: "Ladyfish",
      konkani: "Kane",
      marathi: "Noglya",
      icon: "🐟",
      type: "Fish",
      water: "Brackish",
      avgPrice: 450,
      season: "Summer",
      demand: 4,
      description: "A slender, sweet-tasting fish known for its high nutritional value.",
      location: "River Mouths",
      catchingTime: "Evening",
      trend: "flat",
      uses: "Fish Fry",
    ),
    FishItem(
      name: "Bombay Duck",
      konkani: "Bombil",
      marathi: "Bombil",
      icon: "🐟",
      type: "Fish",
      water: "Sea",
      avgPrice: 300,
      season: "Monsoon",
      demand: 3,
      description: "Soft, gelatinous fish often fried to a crisp exterior.",
      location: "Open Sea",
      catchingTime: "Morning",
      trend: "flat",
      uses: "Deep Fry",
    ),
    FishItem(
      name: "Asian Seabass",
      konkani: "Chonak",
      marathi: "Khajura",
      icon: "🐟",
      type: "Fish",
      water: "Brackish",
      avgPrice: 650,
      season: "Monsoon / Post-Monsoon",
      demand: 4,
      description: "A premium brackish water fish found in Goan estuaries.",
      location: "Chapora River",
      catchingTime: "Evening Tides",
      trend: "up",
      uses: "Steak Fry / Recheado",
    ),
    FishItem(
      name: "Tiger Prawns",
      konkani: "Sungta",
      marathi: "Kolambi",
      icon: "🦐",
      type: "Prawn",
      water: "Brackish",
      avgPrice: 950,
      season: "Summer",
      demand: 5,
      description: "Premium export-quality prawns from the khazan lands.",
      location: "Mandovi Estuary",
      catchingTime: "Low Tide",
      trend: "up",
      uses: "Export / Premium Dining",
    ),
    FishItem(
      name: "Mud Crab",
      konkani: "Kurlli",
      marathi: "Chimbori",
      icon: "🦀",
      type: "Crab",
      water: "Brackish",
      avgPrice: 1100,
      season: "Monsoon",
      demand: 5,
      description: "Large, nutrient-rich crabs found in mangroves.",
      location: "Zuari River Mangroves",
      catchingTime: "Night",
      trend: "up",
      uses: "Crab Xec Xec",
    ),
    FishItem(
      name: "Red Snapper",
      konkani: "Tamso",
      marathi: "Tamb",
      icon: "🐟",
      type: "Fish",
      water: "Sea",
      avgPrice: 550,
      season: "Year-round",
      demand: 4,
      description: "Great for baking and slow-cooked Goan curries.",
      location: "Dona Paula Rocks",
      catchingTime: "Early Morning",
      trend: "flat",
      uses: "Baking / Curry",
    ),
    FishItem(
      name: "Squid",
      konkani: "Mankios",
      marathi: "Squid",
      icon: "🦑",
      type: "Fish",
      water: "Sea",
      avgPrice: 350,
      season: "Winter",
      demand: 4,
      description: "Cephalopod prized for its texture, standard in Calamari dishes.",
      location: "Goan Coast",
      catchingTime: "Night",
      trend: "up",
      uses: "Fried Rings / Amot-tik",
    ),
    FishItem(
      name: "Pearl Spot",
      konkani: "Kalundar",
      marathi: "Karimeen",
      icon: "🐟",
      type: "Fish",
      water: "Brackish",
      avgPrice: 400,
      season: "Year-round",
      demand: 3,
      description: "Oval-shaped fish from the backwaters, highly delicate flavor.",
      location: "St Estevam Waters",
      catchingTime: "Afternoon",
      trend: "flat",
      uses: "Baked in Banana Leaf",
    ),
    FishItem(
      name: "Mussels",
      konkani: "Xinaneto",
      marathi: "Kalkav",
      icon: "🐚",
      type: "Shellfish",
      water: "Sea",
      avgPrice: 150,
      season: "Monsoon",
      demand: 4,
      description: "Collected from rocks during low tide, a popular Goan street snack.",
      location: "Candolim Rocks",
      catchingTime: "Low Tide",
      trend: "flat",
      uses: "Rava Fry",
    ),
    FishItem(
      name: "Lobster",
      konkani: "Nustem",
      marathi: "Shevandi",
      icon: "🦞",
      type: "Crab",
      water: "Sea",
      avgPrice: 2000,
      season: "Winter",
      demand: 5,
      description: "The peak of luxury seafood, primarily for export and high-end hotels.",
      location: "Deep Sea",
      catchingTime: "Night",
      trend: "flat",
      uses: "Grilled Premium",
    ),
    FishItem(
      name: "Shark",
      konkani: "Mori",
      marathi: "Mushi",
      icon: "🦈",
      type: "Fish",
      water: "Sea",
      avgPrice: 400,
      season: "Year-round",
      demand: 3,
      description: "Smaller varieties used for the distinctive Mori Amot-tik curry.",
      location: "Continental Shelf",
      catchingTime: "Dawn",
      trend: "down",
      uses: "Spicy Curry",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFishes = _allFishes;
    _searchController.addListener(_filterList);
    _loadAIRecommendations();
  }

  Future<void> _loadAIRecommendations() async {
    try {
      // 1. Get Current Location
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
        }
      } catch (e) {
        print('Location sensor error: $e');
      }

      // 2. Fetch Weather for Location (or fallback to Panjim)
      final double lat = position?.latitude ?? 15.4967;
      final double lng = position?.longitude ?? 73.8263;
      
      final weatherService = WeatherService();
      final weather = await weatherService.fetchWeatherData(lat: lat, lng: lng);
      
      final recs = await AISpeciesService.getLiveRecommendations(
        temp: weather['temp'],
        waveHeight: weather['wave_height'],
        windSpeed: weather['wind_speed'],
        condition: weather['condition'],
        location: weather['location'] ?? "Current Coastal Zone",
      );
      
      setState(() {
        _aiRecommendations = recs;
        _isAILoading = false;
      });
    } catch (e) {
      print('Error loading AI Recommendations in Directory: $e');
      setState(() => _isAILoading = false);
    }
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFishes = _allFishes.where((fish) {
        final matchesSearch = fish.name.toLowerCase().contains(query) || 
                            fish.konkani.toLowerCase().contains(query) || 
                            fish.marathi.toLowerCase().contains(query);
        final matchesType = _selectedType == 'All' || fish.type == _selectedType;
        final matchesWater = _selectedWater == 'All' || fish.water == _selectedWater;
        return matchesSearch && matchesType && matchesWater;
      }).toList();
    });
  }

  void _showVoiceSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 250,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("LISTENING...", style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 12)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.mic, size: 40, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text("Say a fish name in Konkani or English", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  bool _isMonsoon() {
    final now = DateTime.now();
    // Goan Fishing Ban: June 1st to July 31st
    return now.month == 6 || now.month == 7;
  }

  bool _isRecommendedToday(String name) {
    return _aiRecommendations.any((rec) => rec['name'].toString().toLowerCase().contains(name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Maritime Directory', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 18)),
            Text('GOA MARITIME INTELLIGENCE', style: TextStyle(fontSize: 8, letterSpacing: 2, color: Colors.blue, fontWeight: FontWeight.w900)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none, color: Colors.blue),
            onPressed: _showVoiceSearch,
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _filteredFishes.isEmpty 
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _filteredFishes.length,
                  itemBuilder: (context, index) {
                    final fish = _filteredFishes[index];
                    return _buildIntelligenceCard(fish);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search (Konkani / Marathi / Hindi)...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue, size: 20),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('Type: ', ['All', 'Fish', 'Crab', 'Prawn'], _selectedType, (val) {
                  setState(() => _selectedType = val);
                  _filterList();
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Water: ', ['All', 'Sea', 'Brackish', 'River'], _selectedWater, (val) {
                  setState(() => _selectedWater = val);
                  _filterList();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, List<String> options, String current, Function(String) onSelect) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ...options.map((opt) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ChoiceChip(
            label: Text(opt, style: const TextStyle(fontSize: 10)),
            selected: current == opt,
            onSelected: (_) => onSelect(opt),
            selectedColor: Colors.blue.shade100,
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildIntelligenceCard(FishItem fish) {
    bool recommended = _isRecommendedToday(fish.name);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FishDetailScreen(fish: fish))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Center(child: Text(fish.icon, style: const TextStyle(fontSize: 50))),
                ),
                if (recommended)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                      child: const Text('RECOMMENDED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                    child: Text('₹${fish.avgPrice.toInt()}/kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(fish.konkani, style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusIndicator(fish.isBanned || (_isMonsoon() && fish.water == 'Sea')),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          Icons.star, 
                          size: 8, 
                          color: i < fish.demand ? Colors.orange : Colors.grey.shade300
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return const Center(child: Text('No species found matching your filters.'));
  }
}
