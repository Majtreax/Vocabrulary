import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/theme.dart';
import '../models/model.dart';
import '../widgets/button.dart';
import '../services/tts.dart';
import '../services/storage.dart';

// MULTIPLE CHOICE QUIZ MODE SCREEN
class QuizPage extends StatefulWidget {
  final List<VocabularyWord> allWords;

  const QuizPage({super.key, required this.allWords});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final Random _random = Random();

  final Set<String> _selectedLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
  bool _includeUncategorized = true;

  VocabularyWord? _currentWord;
  List<String> _choices = [];
  String? _selectedAnswer;
  bool _showingResult = false;
  int _correctCount = 0;
  int _incorrectCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await WordStorage.getQuizPreferences();
    if (!mounted) return;
    setState(() {
      _selectedLevels.clear();
      _selectedLevels.addAll(prefs.levels);
      _includeUncategorized = prefs.includeUncategorized;
      _correctCount = prefs.correctCount;
      _incorrectCount = prefs.incorrectCount;
    });
    _generateQuestion();
  }

  void _savePreferences() {
    WordStorage.saveQuizPreferences(
      levels: _selectedLevels,
      includeUncategorized: _includeUncategorized,
      correctCount: _correctCount,
      incorrectCount: _incorrectCount,
    );
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  List<VocabularyWord> get _filteredWords {
    return widget.allWords.where((w) {
      if (w.level.isEmpty) {
        return _includeUncategorized;
      }
      return _selectedLevels.contains(w.level.toUpperCase());
    }).toList();
  }

  // GENERATE MULTIPLE CHOICE QUESTION
  void _generateQuestion() {
    final pool = _filteredWords;
    if (pool.isEmpty) {
      setState(() {
        _currentWord = null;
        _choices = [];
      });
      return;
    }

    final word = pool[_random.nextInt(pool.length)];

    final wrongAnswers = <String>{};
    while (wrongAnswers.length < 4) {
      final randomWord = pool[_random.nextInt(pool.length)];
      if (randomWord.id != word.id && randomWord.wordEn.isNotEmpty) {
        wrongAnswers.add(randomWord.wordEn);
      }
    }

    final allChoices = [word.wordEn, ...wrongAnswers];
    allChoices.shuffle(_random);

    setState(() {
      _currentWord = word;
      _choices = allChoices;
      _selectedAnswer = null;
      _showingResult = false;
    });

    TtsService.speak(word.word);
  }

  // SUBMIT AND EVALUATE SELECTED ANSWER
  void _selectAnswer(String answer) {
    if (_showingResult || _currentWord == null) return;

    setState(() {
      _selectedAnswer = answer;
      _showingResult = true;
    });

    if (answer != _currentWord!.wordEn) {
      setState(() {
        _incorrectCount++;
      });
      _savePreferences();
      Future.delayed(const Duration(milliseconds: 300), () {
        _showCorrectAnswerPopup();
      });
    } else {
      setState(() {
        _correctCount++;
      });
      _savePreferences();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _showingResult) {
          _generateQuestion();
        }
      });
    }
  }

  // DISPLAY CORRECT ANSWER POPUP
  void _showCorrectAnswerPopup() {
    if (_currentWord == null) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: AppTheme.cardDecoration(borderRadius: 24),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 60,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Correct Answer:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentWord!.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "[${_currentWord!.wordTranslit}]",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _currentWord!.wordEn,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateQuestion();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "NEXT QUESTION",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // TOGGLE CEFR DIFFICULTY LEVEL
  void _toggleLevel(String level) {
    setState(() {
      if (_selectedLevels.contains(level)) {
        _selectedLevels.remove(level);
      } else {
        _selectedLevels.add(level);
      }
    });
    _savePreferences();
    _generateQuestion();
  }

  void _toggleUncategorized(bool value) {
    setState(() {
      _includeUncategorized = value;
    });
    _savePreferences();
    _generateQuestion();
  }

  void _clearFilters() {
    setState(() {
      _selectedLevels.clear();
      _includeUncategorized = false;
      _correctCount = 0;
      _incorrectCount = 0;
    });
    _savePreferences();
    _generateQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildFilters(),
              Expanded(
                child:
                    _currentWord == null
                        ? _buildEmptyState()
                        : _buildQuestion(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TOP APP BAR DISPLAY
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quiz Mode",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.secondaryColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$_correctCount",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.cancel, color: Colors.red.shade300, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "$_incorrectCount",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // DIFFICULTY FILTER SELECTION ROW
  Widget _buildFilters() {
    final allLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...allLevels
                  .sublist(0, 4)
                  .map(
                    (level) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _LevelChip(
                        level: level,
                        isSelected: _selectedLevels.contains(level),
                        onTap: () => _toggleLevel(level),
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...allLevels
                  .sublist(4, 6)
                  .map(
                    (level) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _LevelChip(
                        level: level,
                        isSelected: _selectedLevels.contains(level),
                        onTap: () => _toggleLevel(level),
                      ),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _LevelChip(
                  level: "Other",
                  isSelected: _includeUncategorized,
                  onTap: () => _toggleUncategorized(!_includeUncategorized),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: _clearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      "Clear",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0),
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ACTIVE QUESTION CARD DISPLAY
  Widget _buildQuestion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: AppTheme.cardDecoration(
              borderRadius: 20,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => TtsService.speak(_currentWord!.word),
                splashColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                highlightColor: AppTheme.primaryColor.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Center(child: ListenButton(text: _currentWord!.word, size: 28)),
                      const SizedBox(height: 2),
                      Text(
                        _currentWord!.word,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "[${_currentWord!.wordTranslit}]",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          ..._choices.map((choice) {
            final isCorrect = choice == _currentWord!.wordEn;
            final isSelected = choice == _selectedAnswer;

            Color bgColor = AppTheme.surfaceColor;
            Color borderColor = const Color(0xFF45455D);
            Color textColor = Colors.white;

            if (_showingResult && isSelected) {
              if (isCorrect) {
                bgColor = AppTheme.secondaryColor.withValues(alpha: 0.2);
                borderColor = AppTheme.secondaryColor;
                textColor = AppTheme.secondaryColor;
              } else {
                bgColor = Colors.red.withValues(alpha: 0.2);
                borderColor = Colors.red;
                textColor = Colors.red;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectAnswer(choice),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      choice,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // EMPTY STATE WHEN NO WORDS MATCH FILTERS
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 80, color: Color(0xFF666666)),
            const SizedBox(height: 24),
            const Text(
              "No Words Available",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Adjust your difficulty filters to generate questions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CEFR LEVEL FILTER CHIP WIDGET
class _LevelChip extends StatelessWidget {
  final String level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelChip({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : const Color(0xFF252538),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFF45455D),
            width: 1.5,
          ),
        ),
        child: Text(
          level,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.primaryColor : Colors.white70,
          ),
        ),
      ),
    );
  }
}
