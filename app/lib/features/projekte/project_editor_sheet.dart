import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/projects_view.dart';
import '../../l10n/app_localizations.dart';

/// Widget-Keys für Tests.
const Key projectNameFieldKey = Key('project-name');
const Key projectAboutFieldKey = Key('project-about');
const Key projectSaveKey = Key('project-save');

/// Blatt "Neues Projekt" oder "Projekt bearbeiten" (D26): Name und ein Satz,
/// worum es geht (optional). Liefert das Projekt oder `null` bei Abbruch.
Future<Project?> showProjectEditorSheet(
  BuildContext context, {
  Project? existing,
}) {
  return showModalBottomSheet<Project?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ProjectEditorSheet(existing: existing),
  );
}

class _ProjectEditorSheet extends ConsumerStatefulWidget {
  const _ProjectEditorSheet({this.existing});

  final Project? existing;

  @override
  ConsumerState<_ProjectEditorSheet> createState() =>
      _ProjectEditorSheetState();
}

class _ProjectEditorSheetState extends ConsumerState<_ProjectEditorSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _about = TextEditingController(
    text: widget.existing?.about ?? '',
  );
  bool _nameMissing = false;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final actions = ref.read(projectActionsProvider);
    final existing = widget.existing;
    if (existing == null) {
      final project = await actions.create(name: name, about: _about.text);
      navigator.pop(project);
    } else {
      await actions.edit(existing.id, name: name, about: _about.text);
      navigator.pop(existing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
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
              _isNew ? l10n.projectEditorNewTitle : l10n.projectEditorEditTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(l10n.projectNameLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: projectNameFieldKey,
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_nameMissing) setState(() => _nameMissing = false);
              },
              decoration: InputDecoration(
                hintText: l10n.projectNameHint,
                errorText: _nameMissing ? l10n.projectNameRequired : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.projectAboutLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            TextField(
              key: projectAboutFieldKey,
              controller: _about,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: projectSaveKey,
              onPressed: _saving ? null : _save,
              child: Text(_isNew ? l10n.projectCreate : l10n.projectSave),
            ),
          ],
        ),
      ),
    );
  }
}
