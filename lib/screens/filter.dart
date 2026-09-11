import 'package:flutter/material.dart';
import '../theme/theme.dart';

// DIFFICULTY AND ATTRIBUTE FILTER BOTTOM SHEET
class Filters extends StatefulWidget {
  final Set<String> selectedLevels;
  final bool onlyWithSentences;
  final bool includeUncategorized;
  final int totalWords;
  final int knownCount;
  final Function(Set<String>, bool, bool) onApply;

  const Filters({
    super.key,
    required this.selectedLevels,
    required this.onlyWithSentences,
    required this.includeUncategorized,
    required this.totalWords,
    required this.knownCount,
    required this.onApply,
  });

  @override
  State<Filters> createState() => _FiltersState();
}

class _FiltersState extends State<Filters> {
  late Set<String> _selectedLevels;
  late bool _onlyWithSentences;
  late bool _includeUncategorized;

  final List<String> _allLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  void initState() {
    super.initState();
    _selectedLevels = Set.from(widget.selectedLevels);
    _onlyWithSentences = widget.onlyWithSentences;
    _includeUncategorized = widget.includeUncategorized;
  }

  void _toggleLevel(String level) {
    setState(() {
      if (_selectedLevels.contains(level)) {
        _selectedLevels.remove(level);
      } else {
        _selectedLevels.add(level);
      }
    });
    // AUTO APPLY ON FILTER TOGGLE
    widget.onApply(_selectedLevels, _onlyWithSentences, _includeUncategorized);
  }

  void _clearAll() {
    setState(() {
      _selectedLevels.clear();
    });
    widget.onApply(_selectedLevels, _onlyWithSentences, _includeUncategorized);
  }

  void _selectAll() {
    setState(() {
      _selectedLevels = Set.from(_allLevels);
    });
    widget.onApply(_selectedLevels, _onlyWithSentences, _includeUncategorized);
  }

  void _toggleUncategorized(bool value) {
    setState(() {
      _includeUncategorized = value;
    });
    widget.onApply(_selectedLevels, _onlyWithSentences, _includeUncategorized);
  }

  void _toggleSentenceFilter(bool value) {
    setState(() {
      _onlyWithSentences = value;
    });
    widget.onApply(_selectedLevels, _onlyWithSentences, _includeUncategorized);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.sheetGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DRAG HANDLE BAR
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF666666),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
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
                    const Expanded(
                      child: Text(
                        "Proficiency",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SmallControlButton(
                      icon: Icons.check_rounded,
                      label: "All",
                      onTap: _selectAll,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    _SmallControlButton(
                      icon: Icons.close_rounded,
                      label: "Clear",
                      onTap: _clearAll,
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CEFR LEVEL SELECTION GRID
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _LevelRow(
                        levels: ['A1', 'A2'],
                        selected: _selectedLevels,
                        onToggle: _toggleLevel,
                      ),
                      const SizedBox(height: 12),
                      _LevelRow(
                        levels: ['B1', 'B2'],
                        selected: _selectedLevels,
                        onToggle: _toggleLevel,
                      ),
                      const SizedBox(height: 12),
                      _LevelRow(
                        levels: ['C1', 'C2'],
                        selected: _selectedLevels,
                        onToggle: _toggleLevel,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // UNCATEGORIZED WORDS TOGGLE CARD
                _OptionCard(
                  icon: Icons.category_rounded,
                  title: "Uncategorized CEFR",
                  subtitle: "Include ~20k words without strict level.",
                  isActive: _includeUncategorized,
                  onChanged: _toggleUncategorized,
                  activeColor: AppTheme.primaryColor,
                ),

                const SizedBox(height: 12),

                // SENTENCE EXAMPLES TOGGLE CARD
                _OptionCard(
                  icon: Icons.format_quote_rounded,
                  title: "With Sentence Examples",
                  subtitle: "Only ~1k words with sentences.",
                  isActive: _onlyWithSentences,
                  onChanged: _toggleSentenceFilter,
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// CEFR LEVEL SELECTION CHIP
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
        height: 50,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.2)
                  : const Color(0xFF252538),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFF45455D),
            width: 2,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Center(
          child: Text(
            level,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primaryColor : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

// QUICK ACTION CONTROL BUTTON
class _SmallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SmallControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// HORIZONTAL PAIR OF LEVEL CHIPS
class _LevelRow extends StatelessWidget {
  final List<String> levels;
  final Set<String> selected;
  final Function(String) onToggle;

  const _LevelRow({
    required this.levels,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LevelChip(
            level: levels[0],
            isSelected: selected.contains(levels[0]),
            onTap: () => onToggle(levels[0]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _LevelChip(
            level: levels[1],
            isSelected: selected.contains(levels[1]),
            onTap: () => onToggle(levels[1]),
          ),
        ),
      ],
    );
  }
}

// SETTINGS TOGGLE CARD WIDGET
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onChanged,
    this.activeColor = AppTheme.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              isActive
                  ? LinearGradient(
                    colors: [
                      const Color(0xFF1E1E2E),
                      activeColor.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeColor : const Color(0x20FFFFFF),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.15 : 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? activeColor.withValues(alpha: 0.2)
                        : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : Colors.white54,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isActive
                              ? const Color(0xFFBBBBBB)
                              : const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? activeColor : const Color(0xFF666666),
                  width: 2,
                ),
              ),
              child:
                  isActive
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
