import '../model/local_day.dart';
import '../model/note.dart';
import '../model/project.dart';
import '../ports/clock.dart';
import '../ports/repositories.dart';
import '../ports/services.dart';

/// Projekte (D26): anlegen, bearbeiten, zur Seite legen, wieder aufnehmen,
/// löschen; und je Tag festhalten, was gemacht wurde und was gut lief. Die
/// Tagesnotizen sind gewöhnliche [EntryNote]s am Tageseintrag (Schlüssel
/// [ReviewPrompts.projectDone] und [ReviewPrompts.projectGood], `projectId`
/// gesetzt): Sie erscheinen im Eintrag, in "Dein Tag", in der Suche und im
/// Backup wie jede andere Notiz; das Projekt bündelt sie nur.
class ProjectsUseCase {
  const ProjectsUseCase({
    required this.journalId,
    required this.projects,
    required this.notes,
    required this.entries,
    required this.ids,
    required this.clock,
    this.dayRolloverHour = 0,
  });

  final String journalId;
  final ProjectRepository projects;
  final NoteRepository notes;
  final EntryRepository entries;
  final IdGenerator ids;
  final Clock clock;

  /// Stunde, bis zu der eine Notiz noch zum Vortag zählt (wie bei der
  /// Aufnahme; 0 = Kalendertag).
  final int dayRolloverHour;

  /// Legt ein Projekt an; leerer Name wird abgewiesen ([ArgumentError]).
  Future<Project> createProject({required String name, String? about}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', 'leer');
    final now = clock.now();
    final active = await projects.listActive(journalId);
    final trimmedAbout = about?.trim();
    final project = Project(
      id: ids.next(),
      journalId: journalId,
      name: trimmed,
      about: trimmedAbout == null || trimmedAbout.isEmpty ? null : trimmedAbout,
      createdAt: now,
      updatedAt: now,
      sortIndex: active.isEmpty
          ? 0
          : active.map((p) => p.sortIndex).reduce((a, b) => a > b ? a : b) + 1,
    );
    await projects.insert(project);
    return project;
  }

  /// Ändert Name und Beschreibung (leer entfernt die Beschreibung).
  Future<Project?> editProject(
    String projectId, {
    required String name,
    String? about,
  }) async {
    final project = await projects.byId(projectId);
    if (project == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return project;
    final trimmedAbout = about?.trim() ?? '';
    final updated = project.copyWith(
      name: trimmed,
      about: trimmedAbout.isEmpty ? null : trimmedAbout,
      clearAbout: trimmedAbout.isEmpty,
      updatedAt: clock.now(),
    );
    await projects.update(updated);
    return updated;
  }

  Future<void> archiveProject(String projectId) async {
    final project = await projects.byId(projectId);
    if (project == null || !project.isActive) return;
    final now = clock.now();
    await projects.update(project.copyWith(archivedAt: now, updatedAt: now));
  }

  Future<void> reopenProject(String projectId) async {
    final project = await projects.byId(projectId);
    if (project == null || project.isActive) return;
    await projects.update(
      project.copyWith(clearArchived: true, updatedAt: clock.now()),
    );
  }

  /// Löscht das Projekt. Seine Tagesnotizen bleiben im Tagebuch, verlieren
  /// aber die Zuordnung (sie waren immer schon Teil des Tages).
  Future<void> deleteProject(String projectId) async {
    for (final n in await notes.listForProject(projectId)) {
      await notes.update(n.copyWith(clearProjectId: true));
    }
    await projects.delete(projectId);
  }

  /// Hält für [day] (Standard: heute) fest, was am Projekt gemacht wurde
  /// ([done]) und was gut lief ([good]). Leere Texte werden nicht
  /// gespeichert; sind beide leer, passiert nichts. Legt den Tageseintrag
  /// bei Bedarf an. Liefert die angelegten Notizen.
  Future<List<EntryNote>> logDay(
    String projectId, {
    String? done,
    String? good,
    LocalDay? day,
  }) async {
    final doneText = done?.trim() ?? '';
    final goodText = good?.trim() ?? '';
    if (doneText.isEmpty && goodText.isEmpty) return const [];
    final project = await projects.byId(projectId);
    if (project == null) return const [];
    final now = clock.now();
    final targetDay =
        day ?? LocalDay.forMoment(now, rolloverHour: dayRolloverHour);
    final entry = await entries.getOrCreate(journalId, targetDay, now);
    final created = <EntryNote>[];
    Future<void> add(String key, String text) async {
      final note = EntryNote(
        id: ids.next(),
        entryId: entry.id,
        createdAt: now,
        updatedAt: now,
        text: text,
        promptKey: key,
        projectId: projectId,
      );
      await notes.insert(note);
      created.add(note);
    }

    if (doneText.isNotEmpty) await add(ReviewPrompts.projectDone, doneText);
    if (goodText.isNotEmpty) await add(ReviewPrompts.projectGood, goodText);
    return created;
  }

  /// Die Tagesnotizen eines Projekts, neueste zuerst.
  Future<List<EntryNote>> history(String projectId) async =>
      (await notes.listForProject(projectId))
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
