import 'package:flutter/widgets.dart';

import '../app/motion.dart';

/// Blendet sein Kind beim ersten Aufbau ein: Deckkraft 0 auf 1 und acht
/// Pixel von unten nach oben, 220 ms mit kräftigem Ease-out. Mit [index]
/// erscheinen Geschwister gestaffelt (45 ms Versatz), damit eine Liste nicht
/// auf einen Schlag da ist. Mit "Reduce Motion" bleibt nur ein kurzes
/// Aufblenden ohne Ortswechsel.
///
/// Nur Deckkraft und Transformation werden animiert (kein Layout). Die
/// Animation blockiert nichts: Das Kind ist von Anfang an bedienbar.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0});

  final Widget child;

  /// Position in einer Gruppe; bestimmt den Versatz der Staffelung.
  final int index;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    final delay = Motion.stagger * widget.index.clamp(0, 12);
    final total = delay + Motion.enter;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Motion.easeOut),
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = Motion.reduced(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        // Semantik auch bei Deckkraft 0: Der Inhalt ist von Anfang an da.
        final faded = Opacity(
          opacity: t,
          alwaysIncludeSemantics: true,
          child: child,
        );
        if (_reduced || t >= 1) return faded;
        return Transform.translate(
          offset: Offset(0, Motion.enterOffset * (1 - t)),
          child: faded,
        );
      },
    );
  }
}
