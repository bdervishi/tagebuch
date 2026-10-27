import 'package:flutter/material.dart';

import '../app/motion.dart';

/// Pegelanzeige der Aufnahme: Balken aus den letzten Spitzenwerten, neueste
/// rechts. Jeder neue Wert gleitet in 160 ms linear (gleichförmige Bewegung)
/// von der alten zur neuen Höhe, statt zu springen; ältere Balken sind
/// blasser, damit die Richtung lesbar ist. Gezeichnet in einem
/// [CustomPainter] (nur Malen, kein Layout). Mit "Reduce Motion" liefert der
/// Aufrufer keine neuen Werte, die Anzeige steht dann still.
class LevelMeter extends StatefulWidget {
  const LevelMeter({
    super.key,
    required this.levels,
    required this.active,
    this.height = 96,
    this.barWidth = 6,
    this.gap = 6,
  });

  /// Werte 0 bis 1, älteste zuerst.
  final List<double> levels;

  /// Aufnahme läuft (Akzentfarbe) oder pausiert (gedämpft).
  final bool active;
  final double height;
  final double barWidth;
  final double gap;

  @override
  State<LevelMeter> createState() => _LevelMeterState();
}

class _LevelMeterState extends State<LevelMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.quick,
  );
  late List<double> _from = List.of(widget.levels);
  late List<double> _to = List.of(widget.levels);

  @override
  void didUpdateWidget(LevelMeter old) {
    super.didUpdateWidget(old);
    if (!_sameValues(old.levels, widget.levels)) {
      _from = _current();
      _to = List.of(widget.levels);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<double> _current() {
    final t = _controller.value;
    return [
      for (var i = 0; i < _to.length; i++)
        (i < _from.length ? _from[i] : _to[i]) * (1 - t) + _to[i] * t,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.active ? scheme.primary : scheme.outline;
    final width =
        widget.levels.length * (widget.barWidth + widget.gap) - widget.gap;
    return SizedBox(
      height: widget.height,
      width: width,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _LevelPainter(
            levels: _current(),
            color: color,
            barWidth: widget.barWidth,
            gap: widget.gap,
          ),
        ),
      ),
    );
  }
}

class _LevelPainter extends CustomPainter {
  const _LevelPainter({
    required this.levels,
    required this.color,
    required this.barWidth,
    required this.gap,
  });

  final List<double> levels;
  final Color color;
  final double barWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final minHeight = barWidth * 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final radius = Radius.circular(barWidth / 2);
    final center = size.height / 2;
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i].clamp(0.0, 1.0);
      final h = minHeight + (size.height - minHeight) * level;
      final x = i * (barWidth + gap);
      // Ältere Balken (links) blasser: 0,35 bis 1,0.
      final age = levels.length == 1 ? 1.0 : i / (levels.length - 1);
      paint.color = color.withValues(alpha: 0.35 + 0.65 * age);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, center - h / 2, barWidth, h),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelPainter old) =>
      old.color != color ||
      old.barWidth != barWidth ||
      old.gap != gap ||
      !_LevelMeterState._sameValues(old.levels, levels);
}

/// Kleiner Punkt, der während der Aufnahme sanft atmet (Deckkraft 1 auf
/// 0,4 und zurück, 1,2 s, Ease-in-out). Zeigt den Zustand "läuft" neben
/// dem Text an; mit "Reduce Motion" oder in Pause steht er still.
class RecordingDot extends StatefulWidget {
  const RecordingDot({super.key, required this.active, this.size = 10});

  final bool active;
  final double size;

  @override
  State<RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: 0.4,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(RecordingDot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final run = widget.active && !Motion.reduced(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.active ? scheme.primary : scheme.outline,
        ),
      ),
    );
  }
}
