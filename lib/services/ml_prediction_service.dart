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
    required double salinity,
    required double turbidity,
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
          "turbidity": salinity, // maps to salinity in hosted API
          "do": turbidity,       // maps to turbidity in hosted API
        }),
      ).timeout(const Duration(seconds: 10)); // Prevent the app from hanging if service is slow

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String basePrediction = data["prediction"] ?? "Unknown (API returned empty)";
        final String bacterialRisk = _getBacterialInfectionRisk(temperature, ph, salinity, turbidity);
        return "$basePrediction | Bacterial Infection Risk: $bacterialRisk";
      } else {
        print("ML API Error: HTTP ${response.statusCode}");
        return _getLocalFallbackPrediction(species, temperature, ph, salinity, turbidity);
      }
    } catch (e) {
      // If server is spinning down or unavailable, use the fallback
      print("ML API Exception (Falling back to local computation): $e");
      return _getLocalFallbackPrediction(species, temperature, ph, salinity, turbidity);
    }
  }

  static String _getBacterialInfectionRisk(double temperature, double ph, double salinity, double turbidity) {
    int riskScore = 0;

    if (turbidity > 30) {
      riskScore += 2;
    } else if (turbidity > 20) {
      riskScore += 1;
    }

    if (temperature >= 26 && temperature <= 32) {
      riskScore += 1;
    }

    if (ph >= 6.5 && ph <= 8.5) {
      riskScore += 1;
    }

    if (salinity <= 10) {
      riskScore += 1;
    }

    if (riskScore >= 4) {
      return 'High';
    } else if (riskScore >= 2) {
      return 'Moderate';
    }
    return 'Low';
  }

  /// Backup logic mimicking previous local conditions in case of network failures
  static String _getLocalFallbackPrediction(String species, double temperature, double ph, double salinity, double turbidity) {
    // Define acceptable ranges based on species
    double minTemp = species.toLowerCase().contains("seabass") ? 26.0 : 24.0;
    double maxTemp = species.toLowerCase().contains("seabass") ? 32.0 : 30.0;
    double minPh = species.toLowerCase().contains("seabass") ? 7.0 : 6.5;
    double maxPh = species.toLowerCase().contains("seabass") ? 8.5 : 9.0;
    double maxTurb = species.toLowerCase().contains("seabass") ? 20.0 : 25.0;
    double minSal = species.toLowerCase().contains("seabass") ? 10.0 : 0.0;
    double maxSal = species.toLowerCase().contains("seabass") ? 30.0 : 5.0;

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

    // Analyze Salinity
    if (salinity < minSal - 5 || salinity > maxSal + 5) {
      riskScore += 2;
      riskFactors.add("Critical Salinity");
    } else if (salinity < minSal || salinity > maxSal) {
      riskScore += 1;
      riskFactors.add("Unstable Salinity");
    }

    // Analyze Turbidity
    if (turbidity > maxTurb + 10) {
      riskScore += 2;
      riskFactors.add("Critical Turbidity");
    } else if (turbidity > maxTurb) {
      riskScore += 1;
      riskFactors.add("Elevated Turbidity");
    }

    final String bacterialRisk = _getBacterialInfectionRisk(temperature, ph, salinity, turbidity);
    final String basePrediction;
    if (riskScore == 0) {
      basePrediction = "Healthy / Safe conditions (Local)";
    } else if (riskScore <= 2) {
      basePrediction = "Mild risk: ${riskFactors.join(', ')} (Local)";
    } else {
      basePrediction = "High risk: ${riskFactors.join(', ')} (Local)";
    }

    return "$basePrediction | Bacterial Infection Risk: $bacterialRisk";
  }
}
