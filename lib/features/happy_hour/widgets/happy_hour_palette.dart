import 'package:flutter/material.dart';

class HappyHourPalette {
  const HappyHourPalette._();

  static const Color accent = Color(0xFFEC221F);
  static const Color subtitle = Color(0xFFE5A000);
  static const Color timer = Color(0xFF2A2A2A);
  static const Color cardBg = Color(0xFFFEE9E7);

  static Color card(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Color.alphaBlend(accent.withValues(alpha: 0.14), Theme.of(context).cardColor)
        : const Color(0xFFFDEAE4);
  }

  /// The milestone banner keeps the campaign's original amber instead of the red the
  /// home banner and offer sheet moved to: it reads as a progress meter rather than an
  /// alert, and the warm ground stops it competing with the cart button it caps.
  static const Color milestoneAccent = Color(0xFFB5731A);

  static Color milestoneCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Color.alphaBlend(milestoneAccent.withValues(alpha: 0.14), Theme.of(context).cardColor)
        : const Color(0xFFFBEFD1);
  }

  /// The unfilled part of the milestone progress bar.
  static Color milestoneTrack(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFFEF9E9);
  }

  static Color track(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withValues(alpha: 0.15) : Color.alphaBlend(accent.withValues(alpha: 0.14), Theme.of(context).cardColor);
  }
}
