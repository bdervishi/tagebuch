import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/entry_view.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/features/bewegung/exercise_sheet.dart';
import 'package:tagebuch_app/features/bewegung/movement_breaks_editor.dart';
import 'package:tagebuch_app/features/bewegung/movement_calendar_sheet.dart';
import 'package:tagebuch_app/features/bewegung/movement_card.dart';
import 'package:tagebuch_app/features/bewegung/movement_library.dart';
import 'package:tagebuch_app/features/bewegung/movement_screen.dart';
import 'package:tagebuch_app/features/einstellungen/settings_screen.dart';
import 'package:tagebuch_app/features/heute/day_timeline.dart';
import 'package:tagebuch_app/features/mehr/more_screen.dart';
import 'package:tagebuch_app/features/rueckblick/week_review_screen.dart';
import 'package:tagebuch_app/services/platform_features.dart';

import 'test_app.dart';

/// Feste Übungsliste für die Widget-Tests (das Asset lädt in Widget-Tests
/// nicht deterministisch).
const MovementLibrary _library = MovementLibrary(
  exercises: [
    Exercise(
      id: 'x1',
      category: 'stretch',
      minutes: 2,
      de: 'Nacken kreisen',
      en: 'Neck circles',
      howDe: 'Kopf langsam zur Seite neigen.',
      howEn: 'Tilt your head slowly.',
    ),
    Exercise(
      id: 'x2',
      category: 'strength',
      minutes: 1,
      de: '10 Kniebeugen',
      en: '10 squats',
    ),
    Exercise(
      id: 'x3',
      category: 'strength',
      minutes: 0.5,
      de: 'Wandsitz',
      en: 'Wall sit',
    ),
  ],
  categories: [
    ExerciseCategory(key: 'stretch', de: 'Dehnen', en: 'Stretch'),
    ExerciseCategory(key: 'strength', de: 'Kräftigen', en: 'Strengthen'),
  ],
  noticeDe: 'Bei Schmerzen abbrechen.',
  noticeEn: 'Stop if anything hurts.',
);

/// Dienstag, 27. 10. 2026, 10:30: die Pause um 10:00 ist fällig.
final DateTime _tuesdayMorning = DateTime(2026, 10, 27, 10, 30);

/// Dienste mit fester Uhr und fester Übungsliste; Pausen standardmäßig an.
/// Je Test eine App: Ein zweites `pumpWidget` würde den `ProviderScope`
/// aktualisieren statt neu aufbauen und die alten Dienste behalten.
TestServices _services({
  DateTime? now,
  bool enabled = true,
  FakePlatformFeatures? features,
}) {
  final s = TestServices(
    clock: FixedClock(now ?? _tuesdayMorning),
    movementLibrary: _library,
    features: features ?? const NativePlatformFeatures(),
  );
  if (enabled) s.settings.set(AppSettings.keyMovementEnabled, 'true');
  return s;
}

/// Scrollt die Liste des Bildschirms [screen], bis [finder] gebaut und
/// sichtbar ist (die Listen bauen nur den sichtbaren Teil).
Future<void> _scrollTo(
  WidgetTester tester,
  Type screen,
  Finder finder, {
  double delta = 200,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find
        .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
}

/// Baut die App und scrollt "Heute" bis zum Ende; liefert, ob die Karte
/// "Zeit für Bewegung" da ist.
Future<bool> _cardShown(WidgetTester tester, TestServices services) async {
  await tester.pumpWidget(buildTestApp(services: services));
  await tester.pumpAndSettle();
  await scrollTodayTo(tester, find.text('Heute noch nichts aufgenommen.'));
  return find.byKey(movementCardKey).evaluate().isNotEmpty;
}

/// Bewegungspausen (D24).
void main() {
  group('Einstellungen', () {
    testWidgets('Schalter aus; einschalten zeigt Pausen und speichert Zeit', (
      tester,
    ) async {
      final services = _services(enabled: false);
      await tester.pumpWidget(
        buildTestScreen(const SettingsScreen(), services: services),
      );
      await tester.pumpAndSettle();
      await _scrollTo(tester, SettingsScreen, find.byKey(movementEnabledKey));
      expect(find.text('Bewegungspausen'), findsOneWidget);
      final sw = tester.widget<SwitchListTile>(find.byKey(movementEnabledKey));
      expect(sw.value, isFalse);
      expect(find.byKey(movementBreakTimeKey(0)), findsNothing);

      await tester.tap(find.byKey(movementEnabledKey));
      await tester.pumpAndSettle();
      expect(
        await services.settings.get(AppSettings.keyMovementEnabled),
        'true',
      );
      // Standard: 10:00 und 15:00, Montag bis Freitag.
      await _scrollTo(tester, SettingsScreen, find.byKey(movementBreakAddKey));
      expect(find.byKey(movementBreakTimeKey(0)), findsOneWidget);
      expect(find.byKey(movementBreakTimeKey(1)), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      final saturday = tester.widget<FilterChip>(
        find.byKey(movementBreakDayKey(0, DateTime.saturday)),
      );
      expect(saturday.selected, isFalse);
      final monday = tester.widget<FilterChip>(
        find.byKey(movementBreakDayKey(0, DateTime.monday)),
      );
      expect(monday.selected, isTrue);

      // Uhrzeit setzen: Zeitwähler, Eingabe 11:15.
      await _scrollTo(
        tester,
        SettingsScreen,
        find.byKey(movementBreakTimeKey(0)),
      );
      await tester.tap(find.byKey(movementBreakTimeKey(0)));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '11');
      await tester.enterText(fields.at(1), '15');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('11:15'), findsOneWidget);
      final saved = MovementBreak.decodeList(
        await services.settings.get(AppSettings.keyMovementBreaks),
      );
      expect(saved.first.hour, 11);
      expect(saved.first.minute, 15);
      expect(saved.first.weekdays, {1, 2, 3, 4, 5});

      // Wochentag abwählen und Pause hinzufügen (dritte), dann entfernen.
      await _scrollTo(
        tester,
        SettingsScreen,
        find.byKey(movementBreakDayKey(1, DateTime.friday)),
      );
      await tester.tap(find.byKey(movementBreakDayKey(1, DateTime.friday)));
      await tester.pumpAndSettle();
      await _scrollTo(tester, SettingsScreen, find.byKey(movementBreakAddKey));
      await tester.tap(find.byKey(movementBreakAddKey));
      await tester.pumpAndSettle();
      await _scrollTo(
        tester,
        SettingsScreen,
        find.byKey(movementBreakRemoveKey(2)),
      );
      var breaks = MovementBreak.decodeList(
        await services.settings.get(AppSettings.keyMovementBreaks),
      );
      expect(breaks, hasLength(3));
      expect(breaks[1].weekdays, {1, 2, 3, 4});
      expect(breaks[2].hour, 16);
      // Höchstens drei: keine Taste mehr.
      expect(find.byKey(movementBreakAddKey), findsNothing);
      await tester.tap(find.byKey(movementBreakRemoveKey(2)));
      await tester.pumpAndSettle();
      breaks = MovementBreak.decodeList(
        await services.settings.get(AppSettings.keyMovementBreaks),
      );
      expect(breaks, hasLength(2));
      expect(find.byKey(movementBreakAddKey), findsOneWidget);
    });

    testWidgets(
      'Kalenderblatt: Google-Link je Pause mit BYDAY, ICS mit allen Pausen',
      (tester) async {
        final features = FakePlatformFeatures();
        final services = _services(features: features);
        await tester.pumpWidget(
          buildTestScreen(const SettingsScreen(), services: services),
        );
        await tester.pumpAndSettle();
        await _scrollTo(
          tester,
          SettingsScreen,
          find.byKey(movementCalendarKey),
        );
        await tester.tap(find.byKey(movementCalendarKey));
        await tester.pumpAndSettle();
        expect(find.textContaining('nie Tagebuchinhalte'), findsOneWidget);
        expect(find.byKey(movementCalendarGoogleKey(0)), findsOneWidget);
        expect(find.byKey(movementCalendarGoogleKey(1)), findsOneWidget);
        expect(find.textContaining('Mo, Di, Mi, Do, Fr'), findsNWidgets(2));

        await tester.tap(find.byKey(movementCalendarGoogleKey(1)));
        await tester.pumpAndSettle();
        final uri = features.openedLinks.single;
        expect(uri.host, 'calendar.google.com');
        expect(uri.queryParameters['text'], 'Bewegungspause');
        expect(
          uri.queryParameters['details'],
          'Kurz aufstehen, dehnen oder gehen.',
        );
        expect(
          uri.queryParameters['recur'],
          'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
        );
        // Erster Termin: heute (Systemdatum) um 15:00, wie bei der Erinnerung.
        expect(uri.queryParameters['dates'], contains('T150000/'));
        expect(find.textContaining('Kalender geöffnet'), findsOneWidget);
        // Die Snackbar ablaufen lassen, sonst wartet die nächste dahinter.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Outlook: Hinweis auf die Wiederholung.
        await tester.tap(find.byKey(movementCalendarKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(movementCalendarOutlookKey(0)));
        await tester.pumpAndSettle();
        expect(features.openedLinks.last.host, 'outlook.live.com');
        expect(find.textContaining('Wiederholen: wöchentlich'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        // Datei: beide Pausen als Termine mit Wochentagen.
        await tester.tap(find.byKey(movementCalendarKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(movementCalendarIcsKey));
        await tester.pumpAndSettle();
        final (name, events) = features.calendarFiles.single;
        expect(name, 'tagebuch-bewegung.ics');
        expect(events, hasLength(2));
        expect(events[0].hour, 10);
        expect(events[1].hour, 15);
        expect(events[0].weekdays, {1, 2, 3, 4, 5});
        expect(events[0].title, 'Bewegungspause');
        expect(features.downloads, isEmpty);
        expect(find.textContaining('Kalenderdatei erstellt'), findsOneWidget);
      },
    );
  });

  group('Karte "Zeit für Bewegung"', () {
    testWidgets('fehlt, wenn Pausen aus sind', (tester) async {
      expect(await _cardShown(tester, _services(enabled: false)), isFalse);
    });

    testWidgets('fehlt vor der ersten Pause (9:30)', (tester) async {
      expect(
        await _cardShown(tester, _services(now: DateTime(2026, 10, 27, 9, 30))),
        isFalse,
      );
    });

    testWidgets('fehlt am Samstag (Pause gilt Montag bis Freitag)', (
      tester,
    ) async {
      expect(
        await _cardShown(
          tester,
          _services(now: DateTime(2026, 10, 31, 10, 30)),
        ),
        isFalse,
      );
    });

    testWidgets('erscheint ab 10:00 mit drei Vorschlägen', (tester) async {
      await tester.pumpWidget(buildTestApp(services: _services()));
      await tester.pumpAndSettle();
      await scrollTodayTo(tester, find.byKey(movementCardKey));
      expect(find.text('Zeit für Bewegung'), findsOneWidget);
      expect(find.text('Pause 10:00'), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(3));
      expect(find.text('Nacken kreisen · 2 Min.'), findsOneWidget);
      expect(find.text('10 Kniebeugen · 1 Min.'), findsOneWidget);
      expect(find.text('Wandsitz · 30 Sek.'), findsOneWidget);
      expect(find.byKey(movementOtherKey), findsOneWidget);
      expect(find.byKey(movementSkipKey), findsOneWidget);
    });

    testWidgets(
      'Übung antippen speichert Notiz `movement`, Karte weg, Zeitleiste',
      (tester) async {
        final services = _services();
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();
        await scrollTodayTo(tester, find.byKey(movementSuggestionKey('x1')));
        await tester.tap(find.byKey(movementSuggestionKey('x1')));
        await tester.pumpAndSettle();

        final entry = services.entries.items.single;
        expect(entry.day, LocalDay(2026, 10, 27));
        final note = services.notes.items.single;
        expect(note.entryId, entry.id);
        expect(note.promptKey, ReviewPrompts.movement);
        expect(note.isInternal, isFalse);
        expect(note.text, 'Nacken kreisen · 2 Min.');
        expect(note.createdAt, _tuesdayMorning);
        expect(find.byKey(movementCardKey), findsNothing);

        // Zeitleiste: Etikett "Bewegung" mit dem Übungsnamen.
        await scrollTodayTo(tester, find.byKey(dayTimelineKey));
        expect(find.text('Dein Tag'), findsOneWidget);
        expect(find.byKey(dayTimelineRowKey(note.id)), findsOneWidget);
        expect(find.text('Bewegung'), findsOneWidget);
        expect(find.text('Nacken kreisen · 2 Min.'), findsOneWidget);
        expect(find.byIcon(Icons.directions_walk), findsOneWidget);
        // Die Karte kommt nicht zurück, solange keine neue Pause fällig ist.
        expect(find.byKey(movementCardKey), findsNothing);
      },
    );

    testWidgets('"Heute nicht" schließt die Karte ohne Notiz', (tester) async {
      final services = _services();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await scrollTodayTo(tester, find.byKey(movementSkipKey));
      await tester.tap(find.byKey(movementSkipKey));
      await tester.pumpAndSettle();
      expect(find.byKey(movementCardKey), findsNothing);
      expect(services.notes.items, isEmpty);
      expect(services.entries.items, isEmpty);
      expect(
        await services.settings.get(AppSettings.keyMovementDismissed),
        '2026-10-27:0',
      );
      await scrollTodayTo(tester, find.text('Heute noch nichts aufgenommen.'));
    });

    testWidgets('"Etwas anderes": Liste mit Kategorien und Hinweis', (
      tester,
    ) async {
      final services = _services();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await scrollTodayTo(tester, find.byKey(movementOtherKey));
      await tester.tap(find.byKey(movementOtherKey));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseSheet), findsOneWidget);
      expect(find.text('Dehnen'), findsOneWidget);
      expect(find.text('Kräftigen'), findsOneWidget);
      expect(
        find.text(
          'Bei Schmerzen abbrechen; bei Beschwerden ärztlichen Rat einholen.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(exerciseRowKey('x2')));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseSheet), findsNothing);
      expect(services.notes.items.single.text, '10 Kniebeugen · 1 Min.');
      expect(find.byKey(movementCardKey), findsNothing);
    });

    testWidgets('Zweite Pause am Nachmittag; Freitext als Notiz', (
      tester,
    ) async {
      final services = _services(now: DateTime(2026, 10, 27, 15, 5));
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await scrollTodayTo(tester, find.byKey(movementOtherKey));
      expect(find.text('Pause 15:00'), findsOneWidget);
      await tester.tap(find.byKey(movementOtherKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(exerciseFreeTextKey),
        ' Bis zur Post gelaufen ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final note = services.notes.items.single;
      expect(note.text, 'Bis zur Post gelaufen');
      expect(note.promptKey, ReviewPrompts.movement);
      expect(find.byKey(movementCardKey), findsNothing);
    });
  });

  group('"Mehr"', () {
    testWidgets('Zeile "Bewegung" zeigt "Aus"', (tester) async {
      await tester.pumpWidget(
        buildTestApp(services: _services(enabled: false)),
      );
      await tester.pumpAndSettle();
      await openMoreTab(tester);
      expect(find.byKey(moreMovementRowKey), findsOneWidget);
      expect(find.text('Bewegung'), findsOneWidget);
      expect(find.text('Aus'), findsOneWidget);
    });

    testWidgets('nächste Pause und heutige Pausen', (tester) async {
      final services = _services();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await scrollTodayTo(tester, find.byKey(movementSuggestionKey('x1')));
      await tester.tap(find.byKey(movementSuggestionKey('x1')));
      await tester.pumpAndSettle();
      await openMoreTab(tester);
      expect(find.text('Nächste Pause 15:00 · heute 1 Pause'), findsOneWidget);
    });

    testWidgets('Freitagabend: nächste Pause am Montag, mit Wochentag', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(services: _services(now: DateTime(2026, 10, 30, 18))),
      );
      await tester.pumpAndSettle();
      await openMoreTab(tester);
      expect(find.text('Nächste Pause Mo 10:00'), findsOneWidget);
    });

    testWidgets('ohne Wochentage: "Keine Pausen eingestellt"', (tester) async {
      final services = _services();
      await services.settings.set(
        AppSettings.keyMovementBreaks,
        MovementBreak.encodeList([
          const MovementBreak(hour: 10, minute: 0, weekdays: {}),
        ]),
      );
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await openMoreTab(tester);
      expect(find.text('Keine Pausen eingestellt'), findsOneWidget);
    });
  });

  group('Bildschirm "Bewegung"', () {
    testWidgets('Übungen, eigene Übung hinzufügen und entfernen', (
      tester,
    ) async {
      final services = _services();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await openMoreTab(tester);
      await tester.tap(find.byKey(moreMovementRowKey));
      await tester.pumpAndSettle();
      expect(find.byType(MovementScreen), findsOneWidget);
      expect(find.byKey(movementScreenSwitchKey), findsOneWidget);
      expect(find.byKey(movementBreakTimeKey(0)), findsOneWidget);
      expect(find.byKey(movementScreenCalendarKey), findsOneWidget);
      await _scrollTo(
        tester,
        MovementScreen,
        find.byKey(movementExerciseKey('x1')),
      );
      expect(find.text('Dehnen'), findsOneWidget);
      expect(find.text('Kopf langsam zur Seite neigen.'), findsOneWidget);
      await _scrollTo(tester, MovementScreen, find.byKey(movementAddOwnKey));
      expect(find.text('Noch keine eigene Übung.'), findsOneWidget);
      expect(find.textContaining('ärztlichen Rat'), findsOneWidget);

      await tester.tap(find.byKey(movementAddOwnKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(movementOwnTitleKey),
        'Runde um den Block',
      );
      await tester.enterText(find.byKey(movementOwnMinutesKey), '5');
      await tester.tap(find.byKey(movementOwnCategoryKey('strength')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(movementOwnSaveKey));
      await tester.pumpAndSettle();
      final own = Exercise.decodeList(
        await services.settings.get(AppSettings.keyOwnExercises),
      ).single;
      expect(own.own, isTrue);
      expect(own.de, 'Runde um den Block');
      expect(own.minutes, 5);
      expect(own.category, 'strength');
      expect(find.text('Noch keine eigene Übung.'), findsNothing);
      // Die eigene Übung steht in ihrer Kategorie oberhalb der Taste.
      await _scrollTo(
        tester,
        MovementScreen,
        find.byKey(movementExerciseKey(own.id)),
        delta: -200,
      );
      expect(find.text('Runde um den Block'), findsOneWidget);
      await tester.tap(find.byKey(movementOwnRemoveKey(own.id)));
      await tester.pumpAndSettle();
      expect(
        Exercise.decodeList(
          await services.settings.get(AppSettings.keyOwnExercises),
        ),
        isEmpty,
      );
    });
  });

  group('Wochenrückblick', () {
    testWidgets('Abschnitt "Bewegung" mit Punkten je Tag und Übungen', (
      tester,
    ) async {
      final services = _services();
      final yesterday = DateTime(2026, 10, 26, 10);
      await services.services.entries.getOrCreate(
        testJournalId,
        LocalDay.forMoment(yesterday),
        yesterday,
      );
      final entry = services.entries.items.single;
      for (final (i, text) in ['Wandsitz · 30 Sek.', 'Spaziergang'].indexed) {
        await services.notes.insert(
          EntryNote(
            id: 'mv-$i',
            entryId: entry.id,
            createdAt: yesterday.add(Duration(hours: i * 5)),
            updatedAt: yesterday,
            text: text,
            promptKey: ReviewPrompts.movement,
          ),
        );
      }
      await tester.pumpWidget(
        buildTestScreen(const WeekReviewScreen(), services: services),
      );
      await tester.pumpAndSettle();
      await _scrollTo(
        tester,
        WeekReviewScreen,
        find.byKey(const Key('week-movement')),
      );
      expect(find.text('Bewegung'), findsOneWidget);
      expect(find.byKey(const Key('week-movement-dots')), findsOneWidget);
      expect(find.text('Wandsitz · 30 Sek.'), findsOneWidget);
      expect(find.text('Spaziergang'), findsOneWidget);
      // Bewegungsnotizen zählen nicht als Wörter des Eintrags.
      final view = await EntryView.load(services.services, entry);
      expect(view.visibleNotes, hasLength(2));
      expect(view.movementTexts, ['Wandsitz · 30 Sek.', 'Spaziergang']);
      expect(view.wordCount, 0);
    });

    testWidgets('ohne Bewegung die leise Leerzeile, auf Englisch', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestScreen(
          const WeekReviewScreen(),
          services: _services(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollTo(
        tester,
        WeekReviewScreen,
        find.byKey(const Key('week-movement')),
      );
      expect(find.text('Movement'), findsOneWidget);
      expect(find.byKey(const Key('week-movement-dots')), findsNothing);
    });
  });
}
