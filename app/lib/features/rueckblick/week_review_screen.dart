import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_view.dart';
import '../../data/goals_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/mood_dots.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import '../bewegung/movement_texts.dart';

/// Wochenrückblick (D17, D8, D19, D24): die letzten sieben Tage als
/// schlichte Liste der Antworten auf "gut gelaufen" und "gelernt", die
/// erledigten Schritte, der Stimmungsverlauf als sieben Punkte, "Wege diese
/// Woche" (je Weg die erledigten Etappen) und "Bewegung" (Pausen je Tag als
/// Punkte und die Übungen). Keine Zähler als Soll, keine Wertung, keine KI.
class WeekReviewScreen extends ConsumerWidget {
  const WeekReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final week = ref.watch(weekReviewProvider);
    final weekGoals = ref.watch(weekGoalsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weekTitle)),
      body: SafeArea(
        child: switch (week) {
          AsyncData(value: final days) => _WeekBody(
            days: days,
            goals: weekGoals,
          ),
          AsyncError() => Center(child: Text(l10n.startError)),
          _ => Center(
            child: Semantics(
              label: l10n.loadingLabel,
              child: const CircularProgressIndicator(),
            ),
          ),
        },
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

class _WeekBody extends StatelessWidget {
  const _WeekBody({required this.days, required this.goals});

  final List<WeekDay> days;

  /// Je Weg die in dieser Woche erledigten Etappen (D19).
  final List<(Goal, List<Milestone>)> goals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final anyMood = days.any((d) => d.mood != null);
    final good = [
      for (final d in days)
        for (final t in d.good) (d.day, t),
    ];
    final lesson = [
      for (final d in days)
        for (final t in d.lesson) (d.day, t),
    ];
    final steps = [
      for (final d in days)
        if (d.stepDone != null) (d.day, d.stepDone!),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Reveal(index: 0, child: Text(l10n.weekIntro, style: muted)),
        const SizedBox(height: 24),
        Reveal(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.weekMoodHeading, style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              if (anyMood)
                SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  child: MoodDots(
                    days: [for (final d in days) d.day],
                    moods: [for (final d in days) d.mood],
                  ),
                )
              else
                Text(l10n.weekMoodEmpty, style: muted),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Reveal(
          index: 2,
          child: _Section(
            title: l10n.weekGoodHeading,
            icon: Icons.wb_sunny_outlined,
            items: good,
            format: materialL10n.formatMediumDate,
          ),
        ),
        Reveal(
          index: 3,
          child: _Section(
            title: l10n.weekLessonHeading,
            icon: Icons.lightbulb_outline,
            items: lesson,
            format: materialL10n.formatMediumDate,
          ),
        ),
        Reveal(
          index: 4,
          child: _Section(
            title: l10n.weekStepsHeading,
            icon: Icons.check_circle_outline,
            items: steps,
            format: materialL10n.formatMediumDate,
          ),
        ),
        Reveal(
          index: 5,
          child: _GoalsSection(
            goals: goals,
            format: materialL10n.formatMediumDate,
          ),
        ),
        Reveal(
          index: 6,
          child: _MovementSection(
            days: days,
            format: materialL10n.formatMediumDate,
          ),
        ),
      ],
    );
  }
}

/// "Bewegung" (D24): je Tag die Zahl der notierten Pausen als kleine Punkte
/// (schlichte Zählung wie die Stimmungspunkte, kein Soll) und darunter die
/// Übungen mit Datum. Ohne Bewegung in der Woche nur die leise Leerzeile.
class _MovementSection extends StatelessWidget {
  const _MovementSection({required this.days, required this.format});

  final List<WeekDay> days;
  final String Function(DateTime) format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final materialL10n = MaterialLocalizations.of(context);
    final any = days.any((d) => d.movement.isNotEmpty);
    final values = [
      for (final d in days)
        '${materialL10n.formatShortDate(d.day.startOfDay)}: '
            '${l10n.weekMovementCount(d.movement.length)}',
    ].join(', ');
    return Column(
      key: const Key('week-movement'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.directions_walk, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(l10n.weekMovementHeading, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        if (!any)
          Text(
            l10n.weekSectionEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else ...[
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            child: Semantics(
              label: l10n.weekMovementDotsSemantics(values),
              child: ExcludeSemantics(
                child: Row(
                  key: const Key('week-movement-dots'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in days)
                      Expanded(
                        child: Column(
                          children: [
                            for (var i = 0; i < d.movement.length && i < 4; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (d.movement.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: scheme.outlineVariant,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              MovementTexts.weekdayShort(
                                locale,
                                d.day.startOfDay.weekday,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final d in days)
            for (final text in d.movement)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      format(d.day.startOfDay),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// "Wege diese Woche": je Weg die erledigten Etappen mit Datum, ohne Zähler.
class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goals, required this.format});

  final List<(Goal, List<Milestone>)> goals;
  final String Function(DateTime) format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      key: const Key('week-goals'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.route_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(l10n.weekGoalsHeading, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        if (goals.isEmpty)
          Text(
            l10n.weekSectionEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final (goal, milestones) in goals)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, style: theme.textTheme.titleSmall),
                  for (final m in milestones)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            format(m.doneAt!),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.items,
    required this.format,
  });

  final String title;
  final IconData icon;
  final List<(LocalDay, String)> items;
  final String Function(DateTime) format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            l10n.weekSectionEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final (day, text) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format(day.startOfDay),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    text.isEmpty ? l10n.stepCardDone : text,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 24),
      ],
    );
  }
}
