import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.42); // Slightly slower speech for clear regional accents
      _isInitialized = true;
    } catch (e) {
      debugPrint("TTS Initialization error: $e");
    }
  }

  // Phonetic Devanagari mapping for Konkani transliterations (to sound native on Devanagari TTS engine)
  static const Map<String, String> _konkaniDevanagari = {
    "Paplet": "पापलेट",
    "Viswon": "विस्वण",
    "Bangda": "बांगडा",
    "Tarle": "तारले",
    "Kupa": "कुपा",
    "Kane": "काणे",
    "Bombil": "बोंबील",
    "Tamso": "तामसो",
    "Chonak": "चोणक",
    "Mori": "मोरी",
    "Sungta": "सुंगटा",
    "Kurlli": "कुर्ली",
    "Shevandi": "शेवंडी",
    "Xinaneto": "शिनाणेतो",
    "Kalva": "कालवा",
    "Mankios": "माणक्यो",
  };

  // Phonetic Devanagari mapping for Marathi transliterations
  static const Map<String, String> _marathiDevanagari = {
    "Pamplet": "पाम्पलेट",
    "Surmai": "सुरमई",
    "Bangda": "बांगडा",
    "Tarle": "तारले",
    "Kupa": "कुपा",
    "Kane": "काणे",
    "Bombil": "बोंबील",
    "Tamso": "तामसो",
    "Chonak": "चोणक",
    "Mori": "मोरी",
    "Kolambi": "कोळंबी",
    "Chimbori": "चिंबोरी",
    "Shevand": "शेवंड",
    "Shilgya": "शिळग्या",
    "Kalva": "कालवा",
    "Mankios": "माणक्यो",
  };

  /// Pronounces the Konkani name of the fish.
  static Future<void> speakKonkani(String konkaniLatin) async {
    final String text = _konkaniDevanagari[konkaniLatin] ?? konkaniLatin;
    await _speakWithFallback(text, konkaniLatin);
  }

  /// Pronounces the Marathi name of the fish.
  static Future<void> speakMarathi(String marathiLatin) async {
    final String text = _marathiDevanagari[marathiLatin] ?? marathiLatin;
    await _speakWithFallback(text, marathiLatin);
  }

  /// Speaks the Devanagari text, falling back to English if Devanagari locales (Marathi/Hindi) are not available.
  static Future<void> _speakWithFallback(String devanagariText, String fallbackLatinText) async {
    try {
      // Safely stop any current speech first
      await stop();

      // Ensure init is run
      await init();
      if (!_isInitialized) {
        debugPrint("TTS not initialized. Skipping speak.");
        return;
      }

      // 1. Try Marathi TTS first
      bool hasMarathi = false;
      try {
        hasMarathi = await _flutterTts.isLanguageAvailable("mr-IN") as bool;
      } catch (_) {}

      if (hasMarathi) {
        await _flutterTts.setLanguage("mr-IN");
        await _flutterTts.speak(devanagariText);
        return;
      }

      // 2. Try Hindi TTS as fallback (shares Devanagari script and sounds very similar)
      bool hasHindi = false;
      try {
        hasHindi = await _flutterTts.isLanguageAvailable("hi-IN") as bool;
      } catch (_) {}

      if (hasHindi) {
        await _flutterTts.setLanguage("hi-IN");
        await _flutterTts.speak(devanagariText);
        return;
      }

      // 3. Try Indian English for Latin representation (sounds much better than US English for Indian names)
      bool hasIndianEnglish = false;
      try {
        hasIndianEnglish = await _flutterTts.isLanguageAvailable("en-IN") as bool;
      } catch (_) {}

      if (hasIndianEnglish) {
        await _flutterTts.setLanguage("en-IN");
        await _flutterTts.speak(fallbackLatinText);
        return;
      }

      // 4. Ultimate fallback to standard English locale
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.speak(fallbackLatinText);
    } catch (e) {
      debugPrint("TTS play error: $e");
      // Basic last resort speak
      try {
        if (_isInitialized) {
          await _flutterTts.speak(fallbackLatinText);
        }
      } catch (_) {}
    }
  }

  /// Stops any ongoing speech safely.
  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("TTS stop error: $e");
    }
  }
}
