import 'package:flutter/widgets.dart';

import '../app/motion.dart';

/// Sichtbare Rückmeldung beim Drücken: Das Kind schrumpft auf 97 % sobald
/// der Finger aufsetzt (nicht erst beim Loslassen) und federt in 120 ms mit
/// Ease-out zurück. Mit "Reduce Motion" wird statt dessen nur die Deckkraft
/// gesenkt.
///
/// Rein visuell: Die Taste selbst (InkWell, Button) liegt im [child] und
/// behält ihre Gesten und Semantik. Ein Ziehen von mehr als zehn Pixeln
/// (Scrollen) hebt den gedrückten Zustand wieder auf.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = Motion.pressScale,
  });

  final Widget child;
  final bool enabled;

  /// Zielgröße im gedrückten Zustand.
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  static const double _slop = 10;

  bool _pressed = false;
  Offset? _downPosition;

  void _set(bool pressed) {
    if (_pressed == pressed || !mounted) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final pressed = _pressed && widget.enabled;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _downPosition = event.position;
        _set(true);
      },
      onPointerMove: (event) {
        final start = _downPosition;
        if (start != null && (event.position - start).distance > _slop) {
          _set(false);
        }
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: reduced
          ? AnimatedOpacity(
              opacity: pressed ? 0.7 : 1,
              duration: Motion.press,
              curve: Motion.easeOut,
              child: widget.child,
            )
          : AnimatedScale(
              scale: pressed ? widget.scale : 1,
              duration: Motion.press,
              curve: Motion.easeOut,
              child: widget.child,
            ),
    );
  }
}
