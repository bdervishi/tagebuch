import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/goals_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import 'goal_editor_sheet.dart';

/// Widget-Keys für Tests.
const Key goalMenuKey = Key('goal-menu');
const Key goalEditKey = Key('goal-edit');
const Key goalCompleteKey = Key('goal-complete');
const Key goalArchiveKey = Key('goal-archive');
const Key goalReopenKey = Key('goal-reopen');
const Key goalDeleteKey = Key('goal-delete');
const Key goalCompleteSuggestKey = Key('goal-complete-suggest');
const Key goalAddMilestoneFieldKey = Key('goal-add-milestone');
const Key goalAddMilestoneButtonKey = Key('goal-add-milestone-button');

/// Keys der Etappenzeile und ihrer Aktionen.
Key milestoneDoneKey(String milestoneId) => Key('milestone-done-$milestoneId');
Key milestoneDeleteKey(String milestoneId) =>
    Key('milestone-delete-$milestoneId');

/// Details eines Wegs (D19): Warum, Fortschritt "3 von 7 Etappen", die
/// Etappen als abhakbare Liste (Durchstreichen blendet in 160 ms über wie auf
/// der Schrittkarte), Etappe hinzufügen (Textfeld unten, Enter fügt hinzu),
/// und im Menü abschließen, zur Seite legen, bearbeiten, löschen mit
/// Rückfrage. Sind alle Etappen erledigt, schlägt eine Karte das Abschließen
/// vor; abschließen geht aber jederzeit.
class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  final TextEditingController _newMilestone = TextEditingController();
  final FocusNode _newMilestoneFocus = FocusNode();

  @override
  void dispose() {
    _newMilestone.dispose();
    _newMilestoneFocus.dispose();
    super.dispose();
  }

  Future<void> _addMilestone() async {
    final title = _newMilestone.text.trim();
    if (title.isEmpty) return;
    _newMilestone.clear();
    await ref.read(goalActionsProvider).addMilestone(widget.goalId, title);
    // Das Feld behält den Fokus, damit die nächste Etappe gleich folgen kann.
    if (mounted) _newMilestoneFocus.requestFocus();
  }

  Future<void> _delete(GoalView view) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.goalDeleteTitle),
        content: Text(l10n.goalDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keepConfirm),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(goalActionsProvider).delete(view.id);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _reopen(GoalView view) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(goalActionsProvider).reopen(view.id);
    } on GoalLimitReachedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.goalsLimitReached)));
    }
  }

  void _onMenu(_GoalMenuAction action, GoalView view) {
    final actions = ref.read(goalActionsProvider);
    switch (action) {
      case _GoalMenuAction.edit:
        showGoalEditorSheet(context, existing: view);
      case _GoalMenuAction.complete:
        actions.complete(view.id);
      case _GoalMenuAction.archive:
        actions.archive(view.id);
      case _GoalMenuAction.reopen:
        _reopen(view);
      case _GoalMenuAction.delete:
        _delete(view);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final state = ref.watch(goalViewProvider(widget.goalId));
    final view = state.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(view?.goal.title ?? l10n.goalsTitle),
        actions: [
          if (view != null)
            PopupMenuButton<_GoalMenuAction>(
              key: goalMenuKey,
              tooltip: materialL10n.moreButtonTooltip,
              onSelected: (a) => _onMenu(a, view),
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: goalEditKey,
                  value: _GoalMenuAction.edit,
                  child: Text(l10n.goalEdit),
                ),
                if (view.goal.isActive) ...[
                  PopupMenuItem(
                    key: goalCompleteKey,
                    value: _GoalMenuAction.complete,
                    child: Text(l10n.goalComplete),
                  ),
                  PopupMenuItem(
                    key: goalArchiveKey,
                    value: _GoalMenuAction.archive,
                    child: Text(l10n.goalArchive),
                  ),
                ] else
                  PopupMenuItem(
                    key: goalReopenKey,
                    value: _GoalMenuAction.reopen,
                    child: Text(l10n.goalReopen),
                  ),
                PopupMenuItem(
                  key: goalDeleteKey,
                  value: _GoalMenuAction.delete,
                  child: Text(l10n.goalDelete),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          AsyncData(value: null) => Center(child: Text(l10n.goalNotFound)),
          AsyncData(value: final v?) => _body(context, v),
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

  Widget _body(BuildContext context, GoalView view) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = view.goal;
    final progress = view.progress;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final closedAt = goal.closedAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (goal.why != null)
          Reveal(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(goal.why!, style: theme.textTheme.bodyLarge),
            ),
          ),
        Reveal(
          index: 1,
          child: Row(
            children: [
              Icon(Icons.route_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                progress.total == 0
                    ? l10n.goalNoMilestones
                    : l10n.goalProgress(progress.done, progress.total),
                key: const Key('goal-progress'),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ),
        if (closedAt != null)
          Reveal(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                goal.completedAt != null
                    ? l10n.goalCompletedOn(
                        materialL10n.formatMediumDate(closedAt),
                      )
                    : l10n.goalArchivedOn(
                        materialL10n.formatMediumDate(closedAt),
                      ),
                style: muted,
              ),
            ),
          ),
        if (goal.isActive && progress.allDone)
          Reveal(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SurfaceCard(
                color: scheme.tertiaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.goalCompleteSuggestion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        key: goalCompleteSuggestKey,
                        onPressed: () =>
                            ref.read(goalActionsProvider).complete(goal.id),
                        child: Text(l10n.goalComplete),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Reveal(
          index: 3,
          child: Text(
            l10n.goalMilestonesHeading,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (final (i, m) in view.milestones.indexed)
          Reveal(
            index: 4 + i,
            child: _MilestoneTile(milestone: m, enabled: goal.isActive),
          ),
        if (goal.isActive)
          Reveal(
            index: 4 + view.milestones.length,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                key: goalAddMilestoneFieldKey,
                controller: _newMilestone,
                focusNode: _newMilestoneFocus,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addMilestone(),
                decoration: InputDecoration(
                  hintText: l10n.goalAddMilestoneHint,
                  prefixIcon: const Icon(Icons.add, size: 20),
                  suffixIcon: IconButton(
                    key: goalAddMilestoneButtonKey,
                    tooltip: l10n.goalAddMilestone,
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    onPressed: _addMilestone,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _GoalMenuAction { edit, complete, archive, reopen, delete }

/// Eine Etappe: Häkchen, Titel (durchgestrichen, wenn erledigt; der Wechsel
/// blendet in 160 ms über) und Entfernen.
class _MilestoneTile extends ConsumerWidget {
  const _MilestoneTile({required this.milestone, required this.enabled});

  final Milestone milestone;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = milestone.isDone;
    return Semantics(
      label: l10n.goalMilestoneDoneSemantics(milestone.title),
      child: CheckboxListTile(
        key: milestoneDoneKey(milestone.id),
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: done,
        onChanged: enabled
            ? (v) => ref
                  .read(goalActionsProvider)
                  .setMilestoneDone(milestone.id, v ?? false)
            : null,
        title: AnimatedDefaultTextStyle(
          duration: Motion.quick,
          curve: Motion.easeOut,
          style: theme.textTheme.bodyLarge!.copyWith(
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: scheme.onSurfaceVariant,
            color: done ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
          child: Text(milestone.title),
        ),
        secondary: enabled
            ? IconButton(
                key: milestoneDeleteKey(milestone.id),
                tooltip: l10n.goalMilestoneDelete,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () =>
                    ref.read(goalActionsProvider).deleteMilestone(milestone.id),
              )
            : null,
      ),
    );
  }
}
