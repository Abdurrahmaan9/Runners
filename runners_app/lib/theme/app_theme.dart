import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF1C1712);
  static const cream = Color(0xFFF3EEE4);
  static const paper = Color(0xFFFFFBF5);
  static const amber = Color(0xFFC47B16);
  static const pine = Color(0xFF1E6B43);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: pine,
      primary: ink,
      onPrimary: cream,
      secondary: amber,
      onSecondary: ink,
      surface: cream,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        foregroundColor: cream,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: paper,
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        color: paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
