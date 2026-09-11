import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/model.dart';
import '../theme/theme.dart';
import '../utils/transliterator.dart';
import '../widgets/button.dart';
import '../services/tts.dart';

// DICTIONARY SEARCH SCREEN WITH LATIN AND CYRILLIC SUPPORT
class SearchPage extends StatefulWidget {
  final List<VocabularyWord> allWords;

  const SearchPage({super.key, required this.allWords});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const int _pageSize = 30;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<VocabularyWord> _allMatches = [];
  int _displayedCount = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // HANDLE SCROLL PAGINATION FOR LARGE DATASETS
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 250) {
      if (_displayedCount < _allMatches.length) {
        setState(() {
          _displayedCount = math.min(
            _displayedCount + _pageSize,
            _allMatches.length,
          );
        });
      }
    }
  }

  // DEBOUNCED SEARCH QUERY LISTENER
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _allMatches = [];
        _displayedCount = 0;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      _performSearch(query);
    });
  }

  // EXECUTE HIGH PERFORMANCE SEARCH SCAN
  void _performSearch(String query) {
    if (query.isEmpty) return;

    final queryNorm = Transliterator.normalize(query);
    final queryCyrillic = Transliterator.latinToCyrillic(queryNorm);
    final queryLatin = Transliterator.cyrillicToLatin(queryNorm);

    final results = <VocabularyWord>[];
    for (final word in widget.allWords) {
      if (word.matchesQuery(queryNorm, queryCyrillic, queryLatin)) {
        results.add(word);
      }
    }

    results.sort((a, b) => a.id.compareTo(b.id));

    if (mounted) {
      setState(() {
        _allMatches = results;
        _displayedCount = math.min(_pageSize, results.length);
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [_buildTopBar(), Expanded(child: _buildResultsList())],
          ),
        ),
      ),
    );
  }

  // TOP SEARCH BAR WITH INPUT FIELD
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search (Latin or Cyrillic)',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _focusNode.requestFocus();
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RESULTS LIST VIEW OR EMPTY STATE
  Widget _buildResultsList() {
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_rounded,
        subtitle:
            'Search by typing in Latin letters or Cyrillic script. Matches words, transliterations, and translations.',
      );
    }

    if (_allMatches.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Results Found',
        subtitle: 'Try a different search term.',
      );
    }

    final hasMore = _displayedCount < _allMatches.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Showing $_displayedCount of ${_allMatches.length} Matches",
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasMore)
                Text(
                  "Scroll for More",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _displayedCount + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _displayedCount) {
                final word = _allMatches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SearchResultCard(word: word),
                );
              }
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // EMPTY SEARCH STATE DISPLAY
  Widget _buildEmptyState({
    required IconData icon,
    String? title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: const Color(0xFF666666)),
            if (title != null && title.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
            ] else ...[
              const SizedBox(height: 18),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// COMPACT SEARCH RESULT CARD ALIGNED LIKE KNOWN WORD TILES
class _SearchResultCard extends StatelessWidget {
  final VocabularyWord word;

  const _SearchResultCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(
        borderRadius: 14,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => TtsService.speak(word.word),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // CEFR LEVEL PILL
                if (word.level.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      word.level.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // OPTIONAL TYPE PILL
                if (word.type.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      word.type.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // WORD & TRANSLATION CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: word.word,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (word.wordTranslit.isNotEmpty) ...[
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: "[${word.wordTranslit}]",
                                style: const TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        word.wordEn,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // AUDIO LISTEN BUTTON
                ListenButton(
                  text: word.word,
                  size: 20,
                  color: AppTheme.secondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
