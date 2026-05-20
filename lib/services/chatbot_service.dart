import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotService {
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // The system prompt defines the GIS Agent's persona and knowledge baseline
  static const String _systemPrompt = '''
You are GIS Agent, an expert pisciculture specialist and official representative of the Goa Fisheries Department.
You provide precise, easy-to-understand advice for farmers running sea cage farms, brackish water farms, khazan farms, and man-made farms like RAS (Recirculating Aquaculture Systems) and Biofloc.
You can answer questions regarding:
- Water parameters required for various fish species
- Fish disease diagnosis and prevention
- Farm management and best practices
- Subsidies and schemes actively provided by the Goa state government for fish farmers.
Rules:
- Be polite, encouraging, and highly informative.
- Keep answers concise but comprehensive enough to be useful.
- When asked about subsidies, present accurate or plausible schemes reflecting standard Indian/Goan fisheries development guidelines (e.g., PMMSY).
- Never break character. You are the GIS Agent.
''';

  Future<String> sendMessage(List<Map<String, String>> chatHistory) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      return "Error: GROQ_API_KEY is not configured properly in the .env file.";
    }

    // Format messages for the Groq API
    final List<Map<String, dynamic>> messages = [
      {'role': 'system', 'content': _systemPrompt},
    ];
    
    // Add existing chat history
    for (var msg in chatHistory) {
      messages.add({
        'role': msg['role'],
        'content': msg['content'],
      });
    }

    try {
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', // Updated to supported Groq model
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Error from Groq API: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "An error occurred while connecting to the GIS Agent API: $e";
    }
  }
}
