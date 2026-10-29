import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/projects_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import '../rueckblick/prompts.dart';
import 'project_editor_sheet.dart';
import 'project_log_sheet.dart';

/// Widget-Keys für Tests.
const Key projectMenuKey = Key('project-menu');
const Key projectEditKey = Key('project-edit');
const Key projectArchiveKey = Key('project-archive');
const Key projectReopenKey = Key('project-reopen');
const Key projectDeleteKey = Key('project-delete');
const Key projectDetailLogKey = Key('project-detail-log');

/// Key der Tageskarte im Verlauf eines Projekts.
Key projectDayKey(String entryId) => Key('project-day-$entryId');

enum _ProjectMenuAction { edit, archive, reopen, delete }

/// Details eines Projekts (D26): worum es geht, die Taste "Heute
/// festhalten" und der Verlauf als Tageskarten (Datum, "Gemacht", "Gut
/// gelaufen"); ein Tipp auf einen Tag öffnet den Tageseintrag, wo die Notizen
/// wie alle anderen bearbeitet werden. Im Menü bearbeiten, zur Seite legen,
/// wieder aufnehmen, löschen mit Rückfrage.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProjectView view,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.projectDeleteTitle),
        content: Text(l10n.projectDeleteBody),
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
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(projectActionsProvider).delete(view.id);
    if (navigator.canPop()) navigator.pop();
  }

  void _onMenu(
    BuildContext context,
    WidgetRef ref,
    _ProjectMenuAction action,
    ProjectView view,
  ) {
    final actions = ref.read(projectActionsProvider);
    switch (action) {
      case _ProjectMenuAction.edit:
        showProjectEditorSheet(context, existing: view.project);
      case _ProjectMenuAction.archive:
        actions.archive(view.id);
      case _ProjectMenuAction.reopen:
        actions.reopen(view.id);
      case _ProjectMenuAction.delete:
        _delete(context, ref, view);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final state = ref.watch(projectViewProvider(projectId));
    final view = state.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(view?.project.name ?? l10n.projectsTitle),
        actions: [
          if (view != null)
            PopupMenuButton<_ProjectMenuAction>(
              key: projectMenuKey,
              tooltip: materialL10n.moreButtonTooltip,
              onSelected: (a) => _onMenu(context, ref, a, view),
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: projectEditKey,
                  value: _ProjectMenuAction.edit,
                  child: Text(l10n.projectEdit),
                ),
                if (view.project.isActive)
                  PopupMenuItem(
                    key: projectArchiveKey,
                    value: _ProjectMenuAction.archive,
                    child: Text(l10n.projectArchive),
                  )
                else
                  PopupMenuItem(
                    key: projectReopenKey,
                    value: _ProjectMenuAction.reopen,
                    child: Text(l10n.projectReopen),
                  ),
                PopupMenuItem(
                  key: projectDeleteKey,
                  value: _ProjectMenuAction.delete,
                  child: Text(l10n.projectDelete),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          AsyncData(value: null) => Center(child: Text(l10n.projectNotFound)),
          AsyncData(value: final v?) => _Body(view: v),
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

class _Body extends StatelessWidget {
  const _Body({required this.view});

  final ProjectView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final project = view.project;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final archivedAt = project.archivedAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (project.about != null)
          Reveal(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(project.about!, style: theme.textTheme.bodyLarge),
            ),
          ),
        if (archivedAt != null)
          Reveal(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.projectArchivedOn(
                  materialL10n.formatMediumDate(archivedAt),
                ),
                style: muted,
              ),
            ),
          ),
        if (project.isActive)
          Reveal(
            index: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: projectDetailLogKey,
                onPressed: () => showProjectLogSheet(context, project),
                icon: const Icon(Icons.add_comment_outlined),
                label: Text(l10n.projectLogToday),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Reveal(
          index: 2,
          child: Text(
            l10n.projectHistoryHeading,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (view.days.isEmpty)
          Reveal(index: 3, child: Text(l10n.projectNoEntries, style: muted)),
        for (final (i, day) in view.days.indexed)
          Reveal(
            index: 3 + i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DayCard(day: day),
            ),
          ),
      ],
    );
  }
}

/// Ein Tag im Verlauf: Datum und die Notizen mit Etikett.
class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final ProjectDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SurfaceCard(
      key: projectDayKey(day.entryId),
      semanticLabel: l10n.openEntry,
      onTap: () => AppRoutes.openEntry(context, day.entryId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            materialL10n.formatFullDate(day.day.startOfDay),
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          for (final n in day.notes) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  n.promptKey == ReviewPrompts.projectGood
                      ? Icons.wb_sunny_outlined
                      : Icons.check,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PromptTexts.label(l10n, n.promptKey ?? ''),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        n.text.trim(),
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
