import '../utils/transliterator.dart';

// VOCABULARY WORD DATA MODEL
class VocabularyWord {
  final int id;
  final String word;
  final String wordTranslit;
  final String wordEn;
  final String type;
  final String level;
  final String sentence;
  final String sentenceTranslit;
  final String sentenceEn;

  // PRE INDEXED SEARCH STRINGS
  final String normWord;
  final String normTranslit;
  final String normEn;
  final String normLatinWord;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.wordTranslit,
    required this.wordEn,
    required this.type,
    required this.level,
    required this.sentence,
    required this.sentenceTranslit,
    required this.sentenceEn,
    this.normWord = '',
    this.normTranslit = '',
    this.normEn = '',
    this.normLatinWord = '',
  });

  // FACTORY CONSTRUCTOR FROM JSON WITH PRECOMPUTED SEARCH CACHE
  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    final word = json['word'] as String? ?? '';
    final wordTranslit = json['word_translit'] as String? ?? '';
    final wordEn = json['word_en'] as String? ?? '';

    return VocabularyWord(
      id: json['id'] as int? ?? 0,
      word: word,
      wordTranslit: wordTranslit,
      wordEn: wordEn,
      type: json['type'] as String? ?? '',
      level: json['level'] as String? ?? '',
      sentence: json['sentence'] as String? ?? '',
      sentenceTranslit: json['sentence_translit'] as String? ?? '',
      sentenceEn: json['sentence_en'] as String? ?? '',
      normWord: Transliterator.normalize(word),
      normTranslit: Transliterator.normalize(wordTranslit),
      normEn: Transliterator.normalize(wordEn),
      normLatinWord: Transliterator.normalize(Transliterator.cyrillicToLatin(word)),
    );
  }

  // CHECK IF WORD MATCHES QUERY VARIANTS
  bool matchesQuery(String queryNorm, String queryCyrillic, String queryLatin) {
    if (normWord.contains(queryNorm)) return true;
    if (queryCyrillic.isNotEmpty && normWord.contains(queryCyrillic)) return true;
    if (normLatinWord.contains(queryNorm)) return true;
    if (normTranslit.contains(queryNorm)) return true;
    if (queryLatin.isNotEmpty && normTranslit.contains(queryLatin)) return true;
    if (normEn.contains(queryNorm)) return true;
    return false;
  }
}
