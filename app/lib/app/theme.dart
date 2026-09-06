import 'package:flutter/material.dart';

/// Warmer, gedeckter Ausgangston (Lehm). Material 3 leitet daraus ein
/// kontrastsicheres Schema für hell und dunkel ab (Text mindestens 4,5:1).
const Color _seedColor = Color(0xFF9C6B4A);

/// Baut das Thema für die gewünschte Helligkeit.
///
/// Absichten: wenig Reize (keine kräftigen Akzente, flache Flächen),
/// Touch-Ziele mindestens 48 dp ([MaterialTapTargetSize.padded],
/// [VisualDensity.standard] auch auf Desktop), keine feste Schriftgröße.
ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      height: 72,
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
