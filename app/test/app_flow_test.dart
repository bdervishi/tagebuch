import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/aufnahme/recording_screen.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';
import 'package:tagebuch_app/features/onboarding/onboarding_screen.dart';

import 'test_app.dart';

void main() {
  testWidgets('App startet auf "Heute" mit Aufnahmetaste', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Heute'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(recordButtonKey), findsOneWidget);
    expect(find.bySemanticsLabel('Aufnahme starten'), findsOneWidget);
    await scrollTodayTo(tester, find.text('Heute noch nichts aufgenommen.'));
    expect(find.text('Heute noch nichts aufgenommen.'), findsOneWidget);
  });

  testWidgets(
    'Tipp auf die Taste öffnet die Aufnahme, Stopp speichert über die Ports',
    (tester) async {
      final services = TestServices();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(recordButtonKey));
      await pumpTransition(tester);

      expect(find.byType(RecordingScreen), findsOneWidget);
      expect(find.byKey(stopButtonKey), findsOneWidget);
      expect(find.text('Aufnahme läuft'), findsOneWidget);

      // Zwei Sekunden "aufnehmen": Der Zähler läuft.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('0:02'), findsOneWidget);

      await tester.tap(find.byKey(stopButtonKey));
      await pumpTransition(tester);
      await tester.pumpAndSettle();

      expect(find.byType(RecordingScreen), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      await scrollTodayTo(tester, find.text(fakeTranscript));
      expect(find.text('Heute noch nichts aufgenommen.'), findsNothing);
      expect(find.text(fakeTranscript), findsOneWidget);

      final entry = services.entries.items.single;
      final recording = services.recordings.items.single;
      final transcript = services.transcripts.items.single;
      expect(recording.entryId, entry.id);
      expect(recording.duration.inMilliseconds, inInclusiveRange(2000, 2900));
      expect(recording.fileName, '${recording.id}.tgbc');
      expect(recording.waveform, hasLength(100));
      expect(transcript.recordingId, recording.id);
      expect(transcript.text, fakeTranscript);
      expect(transcript.locale, 'de-DE');
      expect(services.deletedFiles, isEmpty);
    },
  );

  testWidgets('Pause hält den Zähler an', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(recordButtonKey));
    await pumpTransition(tester);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(pauseButtonKey));
    await tester.pump();
    expect(find.text('Pausiert'), findsOneWidget);
    final shown = (tester.widget(find.textContaining(':')) as Text).data;
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(shown!), findsOneWidget);

    await tester.tap(find.byKey(pauseButtonKey));
    await tester.pump();
    expect(find.text('Aufnahme läuft'), findsOneWidget);
    await tester.tap(find.byKey(stopButtonKey));
    await pumpTransition(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('Abbrechen mit Rückfrage verwirft die Aufnahme', (tester) async {
    final services = TestServices();
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(recordButtonKey));
    await pumpTransition(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(cancelButtonKey));
    await pumpTransition(tester);

    expect(find.text('Aufnahme verwerfen?'), findsOneWidget);
    await tester.tap(find.text('Verwerfen'));
    await pumpTransition(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RecordingScreen), findsNothing);
    await scrollTodayTo(tester, find.text('Heute noch nichts aufgenommen.'));
    expect(find.text('Heute noch nichts aufgenommen.'), findsOneWidget);
    expect(services.entries.items, isEmpty);
    expect(services.recordings.items, isEmpty);
    expect(services.transcripts.items, isEmpty);
    // Die Datei der verworfenen Aufnahme wird entfernt (Crypto-Shredding).
    expect(services.deletedFiles, hasLength(1));
  });

  testWidgets('"Audio behalten" aus: Aufnahme wird als gelöscht markiert', (
    tester,
  ) async {
    final services = TestServices();
    await services.settings.set('keepAudio', 'false');
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(recordButtonKey));
    await pumpTransition(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(stopButtonKey));
    await pumpTransition(tester);
    await tester.pumpAndSettle();

    final recording = services.recordings.items.single;
    expect(recording.state.name, 'audioDeleted');
    expect(recording.fileKeyWrapped, isEmpty);
    expect(services.deletedFiles, [recording.fileName]);
    await scrollTodayTo(tester, find.byIcon(Icons.text_snippet_outlined));
    expect(find.byIcon(Icons.text_snippet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq), findsNothing);
  });

  testWidgets('Onboarding erscheint beim ersten Start und ist überspringbar', (
    tester,
  ) async {
    final services = TestServices(onboardingDone: false);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Dein Gerätecode schützt das Tagebuch'), findsOneWidget);
    expect(find.text('Schritt 1 von 4'), findsOneWidget);

    await tester.tap(find.byKey(onboardingSkipKey));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byKey(recordButtonKey), findsOneWidget);
    expect(await services.settings.get('onboardingDone'), 'true');
  });

  testWidgets('Untere Leiste wechselt zu Kalender und Einstellungen', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Kalender'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Im Text suchen'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Einstellungen'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Erinnerung aktiv'), findsOneWidget);
    expect(find.text('21:00'), findsOneWidget);
    expect(find.text('Kalendereintrag erstellen'), findsNothing);

    // Der Datenschutz-Abschnitt liegt unten in der Liste.
    await tester.scrollUntilVisible(
      find.text('Was dein Gerät verlässt: nichts.'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Was dein Gerät verlässt: nichts.'), findsOneWidget);
    expect(find.text('Backup erstellen'), findsOneWidget);
  });
}
