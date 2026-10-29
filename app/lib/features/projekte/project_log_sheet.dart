import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/projects_view.dart';
import '../../l10n/app_localizations.dart';
import '../rueckblick/prompts.dart';

/// Widget-Keys für Tests.
const Key projectDoneFieldKey = Key('project-log-done');
const Key projectGoodFieldKey = Key('project-log-good');
const Key projectLogSaveKey = Key('project-log-save');

/// Blatt "Heute festhalten" zu einem Projekt (D26): zwei Felder, "Was hast
/// du gemacht?" und "Was lief gut?". Beide landen als Notizen am heutigen
/// Tageseintrag und erscheinen damit im Tagebuch; ein leeres Feld wird nicht
/// gespeichert. Liefert die Zahl der angelegten Notizen (0 bei Abbruch).
Future<int> showProjectLogSheet(BuildContext context, Project project) async {
  final count = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ProjectLogSheet(project: project),
  );
  return count ?? 0;
}

class _ProjectLogSheet extends ConsumerStatefulWidget {
  const _ProjectLogSheet({required this.project});

  final Project project;

  @override
  ConsumerState<_ProjectLogSheet> createState() => _ProjectLogSheetState();
}

class _ProjectLogSheetState extends ConsumerState<_ProjectLogSheet> {
  final TextEditingController _done = TextEditingController();
  final TextEditingController _good = TextEditingController();
  bool _empty = false;
  bool _saving = false;

  @override
  void dispose() {
    _done.dispose();
    _good.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_done.text.trim().isEmpty && _good.text.trim().isEmpty) {
      setState(() => _empty = true);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final count = await ref
        .read(projectActionsProvider)
        .logToday(widget.project.id, done: _done.text, good: _good.text);
    navigator.pop(count);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return AnimatedPadding(
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
              l10n.projectLogTitle(widget.project.name),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(l10n.projectLogIntro, style: muted),
            const SizedBox(height: 16),
            Text(
              PromptTexts.title(l10n, ReviewPrompts.projectDone),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(l10n.projectDoneHint, style: muted),
            const SizedBox(height: 6),
            TextField(
              key: projectDoneFieldKey,
              controller: _done,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              minLines: 2,
              maxLines: 5,
              onChanged: (_) {
                if (_empty) setState(() => _empty = false);
              },
            ),
            const SizedBox(height: 16),
            Text(
              PromptTexts.title(l10n, ReviewPrompts.projectGood),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(l10n.projectGoodHint, style: muted),
            const SizedBox(height: 6),
            TextField(
              key: projectGoodFieldKey,
              controller: _good,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              minLines: 2,
              maxLines: 5,
              onChanged: (_) {
                if (_empty) setState(() => _empty = false);
              },
            ),
            if (_empty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.projectLogEmpty,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: projectLogSaveKey,
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(l10n.projectLogSave),
            ),
          ],
        ),
      ),
    );
  }
}
