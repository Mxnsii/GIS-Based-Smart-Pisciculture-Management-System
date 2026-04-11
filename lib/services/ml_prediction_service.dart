// No imports needed for local model

class MlPredictionService {
  /// Analyzes water parameters locally using an embedded algorithm 
  /// to predict disease risk, avoiding dependency on a local Flask server.
  static Future<String> getPrediction({
    required String species,
    required double temperature,
    required double ph,
    required double turbidity,
    required double dissolvedOxygen,
  }) async {
    // Small delay to simulate complex ML processing
    await Future.delayed(const Duration(milliseconds: 600));

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
      return "Healthy / Safe conditions";
    } else if (riskScore <= 2) {
      return "Mild risk: ${riskFactors.join(', ')}";
    } else {
      return "High risk: ${riskFactors.join(', ')}";
    }
  }
}
