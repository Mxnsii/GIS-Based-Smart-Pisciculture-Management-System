import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class AISpeciesService {
  // Use the established Gemini API Key
  static const String _apiKey = 'AIzaSyANLBtNn6ynJCTdC6-TDkSXpS5ggpXCfxM';
  
  static Future<List<Map<String, dynamic>>> getLiveRecommendations({
    required double temp,
    required double waveHeight,
    required double windSpeed,
    required String condition,
    required String location,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final String season = _getSeasonContext();
      
      final prompt = '''
      You are a Maritime & Fisheries AI Expert for the Goa/Coastal India region. 
      Generate exactly 5 real-time species recommendations for local pisciculture and fishing based on these CURRENT conditions:
      
      Location: $location
      Temperature: ${temp.toStringAsFixed(1)}°C
      Wave Height: ${waveHeight.toStringAsFixed(1)}m
      Wind Speed: ${windSpeed.toStringAsFixed(1)}km/h
      Condition: $condition
      Current Season: $season
      Date: ${DateTime.now().toString()}

      Consider:
      1. Biological suitability (which species thrive in this temp/sea state).
      2. Economic value (estimated current Goan market price in ₹/kg).
      3. Practicality (e.g., if waves > 2m, deep-sea fishing is risky, so prioritize inland/brackish species).
      4. Seasonal legality (Goa's monsoon fishing ban context).

      Output ONLY a valid JSON list of 5 objects with these exact keys:
      - name: Common name of the species
      - sub: A short 2-3 word highlight (e.g., "Scientific Choice", "Market Leader")
      - price: Price string (e.g., "₹ 450/kg")
      - rating: Integer 1-5 (recommendation strength)
      - trend: 4-5 word market trend description
      - icon: A single emoji representing the species or its environment (🐟, 🦐, 🦀)
      - trendIcon: One of these strings: "up", "down", "flat"
      - bestTime: Best time of day for activity (e.g., "05:00 AM - 08:00 AM")

      Example JSON Output:
      [
        {"name": "Silver Pomfret", "sub": "Premium Coastal Catch", "price": "₹ 850/kg", "rating": 5, "trend": "High Demand, Low Supply", "icon": "🐟", "trendIcon": "up", "bestTime": "04:00 AM - 07:00 AM"},
        ...
      ]
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text != null) {
        String jsonText = response.text!.trim();
        // Clean markdown if present
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7, jsonText.length - 3).trim();
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3, jsonText.length - 3).trim();
        }
        
        final List<dynamic> decoded = jsonDecode(jsonText);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return getFallbackRecommendations(temp);
    } catch (e) {
      print('Error in AISpeciesService: $e');
      return getFallbackRecommendations(temp);
    }
  }

  static String _getSeasonContext() {
    final month = DateTime.now().month;
    if (month >= 6 && month <= 8) return "Monsoon (Fishing Ban Period - High Risk)";
    if (month >= 9 && month <= 11) return "Post-Monsoon (Transition Period)";
    if (month >= 12 || month <= 2) return "Winter (Stable Season)";
    return "Summer (Pre-Monsoon)";
  }

  static List<Map<String, dynamic>> getFallbackRecommendations(double temp) {
    // Basic fallback logic if AI fails
    if (temp > 30) {
      return [
        {"name": "Tilapia", "sub": "Heat Tolerant", "price": "₹ 220/kg", "rating": 4, "trend": "Stable Inland Demand", "icon": "🐟", "trendIcon": "flat", "bestTime": "All Day"},
        {"name": "Asian Seabass", "sub": "Brackish King", "price": "₹ 550/kg", "rating": 3, "trend": "Steady Growth", "icon": "🐟", "trendIcon": "up", "bestTime": "Evening"},
        {"name": "Mud Crab", "sub": "Mangrove Choice", "price": "₹ 900/kg", "rating": 5, "trend": "Premium Export Value", "icon": "🦀", "trendIcon": "up", "bestTime": "Early Morning"},
        {"name": "Mussels", "sub": "Coastal Delicacy", "price": "₹ 150/kg", "rating": 4, "trend": "High Seasonal Supply", "icon": "🐚", "trendIcon": "down", "bestTime": "Evening"},
        {"name": "Milk Fish", "sub": "Healthy Growth", "price": "₹ 300/kg", "rating": 3, "trend": "Stable Local Market", "icon": "🐟", "trendIcon": "flat", "bestTime": "Morning"},
      ];
    }
    return [
        {"name": "Silver Pomfret", "sub": "Premium Catch", "price": "₹ 800/kg", "rating": 5, "trend": "High Seasonal Demand", "icon": "🐟", "trendIcon": "up", "bestTime": "Pre-dawn"},
        {"name": "Kingfish", "sub": "Goan Favorite", "price": "₹ 750/kg", "rating": 4, "trend": "Increasing Supply", "icon": "🐟", "trendIcon": "down", "bestTime": "Morning"},
        {"name": "Pearl Spot", "sub": "Local Delicacy", "price": "₹ 450/kg", "rating": 5, "trend": "High Local Demand", "icon": "🐟", "trendIcon": "flat", "bestTime": "Anytime"},
        {"name": "Red Snapper", "sub": "Coral Quality", "price": "₹ 600/kg", "rating": 4, "trend": "Good Export Demand", "icon": "🐟", "trendIcon": "up", "bestTime": "Evening"},
        {"name": "Squid", "sub": "Cephalopod Choice", "price": "₹ 350/kg", "rating": 3, "trend": "Large Night Catches", "icon": "🦑", "trendIcon": "flat", "bestTime": "Night"},
    ];
  }
}
