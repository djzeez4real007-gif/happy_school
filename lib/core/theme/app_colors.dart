import 'package:flutter/material.dart';

/// Theme-aware colors — use these instead of hardcoded
/// Color(0xFFF5F7FB) / Colors.white so dark mode works.
class AppColors {
  AppColors._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffold(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB);

  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : Colors.white;

  static Color cardBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF0F172A);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? Colors.white70 : const Color(0xFF6B7280);

  static Color textMuted(BuildContext context) =>
      isDark(context) ? Colors.white54 : const Color(0xFF9CA3AF);

  static Color fieldFill(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

  static Color divider(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

  static Color primary = const Color(0xFF1D4ED8);
  static Color primarySoft(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
}
