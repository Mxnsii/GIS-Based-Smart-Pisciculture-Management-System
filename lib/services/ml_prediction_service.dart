import 'dart:convert';
import 'package:http/http.dart' as http;

class MlPredictionService {
  /// Calls the local Flask Python ML server to predict disease risk
  /// based on real-time water parameters.
  static Future<String> getPrediction({
    required String species,
    required double temperature,
    required double ph,
    required double turbidity,
    required double dissolvedOxygen,
  }) async {
    final url = Uri.parse("http://192.168.0.143:5000/predict");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "species": species,
        "temperature": temperature,
        "pH": ph,
        "turbidity": turbidity,
        "do": dissolvedOxygen
      }),
    ).timeout(const Duration(seconds: 10)); // Added timeout so the app doesn't freeze

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["prediction"];
    } else {
      throw Exception("Failed to get ML prediction: ${response.statusCode}");
    }
  }
}
