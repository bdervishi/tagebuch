import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/goals_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import 'goal_editor_sheet.dart';

/// Widget-Keys für Tests.
const Key goalsNewKey = Key('goals-new');
const Key goalsEmptyNewKey = Key('goals-empty-new');

/// Key der Karte eines Wegs auf dem Bildschirm "Wege".
Key goalCardKey(String goalId) => Key('goal-card-$goalId');

/// Bildschirm "Wege" (D19): die aktiven Wege als Karten (Titel, Warum,
/// "3 von 7 Etappen", nächste offene Etappe), darunter ruhig der Abschnitt
/// "Abgeschlossen" mit Datum. Höchstens drei aktive Wege; der Versuch, einen
/// vierten anzulegen, bekommt einen freundlichen Hinweis. Kein Zähler, keine
/// Frist, kein Konfetti.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final canCreate = await ref.read(canCreateGoalProvider.future);
    if (!context.mounted) return;
    if (!canCreate) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.goalsLimitReached)));
      return;
    }
    await showGoalEditorSheet(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = ref.watch(activeGoalsProvider);
    final archived = ref.watch(archivedGoalsProvider).value ?? const [];
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalsTitle),
        actions: [
          IconButton(
            key: goalsNewKey,
            tooltip: l10n.goalsNew,
            icon: const Icon(Icons.add),
            onPressed: () => _create(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (active) {
          AsyncData(value: final goals) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Reveal(index: 0, child: Text(l10n.goalsIntro, style: muted)),
              const SizedBox(height: 20),
              if (goals.isEmpty)
                Reveal(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.goalsEmpty, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: goalsEmptyNewKey,
                        onPressed: () => _create(context, ref),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.goalsNew),
                      ),
                    ],
                  ),
                ),
              for (final (i, view) in goals.indexed)
                Reveal(
                  index: 1 + i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalCard(view: view),
                  ),
                ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 20),
                Reveal(
                  index: 1 + goals.length,
                  child: Text(
                    l10n.goalsArchivedHeading,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (final (i, view) in archived.indexed)
                  Reveal(
                    index: 2 + goals.length + i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ArchivedCard(view: view),
                    ),
                  ),
              ],
            ],
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
    );
  }
}

/// Ein aktiver Weg: Titel, Warum, Fortschritt als "3 von 7 Etappen" und die
/// nächste offene Etappe.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.view});

  final GoalView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = view.progress;
    final next = view.nextOpen;
    final why = view.goal.why;
    return SurfaceCard(
      key: goalCardKey(view.id),
      onTap: () => AppRoutes.openGoal(context, view.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(view.goal.title, style: theme.textTheme.titleMedium),
          if (why != null) ...[
            const SizedBox(height: 4),
            Text(
              why,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.route_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                progress.total == 0
                    ? l10n.goalNoMilestones
                    : l10n.goalProgress(progress.done, progress.total),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          if (progress.total > 0) ...[
            const SizedBox(height: 4),
            Text(
              next == null
                  ? l10n.goalAllDone
                  : l10n.goalNextMilestone(next.title),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ein abgeschlossener oder zur Seite gelegter Weg mit Datum.
class _ArchivedCard extends StatelessWidget {
  const _ArchivedCard({required this.view});

  final GoalView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = view.goal;
    final date = materialL10n.formatMediumDate(goal.closedAt!);
    final progress = view.progress;
    return SurfaceCard(
      key: goalCardKey(goal.id),
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => AppRoutes.openGoal(context, goal.id),
      child: Row(
        children: [
          Icon(
            goal.completedAt != null
                ? Icons.check_circle_outline
                : Icons.inventory_2_outlined,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: theme.textTheme.bodyLarge),
                Text(
                  goal.completedAt != null
                      ? l10n.goalCompletedOn(date)
                      : l10n.goalArchivedOn(date),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (progress.total > 0)
            Text(
              l10n.goalProgressShort(progress.done, progress.total),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
