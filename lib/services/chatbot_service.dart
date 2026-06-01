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
    final lastMsg = chatHistory.isNotEmpty ? chatHistory.last['content'] ?? '' : '';

    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      // Intelligently fall back to Goan expert fisheries knowledge database
      return _getLocalFallbackResponse(lastMsg);
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
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print("Groq API Error: ${response.statusCode}");
        return _getLocalFallbackResponse(lastMsg);
      }
    } catch (e) {
      print("Groq API Exception: $e");
      return _getLocalFallbackResponse(lastMsg);
    }
  }

  /// Comprehensive keyword-matching local knowledge base representing the Goa Fisheries Department persona
  String _getLocalFallbackResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    
    if (lower.contains("salinity") || lower.contains("salt")) {
      return "🌊 **Salinity Guidelines for AquaSync Farms:**\n\n"
          "• **Tilapia**: Thrives best in freshwater to low salinity (**0 - 5 ppt**).\n"
          "• **Catfish**: Requires low salinity (**0 - 8 ppt**).\n"
          "• **Milkfish**: Extremely adaptable, comfortable in moderate to high salinity (**10 - 35 ppt**).\n"
          "• **Whiteleg & Tiger Shrimp**: Thrives in brackish waters (**15 - 30 ppt**) for optimal shell calcification.\n\n"
          "If salinity levels are too high, it leads to osmotic stress and dehydration. Check your live telemetry screen regularly!";
    }
    
    if (lower.contains("ph") || lower.contains("acid") || lower.contains("alkaline")) {
      return "🧪 **pH Level Recommendations:**\n\n"
          "• The ideal safe pH range for all our considered species is **6.5 to 8.5**.\n"
          "• **Below 6.5 (Acidic)**: Causes gill irritation, reduced feeding, and respiratory stress.\n"
          "• **Above 8.5 (Alkaline)**: Dramatically increases the toxicity of dissolved ammonia, which can be fatal.\n\n"
          "We recommend regular water exchanges and using agricultural lime (calcium carbonate) to buffer acidic pond water.";
    }
    
    if (lower.contains("temp") || lower.contains("temperature") || lower.contains("heat") || lower.contains("cold")) {
      return "🌡️ **Temperature Management:**\n\n"
          "• Aquaculture species are ectothermic; their metabolic rate depends on water temperature.\n"
          "• **Tilapia & Catfish**: Thrive in warm waters (**25°C - 32°C**).\n"
          "• **Whiteleg & Tiger Shrimp**: Highly active between **27°C - 32°C**. Growth stops below 20°C.\n\n"
          "During heat waves or cold spells, ensure aerators are running at full capacity to maintain oxygen levels.";
    }
    
    if (lower.contains("disease") || lower.contains("stress") || lower.contains("infect") || lower.contains("sick") || lower.contains("spot")) {
      return "🦠 **AI Disease Diagnosis & Prevention Protocol:**\n\n"
          "Our integrated ML models predict stress levels and disease risk (such as Bacterial Infection and White Spot):\n"
          "1. **Isolate Ponds**: If a 'High Risk' alert is active, isolate the affected RAS tank or pond immediately.\n"
          "2. **Reduce Feed**: Cut daily feeding by **30% to 50%**. Leftover feed decays rapidly, producing toxic ammonia and multiplying bacteria.\n"
          "3. **Boost Aeration**: Run all paddlewheels or diffusers continuously to help fish fight off stress.\n"
          "4. **Consult Officer**: Reach out to the Goan Fisheries Department through our **Report Tab** to file a geotagged complaint.";
    }
    
    if (lower.contains("subsidy") || lower.contains("subsidies") || lower.contains("scheme") || lower.contains("govt") || lower.contains("pmmsy") || lower.contains("goa")) {
      return "📜 **Goa Fisheries Department Subsidies & Schemes:**\n\n"
          "Under the **Pradhan Mantri Matsya Sampada Yojana (PMMSY)**, the Goa State Government provides financial assistance for smart aquaculture:\n"
          "• **General Category Farmers**: **40% subsidy** on setting up RAS units, purchasing aerators, and stocking seeds.\n"
          "• **SC/ST & Women Farmers**: Up to **60% subsidy** on all aquaculture infrastructure.\n\n"
          "You can browse all active schemes directly under the **Schemes Tab** in your Farmer Dashboard and apply through the official Goa portal.";
    }

    if (lower.contains("shrimp") || lower.contains("vannamei") || lower.contains("tiger")) {
      return "🦐 **Shrimp Cultivation best practices:**\n\n"
          "• **Species**: Whiteleg Shrimp (Vannamei) and Tiger Shrimp are considered highly profitable.\n"
          "• **Key Metrics**: Salinity **15 - 30 ppt**, pH **7.5 - 8.5**, and Turbidity **20 - 50 NTU**.\n"
          "• **Warning**: High turbidity combined with low oxygen can trigger White Spot disease. Monitor your live telemetry dials closely!";
    }

    if (lower.contains("hello") || lower.contains("hi ") || lower.contains("hey") || lower.contains("help")) {
      return "👋 **Welcome to AquaSync Copilot!**\n\n"
          "I am your dedicated AI Fisheries Assistant from the **Goa Fisheries Department**.\n\n"
          "You can ask me questions like:\n"
          "• *What is the ideal salinity for tiger shrimp?*\n"
          "• *How do I control disease risk in my RAS?*\n"
          "• *What government subsidies are active in Goa?*\n"
          "• *What happens if pH levels go too high?*";
    }

    return "💬 **AquaSync Copilot Response:**\n\n"
        "Thank you for reaching out! I am here to help you manage your RAS, sea cage, or brackish water farms successfully.\n\n"
        "To get the most accurate advice, please ask me about:\n"
        "• **Water parameters** (pH, Temp, Salinity, Turbidity)\n"
        "• **Aquaculture species** (Tilapia, Shrimp, Catfish, Milkfish)\n"
        "• **AI Disease/Stress warnings** and management\n"
        "• **Goa Government subsidies** under PMMSY";
  }
}
