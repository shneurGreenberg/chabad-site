import 'package:flutter/material.dart';

/// Central palette — deep navy, warm gold, cream paper.
class AppColors {
  static const Color primary = Color(0xFF132A5C);
  static const Color primaryDark = Color(0xFF0B1C3A);
  static const Color primaryMid = Color(0xFF1E3F7A);
  static const Color accent = Color(0xFFC9A227);
  static const Color gold = accent;
  static const Color accentSoft = Color(0xFFE8D48A);
  static const Color surface = Color(0xFFF6F1E8);
  static const Color ink = Color(0xFF12203A);
  static const Color muted = Color(0xFF5C6578);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1C3A), Color(0xFF16356F), Color(0xFF1E4A8C)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [Color(0xFFB8891A), Color(0xFFE8D48A), Color(0xFFC9A227)],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0B1C3A).withValues(alpha: 0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

WidgetStateProperty<Color?> _goldOverlay() {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) {
      return AppColors.gold.withValues(alpha: 0.28);
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) {
      return AppColors.gold.withValues(alpha: 0.16);
    }
    return null;
  });
}

const _clickCursor = WidgetStatePropertyAll(SystemMouseCursors.click);

WidgetStateProperty<double?> _hoverElevation({double rest = 0, double hover = 3}) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.hovered)) return hover;
    if (states.contains(WidgetState.pressed)) return rest;
    return rest;
  });
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Heebo',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ).copyWith(
        overlayColor: _goldOverlay(),
        mouseCursor: _clickCursor,
        elevation: _hoverElevation(),
        shadowColor: WidgetStatePropertyAll(AppColors.gold.withValues(alpha: 0.35)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ).copyWith(
        overlayColor: _goldOverlay(),
        mouseCursor: _clickCursor,
        elevation: _hoverElevation(rest: 1, hover: 4),
        shadowColor: WidgetStatePropertyAll(AppColors.gold.withValues(alpha: 0.35)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ).copyWith(
        overlayColor: _goldOverlay(),
        mouseCursor: _clickCursor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ).copyWith(
        overlayColor: _goldOverlay(),
        mouseCursor: _clickCursor,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        overlayColor: _goldOverlay(),
        mouseCursor: _clickCursor,
      ),
    ),
    listTileTheme: ListTileThemeData(
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      selectedColor: AppColors.gold.withValues(alpha: 0.22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const InstantPageTransitionsBuilder(),
      },
    ),
  );
}

/// No slide/fade between routes — avoids the jumpy web transition.
class InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
