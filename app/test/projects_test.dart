import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/eintrag/entry_screen.dart';
import 'package:tagebuch_app/features/heute/day_timeline.dart';
import 'package:tagebuch_app/features/mehr/more_screen.dart';
import 'package:tagebuch_app/features/projekte/project_detail_screen.dart';
import 'package:tagebuch_app/features/projekte/project_editor_sheet.dart';
import 'package:tagebuch_app/features/projekte/project_log_sheet.dart';
import 'package:tagebuch_app/features/projekte/projects_screen.dart';
import 'package:tagebuch_app/features/rueckblick/week_review_screen.dart';

import 'test_app.dart';

/// Verlässt die oberste Route.
Future<void> _back(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
  await tester.pumpAndSettle();
}

void main() {
  group('Projekte (D26)', () {
    testWidgets(
      'anlegen, heute festhalten; Notizen stehen im Eintrag, im Tag, in der Woche',
      (tester) async {
        final services = TestServices();
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();

        await openMoreTab(tester);
        expect(find.textContaining('Lege ein Projekt an'), findsOneWidget);
        await tester.tap(find.byKey(moreProjectsRowKey));
        await tester.pumpAndSettle();
        expect(find.byType(ProjectsScreen), findsOneWidget);
        expect(find.textContaining('Noch kein Projekt'), findsOneWidget);

        // Ohne Namen geht nichts.
        await tester.tap(find.byKey(projectsEmptyNewKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(projectSaveKey));
        await tester.pumpAndSettle();
        expect(find.text('Gib dem Projekt einen Namen.'), findsOneWidget);
        expect(services.projects.items, isEmpty);

        await tester.enterText(find.byKey(projectNameFieldKey), 'Tagebuch-App');
        await tester.enterText(
          find.byKey(projectAboutFieldKey),
          'Sprach-Tagebuch ohne Cloud.',
        );
        await tester.tap(find.byKey(projectSaveKey));
        await tester.pumpAndSettle();
        final project = services.projects.items.single;
        expect(project.name, 'Tagebuch-App');
        expect(project.about, 'Sprach-Tagebuch ohne Cloud.');
        expect(find.byKey(projectCardKey(project.id)), findsOneWidget);
        expect(find.text('Noch nichts festgehalten.'), findsOneWidget);

        // Heute festhalten: leer wird abgewiesen, dann zwei Notizen.
        await tester.tap(find.byKey(projectLogKey(project.id)));
        await tester.pumpAndSettle();
        expect(find.text('Tagebuch-App · heute'), findsOneWidget);
        await tester.tap(find.byKey(projectLogSaveKey));
        await tester.pumpAndSettle();
        expect(
          find.text('Schreib wenigstens in eines der beiden Felder.'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(projectDoneFieldKey),
          'Parser für EPUB gebaut.',
        );
        await tester.enterText(
          find.byKey(projectGoodFieldKey),
          'Tests liefen auf Anhieb.',
        );
        await tester.tap(find.byKey(projectLogSaveKey));
        await tester.pumpAndSettle();

        final notes = services.notes.items
            .where((n) => n.projectId == project.id)
            .toList();
        expect(notes.map((n) => n.promptKey), [
          ReviewPrompts.projectDone,
          ReviewPrompts.projectGood,
        ]);
        expect(notes.map((n) => n.text), [
          'Parser für EPUB gebaut.',
          'Tests liefen auf Anhieb.',
        ]);
        final today = LocalDay.forMoment(DateTime.now());
        final entry = await services.entries.findByDay(testJournalId, today);
        expect(entry, isNotNull);
        expect(notes.every((n) => n.entryId == entry!.id), isTrue);

        // Karte zeigt den jüngsten Tag mit dem Gemachten.
        expect(find.textContaining('Zuletzt'), findsOneWidget);
        expect(find.text('Parser für EPUB gebaut.'), findsOneWidget);

        // Details: Verlauf mit beiden Notizen, Tipp öffnet den Eintrag.
        await tester.tap(find.byKey(projectCardKey(project.id)));
        await tester.pumpAndSettle();
        expect(find.byType(ProjectDetailScreen), findsOneWidget);
        expect(find.byKey(projectDayKey(entry!.id)), findsOneWidget);
        expect(find.text('Gemacht'), findsOneWidget);
        expect(find.text('Gut gelaufen'), findsOneWidget);
        await tester.tap(find.byKey(projectDayKey(entry.id)));
        await tester.pumpAndSettle();
        expect(find.byType(EntryScreen), findsOneWidget);
        expect(find.text('Tagebuch-App · Gemacht'), findsOneWidget);
        expect(find.text('Tagebuch-App · Gut gelaufen'), findsOneWidget);
        expect(find.text('Tests liefen auf Anhieb.'), findsOneWidget);
        await _back(tester);
        await _back(tester);
        await _back(tester);

        // "Mehr" nennt das Projekt mit Datum.
        expect(find.textContaining('1 Projekt · zuletzt'), findsOneWidget);
        expect(find.textContaining('Tagebuch-App'), findsOneWidget);

        // Wochenrückblick: "Projekte diese Woche".
        await tester.tap(find.byKey(moreWeekRowKey));
        await tester.pumpAndSettle();
        expect(find.byType(WeekReviewScreen), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('week-projects')),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(find.text('Projekte diese Woche'), findsOneWidget);
        expect(find.text('Tagebuch-App'), findsOneWidget);
        expect(find.text('Parser für EPUB gebaut.'), findsOneWidget);
        await _back(tester);

        // "Heute": die Zeitleiste "Dein Tag" zeigt beide Stücke mit Etikett.
        await openTodayTab(tester);
        await scrollTodayTo(tester, find.byKey(dayTimelineKey));
        expect(find.byKey(dayTimelineRowKey(notes[0].id)), findsOneWidget);
        expect(find.byKey(dayTimelineRowKey(notes[1].id)), findsOneWidget);
        expect(find.text('Tagebuch-App · Gemacht'), findsOneWidget);
        expect(find.text('Tagebuch-App · Gut gelaufen'), findsOneWidget);
      },
    );

    testWidgets('zur Seite legen, wieder aufnehmen, löschen lässt Notizen', (
      tester,
    ) async {
      final services = TestServices();
      final useCase = services.services.projectsUseCase();
      final project = await useCase.createProject(name: 'Garten');
      await useCase.logDay(project.id, done: 'Beete umgegraben.');
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await openMoreTab(tester);
      await tester.tap(find.byKey(moreProjectsRowKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(projectCardKey(project.id)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(projectMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(projectArchiveKey));
      await tester.pumpAndSettle();
      expect((await services.projects.byId(project.id))!.isActive, isFalse);
      expect(find.textContaining('Zur Seite gelegt am'), findsOneWidget);
      expect(find.byKey(projectDetailLogKey), findsNothing);

      await tester.tap(find.byKey(projectMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(projectReopenKey));
      await tester.pumpAndSettle();
      expect((await services.projects.byId(project.id))!.isActive, isTrue);
      expect(find.byKey(projectDetailLogKey), findsOneWidget);

      // Bearbeiten über das Blatt.
      await tester.tap(find.byKey(projectMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(projectEditKey));
      await tester.pumpAndSettle();
      expect(find.text('Projekt bearbeiten'), findsOneWidget);
      await tester.enterText(find.byKey(projectNameFieldKey), 'Gemüsegarten');
      await tester.tap(find.byKey(projectSaveKey));
      await tester.pumpAndSettle();
      expect((await services.projects.byId(project.id))!.name, 'Gemüsegarten');

      // Löschen mit Rückfrage; die Notiz bleibt im Tagebuch, ohne Projekt.
      await tester.tap(find.byKey(projectMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(projectDeleteKey));
      await tester.pumpAndSettle();
      expect(find.text('Projekt löschen?'), findsOneWidget);
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(services.projects.items, isEmpty);
      expect(find.byType(ProjectsScreen), findsOneWidget);
      final note = services.notes.items.single;
      expect(note.projectId, isNull);
      expect(note.text, 'Beete umgegraben.');
      expect(note.promptKey, ReviewPrompts.projectDone);
    });
  });
}
