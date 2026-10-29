import 'dart:convert';

import 'package:diary_core/diary_core.dart';
import 'package:test/test.dart';

import 'transfer_support.dart';

void main() {
  final t0 = DateTime(2026, 10, 29, 9);

  test('Project: JSON-Round-Trip, ältere Datensätze tolerant', () {
    final p = Project(
      id: 'p1',
      journalId: 'j',
      name: 'Tagebuch-App',
      about: 'Sprach-Tagebuch ohne Cloud.',
      createdAt: t0,
      updatedAt: t0,
      sortIndex: 1,
    );
    final back = ModelJson.decodeProject(
      jsonDecode(jsonEncode(ModelJson.encodeProject(p)))
          as Map<String, Object?>,
    );
    expect(back.id, 'p1');
    expect(back.name, p.name);
    expect(back.about, p.about);
    expect(back.sortIndex, 1);
    expect(back.isActive, isTrue);
    final archived = p.copyWith(archivedAt: t0.add(const Duration(days: 2)));
    expect(
      ModelJson.decodeProject(ModelJson.encodeProject(archived)).isActive,
      isFalse,
    );
    expect(archived.copyWith(clearArchived: true).isActive, isTrue);
    expect(p.copyWith(clearAbout: true).about, isNull);
    // Ohne sortIndex (älter): 0.
    final old = ModelJson.encodeProject(p)..remove('sortIndex');
    expect(ModelJson.decodeProject(old).sortIndex, 0);
  });

  test('EntryNote.projectId wandert durch JSON und copyWith', () {
    final n = EntryNote(
      id: 'n1',
      entryId: 'e1',
      createdAt: t0,
      updatedAt: t0,
      text: 'Parser fertig.',
      promptKey: ReviewPrompts.projectDone,
      projectId: 'p1',
    );
    final back = ModelJson.decodeNote(ModelJson.encodeNote(n));
    expect(back.projectId, 'p1');
    expect(back.promptKey, 'project_done');
    expect(ReviewPrompts.isProject(back.promptKey), isTrue);
    expect(ReviewPrompts.isInternal(back.promptKey), isFalse);
    expect(n.copyWith(text: 'x').projectId, 'p1');
    expect(n.copyWith(clearProjectId: true).projectId, isNull);
    // Älterer Datensatz ohne Feld.
    final m = ModelJson.encodeNote(n)..remove('projectId');
    expect(ModelJson.decodeNote(m).projectId, isNull);
  });

  group('ProjectsUseCase', () {
    late Device device;
    late ProjectsUseCase useCase;
    setUp(() {
      device = Device('d-');
      useCase = ProjectsUseCase(
        journalId: Device.journalId,
        projects: device.projects,
        notes: device.notes,
        entries: device.entries,
        ids: device.ids,
        clock: device.clock,
      );
    });

    test('anlegen, bearbeiten, zur Seite legen, wieder aufnehmen', () async {
      final p = await useCase.createProject(name: '  Garten ', about: ' ');
      expect(p.name, 'Garten');
      expect(p.about, isNull);
      expect(p.sortIndex, 0);
      final q = await useCase.createProject(name: 'Buch', about: 'Roman');
      expect(q.sortIndex, 1);
      expect(
        () => useCase.createProject(name: '   '),
        throwsA(isA<ArgumentError>()),
      );
      final edited = await useCase.editProject(
        p.id,
        name: 'Gemüsegarten',
        about: 'Hochbeet im Frühjahr',
      );
      expect(edited!.name, 'Gemüsegarten');
      expect(edited.about, 'Hochbeet im Frühjahr');
      await useCase.archiveProject(p.id);
      expect((await device.projects.byId(p.id))!.isActive, isFalse);
      expect(
        (await device.projects.listActive(Device.journalId)).map((x) => x.id),
        [q.id],
      );
      expect(
        (await device.projects.listArchived(Device.journalId)).map((x) => x.id),
        [p.id],
      );
      await useCase.reopenProject(p.id);
      expect((await device.projects.byId(p.id))!.isActive, isTrue);
    });

    test('logDay: zwei Notizen am Tageseintrag, leere Texte nicht', () async {
      final p = await useCase.createProject(name: 'App');
      final created = await useCase.logDay(
        p.id,
        done: ' Parser gebaut. ',
        good: 'Tests liefen auf Anhieb.',
      );
      expect(created, hasLength(2));
      expect(created[0].promptKey, ReviewPrompts.projectDone);
      expect(created[0].text, 'Parser gebaut.');
      expect(created[1].promptKey, ReviewPrompts.projectGood);
      expect(created.every((n) => n.projectId == p.id), isTrue);
      // Beide Notizen hängen am Eintrag des heutigen Tages (Uhr: 27. 10.).
      final today = LocalDay.forMoment(device.clock.now());
      final entry = await device.entries.findByDay(Device.journalId, today);
      expect(entry, isNotNull);
      expect(created.every((n) => n.entryId == entry!.id), isTrue);
      expect(await device.notes.listForEntry(entry!.id), hasLength(2));

      // Nur "gemacht", und für einen anderen Tag.
      final yesterday = today.addDays(-1);
      final one = await useCase.logDay(p.id, done: 'Nur das.', day: yesterday);
      expect(one, hasLength(1));
      expect(await useCase.logDay(p.id, done: '  ', good: ''), isEmpty);
      expect(await useCase.logDay('unbekannt', done: 'x'), isEmpty);

      final history = await useCase.history(p.id);
      expect(history, hasLength(3));
      expect(
        history.first.createdAt.isAfter(history.last.createdAt) ||
            history.first.createdAt == history.last.createdAt,
        isTrue,
      );
    });

    test('löschen lässt die Notizen im Tagebuch, ohne Zuordnung', () async {
      final p = await useCase.createProject(name: 'App');
      final created = await useCase.logDay(p.id, done: 'Etwas.');
      await useCase.deleteProject(p.id);
      expect(await device.projects.byId(p.id), isNull);
      final note = (await device.notes.listForEntry(created.single.entryId))
          .single;
      expect(note.projectId, isNull);
      expect(note.promptKey, ReviewPrompts.projectDone);
      expect(note.text, 'Etwas.');
    });
  });
}
