import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/projects_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import 'project_editor_sheet.dart';
import 'project_log_sheet.dart';

/// Widget-Keys für Tests.
const Key projectsNewKey = Key('projects-new');
const Key projectsEmptyNewKey = Key('projects-empty-new');

/// Key der Karte eines Projekts und seiner Taste "Heute festhalten".
Key projectCardKey(String projectId) => Key('project-card-$projectId');
Key projectLogKey(String projectId) => Key('project-log-$projectId');

/// Bildschirm "Projekte" (D26): die aktiven Projekte als Karten (Name,
/// worum es geht, der jüngste Tag mit dem zuletzt Gemachten) mit der Taste
/// "Heute festhalten"; darunter ruhig "Zur Seite gelegt". Kein Zähler, kein
/// Fortschritt, keine Frist: Das Projekt bündelt, was im Tagebuch steht.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = ref.watch(activeProjectsProvider);
    final archived = ref.watch(archivedProjectsProvider).value ?? const [];
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.projectsTitle),
        actions: [
          IconButton(
            key: projectsNewKey,
            tooltip: l10n.projectsNew,
            icon: const Icon(Icons.add),
            onPressed: () => showProjectEditorSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (active) {
          AsyncData(value: final projects) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Reveal(index: 0, child: Text(l10n.projectsIntro, style: muted)),
              const SizedBox(height: 20),
              if (projects.isEmpty)
                Reveal(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.projectsEmpty,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: projectsEmptyNewKey,
                        onPressed: () => showProjectEditorSheet(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.projectsNew),
                      ),
                    ],
                  ),
                ),
              for (final (i, view) in projects.indexed)
                Reveal(
                  index: 1 + i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProjectCard(view: view),
                  ),
                ),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 20),
                Reveal(
                  index: 1 + projects.length,
                  child: Text(
                    l10n.projectsArchivedHeading,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (final (i, view) in archived.indexed)
                  Reveal(
                    index: 2 + projects.length + i,
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

/// Ein aktives Projekt: Name, worum es geht, der jüngste Tag mit dem zuletzt
/// Gemachten, Taste "Heute festhalten".
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.view});

  final ProjectView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final about = view.project.about;
    final latest = view.latest;
    final latestNote = view.latestNote;
    return SurfaceCard(
      key: projectCardKey(view.id),
      onTap: () => AppRoutes.openProject(context, view.id),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(view.project.name, style: theme.textTheme.titleMedium),
                    if (about != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        about,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                key: projectLogKey(view.id),
                tooltip: l10n.projectLogToday,
                icon: const Icon(Icons.add_comment_outlined),
                color: scheme.primary,
                onPressed: () => showProjectLogSheet(context, view.project),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (latest == null || latestNote == null)
            Text(
              l10n.projectNoEntries,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else ...[
            Text(
              l10n.projectLast(
                materialL10n.formatMediumDate(latest.day.startOfDay),
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              latestNote.text.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Ein zur Seite gelegtes Projekt mit Datum.
class _ArchivedCard extends StatelessWidget {
  const _ArchivedCard({required this.view});

  final ProjectView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final project = view.project;
    final date = materialL10n.formatMediumDate(project.archivedAt!);
    return SurfaceCard(
      key: projectCardKey(project.id),
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => AppRoutes.openProject(context, project.id),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: theme.textTheme.bodyLarge),
                Text(
                  l10n.projectArchivedOn(date),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            l10n.projectDayCount(view.days.length),
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
