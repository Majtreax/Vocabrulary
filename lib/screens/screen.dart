import 'package:flutter/material.dart';
import 'dart:math';
import '../models/model.dart';
import '../services/loader.dart';
import '../services/storage.dart';
import '../services/tts.dart';
import '../theme/theme.dart';
import '../widgets/button.dart';
import 'filter.dart';
import 'search.dart';
import 'study.dart';
import 'known.dart';
import 'quiz.dart';

// MAIN APPLICATION CONTROLLER SCREEN
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<VocabularyWord> _allWords = [];
  List<VocabularyWord> _filteredWords = [];
  final List<VocabularyWord> _history = [];
  final List<int> _recentWordIds = [];
  Set<int> _knownWordIds = {};

  bool _isLoading = true;
  VocabularyWord? _currentWord;
  int _wordChangeIndex = 0;

  Set<String> _selectedLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
  bool _onlyWithSentences = false;
  bool _includeUncategorized = true;

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  // PRONOUNCE ACTIVE WORD VIA TTS
  void _speakCurrentWord() {
    if (_currentWord == null) return;
    TtsService.speak(_currentWord!.word);
  }

  // COMPUTE FILTERED WORD POOL
  List<VocabularyWord> _getFilteredPool() {
    return _allWords.where((w) {
      if (_knownWordIds.contains(w.id)) return false;

      if (w.level.isEmpty) {
        if (!_includeUncategorized) return false;
      } else {
        if (!_selectedLevels.contains(w.level.toUpperCase())) return false;
      }

      if (_onlyWithSentences && w.sentence.isEmpty) return false;
      return true;
    }).toList();
  }

  // SELECT RANDOM WORD FROM FILTERED POOL WITH 10-WORD RECENT BUFFER
  VocabularyWord? _pickRandomWord() {
    if (_filteredWords.isEmpty) return null;
    if (_filteredWords.length == 1) {
      _recordRecentWord(_filteredWords.first.id);
      return _filteredWords.first;
    }

    VocabularyWord selected;

    // IF POOL HAS MORE THAN 10 WORDS, EXCLUDE THE LAST 10 SEEN WORDS
    if (_filteredWords.length > 10) {
      final candidates =
          _filteredWords.where((w) => !_recentWordIds.contains(w.id)).toList();

      if (candidates.isNotEmpty) {
        selected = candidates[_random.nextInt(candidates.length)];
      } else {
        // FALLBACK IF ALL WORDS ARE IN BUFFER (E.G. AFTER POOL SHRINK)
        final fallbackPool =
            _currentWord != null
                ? _filteredWords.where((w) => w.id != _currentWord!.id).toList()
                : _filteredWords;
        selected =
            fallbackPool.isNotEmpty
                ? fallbackPool[_random.nextInt(fallbackPool.length)]
                : _filteredWords.first;
      }
    } else {
      // BYPASS 10-WORD EXCLUSION IF 10 OR FEWER WORDS REMAIN
      final pool =
          _currentWord != null
              ? _filteredWords.where((w) => w.id != _currentWord!.id).toList()
              : _filteredWords;
      selected =
          pool.isNotEmpty
              ? pool[_random.nextInt(pool.length)]
              : _filteredWords.first;
    }

    _recordRecentWord(selected.id);
    return selected;
  }

  void _recordRecentWord(int wordId) {
    _recentWordIds.remove(wordId);
    _recentWordIds.add(wordId);
    if (_recentWordIds.length > 10) {
      _recentWordIds.removeAt(0);
    }
  }

  // ASYNC INITIALIZATION OF DATA AND FILTERS
  Future<void> _loadData() async {
    final words = await VocabularyLoader.loadWords();
    final known = await WordStorage.getKnownWords();
    final filters = await WordStorage.getFilters();

    if (!mounted) return;

    setState(() {
      _allWords = words;
      _knownWordIds = known;

      _selectedLevels = filters['levels'] as Set<String>;
      _onlyWithSentences = filters['onlySentences'] as bool;
      _includeUncategorized = filters['includeUncategorized'] as bool;

      _filteredWords = _getFilteredPool();
      _history.clear();
      _recentWordIds.clear();
      _wordChangeIndex++;
      _currentWord = _pickRandomWord();
      _isLoading = false;
    });

    _speakCurrentWord();
  }

  // APPLY CURRENT FILTERS TO VOCABULARY POOL
  void _applyFilters() {
    _filteredWords = _getFilteredPool();
    _history.clear();
    _recentWordIds.clear();
    _wordChangeIndex++;
    _currentWord = _pickRandomWord();
  }

  // ADVANCE TO NEXT WORD
  void _nextWord() {
    if (_currentWord != null) {
      _history.add(_currentWord!);
    }
    _filteredWords = _getFilteredPool();
    setState(() {
      _wordChangeIndex++;
      if (_filteredWords.isNotEmpty) {
        _currentWord = _pickRandomWord();
      } else {
        _currentWord = null;
      }
    });
    _speakCurrentWord();
  }

  // RETURN TO PREVIOUS WORD IN HISTORY
  void _prevWord() {
    if (_history.isEmpty) return;
    setState(() {
      _wordChangeIndex++;
      _currentWord = _history.removeLast();
      if (_currentWord != null) {
        _recordRecentWord(_currentWord!.id);
      }
      _filteredWords = _getFilteredPool();
    });
    _speakCurrentWord();
  }

  // TOGGLE KNOWN STATUS FOR CURRENT WORD
  void _toggleKnown() {
    if (_currentWord == null) return;
    final word = _currentWord!;

    if (_knownWordIds.contains(word.id)) {
      WordStorage.removeKnownWord(word.id);
      _knownWordIds.remove(word.id);
    } else {
      WordStorage.addKnownWord(word.id);
      _knownWordIds.add(word.id);
      _history.add(word);
    }

    setState(() {
      _wordChangeIndex++;
      _filteredWords = _getFilteredPool();
      _currentWord = _pickRandomWord();
    });
    _speakCurrentWord();
  }

  // OPEN FILTER SELECTION BOTTOM SHEET
  void _openFilters() {
    TtsService.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => Filters(
            selectedLevels: _selectedLevels,
            onlyWithSentences: _onlyWithSentences,
            includeUncategorized: _includeUncategorized,
            totalWords: _allWords.length,
            knownCount: _knownWordIds.length,
            onApply: (levels, withSentences, includeUncategorized) {
              WordStorage.saveFilters(
                levels: levels,
                onlySentences: withSentences,
                includeUncategorized: includeUncategorized,
              );
              setState(() {
                _selectedLevels = levels;
                _onlyWithSentences = withSentences;
                _includeUncategorized = includeUncategorized;
                _applyFilters();
              });
              _speakCurrentWord();
            },
          ),
    );
  }

  // OPEN KNOWN WORDS MANAGEMENT BOTTOM SHEET
  void _openKnownWords() {
    TtsService.stop();
    final knownList =
        _allWords.where((w) => _knownWordIds.contains(w.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => KnownWordsSheet(
            knownWords: knownList,
            onRemove: (id) {
              WordStorage.removeKnownWord(id);
              setState(() {
                _knownWordIds.remove(id);
                _filteredWords = _getFilteredPool();
              });
            },
            onClearAll: () {
              WordStorage.clearKnownWords();
              setState(() {
                _knownWordIds.clear();
                _filteredWords = _getFilteredPool();
              });
            },
          ),
    );
  }

  // NAVIGATE TO FULL SEARCH PAGE
  void _openSearch() {
    TtsService.stop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage(allWords: _allWords)),
    );
  }

  // NAVIGATE TO QUIZ MODE PAGE
  void _openQuiz() {
    TtsService.stop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizPage(allWords: _allWords)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _LoadingView();
    if (_currentWord == null && _filteredWords.isEmpty) {
      return _EmptyView(
        knownCount: _knownWordIds.length,
        onOpenFilters: _openFilters,
        onOpenKnown: _openKnownWords,
      );
    }
    final word = _currentWord ?? _filteredWords.first;
    return StudyView(
      word: word,
      filteredCount: _filteredWords.length,
      knownCount: _knownWordIds.length,
      canGoBack: _history.isNotEmpty,
      isKnown: _knownWordIds.contains(word.id),
      wordChangeIndex: _wordChangeIndex,
      onNext: _nextWord,
      onPrev: _prevWord,
      onMarkKnown: _toggleKnown,
      onOpenFilters: _openFilters,
      onOpenKnown: _openKnownWords,
      onOpenSearch: _openSearch,
      onOpenQuiz: _openQuiz,
    );
  }
}

// ASYNC LOADING PROGRESS INDICATOR
class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}

// EMPTY FILTER STATE VIEW
class _EmptyView extends StatelessWidget {
  final int knownCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenKnown;

  const _EmptyView({
    required this.knownCount,
    required this.onOpenFilters,
    required this.onOpenKnown,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.filter_alt_off_outlined,
                  size: 80,
                  color: Color(0xFF666666),
                ),
                const SizedBox(height: 24),
                const Text(
                  "All Caught Up!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  knownCount == 0
                      ? "No words match your current filters."
                      : "You've mastered all words in this selection!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                GlassActionButton(
                  icon: Icons.tune_rounded,
                  label: "ADJUST FILTERS",
                  color: AppTheme.primaryColor,
                  onTap: onOpenFilters,
                ),
                if (knownCount > 0) ...[
                  const SizedBox(height: 16),
                  GlassActionButton(
                    icon: Icons.check_circle_outline_rounded,
                    label: "MANAGE KNOWN WORDS",
                    color: AppTheme.secondaryColor,
                    onTap: onOpenKnown,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
