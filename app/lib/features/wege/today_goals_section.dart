import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/goals_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/surface_card.dart';

/// Widget-Keys für Tests.
const Key todayGoalsSectionKey = Key('today-goals');
const Key todayGoalsAllKey = Key('today-goals-all');
const Key todayGoalsNewKey = Key('today-goals-new');

/// Key der Zeile eines Wegs auf "Heute".
Key todayGoalKey(String goalId) => Key('today-goal-$goalId');

/// Abschnitt "Deine Wege" auf "Heute" (D19): je aktiver Weg eine kompakte
/// Zeile (Titel, "3 von 7"), Tipp öffnet die Details; ohne Wege nur eine
/// leise Zeile mit Taste, damit "Heute" ohne Wege kaum länger wird. Während
/// des Ladens erscheint nichts, damit nichts springt.
class TodayGoalsSection extends ConsumerWidget {
  const TodayGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(activeGoalsProvider).value;
    if (goals == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (goals.isEmpty) {
      // Leiser Hinweis in einer Zeile: kein Zähler, keine Mahnung.
      return Padding(
        key: todayGoalsSectionKey,
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(
              Icons.route_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.todayGoalsEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              key: todayGoalsNewKey,
              onPressed: () => AppRoutes.openGoals(context),
              child: Text(l10n.goalsNew),
            ),
          ],
        ),
      );
    }
    return Padding(
      key: todayGoalsSectionKey,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.todayGoalsHeading,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                key: todayGoalsAllKey,
                onPressed: () => AppRoutes.openGoals(context),
                child: Text(l10n.todayGoalsAll),
              ),
            ],
          ),
          for (final view in goals)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SurfaceCard(
                key: todayGoalKey(view.id),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                onTap: () => AppRoutes.openGoal(context, view.id),
                child: Row(
                  children: [
                    Icon(Icons.route_outlined, size: 20, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        view.goal.title,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      view.progress.total == 0
                          ? l10n.goalNoMilestones
                          : l10n.goalProgressShort(
                              view.progress.done,
                              view.progress.total,
                            ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
