import 'package:diary_core/diary_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_services.dart';
import 'entry_view.dart';

/// Die Notizen eines Projekts an einem Tag (D26): "gemacht" und "gut
/// gelaufen", in Reihenfolge; ein Tipp öffnet den Tageseintrag.
class ProjectDay {
  const ProjectDay({
    required this.day,
    required this.entryId,
    required this.notes,
  });

  final LocalDay day;
  final String entryId;
  final List<EntryNote> notes;
}

/// Ein Projekt mit seinem Verlauf, neueste Tage zuerst.
class ProjectView {
  const ProjectView({required this.project, required this.days});

  final Project project;
  final List<ProjectDay> days;

  String get id => project.id;

  /// Der jüngste Tag mit Notizen oder `null`.
  ProjectDay? get latest => days.firstOrNull;

  /// Die jüngste "gemacht"-Notiz oder sonst die jüngste Notiz.
  EntryNote? get latestNote {
    final day = latest;
    if (day == null) return null;
    return day.notes
            .where((n) => n.promptKey == ReviewPrompts.projectDone)
            .lastOrNull ??
        day.notes.lastOrNull;
  }

  static Future<ProjectView> load(AppServices s, Project project) async {
    final notes = await s.notes.listForProject(project.id);
    final byEntry = <String, List<EntryNote>>{};
    for (final n in notes) {
      byEntry.putIfAbsent(n.entryId, () => []).add(n);
    }
    final days = <ProjectDay>[];
    for (final e in byEntry.entries) {
      final entry = await s.entries.byId(e.key);
      if (entry == null) continue;
      days.add(ProjectDay(day: entry.day, entryId: entry.id, notes: e.value));
    }
    days.sort((a, b) => b.day.compareTo(a.day));
    return ProjectView(project: project, days: days);
  }
}

/// Aktive Projekte nach Reihenfolge, mit Verlauf.
final activeProjectsProvider = FutureProvider<List<ProjectView>>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  return [
    for (final p in await s.projects.listActive(s.journalId))
      await ProjectView.load(s, p),
  ];
});

/// Zur Seite gelegte Projekte, zuletzt beendete zuerst.
final archivedProjectsProvider = FutureProvider<List<ProjectView>>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  return [
    for (final p in await s.projects.listArchived(s.journalId))
      await ProjectView.load(s, p),
  ];
});

/// Ein Projekt nach Kennung oder `null`.
final projectViewProvider = FutureProvider.family<ProjectView?, String>((
  ref,
  projectId,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final project = await s.projects.byId(projectId);
  return project == null ? null : ProjectView.load(s, project);
});

/// Namen aller Projekte (auch zur Seite gelegter) nach Kennung, für die
/// Etiketten im Eintrag, in "Dein Tag" und im Wochenrückblick.
final projectNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  return {for (final p in await s.projects.listAll(s.journalId)) p.id: p.name};
});

/// Schreibende Aktionen für Projekte. Jede Änderung erhöht den
/// Datenzähler, damit Eintrag, "Dein Tag", "Mehr" und Woche neu laden.
class ProjectActions {
  const ProjectActions(this.ref);
  final Ref ref;

  Future<ProjectsUseCase> _useCase() async =>
      (await ref.read(appServicesProvider.future)).projectsUseCase();

  void _bump() => ref.read(dataVersionProvider.notifier).bump();

  Future<Project> create({required String name, String? about}) async {
    final project = await (await _useCase()).createProject(
      name: name,
      about: about,
    );
    _bump();
    return project;
  }

  Future<void> edit(
    String projectId, {
    required String name,
    String? about,
  }) async {
    await (await _useCase()).editProject(projectId, name: name, about: about);
    _bump();
  }

  /// Hält "gemacht" und "gut gelaufen" für heute fest; liefert die Zahl der
  /// angelegten Notizen (0, wenn beide Felder leer waren).
  Future<int> logToday(String projectId, {String? done, String? good}) async {
    final created = await (await _useCase()).logDay(
      projectId,
      done: done,
      good: good,
    );
    if (created.isNotEmpty) _bump();
    return created.length;
  }

  Future<void> archive(String projectId) async {
    await (await _useCase()).archiveProject(projectId);
    _bump();
  }

  Future<void> reopen(String projectId) async {
    await (await _useCase()).reopenProject(projectId);
    _bump();
  }

  Future<void> delete(String projectId) async {
    await (await _useCase()).deleteProject(projectId);
    _bump();
  }
}

final projectActionsProvider = Provider<ProjectActions>(
  (ref) => ProjectActions(ref),
);
