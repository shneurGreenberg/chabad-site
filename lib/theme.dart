import 'package:flutter/material.dart';

import 'models.dart';

/// Coordinated site palettes. Some are dark-mode.
class SitePalette {
  const SitePalette({
    required this.id,
    required this.name,
    required this.isDark,
    required this.primary,
    required this.primaryDark,
    required this.primaryMid,
    required this.accent,
    required this.accentSoft,
    required this.surface,
    required this.card,
    required this.ink,
    required this.muted,
    required this.onPrimary,
    required this.onAccent,
  });

  final String id;
  final Loc name;
  final bool isDark;
  final Color primary;
  final Color primaryDark;
  final Color primaryMid;
  final Color accent;
  final Color accentSoft;
  final Color surface;
  final Color card;
  final Color ink;
  final Color muted;
  final Color onPrimary;
  final Color onAccent;

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primaryMid, primary],
      );

  LinearGradient get goldGradient => LinearGradient(
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.centerEnd,
        colors: [
          Color.lerp(accent, Colors.black, 0.18)!,
          accentSoft,
          accent,
        ],
      );

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: (isDark ? Colors.black : primaryDark)
              .withValues(alpha: isDark ? 0.45 : 0.07),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

class SitePalettes {
  static const classic = SitePalette(
    id: 'classic',
    name: {'he': 'קלאסי — צי וזהב', 'en': 'Classic navy & gold', 'ru': 'Классика: синий и золото'},
    isDark: false,
    primary: Color(0xFF132A5C),
    primaryDark: Color(0xFF0B1C3A),
    primaryMid: Color(0xFF1E3F7A),
    accent: Color(0xFFC9A227),
    accentSoft: Color(0xFFE8D48A),
    surface: Color(0xFFF6F1E8),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF12203A),
    muted: Color(0xFF5C6578),
    onPrimary: Color(0xFFFFFFFF),
    onAccent: Color(0xFF0B1C3A),
  );

  static const olive = SitePalette(
    id: 'olive',
    name: {'he': 'זית וזהב', 'en': 'Olive & gold', 'ru': 'Олива и золото'},
    isDark: false,
    primary: Color(0xFF3D4A2C),
    primaryDark: Color(0xFF242C1A),
    primaryMid: Color(0xFF5A6B3E),
    accent: Color(0xFFC4A35A),
    accentSoft: Color(0xFFE6D5A3),
    surface: Color(0xFFF4F0E4),
    card: Color(0xFFFFFDF7),
    ink: Color(0xFF1F2418),
    muted: Color(0xFF5E6654),
    onPrimary: Color(0xFFF8F4E8),
    onAccent: Color(0xFF242C1A),
  );

  static const wine = SitePalette(
    id: 'wine',
    name: {'he': 'יין ושמפניה', 'en': 'Wine & champagne', 'ru': 'Вино и шампань'},
    isDark: false,
    primary: Color(0xFF6B1D2A),
    primaryDark: Color(0xFF3F1018),
    primaryMid: Color(0xFF8B2E3C),
    accent: Color(0xFFD4B483),
    accentSoft: Color(0xFFF0DEC0),
    surface: Color(0xFFF8F1EA),
    card: Color(0xFFFFFCF8),
    ink: Color(0xFF2A1216),
    muted: Color(0xFF6E5860),
    onPrimary: Color(0xFFFFF8F2),
    onAccent: Color(0xFF3F1018),
  );

  static const sea = SitePalette(
    id: 'sea',
    name: {'he': 'ים וחול', 'en': 'Sea & sand', 'ru': 'Море и песок'},
    isDark: false,
    primary: Color(0xFF0F4C5C),
    primaryDark: Color(0xFF083038),
    primaryMid: Color(0xFF1A6A7A),
    accent: Color(0xFFD4A017),
    accentSoft: Color(0xFFE8D48A),
    surface: Color(0xFFF3EEE3),
    card: Color(0xFFFFFDF8),
    ink: Color(0xFF123038),
    muted: Color(0xFF5A6B70),
    onPrimary: Color(0xFFFFFFFF),
    onAccent: Color(0xFF083038),
  );

  static const midnight = SitePalette(
    id: 'midnight',
    name: {'he': 'חצות — מצב כהה', 'en': 'Midnight (dark)', 'ru': 'Полночь (тёмная)'},
    isDark: true,
    primary: Color(0xFF9BB4E0),
    primaryDark: Color(0xFF070E1C),
    primaryMid: Color(0xFF152448),
    accent: Color(0xFFE0B84A),
    accentSoft: Color(0xFFF0D78A),
    surface: Color(0xFF0C1428),
    card: Color(0xFF152038),
    ink: Color(0xFFF3EDE0),
    muted: Color(0xFFA8B0C4),
    onPrimary: Color(0xFF0B1C3A),
    onAccent: Color(0xFF0B1C3A),
  );

  static const onyx = SitePalette(
    id: 'onyx',
    name: {'he': 'אוניקס — מצב כהה', 'en': 'Onyx (dark)', 'ru': 'Оникс (тёмная)'},
    isDark: true,
    primary: Color(0xFFE2C36D),
    primaryDark: Color(0xFF0A0A0C),
    primaryMid: Color(0xFF1C1C22),
    accent: Color(0xFFD4A017),
    accentSoft: Color(0xFFE8D48A),
    surface: Color(0xFF121214),
    card: Color(0xFF1C1C21),
    ink: Color(0xFFF4EFE4),
    muted: Color(0xFFB0AAA0),
    onPrimary: Color(0xFF121214),
    onAccent: Color(0xFF121214),
  );

  static const forestNight = SitePalette(
    id: 'forestNight',
    name: {'he': 'יער בלילה — מצב כהה', 'en': 'Forest night (dark)', 'ru': 'Ночной лес (тёмная)'},
    isDark: true,
    primary: Color(0xFFC9B07A),
    primaryDark: Color(0xFF0E140C),
    primaryMid: Color(0xFF1C2A18),
    accent: Color(0xFFC4A35A),
    accentSoft: Color(0xFFE6D5A3),
    surface: Color(0xFF121A10),
    card: Color(0xFF1A2418),
    ink: Color(0xFFF3EEDC),
    muted: Color(0xFFB5B8A8),
    onPrimary: Color(0xFF121A10),
    onAccent: Color(0xFF121A10),
  );

  static const List<SitePalette> all = [
    classic,
    olive,
    wine,
    sea,
    midnight,
    onyx,
    forestNight,
  ];

  static SitePalette byId(String? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return classic;
  }
}

/// Active palette tokens. Bound from [MaterialApp] when the admin picks a look.
class AppColors {
  static SitePalette _p = SitePalettes.classic;

  static SitePalette get palette => _p;
  static void bind(SitePalette p) => _p = p;

  static Color get primary => _p.primary;
  static Color get primaryDark => _p.primaryDark;
  static Color get primaryMid => _p.primaryMid;
  static Color get accent => _p.accent;
  static Color get gold => _p.accent;
  static Color get accentSoft => _p.accentSoft;
  static Color get surface => _p.surface;
  static Color get card => _p.card;
  static Color get ink => _p.ink;
  static Color get muted => _p.muted;
  static Color get onPrimary => _p.onPrimary;
  static Color get onAccent => _p.onAccent;
  static bool get isDark => _p.isDark;

  static LinearGradient get heroGradient => _p.heroGradient;
  static LinearGradient get goldGradient => _p.goldGradient;
  static List<BoxShadow> get cardShadow => _p.cardShadow;
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

ThemeData buildAppTheme([SitePalette? palette]) {
  final p = palette ?? AppColors.palette;
  AppColors.bind(p);
  final brightness = p.isDark ? Brightness.dark : Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: brightness,
    primary: p.primary,
    secondary: p.accent,
    surface: p.card,
    onSurface: p.ink,
    onSurfaceVariant: p.muted,
    onPrimary: p.onPrimary,
    outline: p.muted,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.surface,
    fontFamily: 'Heebo',
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: p.card,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: p.card,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.ink.withValues(alpha: p.isDark ? 0.12 : 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: p.primaryDark,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ).copyWith(
        overlayColor: _goldOverlay(),
        mouseCursor: _clickCursor,
        elevation: _hoverElevation(),
        shadowColor: WidgetStatePropertyAll(p.accent.withValues(alpha: 0.35)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ).copyWith(
        overlayColor: _goldOverlay(),
        mouseCursor: _clickCursor,
        elevation: _hoverElevation(rest: 1, hover: 4),
        shadowColor: WidgetStatePropertyAll(p.accent.withValues(alpha: 0.35)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        side: BorderSide(color: p.primary, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ).copyWith(
        overlayColor: _goldOverlay(),
        mouseCursor: _clickCursor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
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
    iconTheme: IconThemeData(color: p.ink),
    listTileTheme: ListTileThemeData(
      mouseCursor: WidgetStateMouseCursor.clickable,
      iconColor: p.primary,
      textColor: p.ink,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      side: BorderSide(color: p.ink.withValues(alpha: 0.08)),
      selectedColor: p.accent.withValues(alpha: 0.22),
      backgroundColor: p.card,
      labelStyle: TextStyle(color: p.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.isDark ? p.primaryMid.withValues(alpha: 0.35) : p.card,
      hintStyle: TextStyle(color: p.muted),
      labelStyle: TextStyle(color: p.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.ink.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.ink.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.primary, width: 1.6),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: p.ink,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: p.ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: p.ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(color: p.ink),
      titleSmall: base.textTheme.titleSmall?.copyWith(color: p.ink),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: p.ink),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(color: p.ink),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: p.muted),
      labelLarge: base.textTheme.labelLarge?.copyWith(color: p.ink),
      labelMedium: base.textTheme.labelMedium?.copyWith(color: p.muted),
      labelSmall: base.textTheme.labelSmall?.copyWith(color: p.muted),
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
