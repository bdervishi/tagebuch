import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'motion.dart';

/// Warmer, gedeckter Ausgangston (Lehm). Material 3 leitet daraus ein
/// kontrastsicheres Schema für hell und dunkel ab (Text mindestens 4,5:1).
const Color _seedColor = Color(0xFF9C6B4A);

/// Radius der Bedienelemente (Tasten, Felder); Karten nutzen 20.
const double _controlRadius = 14;

/// Baut das Thema für die gewünschte Helligkeit (docs/12-gestaltung.md).
///
/// Absichten: wenig Reize (keine kräftigen Akzente, flache Flächen ohne
/// Oberflächen-Tint), Tiefe über halbtransparente Schatten statt Rahmen,
/// Schrift mit größenabhängiger Laufweite (eng bei großen Graden, neutral im
/// Fließtext), Touch-Ziele mindestens 48 dp ([MaterialTapTargetSize.padded],
/// [VisualDensity.standard] auch auf Desktop), keine feste Schriftgröße.
/// Routen wechseln mit der plattformüblichen Bewegung: iOS schiebt, sonst
/// blendet Material 3 nach vorn.
ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
  );
  final base = ThemeData(
    // Gebündelte Schrift, damit auf dem Web nichts von einem CDN nachgeladen wird (D16).
    fontFamily: 'Inter',
    colorScheme: scheme,
    brightness: brightness,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
  final text = _tuneTypography(base.textTheme);
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_controlRadius),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_controlRadius),
    borderSide: BorderSide.none,
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: controlShape,
        minimumSize: const Size(64, 52),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        animationDuration: Motion.press,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: controlShape,
        minimumSize: const Size(64, 52),
        side: BorderSide(color: scheme.outlineVariant),
        animationDuration: Motion.press,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: controlShape,
        animationDuration: Motion.press,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: controlShape,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      backgroundColor: scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
    ),
    // year2023: false schaltet auf das aktuelle Material-3-Aussehen (runde
    // Enden, Lücke); das Flag ist der vorgesehene Weg, solange es Standard wird.
    // ignore: deprecated_member_use
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      // ignore: deprecated_member_use
      year2023: false,
      strokeCap: StrokeCap.round,
    ),
    // ignore: deprecated_member_use
    sliderTheme: const SliderThemeData(year2023: false),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Icon(Icons.check, size: 16)
            : null,
      ),
    ),
  );
}

/// Laufweite und Zeilenhöhe je Größe: große Grade enger (Buchstaben wirken
/// mit wachsender Größe zu weit), Fließtext neutral mit bequemer Zeilenhöhe,
/// Beschriftungen leicht gesperrt. Gewicht statt Größe für Hierarchie.
TextTheme _tuneTypography(TextTheme t) {
  return t.copyWith(
    displayLarge: t.displayLarge?.copyWith(
      letterSpacing: -1.5,
      fontWeight: FontWeight.w300,
      height: 1.05,
    ),
    displayMedium: t.displayMedium?.copyWith(letterSpacing: -1.0, height: 1.1),
    displaySmall: t.displaySmall?.copyWith(letterSpacing: -0.6, height: 1.1),
    headlineLarge: t.headlineLarge?.copyWith(
      letterSpacing: -0.5,
      fontWeight: FontWeight.w600,
      height: 1.15,
    ),
    headlineMedium: t.headlineMedium?.copyWith(
      letterSpacing: -0.4,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    headlineSmall: t.headlineSmall?.copyWith(
      letterSpacing: -0.3,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    titleLarge: t.titleLarge?.copyWith(
      letterSpacing: -0.2,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: t.titleMedium?.copyWith(
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: t.titleSmall?.copyWith(
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: t.bodyLarge?.copyWith(letterSpacing: 0, height: 1.5),
    bodyMedium: t.bodyMedium?.copyWith(letterSpacing: 0, height: 1.45),
    bodySmall: t.bodySmall?.copyWith(letterSpacing: 0.1, height: 1.4),
    labelLarge: t.labelLarge?.copyWith(letterSpacing: 0.1),
    labelMedium: t.labelMedium?.copyWith(letterSpacing: 0.3),
    labelSmall: t.labelSmall?.copyWith(letterSpacing: 0.4),
  );
}
