import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/goals_view.dart';
import '../../l10n/app_localizations.dart';

/// Widget-Keys für Tests.
const Key goalTitleFieldKey = Key('goal-title');
const Key goalWhyFieldKey = Key('goal-why');
const Key goalSaveKey = Key('goal-save');

/// Key des Textfelds der [index]-ten ersten Etappe im Blatt "Neuer Weg".
Key goalMilestoneFieldKey(int index) => Key('goal-milestone-$index');

/// Mehr Felder für erste Etappen gibt es im Blatt nicht; weitere kommen in
/// den Details dazu.
const int maxInitialMilestoneFields = 5;

/// Blatt "Neuer Weg" oder "Weg bearbeiten" (D19): Titel, Warum (ein Satz,
/// optional) und beim Anlegen die ersten Etappen. Liefert das angelegte oder
/// geänderte Ziel oder `null`, wenn abgebrochen. Kommt von unten wie die
/// anderen Blätter (docs/12 Abschnitt 8); die Tastatur schiebt den Inhalt.
Future<Goal?> showGoalEditorSheet(BuildContext context, {GoalView? existing}) {
  return showModalBottomSheet<Goal?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _GoalEditorSheet(existing: existing),
  );
}

class _GoalEditorSheet extends ConsumerStatefulWidget {
  const _GoalEditorSheet({this.existing});

  final GoalView? existing;

  @override
  ConsumerState<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<_GoalEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.goal.title ?? '',
  );
  late final TextEditingController _why = TextEditingController(
    text: widget.existing?.goal.why ?? '',
  );
  final List<TextEditingController> _milestones = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _titleMissing = false;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _title.dispose();
    _why.dispose();
    for (final c in _milestones) {
      c.dispose();
    }
    super.dispose();
  }

  /// Sobald das letzte Etappenfeld Text hat, erscheint ein weiteres leeres.
  void _onMilestoneChanged() {
    if (_milestones.length < maxInitialMilestoneFields &&
        _milestones.last.text.trim().isNotEmpty) {
      setState(() => _milestones.add(TextEditingController()));
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleMissing = true);
      return;
    }
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(goalActionsProvider);
    try {
      final existing = widget.existing;
      if (existing == null) {
        final goal = await actions.create(
          title: title,
          why: _why.text,
          milestoneTitles: [for (final c in _milestones) c.text],
        );
        navigator.pop(goal);
      } else {
        await actions.edit(existing.id, title: title, why: _why.text);
        navigator.pop(existing.goal);
      }
    } on GoalLimitReachedException {
      navigator.pop(null);
      messenger.showSnackBar(SnackBar(content: Text(l10n.goalsLimitReached)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      // Die Tastatur schiebt den Inhalt; Dauer und Kurve aus docs/12.
      duration: Motion.enter,
      curve: Motion.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isNew ? l10n.goalEditorNewTitle : l10n.goalEditorEditTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(l10n.goalTitleLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: goalTitleFieldKey,
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_titleMissing) setState(() => _titleMissing = false);
              },
              decoration: InputDecoration(
                hintText: l10n.goalTitleHint,
                errorText: _titleMissing ? l10n.goalTitleRequired : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.goalWhyLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: goalWhyFieldKey,
              controller: _why,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: _isNew
                  ? TextInputAction.next
                  : TextInputAction.done,
              maxLines: 2,
              minLines: 1,
            ),
            if (_isNew) ...[
              const SizedBox(height: 16),
              Text(
                l10n.goalFirstMilestonesLabel,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              for (final (i, c) in _milestones.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    key: goalMilestoneFieldKey(i),
                    controller: c,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _onMilestoneChanged(),
                    decoration: InputDecoration(
                      hintText: l10n.goalMilestoneHint,
                      prefixIcon: Icon(
                        Icons.radio_button_unchecked,
                        size: 18,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: goalSaveKey,
              onPressed: _saving ? null : _save,
              child: Text(_isNew ? l10n.goalCreate : l10n.goalSave),
            ),
          ],
        ),
      ),
    );
  }
}
