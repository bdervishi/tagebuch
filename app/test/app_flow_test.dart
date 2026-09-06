import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/entries_notifier.dart';
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
    expect(find.text('Heute noch nichts aufgenommen.'), findsOneWidget);
  });

  testWidgets('Tipp auf die Taste öffnet die Aufnahme, Stopp erzeugt Eintrag', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
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
    expect(find.text('Heute noch nichts aufgenommen.'), findsNothing);
    expect(find.text('Transkription folgt'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TodayScreen)),
    );
    final entries = container.read(entriesProvider);
    expect(entries, hasLength(1));
    expect(entries.single.duration, const Duration(seconds: 2));
    expect(entries.single.transcript, 'Transkription folgt');
    expect(entries.single.language, 'de-DE');
  });

  testWidgets('Abbrechen mit Rückfrage verwirft die Aufnahme', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(recordButtonKey));
    await pumpTransition(tester);
    await tester.tap(find.byKey(cancelButtonKey));
    await pumpTransition(tester);

    expect(find.text('Aufnahme verwerfen?'), findsOneWidget);
    await tester.tap(find.text('Verwerfen'));
    await pumpTransition(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RecordingScreen), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TodayScreen)),
    );
    expect(container.read(entriesProvider), isEmpty);
  });

  testWidgets('Onboarding erscheint beim ersten Start und ist überspringbar', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(onboardingDone: false));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Dein Gerätecode schützt das Tagebuch'), findsOneWidget);
    expect(find.text('Schritt 1 von 4'), findsOneWidget);

    await tester.tap(find.byKey(onboardingSkipKey));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byKey(recordButtonKey), findsOneWidget);
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
