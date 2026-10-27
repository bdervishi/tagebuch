import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';
import 'package:tagebuch_app/features/kalender/calendar_screen.dart';
import 'package:tagebuch_app/features/rueckblick/week_review_screen.dart';
import 'package:tagebuch_app/features/schreiben/write_screen.dart';
import 'package:tagebuch_app/features/wege/goal_detail_screen.dart';
import 'package:tagebuch_app/features/wege/goal_editor_sheet.dart';
import 'package:tagebuch_app/features/wege/goals_screen.dart';
import 'package:tagebuch_app/features/wege/today_goals_section.dart';
import 'package:tagebuch_app/widgets/step_card.dart';

import 'test_app.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Goal _goal(String id, String title, {int sort = 0, String? why}) {
  final at = DateTime(2026, 10, 20, 21);
  return Goal(
    id: id,
    journalId: testJournalId,
    title: title,
    why: why,
    createdAt: at,
    updatedAt: at,
    sortIndex: sort,
  );
}

Milestone _milestone(
  String id,
  String goalId,
  String title, {
  int sort = 0,
  DateTime? doneAt,
}) => Milestone(
  id: id,
  goalId: goalId,
  title: title,
  sortIndex: sort,
  createdAt: DateTime(2026, 10, 20, 21),
  doneAt: doneAt,
);

/// Verlässt die oberste Route (die AppBar der App hat keinen Standard-Zurück-
/// Knopf, den `pageBack` finden könnte).
Future<void> _back(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
  await tester.pumpAndSettle();
}

void main() {
  group('Wege (D19)', () {
    testWidgets('Weg anlegen, Etappen abhaken und hinzufügen, abschließen', (
      tester,
    ) async {
      final services = TestServices();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();

      // "Heute": leiser Hinweis mit Taste, kein Zähler.
      await tester.ensureVisible(find.byKey(todayGoalsNewKey));
      await tester.pumpAndSettle();
      // Ohne Wege nur die leise Zeile, keine Überschrift.
      expect(find.textContaining('Setze dir einen Weg'), findsOneWidget);
      expect(find.text('Deine Wege'), findsNothing);
      await tester.tap(find.byKey(todayGoalsNewKey));
      await tester.pumpAndSettle();
      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.textContaining('Noch kein Weg'), findsOneWidget);

      await tester.tap(find.byKey(goalsEmptyNewKey));
      await tester.pumpAndSettle();
      // Ohne Titel geht nichts.
      await tester.tap(find.byKey(goalSaveKey));
      await tester.pumpAndSettle();
      expect(find.text('Gib dem Weg einen Titel.'), findsOneWidget);
      expect(services.goals.goals, isEmpty);

      await tester.enterText(
        find.byKey(goalTitleFieldKey),
        'Jeden Abend zehn Minuten lesen',
      );
      await tester.enterText(
        find.byKey(goalWhyFieldKey),
        'Weil Abende mit Buch ruhiger enden.',
      );
      await tester.enterText(
        find.byKey(goalMilestoneFieldKey(0)),
        'Buch aussuchen',
      );
      await tester.enterText(find.byKey(goalMilestoneFieldKey(1)), 'Kapitel 1');
      await tester.pumpAndSettle();
      // Das letzte gefüllte Feld bringt ein weiteres leeres hervor.
      expect(find.byKey(goalMilestoneFieldKey(2)), findsOneWidget);
      await tester.tap(find.byKey(goalSaveKey));
      await tester.pumpAndSettle();

      final goal = services.goals.goals.single;
      expect(goal.title, 'Jeden Abend zehn Minuten lesen');
      expect(goal.why, 'Weil Abende mit Buch ruhiger enden.');
      expect(goal.isActive, isTrue);
      expect(services.goals.milestones.map((m) => m.title), [
        'Buch aussuchen',
        'Kapitel 1',
      ]);
      expect(find.byKey(goalCardKey(goal.id)), findsOneWidget);
      expect(find.text('0 von 2 Etappen'), findsOneWidget);
      expect(find.text('Als Nächstes: Buch aussuchen'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);

      // Details: abhaken, Fortschritt "1 von 2".
      await tester.tap(find.byKey(goalCardKey(goal.id)));
      await tester.pumpAndSettle();
      expect(find.byType(GoalDetailScreen), findsOneWidget);
      final first = services.goals.milestones.first;
      await tester.tap(find.byKey(milestoneDoneKey(first.id)));
      await tester.pumpAndSettle();
      expect((await services.goals.milestoneById(first.id))!.isDone, isTrue);
      expect(find.text('1 von 2 Etappen'), findsOneWidget);
      expect(find.byKey(goalCompleteSuggestKey), findsNothing);

      // Etappe hinzufügen: Enter fügt hinzu.
      await tester.enterText(find.byKey(goalAddMilestoneFieldKey), 'Kapitel 2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        (await services.goals.listMilestones(goal.id)).map((m) => m.title),
        ['Buch aussuchen', 'Kapitel 1', 'Kapitel 2'],
      );
      expect(find.text('1 von 3 Etappen'), findsOneWidget);
      // Das Feld ist wieder leer.
      expect(
        (tester.widget(
          find.byKey(goalAddMilestoneFieldKey),
        ) as TextField).controller!.text,
        isEmpty,
      );

      // Alle abhaken: Vorschlag zum Abschließen, kein Konfetti.
      for (final m
          in services.goals.milestones.where((m) => !m.isDone).toList()) {
        await tester.tap(find.byKey(milestoneDoneKey(m.id)));
        await tester.pumpAndSettle();
      }
      expect(find.text('3 von 3 Etappen'), findsOneWidget);
      expect(find.byKey(goalCompleteSuggestKey), findsOneWidget);
      await tester.tap(find.byKey(goalCompleteSuggestKey));
      await tester.pumpAndSettle();
      expect(services.goals.goals.single.completedAt, isNotNull);
      expect(find.byKey(goalCompleteSuggestKey), findsNothing);
      expect(find.textContaining('Abgeschlossen am'), findsOneWidget);
      // Abgeschlossen: keine neuen Etappen mehr.
      expect(find.byKey(goalAddMilestoneFieldKey), findsNothing);

      // Zurück: der Weg steht unter "Abgeschlossen".
      await _back(tester);
      expect(find.text('Abgeschlossen'), findsOneWidget);
      expect(find.byKey(goalCardKey(goal.id)), findsOneWidget);
      expect(find.text('3 von 3'), findsOneWidget);
    });

    testWidgets('Höchstens drei aktive Wege, freundlich abgelehnt', (
      tester,
    ) async {
      final services = TestServices();
      for (var i = 0; i < 3; i++) {
        await services.goals.insertGoal(_goal('g$i', 'Weg $i', sort: i));
      }
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(TodayScreen)))
          .pushNamed('/goals');
      await tester.pumpAndSettle();
      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.byKey(goalCardKey('g0')), findsOneWidget);
      expect(find.byKey(goalCardKey('g2')), findsOneWidget);

      await tester.tap(find.byKey(goalsNewKey));
      await tester.pumpAndSettle();
      expect(find.byKey(goalTitleFieldKey), findsNothing);
      expect(find.textContaining('Drei Wege sind genug'), findsOneWidget);
      expect(services.goals.goals, hasLength(3));

      // Zur Seite legen macht Platz; im Archiv mit Datum, wieder aufnehmbar.
      await tester.tap(find.byKey(goalCardKey('g2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(goalMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(goalArchiveKey));
      await tester.pumpAndSettle();
      expect(
        services.goals.goals.firstWhere((g) => g.id == 'g2').isActive,
        isFalse,
      );
      expect(find.textContaining('Zur Seite gelegt am'), findsOneWidget);
      await _back(tester);
      expect(find.text('Abgeschlossen'), findsOneWidget);
      await tester.tap(find.byKey(goalsNewKey));
      await tester.pumpAndSettle();
      expect(find.byKey(goalTitleFieldKey), findsOneWidget);
    });

    testWidgets('Weg löschen mit Rückfrage nimmt die Etappen mit', (
      tester,
    ) async {
      final services = TestServices();
      await services.goals.insertGoal(_goal('g', 'Lesen', why: 'Ruhe.'));
      await services.goals.insertMilestone(_milestone('m', 'g', 'Buch'));
      await tester.pumpWidget(
        buildTestScreen(
          const GoalDetailScreen(goalId: 'g'),
          services: services,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ruhe.'), findsOneWidget);
      expect(find.text('Buch'), findsOneWidget);

      await tester.tap(find.byKey(goalMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(goalDeleteKey));
      await tester.pumpAndSettle();
      expect(find.text('Weg löschen?'), findsOneWidget);
      await tester.tap(find.text('Behalten'));
      await tester.pumpAndSettle();
      expect(services.goals.goals, hasLength(1));

      await tester.tap(find.byKey(goalMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(goalDeleteKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(services.goals.goals, isEmpty);
      expect(services.goals.milestones, isEmpty);
      expect(find.text('Diesen Weg gibt es nicht mehr.'), findsOneWidget);
    });

    testWidgets(
      'Schritt für heute mit Weg: Häkchen macht eine Etappe, zurück entfernt sie',
      (tester) async {
        final today = _today();
        final services = TestServices(
          seed: [
            testEntry(
              id: 'y',
              day: today.subtract(const Duration(days: 1)),
              notes: {'next': 'Wenn ich heimkomme, dann Kapitel 1.'},
            ),
          ],
        );
        await services.goals.insertGoal(_goal('g', 'Lesen'));
        await services.goals.insertMilestone(_milestone('m0', 'g', 'Buch'));
        // Die gestrige Antwort hängt am Weg.
        final step = services.notes.items.single;
        await services.notes.update(step.copyWith(goalId: 'g'));

        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();
        expect(find.byKey(stepCardKey), findsOneWidget);
        expect(find.byKey(stepGoalKey), findsOneWidget);
        expect(find.text('Weg: Lesen'), findsOneWidget);

        await tester.ensureVisible(find.byKey(stepDoneKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(stepDoneKey));
        await tester.pumpAndSettle();
        final created = services.goals.milestones.where((m) => m.id != 'm0');
        expect(created, hasLength(1));
        final milestone = created.single;
        expect(milestone.goalId, 'g');
        expect(milestone.title, 'Wenn ich heimkomme, dann Kapitel 1.');
        expect(milestone.isDone, isTrue);
        expect(milestone.sortIndex, 1);
        final mark = services.notes.items
            .where((n) => n.promptKey == ReviewPrompts.nextDone)
            .single;
        expect(StepDoneMark.parse(mark.text).milestoneId, milestone.id);
        // "Deine Wege" zählt mit: 1 von 2.
        await tester.ensureVisible(find.byKey(todayGoalKey('g')));
        await tester.pumpAndSettle();
        expect(find.text('1 von 2'), findsOneWidget);

        // Zurücknehmen entfernt die Etappe wieder.
        await tester.ensureVisible(find.byKey(stepDoneKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(stepDoneKey));
        await tester.pumpAndSettle();
        expect(services.goals.milestones.map((m) => m.id), ['m0']);
        expect(
          services.notes.items.where((n) => n.promptKey == 'next_done'),
          isEmpty,
        );
        expect(find.text('0 von 1'), findsOneWidget);
      },
    );

    testWidgets('Schritt ohne Weg: Häkchen bleibt wie bisher (`1`)', (
      tester,
    ) async {
      final today = _today();
      final services = TestServices(
        seed: [
          testEntry(
            id: 'y',
            day: today.subtract(const Duration(days: 1)),
            notes: {'next': 'Zahnarzt anrufen.'},
          ),
        ],
      );
      await services.goals.insertGoal(_goal('g', 'Lesen'));
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      expect(find.byKey(stepGoalKey), findsNothing);
      await tester.ensureVisible(find.byKey(stepDoneKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(stepDoneKey));
      await tester.pumpAndSettle();
      expect(services.goals.milestones, isEmpty);
      expect(
        services.notes.items
            .where((n) => n.promptKey == ReviewPrompts.nextDone)
            .single
            .text,
        '1',
      );
    });

    testWidgets('Schreiben: Schritt für morgen per Chip einem Weg zuordnen', (
      tester,
    ) async {
      final services = TestServices();
      await services.goals.insertGoal(_goal('g', 'Lesen'));
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(writeButtonKey));
      await tester.pumpAndSettle();
      // Chips nur beim vierten Impuls.
      expect(find.byKey(writeGoalChipKey('g')), findsNothing);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(writeNextKey));
        await tester.pumpAndSettle();
      }
      expect(find.text('Der eine Schritt für morgen'), findsOneWidget);
      expect(find.byKey(writeGoalChipKey(null)), findsOneWidget);
      expect(find.byKey(writeGoalChipKey('g')), findsOneWidget);

      await tester.enterText(
        find.byKey(writeFieldKey(ReviewPrompts.next)),
        'Wenn ich heimkomme, dann Kapitel 1.',
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(services.notes.items.single.goalId, isNull);

      await tester.tap(find.byKey(writeGoalChipKey('g')));
      await tester.pumpAndSettle();
      expect(services.notes.items.single.goalId, 'g');
      expect(services.notes.items.single.text, endsWith('Kapitel 1.'));

      await tester.tap(find.byKey(writeGoalChipKey(null)));
      await tester.pumpAndSettle();
      expect(services.notes.items.single.goalId, isNull);

      await tester.tap(find.byKey(writeGoalChipKey('g')));
      await tester.tap(find.byKey(writeCloseKey));
      await tester.pumpAndSettle();
      expect(services.notes.items.single.goalId, 'g');
    });

    testWidgets(
      '"Heute" zeigt die Wege, Wochenrückblick die Etappen der Woche',
      (tester) async {
        final today = _today();
        final services = TestServices();
        await services.goals.insertGoal(_goal('g', 'Lesen', sort: 0));
        await services.goals.insertGoal(_goal('h', 'Laufen', sort: 1));
        await services.goals.insertMilestone(
          _milestone(
            'm1',
            'g',
            'Buch aussuchen',
            doneAt: today.subtract(const Duration(days: 2)),
          ),
        );
        await services.goals.insertMilestone(
          _milestone(
            'm2',
            'g',
            'Alt und vergessen',
            sort: 1,
            doneAt: today.subtract(const Duration(days: 10)),
          ),
        );
        await services.goals.insertMilestone(
          _milestone('m3', 'g', 'Kapitel 1', sort: 2),
        );
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(todayGoalKey('h')));
        await tester.pumpAndSettle();
        expect(find.byKey(todayGoalKey('g')), findsOneWidget);
        expect(find.text('2 von 3'), findsOneWidget);
        expect(find.text('Noch keine Etappen'), findsOneWidget);
        await tester.tap(find.byKey(todayGoalKey('g')));
        await tester.pumpAndSettle();
        expect(find.byType(GoalDetailScreen), findsOneWidget);
        expect(find.text('2 von 3 Etappen'), findsOneWidget);
        await _back(tester);
        expect(find.byType(TodayScreen), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Kalender'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(weekButtonKey));
        await tester.pumpAndSettle();
        expect(find.byType(WeekReviewScreen), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('week-goals')));
        await tester.pumpAndSettle();
        expect(find.text('Wege diese Woche'), findsOneWidget);
        expect(find.text('Lesen'), findsOneWidget);
        expect(find.text('Buch aussuchen'), findsOneWidget);
        expect(find.text('Alt und vergessen'), findsNothing);
        expect(find.text('Kapitel 1'), findsNothing);
        // Wege ohne erledigte Etappen fehlen hier.
        expect(find.text('Laufen'), findsNothing);
      },
    );
  });
}
