import 'package:flutter/material.dart';

import 'pressable.dart';

/// Karte als weiche Fläche statt Rahmen: hell mit zwei halbtransparenten
/// Schatten (einem weiten, einem engen), dunkel mit einer Haarlinie, weil
/// Schatten auf dunklem Grund verschwinden. Ecken 20 Pixel, kein Oberflächen-
/// Tint. Mit [onTap] wird die Karte drückbar: Ink im Material plus
/// Verkleinerung über [Pressable].
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;

  /// Hintergrund; ohne Angabe die ruhige Containerfläche des Schemas.
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Zusätzliche Beschreibung für den Screenreader (z. B. "Eintrag öffnen"),
  /// wenn die Karte als Ganzes tippbar ist; die Texte der Karte werden
  /// ohnehin mitgelesen.
  final String? semanticLabel;

  static const double radius = 20;

  /// Form der Karte (auch für Ink-Begrenzung und Fokusrahmen).
  static final ShapeBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
  );

  /// Schatten für helle Flächen: weit und leise plus eng und etwas dichter.
  static List<BoxShadow> shadows(ColorScheme scheme) => [
    BoxShadow(
      color: scheme.shadow.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: scheme.shadow.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = color ?? scheme.surfaceContainerLow;
    final decoration = BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      border: dark
          ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45))
          : null,
      boxShadow: dark ? null : shadows(scheme),
    );
    Widget content = Padding(padding: padding, child: child);
    final tap = onTap;
    // Immer ein durchsichtiges Material in der Karte: Ink von ListTiles und
    // der Karte selbst zeichnet darauf, nicht hinter der Fläche.
    content = Material(
      type: MaterialType.transparency,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: tap == null ? content : InkWell(onTap: tap, child: content),
    );
    Widget card = DecoratedBox(decoration: decoration, child: content);
    if (tap != null) {
      // Ein Semantik-Knoten für die ganze Karte: Texte, optionale
      // Beschreibung und die Tipp-Aktion zusammen (wie bei ListTile).
      card = MergeSemantics(
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: Pressable(child: card),
        ),
      );
    }
    return card;
  }
}
