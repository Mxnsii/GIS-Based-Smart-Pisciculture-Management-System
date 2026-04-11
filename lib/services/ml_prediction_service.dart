import 'dart:convert';
import 'package:http/http.dart' as http;

class MlPredictionService {
  // Remote API URL pointing to the newly deployed Render instance
  static const String _apiUrl = "https://gis-based-smart-pisciculture-management.onrender.com/predict";

  /// Analyzes water parameters using the cloud ML model.
  /// Automatically safely falls back to local rule-based algorithm if the cloud server is unavailable.
  static Future<String> getPrediction({
    required String species,
    required double temperature,
    required double ph,
    required double turbidity,
    required double dissolvedOxygen,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "species": species,
          "temperature": temperature,
          "pH": ph,
          "turbidity": turbidity,
          "do": dissolvedOxygen,
        }),
      ).timeout(const Duration(seconds: 10)); // Prevent the app from hanging if service is slow

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["prediction"] ?? "Unknown (API returned empty)";
      } else {
        print("ML API Error: HTTP ${response.statusCode}");
        return _getLocalFallbackPrediction(species, temperature, ph, turbidity);
      }
    } catch (e) {
      // If server is spinning down or unavailable, use the fallback
      print("ML API Exception (Falling back to local computation): $e");
      return _getLocalFallbackPrediction(species, temperature, ph, turbidity);
    }
  }

  /// Backup logic mimicking previous local conditions in case of network failures
  static String _getLocalFallbackPrediction(String species, double temperature, double ph, double turbidity) {
    // Define acceptable ranges based on species
    double minTemp = species.toLowerCase().contains("seabass") ? 26.0 : 24.0;
    double maxTemp = species.toLowerCase().contains("seabass") ? 32.0 : 30.0;
    double minPh = species.toLowerCase().contains("seabass") ? 7.0 : 6.5;
    double maxPh = species.toLowerCase().contains("seabass") ? 8.5 : 9.0;
    double maxTurb = species.toLowerCase().contains("seabass") ? 20.0 : 25.0;

    int riskScore = 0;
    List<String> riskFactors = [];

    // Analyze Temperature
    if (temperature < minTemp - 2 || temperature > maxTemp + 2) {
      riskScore += 2;
      riskFactors.add("Critical Temp");
    } else if (temperature < minTemp || temperature > maxTemp) {
      riskScore += 1;
      riskFactors.add("Mild Temp Alert");
    }

    // Analyze pH
    if (ph < minPh - 0.5 || ph > maxPh + 0.5) {
      riskScore += 2;
      riskFactors.add("Critical pH");
    } else if (ph < minPh || ph > maxPh) {
      riskScore += 1;
      riskFactors.add("Mild pH Alert");
    }

    // Analyze Turbidity
    if (turbidity > maxTurb + 10) {
      riskScore += 2;
      riskFactors.add("Critical Turbidity");
    } else if (turbidity > maxTurb) {
      riskScore += 1;
      riskFactors.add("Elevated Turbidity");
    }

    // Return prediction based on overall risk score
    if (riskScore == 0) {
      return "Healthy / Safe conditions (Local)";
    } else if (riskScore <= 2) {
      return "Mild risk: ${riskFactors.join(', ')} (Local)";
    } else {
      return "High risk: ${riskFactors.join(', ')} (Local)";
    }
  }
}
