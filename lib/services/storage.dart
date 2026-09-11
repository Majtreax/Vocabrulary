import 'package:shared_preferences/shared_preferences.dart';

// LOCAL PERSISTENCE SERVICE
class WordStorage {
  static const String _key = 'known_words';

  // LOAD KNOWN WORD IDENTIFIERS
  static Future<Set<int>> getKnownWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_key);
      if (stored == null) return {};
      return stored.map((id) => int.parse(id)).toSet();
    } catch (e) {
      return {};
    }
  }

  // ADD WORD TO KNOWN SET
  static Future<bool> addKnownWord(int wordId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final known =
          await getKnownWords()
            ..add(wordId);
      return await prefs.setStringList(_key, known.map((id) => '$id').toList());
    } catch (e) {
      return false;
    }
  }

  // REMOVE WORD FROM KNOWN SET
  static Future<bool> removeKnownWord(int wordId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final known =
          await getKnownWords()
            ..remove(wordId);
      return await prefs.setStringList(_key, known.map((id) => '$id').toList());
    } catch (e) {
      return false;
    }
  }

  // CLEAR ALL KNOWN WORDS
  static Future<bool> clearKnownWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (e) {
      return false;
    }
  }

  // FILTER SETTINGS PERSISTENCE KEYS
  static const String _keyLevels = 'filter_levels';
  static const String _keySentences = 'filter_sentences';
  static const String _keyUncategorized = 'filter_uncategorized';

  // LOAD SAVED FILTER PREFERENCES
  static Future<Map<String, dynamic>> getFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final levelsList = prefs.getStringList(_keyLevels);
      final levels =
          levelsList != null
              ? levelsList.toSet()
              : {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};

      final onlySentences = prefs.getBool(_keySentences) ?? false;
      final includeUncategorized = prefs.getBool(_keyUncategorized) ?? true;

      return {
        'levels': levels,
        'onlySentences': onlySentences,
        'includeUncategorized': includeUncategorized,
      };
    } catch (e) {
      return {
        'levels': {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'},
        'onlySentences': false,
        'includeUncategorized': true,
      };
    }
  }

  // SAVE FILTER PREFERENCES
  static Future<void> saveFilters({
    required Set<String> levels,
    required bool onlySentences,
    required bool includeUncategorized,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyLevels, levels.toList());
      await prefs.setBool(_keySentences, onlySentences);
      await prefs.setBool(_keyUncategorized, includeUncategorized);
    } catch (e) {
      // IGNORE SAVE FAILURES SILENTLY
    }
  }

  // QUIZ SETTINGS PERSISTENCE KEYS
  static const String _keyQuizLevels = 'quiz_levels';
  static const String _keyQuizUncategorized = 'quiz_uncategorized';
  static const String _keyQuizCorrect = 'quiz_correct';
  static const String _keyQuizIncorrect = 'quiz_incorrect';

  // LOAD QUIZ PREFERENCES
  static Future<QuizPreferences> getQuizPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final levelsList = prefs.getStringList(_keyQuizLevels);
      final levels =
          levelsList != null
              ? levelsList.toSet()
              : {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};

      final includeUncategorized = prefs.getBool(_keyQuizUncategorized) ?? true;
      final correct = prefs.getInt(_keyQuizCorrect) ?? 0;
      final incorrect = prefs.getInt(_keyQuizIncorrect) ?? 0;

      return QuizPreferences(
        levels: levels,
        includeUncategorized: includeUncategorized,
        correctCount: correct,
        incorrectCount: incorrect,
      );
    } catch (e) {
      return const QuizPreferences(
        levels: {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'},
        includeUncategorized: true,
        correctCount: 0,
        incorrectCount: 0,
      );
    }
  }

  // SAVE QUIZ PREFERENCES
  static Future<void> saveQuizPreferences({
    required Set<String> levels,
    required bool includeUncategorized,
    required int correctCount,
    required int incorrectCount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyQuizLevels, levels.toList());
      await prefs.setBool(_keyQuizUncategorized, includeUncategorized);
      await prefs.setInt(_keyQuizCorrect, correctCount);
      await prefs.setInt(_keyQuizIncorrect, incorrectCount);
    } catch (e) {
      // IGNORE SAVE FAILURES SILENTLY
    }
  }
}

// QUIZ PREFERENCES DATA MODEL
class QuizPreferences {
  final Set<String> levels;
  final bool includeUncategorized;
  final int correctCount;
  final int incorrectCount;

  const QuizPreferences({
    required this.levels,
    required this.includeUncategorized,
    required this.correctCount,
    required this.incorrectCount,
  });
}
