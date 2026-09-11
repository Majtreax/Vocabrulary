import 'package:flutter/material.dart';
import '../models/model.dart';
import '../theme/theme.dart';
import 'button.dart';

// VOCABULARY FLASHCARD PRESENTATION WIDGET
class VocabCard extends StatelessWidget {
  final VocabularyWord word;
  final VoidCallback? onTap;
  final Color? highlightColor;
  final double highlightProgress;
  final bool isTouched;

  const VocabCard({
    super.key,
    required this.word,
    this.onTap,
    this.highlightColor,
    this.highlightProgress = 0.0,
    this.isTouched = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSurface = highlightColor == AppTheme.surfaceColor;
    final activeHighlight =
        isSurface
            ? const Color(0xFF7E7E98)
            : (highlightColor ?? AppTheme.primaryColor);
    final progress = highlightProgress.clamp(0.0, 1.0);

    final cardContent = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              const Color(0xFF1E1E1E),
              isSurface ? AppTheme.surfaceColor : activeHighlight,
              progress * 0.20,
            )!,
            Color.lerp(
              const Color(0xFF252538),
              isSurface ? AppTheme.surfaceColor : activeHighlight,
              progress * 0.15,
            )!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isTouched ? 0.6 : 0.4),
            blurRadius: isTouched ? 28 : 20,
            offset: Offset(0, isTouched ? 12 : 8),
          ),
          BoxShadow(
            color: activeHighlight.withValues(alpha: 0.1 + progress * 0.35),
            blurRadius: 15 + progress * 15,
            offset: const Offset(0, 4),
            spreadRadius: progress * 1.5,
          ),
        ],
        border: Border.all(
          color:
              progress > 0.02
                  ? activeHighlight.withValues(
                    alpha: (0.25 + progress * 0.75).clamp(0.0, 1.0),
                  )
                  : const Color(0x20FFFFFF),
          width: 1.0 + progress * 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            highlightColor: AppTheme.primaryColor.withValues(alpha: 0.06),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LEVEL AND TYPE BADGES
                  if (word.level.isNotEmpty || word.type.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (word.level.isNotEmpty)
                          _Badge(word.level.toUpperCase(), AppTheme.secondaryColor),
                        if (word.type.isNotEmpty)
                          _Badge(word.type.toUpperCase(), AppTheme.primaryColor),
                      ],
                    ),

                  if (word.level.isNotEmpty || word.type.isNotEmpty)
                    const SizedBox(height: 14),

                  // AUDIO PRONUNCIATION BUTTON
                  Center(
                    child: ListenButton(
                      text: word.word,
                      size: 28,
                      color: AppTheme.secondaryColor,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // CYRILLIC TARGET WORD
                  Text(
                    word.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // TRANSLITERATION
                  if (word.wordTranslit.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "[${word.wordTranslit}]",
                      style: TextStyle(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  _Divider(),
                  const SizedBox(height: 12),

                  // ENGLISH TRANSLATION
                  Text(
                    word.wordEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),

                  // EXAMPLE SENTENCE BOX
                  if (word.sentence.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SentenceBox(word: word),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }
}

// BADGE PILL WIDGET
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// HORIZONTAL GRADIENT DIVIDER
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

// EXAMPLE SENTENCE DISPLAY CONTAINER
class _SentenceBox extends StatelessWidget {
  final VocabularyWord word;

  const _SentenceBox({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x15FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x10FFFFFF)),
      ),
      child: Column(
        children: [
          Text(
            word.sentence,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFEEEEEE),
              height: 1.5,
            ),
          ),
          if (word.sentenceTranslit.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "[${word.sentenceTranslit}]",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Color(0xFF80CBC4),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "\"${word.sentenceEn}\"",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xCCFFFFFF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
