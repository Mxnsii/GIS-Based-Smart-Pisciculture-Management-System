import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

/// Holds live price data for a single fish species
class FishPriceData {
  final double price;
  final String trend; // 'up', 'down', 'flat'
  final double changePct;
  final DateTime lastUpdated;
  final String source;

  FishPriceData({
    required this.price,
    required this.trend,
    required this.changePct,
    required this.lastUpdated,
    required this.source,
  });

  factory FishPriceData.fromMap(Map<dynamic, dynamic> map) {
    return FishPriceData(
      price: (map['price'] as num).toDouble(),
      trend: map['trend'] ?? 'flat',
      changePct: (map['change_pct'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.tryParse(map['last_updated'] ?? '') ?? DateTime.now(),
      source: map['source'] ?? 'Firebase',
    );
  }

  Map<String, dynamic> toMap() => {
    'price': price,
    'trend': trend,
    'change_pct': changePct,
    'last_updated': lastUpdated.toIso8601String(),
    'source': source,
    'date': DateFormat('yyyy-MM-dd').format(lastUpdated),
  };
}

class FishPriceService {
  static const String _apiKey = 'AIzaSyANLBtNn6ynJCTdC6-TDkSXpS5ggpXCfxM';
  static final DatabaseReference _ref =
      FirebaseDatabase.instance.ref('fish_market_prices');

  // Baseline prices (₹/kg) for Goa market — used as seed for AI
  static const Map<String, double> _basePrices = {
    'Silver Pomfret': 850,
    'Kingfish': 750,
    'Mackerel': 200,
    'Sardines': 120,
    'Tuna': 500,
    'Ladyfish': 180,
    'Bombay Duck': 150,
    'Red Snapper': 650,
    'Asian Seabass': 700,
    'Shark': 350,
    'Tiger Prawns': 950,
    'Mud Crab': 1200,
    'Lobster': 2500,
    'Mussels': 250,
    'Oysters': 600,
    'Squid': 400,
  };

  /// Stream of all live prices from Firebase
  static Stream<Map<String, FishPriceData>> getPricesStream() {
    return _ref.onValue.map((event) {
      if (event.snapshot.value == null) return {};
      try {
        final raw = event.snapshot.value as Map<dynamic, dynamic>;
        return raw.map((key, value) => MapEntry(
          key.toString(),
          FishPriceData.fromMap(value as Map<dynamic, dynamic>),
        ));
      } catch (_) {
        return {};
      }
    });
  }

  /// Call this on app start — refreshes prices if older than 12 hours
  static Future<void> ensurePricesAreFresh() async {
    try {
      final snapshot = await _ref.child('Silver Pomfret/date').get();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Check if we already updated today
      if (snapshot.exists && snapshot.value == today) return;

      // Prices are stale — regenerate with Gemini
      await _generateWithGemini();
    } catch (e) {
      // If Firebase fails, seed with realistic fallback prices
      await _seedWithFallback();
    }
  }

  /// Uses Gemini AI to generate realistic Goa market prices for today
  static Future<void> _generateWithGemini() async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final today = DateFormat('MMMM d, yyyy').format(DateTime.now());
      final dayOfWeek = DateFormat('EEEE').format(DateTime.now());
      final month = DateFormat('MMMM').format(DateTime.now());

      final speciesList = _basePrices.entries
          .map((e) => '${e.key}: baseline ₹${e.value}/kg')
          .join('\n');

      final prompt = '''
You are a fish market price analyst for Goa, India. Generate realistic wholesale market prices for today ($today, $dayOfWeek) at the Panaji fish market, Goa.

Context:
- Month: $month (consider monsoon season Jun-Sep affects availability)
- Location: Goa coastline market (Panaji wholesale market)
- Currency: Indian Rupees (₹) per kg
- All prices must be whole numbers

Species with baseline prices:
$speciesList

Rules for pricing:
1. Prices should vary ±15% from baseline based on season, day of week (higher on weekends), demand
2. Monsoon months (Jun-Sep): sea fish prices go UP 20-40% (reduced catch), shellfish go UP 15%
3. Post-monsoon (Oct-Nov): prices drop as catch resumes
4. Lobster, Pomfret, Mud Crab always command premium pricing
5. Weekend prices (Friday/Saturday/Sunday) are 5-10% higher
6. trend: "up" if price > baseline, "down" if < baseline, "flat" if within 3%
7. change_pct: percentage change from baseline (positive or negative)

Return ONLY a valid JSON object with this exact structure (no markdown):
{
  "Silver Pomfret": {"price": 875, "trend": "up", "change_pct": 2.9},
  "Kingfish": {"price": 720, "trend": "down", "change_pct": -4.0},
  ... (all 16 species)
}
''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        String jsonText = response.text!.trim();
        // Strip markdown if present
        if (jsonText.startsWith('```')) {
          jsonText = jsonText.replaceAll(RegExp(r'```(?:json)?'), '').trim();
        }

        final Map<String, dynamic> parsed = jsonDecode(jsonText);
        final now = DateTime.now();
        final today = DateFormat('yyyy-MM-dd').format(now);

        final Map<String, dynamic> updates = {};
        parsed.forEach((species, data) {
          final d = data as Map<String, dynamic>;
          updates[species] = {
            'price': (d['price'] as num).toDouble(),
            'trend': d['trend'] ?? 'flat',
            'change_pct': (d['change_pct'] as num?)?.toDouble() ?? 0.0,
            'last_updated': now.toIso8601String(),
            'date': today,
            'source': 'Gemini-AI-Goa-Market',
          };
        });

        await _ref.update(updates);
      }
    } catch (e) {
      print('Gemini price generation failed: $e');
      await _seedWithFallback();
    }
  }

  /// Fallback: seeds Firebase with realistic daily-varied prices
  static Future<void> _seedWithFallback() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final isMonsoon = now.month >= 6 && now.month <= 9;
    final isWeekend = now.weekday >= 5;

    final Map<String, dynamic> updates = {};
    _basePrices.forEach((species, base) {
      final seed = (dayOfYear * 37 + species.hashCode) & 0x7FFFFFFF;
      final jitterPct = ((seed % 21) - 10) / 100.0; // -10% to +10%
      double monsoonFactor = 1.0;
      if (isMonsoon && (species != 'Mud Crab' && species != 'Tiger Prawns' && species != 'Mussels')) {
        monsoonFactor = 1.25;
      }
      final weekendFactor = isWeekend ? 1.07 : 1.0;
      final price = (base * (1 + jitterPct) * monsoonFactor * weekendFactor).roundToDouble();
      final changePct = ((price - base) / base * 100).roundToDouble();

      updates[species] = {
        'price': price,
        'trend': changePct > 3.0 ? 'up' : changePct < -3.0 ? 'down' : 'flat',
        'change_pct': changePct,
        'last_updated': now.toIso8601String(),
        'date': today,
        'source': 'Goa-Market-Estimate',
      };
    });

    try {
      await _ref.update(updates);
    } catch (_) {}
  }
}
