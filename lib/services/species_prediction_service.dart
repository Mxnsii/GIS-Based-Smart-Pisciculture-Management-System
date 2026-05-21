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
        
    // Mimic the ranges defined in species_rec.ipynb
    Map<String, int> scores = {
      "Whiteleg Shrimp": 0,
      "Tiger Shrimp": 0,
      "Tilapia": 0,
      "Catfish": 0,
      "Milkfish": 0,
    };

    // Whiteleg Shrimp (Temp 28-32, pH 7.5-8.5, Salinity 15-25, Turbidity 20-50)
    if (temp >= 28 && temp <= 32) scores["Whiteleg Shrimp"] = (scores["Whiteleg Shrimp"] ?? 0) + 30;
    if (ph >= 7.5 && ph <= 8.5) scores["Whiteleg Shrimp"] = (scores["Whiteleg Shrimp"] ?? 0) + 20;
    if (salinity >= 15 && salinity <= 25) scores["Whiteleg Shrimp"] = (scores["Whiteleg Shrimp"] ?? 0) + 40;
    if (turbidity >= 20 && turbidity <= 50) scores["Whiteleg Shrimp"] = (scores["Whiteleg Shrimp"] ?? 0) + 10;

    // Tiger Shrimp (Temp 27-31, pH 7.5-8.5, Salinity 15-30, Turbidity 25-55)
    if (temp >= 27 && temp <= 31) scores["Tiger Shrimp"] = (scores["Tiger Shrimp"] ?? 0) + 30;
    if (ph >= 7.5 && ph <= 8.5) scores["Tiger Shrimp"] = (scores["Tiger Shrimp"] ?? 0) + 20;
    if (salinity >= 15 && salinity <= 30) scores["Tiger Shrimp"] = (scores["Tiger Shrimp"] ?? 0) + 40;
    if (turbidity >= 25 && turbidity <= 55) scores["Tiger Shrimp"] = (scores["Tiger Shrimp"] ?? 0) + 10;

    // Tilapia (Temp 24-30, pH 6.5-8.5, Salinity 0-5, Turbidity 10-30)
    if (temp >= 24 && temp <= 30) scores["Tilapia"] = (scores["Tilapia"] ?? 0) + 30;
    if (ph >= 6.5 && ph <= 8.5) scores["Tilapia"] = (scores["Tilapia"] ?? 0) + 20;
    if (salinity >= 0 && salinity <= 5) scores["Tilapia"] = (scores["Tilapia"] ?? 0) + 40;
    if (turbidity >= 10 && turbidity <= 30) scores["Tilapia"] = (scores["Tilapia"] ?? 0) + 10;

    // Catfish (Temp 25-32, pH 6.5-8, Salinity 0-8, Turbidity 15-40)
    if (temp >= 25 && temp <= 32) scores["Catfish"] = (scores["Catfish"] ?? 0) + 30;
    if (ph >= 6.5 && ph <= 8) scores["Catfish"] = (scores["Catfish"] ?? 0) + 20;
    if (salinity >= 0 && salinity <= 8) scores["Catfish"] = (scores["Catfish"] ?? 0) + 40;
    if (turbidity >= 15 && turbidity <= 40) scores["Catfish"] = (scores["Catfish"] ?? 0) + 10;

    // Milkfish (Temp 26-32, pH 7-8.5, Salinity 10-35, Turbidity 20-45)
    if (temp >= 26 && temp <= 32) scores["Milkfish"] = (scores["Milkfish"] ?? 0) + 30;
    if (ph >= 7 && ph <= 8.5) scores["Milkfish"] = (scores["Milkfish"] ?? 0) + 20;
    if (salinity >= 10 && salinity <= 35) scores["Milkfish"] = (scores["Milkfish"] ?? 0) + 40;
    if (turbidity >= 20 && turbidity <= 45) scores["Milkfish"] = (scores["Milkfish"] ?? 0) + 10;

    // Convert to list and sort
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
