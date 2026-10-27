import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/aufnahme/recording_screen.dart';
import 'package:tagebuch_app/features/eintrag/entry_screen.dart';
import 'package:tagebuch_app/features/heute/day_timeline.dart';
import 'package:tagebuch_app/features/heute/quick_note_sheet.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';
import 'package:tagebuch_app/features/kalender/calendar_screen.dart';
import 'package:tagebuch_app/features/schreiben/write_screen.dart';

import 'test_app.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Kurznotizen über den Tag und der Tag als Zeitleiste (D22).
void main() {
  group('Kurznotiz (D22)', () {
    testWidgets('Blatt speichert eine Notiz `quick` am heutigen Eintrag', (
      tester,
    ) async {
      final services = TestServices();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(quickTextKey));
      await tester.pumpAndSettle();
      expect(find.byType(QuickNoteSheet), findsOneWidget);
      expect(find.text('Kurznotiz'), findsWidgets);

      // Leer: die Taste bleibt aus, Enter schließt nur, nichts gespeichert.
      final save = tester.widget<FilledButton>(find.byKey(quickNoteSaveKey));
      expect(save.onPressed, isNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(QuickNoteSheet), findsNothing);
      expect(services.notes.items, isEmpty);
      expect(services.entries.items, isEmpty);

      // Mit Text: Speichern legt den Eintrag von heute und die Notiz an.
      await tester.tap(find.byKey(quickTextKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(quickNoteFieldKey),
        '  Kaffee mit Lena, gutes Gespräch. ',
      );
      await tester.pump();
      await tester.tap(find.byKey(quickNoteSaveKey));
      await tester.pumpAndSettle();
      expect(find.byType(QuickNoteSheet), findsNothing);

      final entry = services.entries.items.single;
      expect(entry.day, LocalDay.forMoment(DateTime.now()));
      final note = services.notes.items.single;
      expect(note.entryId, entry.id);
      expect(note.promptKey, ReviewPrompts.quick);
      expect(note.isInternal, isFalse);
      expect(note.text, 'Kaffee mit Lena, gutes Gespräch.');
      expect(note.wordCount, 5);

      // Enter speichert ebenso (zweite Notiz, eigener Datensatz).
      await tester.tap(find.byKey(quickTextKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(quickNoteFieldKey), 'Zug verpasst.');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(services.notes.items, hasLength(2));
      expect(services.entries.items, hasLength(1));

      // Beide erscheinen in der Zeitleiste "Dein Tag".
      await scrollTodayTo(tester, find.byKey(dayTimelineKey));
      expect(find.text('Dein Tag'), findsOneWidget);
      expect(find.text('Heute noch nichts aufgenommen.'), findsNothing);
      expect(find.text('Kaffee mit Lena, gutes Gespräch.'), findsOneWidget);
      expect(find.text('Zug verpasst.'), findsOneWidget);
    });

    testWidgets(
      'Zeitleiste: Stücke mit Uhrzeit in Reihenfolge, Tipp öffnet den Eintrag',
      (tester) async {
        final services = TestServices(
          seed: [
            testEntry(
              id: 't',
              day: _today(),
              transcript: 'Abends gesprochen.',
              quickNotes: ['Morgens: Lauf im Park.', 'Mittags: Termin lief.'],
              notes: {'good': 'Sonne.'},
            ),
          ],
        );
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();
        await scrollTodayTo(tester, find.byKey(dayTimelineKey));

        expect(find.text('Dein Tag'), findsOneWidget);
        expect(find.byKey(dayTimelineRowKey('note-t-quick-0')), findsOneWidget);
        expect(find.byKey(dayTimelineRowKey('note-t-quick-1')), findsOneWidget);
        expect(find.byKey(dayTimelineRowKey('rec-t')), findsOneWidget);
        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('11:00'), findsOneWidget);
        expect(find.text('21:00'), findsOneWidget);
        // Symbole und Etiketten: Kurznotiz, Aufnahme, Impuls-Antwort.
        expect(
          find.descendant(
            of: find.byKey(dayTimelineKey),
            matching: find.byIcon(Icons.short_text),
          ),
          findsNWidgets(2),
        );
        expect(find.text('Gut gelaufen'), findsOneWidget);
        expect(find.text('Aufnahme'), findsOneWidget);

        // Chronologisch: die Zeilen stehen untereinander in dieser Reihenfolge.
        final y0 = tester
            .getTopLeft(find.byKey(dayTimelineRowKey('note-t-quick-0')))
            .dy;
        final y1 = tester
            .getTopLeft(find.byKey(dayTimelineRowKey('note-t-quick-1')))
            .dy;
        final y2 = tester.getTopLeft(find.byKey(dayTimelineRowKey('rec-t'))).dy;
        expect(y0, lessThan(y1));
        expect(y1, lessThan(y2));

        await tester.ensureVisible(
          find.byKey(dayTimelineRowKey('note-t-quick-1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(dayTimelineRowKey('note-t-quick-1')));
        await tester.pumpAndSettle();
        expect(find.byType(EntryScreen), findsOneWidget);
        expect(find.text('Mittags: Termin lief.'), findsOneWidget);
        // Im Eintrag trägt die Kurznotiz ihr Etikett.
        expect(find.text('Kurznotiz'), findsWidgets);
      },
    );

    testWidgets('Ohne Stücke bleibt die leise Zeile', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await scrollTodayTo(tester, find.text('Heute noch nichts aufgenommen.'));
      expect(find.byKey(dayTimelineKey), findsNothing);
    });

    testWidgets('Suche findet eine Kurznotiz', (tester) async {
      final services = TestServices(
        seed: [
          testEntry(
            id: 'a',
            day: DateTime(2026, 9, 6),
            withRecording: false,
            quickNotes: ['Kurz: Regen auf der Brücke.'],
          ),
        ],
      );
      final hits = await services.services.search.search('brücke');
      expect(hits.single.entryId, 'a');
      expect(hits.single.jumpTo, isNull);

      await tester.pumpWidget(
        buildTestScreen(
          CalendarScreen(initialMonth: DateTime(2026, 9)),
          services: services,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(searchFieldKey), 'brücke');
      await tester.pumpAndSettle();
      expect(find.text('1 Eintrag'), findsOneWidget);
      expect(find.textContaining('Regen auf der Brücke'), findsOneWidget);
    });
  });

  group('Sprachnotiz (D22)', () {
    testWidgets(
      'Schnellmodus: keine Impuls-Karte trotz geführtem Rückblick, speichert',
      (tester) async {
        final services = TestServices();
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(quickVoiceKey));
        await pumpTransition(tester);
        expect(find.byType(RecordingScreen), findsOneWidget);
        expect(find.text('Sprachnotiz'), findsOneWidget);
        expect(find.text('Kurz und knapp. Stopp speichert.'), findsOneWidget);
        expect(find.byKey(promptCardKey), findsNothing);
        expect(find.text('Aufnahme läuft'), findsOneWidget);

        await tester.pump(const Duration(seconds: 2));
        await tester.tap(find.byKey(stopButtonKey));
        await pumpTransition(tester);
        await tester.pumpAndSettle();

        expect(find.byType(RecordingScreen), findsNothing);
        final recording = services.recordings.items.single;
        final entry = services.entries.items.single;
        expect(recording.entryId, entry.id);
        expect(services.transcripts.items.single.recordingId, recording.id);
        // Keine prompts_at-Notiz: Die Sprachnotiz ist eine Aufnahme ohne Impulse.
        expect(services.notes.items, isEmpty);

        await scrollTodayTo(tester, find.byKey(dayTimelineKey));
        expect(find.byKey(dayTimelineRowKey(recording.id)), findsOneWidget);
        expect(find.text(fakeTranscript), findsOneWidget);
      },
    );

    testWidgets('Geführte Aufnahme nennt die Zahl der Stücke von heute', (
      tester,
    ) async {
      final services = TestServices(
        seed: [
          testEntry(
            id: 't',
            day: _today(),
            withRecording: false,
            quickNotes: ['Eins.', 'Zwei.', 'Drei.'],
          ),
        ],
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(recordButtonKey));
      await pumpTransition(tester);
      expect(find.byKey(promptCardKey), findsOneWidget);
      expect(find.text('3 Notizen von heute im Eintrag'), findsOneWidget);
      // Nur die Zahl, keine Inhalte.
      expect(find.text('Eins.'), findsNothing);
      await tester.tap(find.byKey(promptAdvanceKey));
      await tester.pump();
      expect(find.byKey(promptNotesTodayKey), findsNothing);
      await tester.tap(find.byKey(stopButtonKey));
      await pumpTransition(tester);
      await tester.pumpAndSettle();
    });
  });

  group('Abendrückblick mit "Heute bisher" (D22)', () {
    testWidgets('Schreib-Assistent zeigt die Stücke des Tages im Schritt 1', (
      tester,
    ) async {
      final services = TestServices(
        seed: [
          testEntry(
            id: 't',
            day: _today(),
            transcript: 'Kurz gesprochen am Abend.',
            quickNotes: ['Lauf im Park.', 'Termin lief.'],
          ),
        ],
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(writeButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(WriteScreen), findsOneWidget);
      expect(find.byKey(writeTodaySoFarKey), findsOneWidget);
      expect(find.text('Heute bisher'), findsOneWidget);
      expect(find.text('Lauf im Park.'), findsOneWidget);
      expect(find.text('Termin lief.'), findsOneWidget);
      expect(find.text('Kurz gesprochen am Abend.'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.byKey(writeFieldKey(ReviewPrompts.free)), findsOneWidget);

      // Zuklappen lässt die Liste verschwinden, die Überschrift bleibt.
      await tester.tap(find.text('Heute bisher'));
      await tester.pumpAndSettle();
      expect(find.text('Lauf im Park.'), findsNothing);
      await tester.tap(find.text('Heute bisher'));
      await tester.pumpAndSettle();

      // "Alle im Eintrag" öffnet den Eintrag.
      await tester.tap(find.byKey(writeTodaySoFarAllKey));
      await tester.pumpAndSettle();
      expect(find.byType(EntryScreen), findsOneWidget);
    });

    testWidgets('Ohne Stücke keine Liste', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(writeButtonKey));
      await tester.pumpAndSettle();
      expect(find.byType(WriteScreen), findsOneWidget);
      expect(find.byKey(writeTodaySoFarKey), findsNothing);
    });

    testWidgets('Höchstens die letzten acht Stücke', (tester) async {
      final services = TestServices(
        seed: [
          testEntry(
            id: 't',
            day: _today(),
            withRecording: false,
            quickNotes: [for (var i = 1; i <= 10; i++) 'Notiz $i.'],
          ),
        ],
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(writeButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(writeTodaySoFarKey), findsOneWidget);
      expect(find.text('Notiz 1.'), findsNothing);
      expect(find.text('Notiz 2.'), findsNothing);
      expect(find.text('Notiz 3.'), findsOneWidget);
      expect(find.text('Notiz 10.'), findsOneWidget);
    });
  });
}
