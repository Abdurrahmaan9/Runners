import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const teal = Color(0xFF0E7C74);
  static const tealDeep = Color(0xFF0B6A63);
  static const copper = Color(0xFFC4622A);
  static const Color ink = AppColors.lightInk;
  static const Color muted = AppColors.lightMuted;
  static const Color mist = AppColors.lightMist;
  static const Color field = AppColors.lightField;
  static const Color line = AppColors.lightLine;
  static const white = Color(0xFFFFFFFF);

  static const Color pine = teal;
  static const Color amber = copper;
  static const Color cream = white;
  static const Color paper = white;

  static ThemeData get light => _theme(AppColors.light, Brightness.light);

  static ThemeData get dark => _theme(AppColors.dark, Brightness.dark);

  static ThemeData _theme(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: brightness,
      primary: teal,
      onPrimary: white,
      secondary: copper,
      onSecondary: white,
      surface: colors.surface,
      onSurface: colors.ink,
      error: const Color(0xFFC2413B),
    );
    const shape = StadiumBorder();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.surface,
      extensions: [colors],
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1.05,
          fontWeight: FontWeight.w800,
          color: colors.ink,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colors.ink,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.35, color: colors.muted),
        labelLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(color: colors.line, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: teal.withValues(alpha: 0.15),
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
        fillColor: colors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: colors.muted, fontSize: 16),
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
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}

class AppColors extends ThemeExtension<AppColors> {
  const new({
    required this.ink,
    required this.muted,
    required this.mist,
    required this.field,
    required this.line,
    required this.surface,
  });

  static const lightInk = Color(0xFF14241F);
  static const lightMuted = Color(0xFF66736E);
  static const lightMist = Color(0xFFF3F6F4);
  static const lightField = Color(0xFFEEF3F1);
  static const lightLine = Color(0xFFE3EAE6);

  static const light = AppColors(
    ink: lightInk,
    muted: lightMuted,
    mist: lightMist,
    field: lightField,
    line: lightLine,
    surface: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    ink: Color(0xFFF4F7F5),
    muted: Color(0xFFA7B4AF),
    mist: Color(0xFF1C2824),
    field: Color(0xFF24302C),
    line: Color(0xFF31403B),
    surface: Color(0xFF121A17),
  );

  final Color ink;
  final Color muted;
  final Color mist;
  final Color field;
  final Color line;
  final Color surface;

  @override
  AppColors copyWith({
    Color? ink,
    Color? muted,
    Color? mist,
    Color? field,
    Color? line,
    Color? surface,
  }) {
    return AppColors(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      mist: mist ?? this.mist,
      field: field ?? this.field,
      line: line ?? this.line,
      surface: surface ?? this.surface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mist: Color.lerp(mist, other.mist, t)!,
      field: Color.lerp(field, other.field, t)!,
      line: Color.lerp(line, other.line, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
