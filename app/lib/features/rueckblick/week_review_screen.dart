import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/mood_dots.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';

/// Wochenrückblick (D17, D8): die letzten sieben Tage als schlichte Liste
/// der Antworten auf "gut gelaufen" und "gelernt", die erledigten Schritte
/// und der Stimmungsverlauf als sieben Punkte. Keine Zähler, keine Wertung,
/// keine KI.
class WeekReviewScreen extends ConsumerWidget {
  const WeekReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final week = ref.watch(weekReviewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weekTitle)),
      body: SafeArea(
        child: switch (week) {
          AsyncData(value: final days) => _WeekBody(days: days),
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
  const _WeekBody({required this.days});

  final List<WeekDay> days;

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
