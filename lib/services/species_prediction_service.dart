class SpeciesPredictionService {
  /// Calculates species suitability directly from sensor readings.
  ///
  /// This uses the local species prediction logic defined in the model file,
  /// rather than relying on remote API output.
  static Future<List<Map<String, dynamic>>> getSpeciesRecommendations({
    required double temperature,
    required double ph,
    required double salinity,
    required double turbidity,
  }) async {
    // Use the local species prediction model to calculate suitability scores
    // directly from current sensor readings.
    return _getLocalFallbackRecommendations(temperature, ph, salinity, turbidity);
  }

  /// Backup logic mimicking the Random Forest model's behavior
  static List<Map<String, dynamic>> _getLocalFallbackRecommendations(
      double temp, double ph, double salinity, double turbidity) {

    double scoreParameter(double value, double min, double max, int weight) {
      final double midpoint = (min + max) / 2;
      final double halfRange = (max - min) / 2;
      if (halfRange <= 0) {
        return value == min ? weight.toDouble() : 0.0;
      }

      if (value >= min && value <= max) {
        final double distance = (value - midpoint).abs();
        // Keep safe values high, but still vary scores inside the range.
        return weight * (1.0 - 0.25 * (distance / halfRange));
      }

      final double diff = value < min ? min - value : value - max;
      return weight * (0.75 - 0.75 * (diff / halfRange)).clamp(0.0, 0.75);
    }

    Map<String, double> scores = {
      "Whiteleg Shrimp": 0.0,
      "Tiger Shrimp": 0.0,
      "Tilapia": 0.0,
      "Catfish": 0.0,
      "Milkfish": 0.0,
    };

    // Whiteleg Shrimp (Temp 28-32, pH 7.5-8.5, Salinity 15-25, Turbidity 20-50)
    scores["Whiteleg Shrimp"] = (scores["Whiteleg Shrimp"] ?? 0) + scoreParameter(temp, 28, 32, 30);
    scores["Whiteleg Shrimp"] = (scores["Whiteleg Shrimp"] ?? 0) + scoreParameter(ph, 7.5, 8.5, 20);
    scores["Whiteleg Shrimp"] = (scores["Whiteleg Shrimp"] ?? 0) + scoreParameter(salinity, 15, 25, 40);
    scores["Whiteleg Shrimp"] = (scores["Whiteleg Shrimp"] ?? 0) + scoreParameter(turbidity, 20, 50, 10);

    // Tiger Shrimp (Temp 27-31, pH 7.5-8.5, Salinity 15-30, Turbidity 25-55)
    scores["Tiger Shrimp"] = (scores["Tiger Shrimp"] ?? 0) + scoreParameter(temp, 27, 31, 30);
    scores["Tiger Shrimp"] = (scores["Tiger Shrimp"] ?? 0) + scoreParameter(ph, 7.5, 8.5, 20);
    scores["Tiger Shrimp"] = (scores["Tiger Shrimp"] ?? 0) + scoreParameter(salinity, 15, 30, 40);
    scores["Tiger Shrimp"] = (scores["Tiger Shrimp"] ?? 0) + scoreParameter(turbidity, 25, 55, 10);

    // Tilapia (Temp 24-30, pH 6.5-8.5, Salinity 0-5, Turbidity 10-30)
    scores["Tilapia"] = (scores["Tilapia"] ?? 0) + scoreParameter(temp, 24, 30, 30);
    scores["Tilapia"] = (scores["Tilapia"] ?? 0) + scoreParameter(ph, 6.5, 8.5, 20);
    scores["Tilapia"] = (scores["Tilapia"] ?? 0) + scoreParameter(salinity, 0, 5, 40);
    scores["Tilapia"] = (scores["Tilapia"] ?? 0) + scoreParameter(turbidity, 10, 30, 10);

    // Catfish (Temp 25-32, pH 6.5-8, Salinity 0-8, Turbidity 15-40)
    scores["Catfish"] = (scores["Catfish"] ?? 0) + scoreParameter(temp, 25, 32, 30);
    scores["Catfish"] = (scores["Catfish"] ?? 0) + scoreParameter(ph, 6.5, 8, 20);
    scores["Catfish"] = (scores["Catfish"] ?? 0) + scoreParameter(salinity, 0, 8, 40);
    scores["Catfish"] = (scores["Catfish"] ?? 0) + scoreParameter(turbidity, 15, 40, 10);

    // Milkfish (Temp 26-32, pH 7-8.5, Salinity 10-35, Turbidity 20-45)
    scores["Milkfish"] = (scores["Milkfish"] ?? 0) + scoreParameter(temp, 26, 32, 30);
    scores["Milkfish"] = (scores["Milkfish"] ?? 0) + scoreParameter(ph, 7, 8.5, 20);
    scores["Milkfish"] = (scores["Milkfish"] ?? 0) + scoreParameter(salinity, 10, 35, 40);
    scores["Milkfish"] = (scores["Milkfish"] ?? 0) + scoreParameter(turbidity, 20, 45, 10);

    List<Map<String, dynamic>> results = [];
    scores.forEach((species, score) {
      String status = "";
      if (score >= 85) {
        status = "Highly Suitable";
      } else if (score >= 70) {
        status = "Suitable";
      } else if (score >= 50) {
        status = "Moderately Suitable";
      } else {
        status = "Low Suitability";
      }

      results.add({
        "species": species,
        "score": score.toDouble(),
        "status": status,
        "isLocalFallback": true,
      });
    });

    results.sort((a, b) => b["score"].compareTo(a["score"]));
    return results;
  }
}
