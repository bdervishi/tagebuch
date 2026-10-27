import 'package:flutter/material.dart';

import '../app/motion.dart';
import 'pressable.dart';

/// Widget-Key der großen Aufnahmetaste (für Tests).
const Key recordButtonKey = Key('record-button');

/// Die eine große Taste auf "Heute": Kreis in der Akzentfarbe mit zwei
/// leisen Ringen darum und einem farbigen Schatten, der sie von der Fläche
/// abhebt. Deutlich größer als 48 dp. Rückmeldung beim Drücken über
/// [Pressable]; sonst keine Bewegung (die Taste wird jeden Tag gesehen).
class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.icon = Icons.mic,
    this.size = 132,
  });

  final VoidCallback onPressed;
  final String semanticLabel;
  final IconData icon;

  /// Durchmesser des Kerns; die Ringe liegen außen herum.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final outer = size + 56;
    final middle = size + 28;
    // Ein Semantik-Knoten für die ganze Taste: Beschriftung und die
    // Tipp-Aktion des InkWell zusammen (wie bei ListTile).
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Pressable(
          child: SizedBox(
            width: outer,
            height: outer,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _Ring(diameter: outer, color: scheme.primary, alpha: 0.07),
                _Ring(diameter: middle, color: scheme.primary, alpha: 0.12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(
                          alpha: dark ? 0.25 : 0.35,
                        ),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    key: recordButtonKey,
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    animationDuration: Motion.press,
                    child: InkWell(
                      onTap: onPressed,
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: Icon(
                          icon,
                          size: size * 0.44,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.diameter,
    required this.color,
    required this.alpha,
  });

  final double diameter;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: alpha),
          ),
        ),
      ),
    );
  }
}
