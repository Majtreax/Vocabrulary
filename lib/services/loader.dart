import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/model.dart';

// VOCABULARY ASSET LOADER SERVICE
class VocabularyLoader {
  static const String _assetPath = 'assets/dictionary.json';

  // LOAD WORDS FROM JSON ASSET USING BACKGROUND ISOLATE
  static Future<List<VocabularyWord>> loadWords() async {
    try {
      final String response = await rootBundle.loadString(_assetPath);
      return await compute(_parseJson, response);
    } catch (e) {
      debugPrint("Error loading vocabulary: $e");
      return [];
    }
  }

  // PARSE JSON STRING IN ISOLATE
  static List<VocabularyWord> _parseJson(String response) {
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => VocabularyWord.fromJson(json)).toList();
  }
}
