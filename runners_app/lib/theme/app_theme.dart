import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const teal = Color(0xFF0E7C74);
  static const tealDeep = Color(0xFF0B6A63);
  static const copper = Color(0xFFC4622A);
  static const ink = Color(0xFF14241F);
  static const muted = Color(0xFF66736E);
  static const mist = Color(0xFFF3F6F4);
  static const field = Color(0xFFEEF3F1);
  static const line = Color(0xFFE3EAE6);
  static const white = Color(0xFFFFFFFF);

  static const Color pine = teal;
  static const Color amber = copper;
  static const Color cream = white;
  static const Color paper = white;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      primary: teal,
      onPrimary: white,
      secondary: copper,
      onSecondary: white,
      surface: white,
      error: const Color(0xFFC2413B),
    );
    const shape = StadiumBorder();
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: white,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1.05,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.35, color: muted),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: white,
          minimumSize: const Size.fromHeight(56),
          shape: shape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: teal,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: teal, width: 1.4),
          shape: shape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: const TextStyle(color: Color(0xFF8A9691), fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal, width: 1.4),
        ),
      ),
      cardTheme: const CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
