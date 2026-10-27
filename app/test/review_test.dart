import 'dart:convert';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/features/aufnahme/recording_screen.dart';
import 'package:tagebuch_app/features/eintrag/entry_screen.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';
import 'package:tagebuch_app/features/kalender/calendar_screen.dart';
import 'package:tagebuch_app/features/rueckblick/week_review_screen.dart';
import 'package:tagebuch_app/features/schreiben/write_screen.dart';
import 'package:tagebuch_app/widgets/mood_dots.dart';
import 'package:tagebuch_app/widgets/mood_selector.dart';
import 'package:tagebuch_app/widgets/step_card.dart';

import 'test_app.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  group('Schreiben statt sprechen (D17)', () {
    testWidgets(
      'Geführt: vier Felder, Autospeichern nach 1 s, leere Felder nicht',
      (tester) async {
        final services = TestServices();
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(writeButtonKey));
        await tester.pumpAndSettle();
        expect(find.byType(WriteScreen), findsOneWidget);
        expect(
          find.text('Was ist heute passiert, was beschäftigt dich?'),
          findsOneWidget,
        );
        expect(find.text('Drei Dinge reichen.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Der eine Schritt für morgen'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Der eine Schritt für morgen'), findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, 800));
        await tester.pumpAndSettle();
        expect(find.text('Noch kein Wort'), findsOneWidget);
        // Das Textfeld lässt die Rechtschreibhilfe des Systems zu.
        final field = tester.widget(
          find.byKey(writeFieldKey(ReviewPrompts.good)),
        ) as TextField;
        expect(field.autocorrect, isTrue);
        expect(field.enableSuggestions, isTrue);
        expect(field.maxLines, isNull);

        await tester.enterText(
          find.byKey(writeFieldKey(ReviewPrompts.good)),
          'Kaffee, Sonne, ein Anruf.',
        );
        await tester.pump();
        expect(find.text('4 Wörter'), findsOneWidget);
        // Vor Ablauf der Entprellung ist nichts gespeichert.
        await tester.pump(const Duration(milliseconds: 500));
        expect(services.notes.items, isEmpty);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        final saved = services.notes.items.single;
        expect(saved.promptKey, 'good');
        expect(saved.text, 'Kaffee, Sonne, ein Anruf.');
        expect(saved.source, NoteSource.typed);
        final entry = services.entries.items.single;
        expect(saved.entryId, entry.id);
        expect(entry.day, LocalDay.forMoment(DateTime.now()));

        // Weiter tippen im selben Feld ändert dieselbe Notiz.
        await tester.enterText(
          find.byKey(writeFieldKey(ReviewPrompts.good)),
          'Kaffee, Sonne, ein Anruf. Und Regen.',
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(services.notes.items.single.id, saved.id);
        expect(services.notes.items.single.text, endsWith('Und Regen.'));

        // Zweites Feld, dann sofort schließen: Speichern beim Verlassen.
        await tester.scrollUntilVisible(
          find.byKey(writeFieldKey(ReviewPrompts.next)),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(writeFieldKey(ReviewPrompts.next)),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(writeFieldKey(ReviewPrompts.next)),
          'Wenn ich morgen aufstehe, dann 10 Minuten lesen.',
        );
        await tester.pump();
        await tester.tap(find.byKey(writeCloseKey));
        await tester.pumpAndSettle();
        expect(find.byType(WriteScreen), findsNothing);
        expect(services.notes.items, hasLength(2));
        expect(
          services.notes.items.map((n) => n.promptKey),
          containsAll(['good', 'next']),
        );
        // Leere Felder (free, lesson) wurden nicht gespeichert.
        expect(
          services.notes.items.where((n) => n.promptKey == 'free'),
          isEmpty,
        );
        // "Heute" zeigt den geschriebenen Eintrag.
        expect(find.byType(TodayScreen), findsOneWidget);
        expect(find.text('Heute noch nichts aufgenommen.'), findsNothing);
        expect(find.textContaining('Kaffee, Sonne'), findsOneWidget);
        expect(find.textContaining('Geschrieben um'), findsOneWidget);
      },
    );

    testWidgets('Frei: ein Feld; nichts geschrieben legt keinen Eintrag an', (
      tester,
    ) async {
      final services = TestServices();
      await services.settings.set(AppSettings.keyGuidedReview, 'false');
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(writeButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(writeFieldKey(null)), findsOneWidget);
      expect(find.byKey(writeFieldKey(ReviewPrompts.good)), findsNothing);
      expect(find.byKey(moodSliderKey), findsNothing);

      // Tippen und wieder leeren: nichts bleibt.
      await tester.enterText(find.byKey(writeFieldKey(null)), 'Hallo');
      await tester.pump(const Duration(seconds: 2));
      expect(services.notes.items, hasLength(1));
      await tester.enterText(find.byKey(writeFieldKey(null)), '   ');
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byKey(writeCloseKey));
      await tester.pumpAndSettle();
      expect(services.notes.items, isEmpty);
      expect(services.entries.items, isEmpty);
      expect(find.text('Heute noch nichts aufgenommen.'), findsOneWidget);
    });

    testWidgets('Eintrag: Notiz bearbeiten und löschen', (tester) async {
      final services = TestServices(
        seed: [
          testEntry(
            id: 'a',
            day: DateTime(2026, 10, 20),
            transcript: 'Gesprochen.',
            notes: {'lesson': 'Früher Schluss machen.'},
          ),
        ],
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      // Direkt zum Eintrag.
      final context = tester.element(find.byType(TodayScreen));
      Navigator.of(context).pushNamed('/entry', arguments: 'a');
      await tester.pumpAndSettle();

      expect(find.byType(EntryScreen), findsOneWidget);
      expect(find.text('Gesprochen.'), findsOneWidget);
      expect(find.text('Früher Schluss machen.'), findsOneWidget);
      expect(find.text('Gelernt'), findsOneWidget);
      // Aufnahme vor Notiz (chronologisch).
      final playerY = tester.getTopLeft(find.byKey(playerSliderKey)).dy;
      final noteY = tester.getTopLeft(find.text('Früher Schluss machen.')).dy;
      expect(playerY, lessThan(noteY));

      await tester.ensureVisible(
        find.byKey(const Key('note-edit-note-a-lesson')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-edit-note-a-lesson')));
      await tester.pumpAndSettle();
      expect(find.byType(WriteScreen), findsOneWidget);
      // Nur dieses Feld, mit dem Impuls als Überschrift.
      expect(find.byKey(writeFieldKey(ReviewPrompts.lesson)), findsOneWidget);
      expect(find.byKey(writeFieldKey(ReviewPrompts.good)), findsNothing);
      await tester.enterText(
        find.byKey(writeFieldKey(ReviewPrompts.lesson)),
        'Früher Schluss machen, Handy weg.',
      );
      await tester.tap(find.byKey(writeCloseKey));
      await tester.pumpAndSettle();
      expect(
        services.notes.items.single.text,
        'Früher Schluss machen, Handy weg.',
      );
      expect(find.text('Früher Schluss machen, Handy weg.'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('note-delete-note-a-lesson')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-delete-note-a-lesson')));
      await tester.pumpAndSettle();
      expect(find.text('Notiz löschen?'), findsOneWidget);
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(services.notes.items, isEmpty);
      expect(find.text('Gesprochen.'), findsOneWidget);
    });

    testWidgets('Suche findet Notizen, Treffer ohne Sprungziel', (
      tester,
    ) async {
      final services = TestServices(
        seed: [
          testEntry(
            id: 'a',
            day: DateTime(2026, 9, 6),
            withRecording: false,
            notes: {'': 'Nur geschrieben: Spaziergang am Fluss.'},
          ),
        ],
      );
      final hits = await services.services.search.search('fluss');
      expect(hits.single.entryId, 'a');
      expect(hits.single.recordingId, isNull);
      expect(hits.single.jumpTo, isNull);
      expect(await services.services.search.search('prompts_at'), isEmpty);

      await tester.pumpWidget(
        buildTestScreen(
          CalendarScreen(initialMonth: DateTime(2026, 9)),
          services: services,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(searchFieldKey), 'spaziergang');
      await tester.pumpAndSettle();
      expect(find.text('1 Eintrag'), findsOneWidget);
      expect(find.textContaining('Spaziergang am Fluss'), findsOneWidget);
      // Nur geschriebene Tage zeigen die Wortzahl statt der Dauer.
      expect(find.text('5 Wörter'), findsOneWidget);
    });
  });

  group('Geführter Rückblick (D17)', () {
    testWidgets(
      'Aufnahme: Impulse nacheinander, "Weiter" und nach 45 s, Zeitmarken',
      (tester) async {
        final services = TestServices();
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(recordButtonKey));
        await pumpTransition(tester);

        expect(find.byKey(promptCardKey), findsOneWidget);
        expect(find.text('Impuls 1 von 4'), findsOneWidget);
        expect(
          find.text('Was ist heute passiert, was beschäftigt dich?'),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 10));
        await tester.tap(find.byKey(promptAdvanceKey));
        await tester.pump();
        expect(find.text('Impuls 2 von 4'), findsOneWidget);
        expect(
          find.text('Was ist heute gut gelaufen, wofür bist du dankbar?'),
          findsOneWidget,
        );
        // Automatisch nach 45 Sekunden, die Aufnahme läuft weiter.
        await tester.pump(const Duration(seconds: 44));
        expect(find.text('Impuls 2 von 4'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Impuls 3 von 4'), findsOneWidget);
        expect(find.text('Aufnahme läuft'), findsOneWidget);
        await tester.tap(find.byKey(promptAdvanceKey));
        await tester.pump();
        expect(find.text('Impuls 4 von 4'), findsOneWidget);
        expect(find.byKey(promptAdvanceKey), findsNothing);

        await tester.tap(find.byKey(stopButtonKey));
        await pumpTransition(tester);
        await tester.pumpAndSettle();

        final recording = services.recordings.items.single;
        final marksNote = services.notes.items.single;
        expect(marksNote.promptKey, ReviewPrompts.promptsAt);
        expect(marksNote.entryId, recording.entryId);
        final marks = PromptMarks.fromJson(
          jsonDecode(marksNote.text) as Map<String, Object?>,
        );
        expect(marks.recordingId, recording.id);
        expect(marks.marks.map((m) => m.promptKey), [
          'free',
          'good',
          'lesson',
          'next',
        ]);
        // Der Zähler tickt alle 250 ms; die Marken liegen im erwarteten Fenster.
        expect(marks.marks[0].at, Duration.zero);
        expect(
          marks.marks[1].at.inMilliseconds,
          inInclusiveRange(10000, 10500),
        );
        expect(
          marks.marks[2].at.inMilliseconds,
          inInclusiveRange(55000, 55500),
        );
        expect(
          marks.marks[2].at - marks.marks[1].at,
          const Duration(seconds: 45),
        );
        // Die interne Notiz erscheint nicht als Text auf "Heute".
        expect(find.textContaining('recordingId'), findsNothing);
        expect(find.text(fakeTranscript), findsOneWidget);
      },
    );

    testWidgets('Einstellung aus: keine Impulse bei der Aufnahme', (
      tester,
    ) async {
      final services = TestServices();
      await services.settings.set(AppSettings.keyGuidedReview, 'false');
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(recordButtonKey));
      await pumpTransition(tester);
      expect(find.byKey(promptCardKey), findsNothing);
      await tester.tap(find.byKey(stopButtonKey));
      await pumpTransition(tester);
      await tester.pumpAndSettle();
      expect(services.notes.items, isEmpty);
    });

    testWidgets('Stimmung am Eintrag: selbst gesetzt, wieder entfernbar', (
      tester,
    ) async {
      final services = TestServices(
        seed: [testEntry(id: 'a', day: DateTime(2026, 10, 20))],
      );
      await tester.pumpWidget(
        buildTestScreen(const EntryScreen(entryId: 'a'), services: services),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nicht gesetzt'), findsOneWidget);
      expect(find.byKey(moodClearKey), findsNothing);

      await tester.tap(find.byKey(moodSliderKey));
      await tester.pumpAndSettle();
      expect(services.entries.items.single.mood, '3');
      expect(find.byKey(const Key('mood-word')), findsOneWidget);
      expect(
        (tester.widget(find.byKey(const Key('mood-word'))) as Text).data,
        'neutral',
      );

      await tester.drag(find.byKey(moodSliderKey), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(services.entries.items.single.mood, '5');
      expect(
        (tester.widget(find.byKey(const Key('mood-word'))) as Text).data,
        'leicht',
      );

      await tester.tap(find.byKey(moodClearKey));
      await tester.pumpAndSettle();
      expect(services.entries.items.single.mood, isNull);
      expect(find.text('Nicht gesetzt'), findsOneWidget);
    });

    testWidgets('Karte "Dein Schritt für heute" mit Häkchen, ohne Streak', (
      tester,
    ) async {
      final today = _today();
      final services = TestServices(
        seed: [
          testEntry(
            id: 'y',
            day: today.subtract(const Duration(days: 1)),
            notes: {
              'next':
                  'Wenn ich morgen den Rechner aufklappe, dann '
                  'zuerst die Steuer.',
            },
          ),
        ],
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();

      expect(find.byKey(stepCardKey), findsOneWidget);
      expect(find.text('Dein Schritt für heute'), findsOneWidget);
      expect(find.textContaining('zuerst die Steuer'), findsOneWidget);
      expect(find.textContaining('Kette'), findsNothing);

      await tester.ensureVisible(find.byKey(stepDoneKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(stepDoneKey));
      await tester.pumpAndSettle();
      final todayEntry = services.entries.items
          .where((e) => e.day == LocalDay.forMoment(today))
          .single;
      final done = services.notes.items
          .where((n) => n.promptKey == ReviewPrompts.nextDone)
          .single;
      expect(done.entryId, todayEntry.id);
      expect(done.text, '1');
      final box = tester.widget(
        find.descendant(
          of: find.byKey(stepDoneKey),
          matching: find.byType(Checkbox),
        ),
      ) as Checkbox;
      expect(box.value, isTrue);
      // Die interne Notiz macht den Tag nicht zu einem "Eintrag mit Text".
      expect(find.text('Heute noch nichts aufgenommen.'), findsNothing);

      // Zurücknehmen ist erlaubt.
      await tester.ensureVisible(find.byKey(stepDoneKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(stepDoneKey));
      await tester.pumpAndSettle();
      expect(
        services.notes.items.where((n) => n.promptKey == 'next_done'),
        isEmpty,
      );
    });

    testWidgets('Ohne gestrigen Schritt keine Karte', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(stepCardKey), findsNothing);
    });

    testWidgets('"Vor einem Jahr" und "Vor einem Monat" auf Heute', (
      tester,
    ) async {
      final today = _today();
      final yearAgo = DateTime(today.year - 1, today.month, today.day);
      final services = TestServices(
        seed: [testEntry(id: 'y', day: yearAgo, transcript: 'Damals im Park.')],
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lookback-yearAgo')), findsOneWidget);
      expect(find.text('Vor einem Jahr'), findsOneWidget);
      expect(find.text('Damals im Park.'), findsOneWidget);
      expect(find.byKey(const Key('lookback-monthAgo')), findsNothing);
    });

    testWidgets('Wochenrückblick: Liste und sieben Punkte', (tester) async {
      final today = _today();
      DateTime ago(int d) => today.subtract(Duration(days: d));
      final services = TestServices(
        seed: [
          testEntry(
            id: 'd6',
            day: ago(6),
            mood: 2,
            notes: {'good': 'Spaziergang.', 'lesson': 'Früher ins Bett.'},
          ),
          testEntry(
            id: 'd3',
            day: ago(3),
            mood: 4,
            notes: {'next': 'Zahnarzt anrufen.'},
          ),
          testEntry(
            id: 'd2',
            day: ago(2),
            mood: 5,
            notes: {'good': 'Anruf erledigt.', 'next_done': '1'},
          ),
          // Älter als sieben Tage: taucht nicht auf.
          testEntry(id: 'old', day: ago(9), mood: 1, notes: {'good': 'Alt.'}),
        ],
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
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
      expect(find.text('Deine Woche'), findsOneWidget);
      expect(find.byKey(moodDotsKey), findsOneWidget);
      expect(find.text('Spaziergang.'), findsOneWidget);
      expect(find.text('Anruf erledigt.'), findsOneWidget);
      expect(find.text('Früher ins Bett.'), findsOneWidget);
      // Erledigter Schritt: die Antwort des Vortags.
      expect(find.text('Zahnarzt anrufen.'), findsOneWidget);
      expect(find.text('Alt.'), findsNothing);
      // Screenreader hört Wörter statt Zahlen.
      expect(
        find.bySemanticsLabel(RegExp(r'Stimmungsverlauf.*müde.*gut.*leicht')),
        findsOneWidget,
      );
      expect(find.textContaining('Zähler'), findsOneWidget);
    });

    testWidgets('Einstellung "Geführter Rückblick" speichert', (tester) async {
      final services = TestServices();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Einstellungen'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Geführter Rückblick'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Geführter Rückblick'));
      await tester.pumpAndSettle();
      expect(await services.settings.get(AppSettings.keyGuidedReview), 'false');
    });
  });
}
