import 'package:flutter/material.dart';
import '../models/model.dart';
import '../theme/theme.dart';
import '../widgets/button.dart';
import '../services/tts.dart';

// KNOWN WORDS MANAGEMENT BOTTOM SHEET
class KnownWordsSheet extends StatefulWidget {
  final List<VocabularyWord> knownWords;
  final Function(int wordId) onRemove;
  final VoidCallback onClearAll;

  const KnownWordsSheet({
    super.key,
    required this.knownWords,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  State<KnownWordsSheet> createState() => _KnownWordsSheetState();
}

class _KnownWordsSheetState extends State<KnownWordsSheet> {
  late List<VocabularyWord> _words;

  @override
  void initState() {
    super.initState();
    _words = List.of(widget.knownWords);
  }

  void _handleRemove(int wordId) {
    setState(() {
      _words.removeWhere((w) => w.id == wordId);
    });
    widget.onRemove(wordId);
  }

  void _handleClearAll() {
    setState(() {
      _words.clear();
    });
    widget.onClearAll();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.sheetGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(),
              _Header(count: _words.length),
              const Divider(color: Color(0xFF2A2A3E), height: 1),

              Flexible(
                child:
                    _words.isEmpty
                        ? _EmptyState()
                        : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _words.length,
                          itemBuilder:
                              (_, i) => _WordTile(
                                word: _words[i],
                                onRemove: () => _handleRemove(_words[i].id),
                              ),
                        ),
              ),

              if (_words.isNotEmpty)
                _ClearButton(count: _words.length, onClearAll: _handleClearAll),
            ],
          ),
        ),
      ),
    );
  }
}

// DRAG HANDLE BAR
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// SHEET HEADER DISPLAY
class _Header extends StatelessWidget {
  final int count;

  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Known Words",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "$count Words Mastered",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A3E),
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}

// EMPTY STATE DISPLAY
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          Text(
            "No words marked as known yet.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// COMPACT KNOWN WORD CARD TILE WITH MAIN CARD GRADIENT
class _WordTile extends StatelessWidget {
  final VocabularyWord word;
  final VoidCallback onRemove;

  const _WordTile({required this.word, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

          // AUDIO LISTEN BUTTON
          ListenButton(
            text: word.word,
            size: 20,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 4),

          // REMOVE / UNMARK BUTTON
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: Colors.redAccent.withValues(alpha: 0.8),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: "Mark as Unknown",
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }
}

// COMPACT CLEAR ALL KNOWN WORDS BUTTON
class _ClearButton extends StatelessWidget {
  final int count;
  final VoidCallback onClearAll;

  const _ClearButton({required this.count, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A3E))),
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showConfirmation(context),
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.redAccent.withValues(alpha: 0.2),
            highlightColor: Colors.redAccent.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Clear All Known Words",
                    style: TextStyle(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // CONFIRMATION DIALOG FOR CLEARING KNOWN WORDS
  void _showConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Clear All Known Words?",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "This will move all $count words back to the study queue.",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  onClearAll();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text("Clear All"),
              ),
            ],
          ),
    );
  }
}
