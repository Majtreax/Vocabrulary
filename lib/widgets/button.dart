import 'package:flutter/material.dart';
import '../services/tts.dart';

// BOTTOM NAVIGATION BAR BUTTON
class NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isSuccess;
  final bool isWarning;
  final Color? customBgColor;
  final Color? customFgColor;

  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    this.isSuccess = false,
    this.isWarning = false,
    this.customBgColor,
    this.customFgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    final bgColor =
        isDisabled
            ? const Color(0xFF2A2A2A)
            : customBgColor ??
                (isWarning
                    ? const Color(0xFFFF6B81)
                    : isSuccess
                    ? const Color(0xFF03DAC6)
                    : isPrimary
                    ? const Color(0xFFBB86FC)
                    : const Color(0xFF1E1E1E));

    final fgColor =
        isDisabled
            ? const Color(0xFF666666)
            : customFgColor ??
                (isWarning || isSuccess || isPrimary
                    ? Colors.black
                    : Colors.white);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              !isDisabled
                  ? [
                    BoxShadow(
                      color: bgColor.withValues(
                        alpha: isSuccess || isPrimary ? 0.3 : 0,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: fgColor),
                const SizedBox(width: 8),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
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

// OUTLINED GLASS ACTION BUTTON
class GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const GlassActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
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

// TEXT TO SPEECH PRONUNCIATION BUTTON
class ListenButton extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;

  const ListenButton({
    super.key,
    required this.text,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? const Color(0xFF03DAC6);

    return IconButton(
      onPressed: () => TtsService.speak(text),
      icon: Icon(Icons.volume_up_rounded, size: size, color: iconColor),
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      splashRadius: 18,
    );
  }
}
