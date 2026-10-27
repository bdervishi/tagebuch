import 'dart:convert';

import 'package:diary_core/diary_core.dart';
import 'package:test/test.dart';

import 'transfer_support.dart';

void main() {
  final t0 = DateTime(2026, 10, 27, 21);

  test('Goal und Milestone: JSON-Round-Trip, ältere Datensätze tolerant', () {
    final g = Goal(
      id: 'g1',
      journalId: 'j',
      title: 'Jeden Tag zehn Minuten lesen',
      why: 'Weil Abende mit Buch ruhiger enden.',
      createdAt: t0,
      updatedAt: t0,
      sortIndex: 2,
    );
    final back = ModelJson.decodeGoal(
      jsonDecode(jsonEncode(ModelJson.encodeGoal(g))) as Map<String, Object?>,
    );
    expect(back.id, 'g1');
    expect(back.title, g.title);
    expect(back.why, g.why);
    expect(back.sortIndex, 2);
    expect(back.completedAt, isNull);
    expect(back.archivedAt, isNull);
    expect(back.isActive, isTrue);
    expect(back.closedAt, isNull);

    final done = g.copyWith(completedAt: t0.add(const Duration(days: 3)));
    final doneBack = ModelJson.decodeGoal(ModelJson.encodeGoal(done));
    expect(doneBack.isActive, isFalse);
    expect(doneBack.closedAt, done.completedAt);
    expect(done.copyWith(clearCompleted: true).isActive, isTrue);
    expect(g.copyWith(clearWhy: true).why, isNull);

    final m = Milestone(
      id: 'm1',
      goalId: 'g1',
      title: 'Buch aussuchen',
      sortIndex: 0,
      createdAt: t0,
    );
    final mBack = ModelJson.decodeMilestone(
      jsonDecode(jsonEncode(ModelJson.encodeMilestone(m)))
          as Map<String, Object?>,
    );
    expect(mBack.isDone, isFalse);
    expect(mBack.title, 'Buch aussuchen');
    final mDone = m.copyWith(doneAt: t0);
    expect(
      ModelJson.decodeMilestone(ModelJson.encodeMilestone(mDone)).doneAt,
      t0,
    );
    expect(mDone.copyWith(clearDone: true).isDone, isFalse);

    // Minimaler Datensatz ohne optionale Felder.
    final minimal = ModelJson.decodeGoal({
      'id': 'g2',
      'journalId': 'j',
      'title': 'x',
      'createdAt': '2026-10-27T19:00:00.000Z',
      'updatedAt': '2026-10-27T19:00:00.000Z',
    });
    expect(minimal.sortIndex, 0);
    expect(minimal.why, isNull);
  });

  test('EntryNote.goalId: Round-Trip, fehlt bei alten Datensätzen', () {
    final n = EntryNote(
      id: 'n1',
      entryId: 'e1',
      createdAt: t0,
      updatedAt: t0,
      text: 'Wenn ich morgen heimkomme, dann Kapitel 1.',
      promptKey: ReviewPrompts.next,
      goalId: 'g1',
    );
    final back = ModelJson.decodeNote(ModelJson.encodeNote(n));
    expect(back.goalId, 'g1');
    expect(back.copyWith(clearGoalId: true).goalId, isNull);
    expect(back.copyWith(text: 'x').goalId, 'g1');
    final legacy = ModelJson.decodeNote({
      'id': 'n2',
      'entryId': 'e1',
      'createdAt': '2026-10-27T19:00:00.000Z',
      'updatedAt': '2026-10-27T19:00:00.000Z',
      'text': 'alt',
    });
    expect(legacy.goalId, isNull);
  });

  test(
    'StepDoneMark: `1` ohne Etappe, JSON mit Etappe, Unlesbares tolerant',
    () {
      expect(const StepDoneMark().encode(), '1');
      expect(StepDoneMark.parse('1').milestoneId, isNull);
      expect(StepDoneMark.parse('').milestoneId, isNull);
      expect(StepDoneMark.parse('{kaputt').milestoneId, isNull);
      expect(StepDoneMark.parse('{"other":1}').milestoneId, isNull);
      final mark = const StepDoneMark(milestoneId: 'm9').encode();
      expect(mark, '{"milestoneId":"m9"}');
      expect(StepDoneMark.parse(mark).milestoneId, 'm9');
    },
  );

  test('GoalProgress: erledigt von allen, kein Prozent', () {
    final ms = [
      for (var i = 0; i < 7; i++)
        Milestone(
          id: 'm$i',
          goalId: 'g',
          title: '$i',
          sortIndex: i,
          createdAt: t0,
          doneAt: i < 3 ? t0 : null,
        ),
    ];
    final p = GoalProgress.of(ms);
    expect(p.done, 3);
    expect(p.total, 7);
    expect(p.allDone, isFalse);
    expect(GoalProgress.of(const []).allDone, isFalse);
    expect(GoalProgress.of(ms.take(3)).allDone, isTrue);
  });

  group('GoalsUseCase', () {
    late MemoryGoals repo;
    late FixedClock clock;
    late GoalsUseCase useCase;

    setUp(() {
      repo = MemoryGoals();
      clock = FixedClock(t0);
      useCase = GoalsUseCase(
        journalId: 'j',
        goals: repo,
        ids: MemoryIds('id-'),
        clock: clock,
      );
    });

    test('höchstens drei aktive Ziele', () async {
      await useCase.createGoal(title: 'Eins');
      await useCase.createGoal(title: 'Zwei', why: '  ');
      final three = await useCase.createGoal(
        title: ' Drei ',
        why: 'Darum.',
        milestoneTitles: ['a', '', ' b '],
      );
      expect(three.title, 'Drei');
      expect(three.why, 'Darum.');
      expect(three.sortIndex, 2);
      expect((await repo.listActive('j')).map((g) => g.title), [
        'Eins',
        'Zwei',
        'Drei',
      ]);
      expect((await repo.listActive('j'))[1].why, isNull);
      expect((await repo.listMilestones(three.id)).map((m) => m.title), [
        'a',
        'b',
      ]);
      expect(await useCase.canCreate(), isFalse);
      await expectLater(
        useCase.createGoal(title: 'Vier'),
        throwsA(isA<GoalLimitReachedException>()),
      );
      expect(repo.goals, hasLength(3));

      // Abschließen macht Platz; Wiedereröffnen nur mit Platz.
      await useCase.completeGoal(three.id);
      expect(await useCase.canCreate(), isTrue);
      expect((await repo.listArchived('j')).single.completedAt, t0);
      await useCase.createGoal(title: 'Vier');
      await expectLater(
        useCase.reopenGoal(three.id),
        throwsA(isA<GoalLimitReachedException>()),
      );
      await useCase.archiveGoal('id-1');
      await useCase.reopenGoal(three.id);
      expect((await repo.goalById(three.id))!.isActive, isTrue);
      expect((await repo.listArchived('j')).single.archivedAt, t0);
    });

    test(
      'Etappen: hinzufügen, abhaken, Fortschritt, Löschen räumt auf',
      () async {
        final g = await useCase.createGoal(title: 'Lesen');
        final m1 = (await useCase.addMilestone(g.id, 'Buch aussuchen'))!;
        expect(await useCase.addMilestone(g.id, '   '), isNull);
        final m2 = (await useCase.addMilestone(g.id, 'Kapitel 1'))!;
        expect(m2.sortIndex, m1.sortIndex + 1);
        expect((await useCase.progress(g.id)).total, 2);

        clock.advance(const Duration(hours: 1));
        await useCase.setMilestoneDone(m1.id, true);
        final p = await useCase.progress(g.id);
        expect(p.done, 1);
        expect((await repo.milestoneById(m1.id))!.doneAt, clock.now());
        await useCase.setMilestoneDone(m1.id, false);
        expect((await repo.milestoneById(m1.id))!.isDone, isFalse);

        // Aus dem Schritt für heute: bereits erledigt, hinten angehängt.
        final fromStep = await useCase.addDoneMilestone(
          g.id,
          'Wenn ich heimkomme, dann lesen.',
        );
        expect(fromStep!.isDone, isTrue);
        expect(fromStep.sortIndex, 2);
        // Nicht für ein abgeschlossenes Ziel.
        await useCase.completeGoal(g.id);
        expect(await useCase.addDoneMilestone(g.id, 'x'), isNull);
        expect(await useCase.addDoneMilestone('fremd', 'x'), isNull);

        await useCase.editGoal(g.id, title: 'Mehr lesen', why: '');
        final edited = (await repo.goalById(g.id))!;
        expect(edited.title, 'Mehr lesen');
        expect(edited.why, isNull);

        await useCase.deleteMilestone(m2.id);
        expect(await repo.milestoneById(m2.id), isNull);
        await useCase.deleteGoal(g.id);
        expect(await repo.goalById(g.id), isNull);
        expect(await repo.listAllMilestones(), isEmpty);
      },
    );

    test(
      'doneSince: je Ziel die seit dem Zeitpunkt erledigten Etappen',
      () async {
        final a = await useCase.createGoal(title: 'A');
        final b = await useCase.createGoal(title: 'B');
        await useCase.addMilestone(b.id, 'offen');
        clock.setTo(DateTime(2026, 10, 20));
        final old = (await useCase.addMilestone(a.id, 'alt'))!;
        await useCase.setMilestoneDone(old.id, true);
        clock.setTo(DateTime(2026, 10, 25));
        final recent = (await useCase.addMilestone(a.id, 'neu'))!;
        await useCase.setMilestoneDone(recent.id, true);
        final since = await useCase.doneSince(DateTime(2026, 10, 21));
        expect(since.keys.map((g) => g.id), [a.id]);
        expect(since[a]!.map((m) => m.title), ['neu']);
      },
    );
  });
}
