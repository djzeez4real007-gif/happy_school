import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF1D4ED8);
  static const Color secondaryColor = Color(0xFF3B82F6);

  static const Color lightBg = Color(0xFFF5F7FB);
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkField = Color(0xFF1E293B);

  // ----------------------------------------------------------
  // LIGHT
  // ----------------------------------------------------------
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    canvasColor: lightBg,
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE5E7EB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
      surface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: _inputLight,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ),
    inputDecorationTheme: _inputLight,
    textTheme: GoogleFonts.poppinsTextTheme(),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF475569),
      textColor: Color(0xFF0F172A),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB)),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.transparent;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha: 0.35);
        }
        return Colors.grey.shade300;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF0F172A)),
  );

  // ----------------------------------------------------------
  // DARK
  // ----------------------------------------------------------
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    canvasColor: darkBg,
    cardColor: darkCard,
    dividerColor: darkBorder,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: const Color(0xFF60A5FA),
      secondary: secondaryColor,
      brightness: Brightness.dark,
      surface: darkCard,
      onSurface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: darkCard,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkCard,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: _inputDark,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(darkCard),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ),
    inputDecorationTheme: _inputDark,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white70,
      textColor: Colors.white,
    ),
    dividerTheme: const DividerThemeData(color: darkBorder),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF60A5FA);
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: Colors.white54),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF60A5FA);
        }
        return Colors.grey.shade500;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF60A5FA).withValues(alpha: 0.35);
        }
        return Colors.white24;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF60A5FA),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    primaryIconTheme: const IconThemeData(color: Colors.white),
    drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF020617)),
  );

  static final InputDecorationTheme _inputLight = InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: TextStyle(color: Colors.grey.shade500),
    labelStyle: const TextStyle(color: Color(0xFF64748B)),
    prefixIconColor: primaryColor,
    suffixIconColor: const Color(0xFF64748B),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primaryColor, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
  );

  static final InputDecorationTheme _inputDark = InputDecorationTheme(
    filled: true,
    fillColor: darkField,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(color: Colors.white38),
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIconColor: const Color(0xFF60A5FA),
    suffixIconColor: Colors.white54,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFF87171)),
    ),
  );
}
