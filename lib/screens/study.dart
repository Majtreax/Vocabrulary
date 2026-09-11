import 'package:flutter/material.dart';
import '../models/model.dart';
import '../theme/theme.dart';
import '../widgets/card.dart';
import '../widgets/button.dart';
import '../services/tts.dart';

// MAIN STUDY PRESENTATION VIEW
class StudyView extends StatelessWidget {
  final VocabularyWord word;
  final int filteredCount;
  final int knownCount;
  final bool canGoBack;
  final bool isKnown;
  final int wordChangeIndex;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onMarkKnown;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenKnown;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenQuiz;

  const StudyView({
    super.key,
    required this.word,
    required this.filteredCount,
    required this.knownCount,
    required this.canGoBack,
    this.isKnown = false,
    this.wordChangeIndex = 0,
    required this.onNext,
    required this.onPrev,
    required this.onMarkKnown,
    required this.onOpenFilters,
    required this.onOpenKnown,
    required this.onOpenSearch,
    required this.onOpenQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              // TOP BAR METRICS AND ACTIONS
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Word Count: $filteredCount",
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // TAPPABLE KNOWN COUNT BADGE
                        GestureDetector(
                          onTap: onOpenKnown,
                          child: Row(
                            children: [
                              Text(
                                "$knownCount Marked Known",
                                style: TextStyle(
                                  color:
                                      knownCount > 0
                                          ? AppTheme.secondaryColor
                                          : const Color(0xFF666666),
                                  fontSize: 16,
                                  fontWeight:
                                      knownCount > 0
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                ),
                              ),
                              if (knownCount > 0) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppTheme.secondaryColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: onOpenQuiz,
                          icon: const Icon(Icons.quiz_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surfaceColor,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onOpenSearch,
                          icon: const Icon(Icons.search_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surfaceColor,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onOpenFilters,
                          icon: const Icon(Icons.tune),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surfaceColor,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // SWIPEABLE FLASHCARD CONTAINER
              Expanded(
                child: Center(
                  child: SwipeableFlashcard(
                    key: ValueKey('${word.id}_$wordChangeIndex'),
                    word: word,
                    canGoBack: canGoBack,
                    isKnown: isKnown,
                    onNext: onNext,
                    onPrev: onPrev,
                    onMarkKnown: onMarkKnown,
                  ),
                ),
              ),

              // BOTTOM NAVIGATION CONTROLS
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: "Back",
                      onTap: canGoBack ? onPrev : null,
                    ),
                    NavButton(
                      icon:
                          isKnown
                              ? Icons.remove_circle_outline_rounded
                              : Icons.check_circle_outline_rounded,
                      label: isKnown ? "Unknown" : "Known",
                      onTap: onMarkKnown,
                      isPrimary: false,
                      isSuccess: !isKnown,
                      isWarning: isKnown,
                    ),
                    NavButton(
                      icon: Icons.shuffle_rounded,
                      label: "Next",
                      onTap: onNext,
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// AXIS LOCKED SWIPEABLE FLASHCARD WIDGET
class SwipeableFlashcard extends StatefulWidget {
  final VocabularyWord word;
  final bool canGoBack;
  final bool isKnown;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onMarkKnown;

  const SwipeableFlashcard({
    super.key,
    required this.word,
    required this.canGoBack,
    this.isKnown = false,
    required this.onNext,
    required this.onPrev,
    required this.onMarkKnown,
  });

  @override
  State<SwipeableFlashcard> createState() => _SwipeableFlashcardState();
}

class _SwipeableFlashcardState extends State<SwipeableFlashcard>
    with TickerProviderStateMixin {
  double _dragDx = 0.0;
  double _dragDy = 0.0;
  double _accumulatedDx = 0.0;
  double _accumulatedDy = 0.0;
  Axis? _lockedAxis;
  bool _isDragging = false;
  bool _isExiting = false;

  late AnimationController _animController;
  late AnimationController _enterController;
  Animation<Offset>? _exitAnimation;
  Animation<Offset>? _springAnimation;
  late Animation<double> _enterScaleAnimation;
  late Animation<double> _enterFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _enterScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutQuad),
    );
    _enterFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));
    _enterController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SwipeableFlashcard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word.id != widget.word.id) {
      _isExiting = false;
      _dragDx = 0.0;
      _dragDy = 0.0;
      _lockedAxis = null;
      _enterController.forward(from: 0);
    }
  }

  // PAN GESTURE START HANDLER
  void _onPanStart(DragStartDetails details) {
    if (_isExiting) return;
    _animController.stop();
    setState(() {
      _isDragging = true;
      _lockedAxis = null;
      _accumulatedDx = 0.0;
      _accumulatedDy = 0.0;
      _dragDx = 0.0;
      _dragDy = 0.0;
    });
  }

  // AXIS DETERMINATION AND DRAG CLAMPING
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isExiting) return;

    final dx = details.delta.dx;
    final dy = details.delta.dy;

    _accumulatedDx += dx;
    _accumulatedDy += dy;

    if (_lockedAxis == null) {
      if (_accumulatedDx.abs() > 8 || _accumulatedDy.abs() > 8) {
        if (_accumulatedDx.abs() > _accumulatedDy.abs()) {
          _lockedAxis = Axis.horizontal;
        } else if (_accumulatedDy > 4) {
          _lockedAxis = Axis.vertical;
        } else {
          return;
        }
      } else {
        return;
      }
    }

    setState(() {
      if (_lockedAxis == Axis.horizontal) {
        double newDx = _dragDx + dx;
        if (newDx > 0) {
          _dragDx = newDx.clamp(0.0, 140.0);
        } else {
          if (widget.canGoBack) {
            _dragDx = newDx.clamp(-140.0, 0.0);
          } else {
            _dragDx = (_dragDx + dx * 0.2).clamp(-30.0, 0.0);
          }
        }
        _dragDy = 0.0;
      } else if (_lockedAxis == Axis.vertical) {
        double newDy = _dragDy + dy;
        _dragDy = newDy.clamp(0.0, 140.0);
        _dragDx = 0.0;
      }
    });
  }

  // GESTURE END THRESHOLD EVALUATION
  void _onPanEnd(DragEndDetails details) {
    if (_isExiting) return;
    setState(() => _isDragging = false);

    final size = MediaQuery.of(context).size;
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    if (_lockedAxis == Axis.horizontal) {
      if (_dragDx > 60 || vx > 300) {
        _animateExit(
          target: Offset(size.width * 1.3, 0),
          onComplete: widget.onNext,
        );
        return;
      }

      if ((_dragDx < -60 || vx < -300) && widget.canGoBack) {
        _animateExit(
          target: Offset(-size.width * 1.3, 0),
          onComplete: widget.onPrev,
        );
        return;
      }
    } else if (_lockedAxis == Axis.vertical) {
      if (_dragDy > 45 || vy > 250) {
        _animateExit(
          target: Offset(0, size.height * 0.85),
          onComplete: widget.onMarkKnown,
        );
        return;
      }
    }

    _animateSpringBack();
  }

  void _onPanCancel() {
    if (!_isExiting) {
      setState(() => _isDragging = false);
      _animateSpringBack();
    }
  }

  // ANIMATE CARD EXIT OFF SCREEN
  void _animateExit({
    required Offset target,
    required VoidCallback onComplete,
  }) {
    _isExiting = true;
    final start = Offset(_dragDx, _dragDy);
    _exitAnimation = Tween<Offset>(begin: start, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInCubic),
    );

    _animController.addListener(_handleAnimUpdate);
    _animController.forward(from: 0).then((_) {
      _animController.removeListener(_handleAnimUpdate);
      onComplete();
    });
  }

  // ANIMATE SPRING RETURN TO CENTER
  void _animateSpringBack() {
    final start = Offset(_dragDx, _dragDy);
    _springAnimation = Tween<Offset>(begin: start, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.addListener(_handleSpringUpdate);
    _animController.forward(from: 0).then((_) {
      _animController.removeListener(_handleSpringUpdate);
      setState(() {
        _dragDx = 0.0;
        _dragDy = 0.0;
        _lockedAxis = null;
      });
    });
  }

  void _handleAnimUpdate() {
    if (_exitAnimation != null) {
      setState(() {
        _dragDx = _exitAnimation!.value.dx;
        _dragDy = _exitAnimation!.value.dy;
      });
    }
  }

  void _handleSpringUpdate() {
    if (_springAnimation != null) {
      setState(() {
        _dragDx = _springAnimation!.value.dx;
        _dragDy = _springAnimation!.value.dy;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color? highlightColor;
    double progress = 0.0;

    if (_lockedAxis == Axis.horizontal) {
      if (_dragDx > 0) {
        highlightColor = AppTheme.primaryColor;
        progress = (_dragDx / 75.0).clamp(0.0, 1.0);
      } else if (_dragDx < 0) {
        highlightColor = AppTheme.surfaceColor;
        progress = (-_dragDx / 75.0).clamp(0.0, 1.0);
      }
    } else if (_lockedAxis == Axis.vertical && _dragDy > 0) {
      highlightColor =
          widget.isKnown ? const Color(0xFFFF6B81) : AppTheme.secondaryColor;
      progress = (_dragDy / 60.0).clamp(0.0, 1.0);
    }

    final rotation = (_dragDx / 1800).clamp(-0.07, 0.07);
    final touchScale = 1.0 - (progress * 0.015);

    return SizedBox.expand(
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedBuilder(
            animation: _enterController,
            builder: (context, child) {
              return Transform.scale(
                scale: _enterScaleAnimation.value,
                child: Opacity(opacity: _enterFadeAnimation.value, child: child),
              );
            },
            child: Transform.translate(
              offset: Offset(_dragDx, _dragDy),
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: touchScale,
                  child: VocabCard(
                    word: widget.word,
                    highlightColor: highlightColor,
                    highlightProgress: progress,
                    isTouched: _isDragging,
                    onTap: () {
                      TtsService.speak(widget.word.word);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
