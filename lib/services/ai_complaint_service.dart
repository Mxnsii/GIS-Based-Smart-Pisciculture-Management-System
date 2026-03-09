import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIComplaintService {
  // TODO: Replace with your actual Gemini API Key
  static const String _apiKey = 'AIzaSyANLBtNn6ynJCTdC6-TDkSXpS5ggpXCfxM';
  
  static Future<Map<String, dynamic>?> analyzeComplaint(Map<String, dynamic> complaintData) async {
    if (_apiKey == 'AIzaSyANLBtNn6ynJCTdC6-TDkSXpS5ggpXCfxM') {
      // Mock Data if API key is not provided to prevent crashes
      return _getMockAnalysis(complaintData);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = '''
      You are an AI analyst for a Maritime and Pisciculture Authority. Analyze the following complaint and output a JSON response.
      
      Complaint Data:
      Activity Type: ${complaintData['activityType']}
      Vessel Type: ${complaintData['vesselType']}
      Description: ${complaintData['description']}
      Location: Lat ${complaintData['location']?.latitude}, Lng ${complaintData['location']?.longitude}
      
      Determine the following based on the maritime rules, illegal fishing context, and GIS context:
      1. priority: "High", "Medium", or "Low". Give High to illegal fishing in critical zones or large operations.
      2. category: General categorization of the issue based on description (e.g., "Illegal Trawling", "Net Violations", "Unlicensed Fishing").
      3. isHotspot: true or false. Determine if this sounds like a recurring hotspot violation.
      4. pfzProximity: "Inside PFZ", "Near PFZ", or "Outside PFZ" (estimate based on context, since exact geo-analysis requires pure DB, give a realistic guess based on description).
      5. crzViolation: true or false. Coastal Regulation Zone violation? (e.g. fishing too close to shore or mangroves).
      6. summary: A 1-2 sentence brief summary of the AI's assessment.
      
      Output exactly and ONLY in valid JSON format:
      {
        "priority": "High|Medium|Low",
        "category": "string",
        "isHotspot": boolean,
        "pfzProximity": "string",
        "crzViolation": boolean,
        "summary": "string"
      }
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text != null) {
        String jsonText = response.text!.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7, jsonText.length - 3).trim();
        } else if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3, jsonText.length - 3).trim();
        }
        return jsonDecode(jsonText);
      }
      return null;
    } catch (e) {
      print('Error during AI complaint analysis: \$e');
      return _getMockAnalysis(complaintData); // fallback
    }
  }

  static Map<String, dynamic> _getMockAnalysis(Map<String, dynamic> data) {
    String activity = data['activityType']?.toString().toLowerCase() ?? '';
    String description = data['description']?.toString().toLowerCase() ?? '';
    
    String priority = 'Medium';
    if (activity.contains('trawl') || description.contains('trawl') || activity.contains('dynamite')) {
      priority = 'High';
    } else if (activity.contains('line') && !description.contains('illegal')) {
      priority = 'Low';
    }

    bool isCrz = description.contains('shore') || description.contains('mangrove') || description.contains('coast');

    return {
      "priority": priority,
      "category": (data['activityType'] ?? "General Incident").toString(),
      "isHotspot": description.contains('again') || description.contains('always'),
      "pfzProximity": description.contains('deep') ? "Inside PFZ" : "Outside PFZ",
      "crzViolation": isCrz,
      "summary": "Mock AI Analysis: Highlighted as \$priority priority based on reported activity characteristics.",
      "isMock": true
    };
  }
}
