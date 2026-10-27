import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';

import '../features/rueckblick/prompts.dart';
import '../l10n/app_localizations.dart';

/// Widget-Key für Tests.
const Key moodDotsKey = Key('mood-dots');

/// Stimmungsverlauf als sieben Punkte, ohne Diagramm-Abhängigkeit (D17).
/// Ein Punkt je Tag auf fünf Stufen; fehlende Tage bleiben leer, aufeinander
/// folgende Punkte sind durch eine leise Linie verbunden. Der Screenreader
/// hört die Werte als Wörter.
class MoodDots extends StatelessWidget {
  const MoodDots({super.key, required this.days, required this.moods});

  /// Die sieben Tage (älteste zuerst).
  final List<LocalDay> days;

  /// Stimmung 1 bis 5 je Tag oder `null`.
  final List<int?> moods;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final values = [
      for (var i = 0; i < days.length; i++)
        '${materialL10n.formatShortDate(days[i].startOfDay)}: '
            '${moods[i] == null ? l10n.moodDotMissing : PromptTexts.mood(l10n, moods[i]!)}',
    ].join(', ');
    return Semantics(
      label: l10n.moodDotsSemantics(values),
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              key: moodDotsKey,
              height: 96,
              child: CustomPaint(
                size: const Size(double.infinity, 96),
                painter: _MoodDotsPainter(
                  moods: moods,
                  dot: scheme.primary,
                  line: scheme.outlineVariant,
                  grid: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: Text(
                      materialL10n.narrowWeekdays[day.startOfDay.weekday % 7],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodDotsPainter extends CustomPainter {
  const _MoodDotsPainter({
    required this.moods,
    required this.dot,
    required this.line,
    required this.grid,
  });

  final List<int?> moods;
  final Color dot;
  final Color line;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (moods.isEmpty) return;
    const padding = 8.0;
    final slot = size.width / moods.length;
    final usable = size.height - 2 * padding;
    double y(int mood) =>
        padding + usable * (MoodScale.max - mood) / (MoodScale.max - 1);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var m = MoodScale.min; m <= MoodScale.max; m++) {
      canvas.drawLine(Offset(0, y(m)), Offset(size.width, y(m)), gridPaint);
    }
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = dot;
    Offset? previous;
    for (var i = 0; i < moods.length; i++) {
      final mood = moods[i];
      if (mood == null) {
        previous = null;
        continue;
      }
      final p = Offset(slot * i + slot / 2, y(mood));
      if (previous != null) canvas.drawLine(previous, p, linePaint);
      previous = p;
    }
    for (var i = 0; i < moods.length; i++) {
      final mood = moods[i];
      if (mood == null) continue;
      canvas.drawCircle(Offset(slot * i + slot / 2, y(mood)), 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MoodDotsPainter old) =>
      old.moods != moods ||
      old.dot != dot ||
      old.line != line ||
      old.grid != grid;
}
