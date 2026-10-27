import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/app/routes.dart';
import 'package:tagebuch_app/features/einstellungen/settings_screen.dart';
import 'package:tagebuch_app/features/eintrag/entry_screen.dart';
import 'package:tagebuch_app/features/kalender/calendar_screen.dart';
import 'package:tagebuch_app/features/onboarding/onboarding_screen.dart';

import 'test_app.dart';

void main() {
  testWidgets('Eintrag zeigt Player, Wellenform und spielt simuliert ab', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestScreen(
        const EntryScreen(entryId: 'a'),
        seed: [
          testEntry(
            id: 'a',
            day: DateTime(2026, 9, 6),
            transcript: 'Kaffee im Park',
            duration: const Duration(seconds: 90),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kaffee im Park'), findsOneWidget);
    expect(find.text('1 Min. 30 Sek.'), findsOneWidget);
    expect(find.text('Mit Audio'), findsOneWidget);
    expect(find.byKey(playerSliderKey), findsOneWidget);
    expect(find.text('0:00 / 1:30'), findsOneWidget);
    expect(find.byTooltip('Abspielen'), findsOneWidget);

    await tester.tap(find.byKey(playButtonKey));
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0:02 / 1:30'), findsOneWidget);

    // Geschwindigkeit 2× verdoppelt den Fortschritt.
    await tester.tap(find.text('2×'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0:06 / 1:30'), findsOneWidget);

    await tester.tap(find.byKey(playButtonKey));
    await tester.pump();
    expect(find.byTooltip('Abspielen'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0:06 / 1:30'), findsOneWidget);
  });

  testWidgets('Suchtreffer öffnet den Eintrag an der Trefferposition', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        seed: [
          testEntry(
            id: 'a',
            day: DateTime(2026, 9, 6),
            transcript: 'Kaffee im Park. Dann über die Straße.',
            segments: ['Kaffee im Park.', 'Dann über die Straße.'],
            duration: const Duration(seconds: 60),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Kalender'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(searchFieldKey), 'Strasse');
    await tester.pumpAndSettle();
    expect(find.text('1 Eintrag'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('entry-tile-a')));
    await tester.pumpAndSettle();

    expect(find.byType(EntryScreen), findsOneWidget);
    final screen = tester.widget<EntryScreen>(find.byType(EntryScreen));
    expect(screen.jumpTo, const Duration(seconds: 30));
    expect(find.text('0:30 / 1:00'), findsOneWidget);
  });

  testWidgets('Einstellungen werden über das Repository gespeichert', (
    tester,
  ) async {
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

    await tester.tap(find.text('Erinnerung aktiv'));
    await tester.pumpAndSettle();
    expect((await services.settings.reminder()).enabled, isFalse);

    await tester.scrollUntilVisible(
      find.text('Sprache der Transkription'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Sprache der Transkription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Englisch'));
    await tester.pumpAndSettle();
    expect(await services.settings.get('language'), 'en');
    expect(find.text('en'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Audio behalten'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Audio behalten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio behalten'));
    await tester.pumpAndSettle();
    expect(await services.settings.get('keepAudio'), 'false');
  });

  testWidgets('Web: Onboarding mit Installationsschritt für iOS', (
    tester,
  ) async {
    final features = FakePlatformFeatures(isIos: true);
    final services = TestServices(onboardingDone: false, features: features);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Als App installieren'), findsOneWidget);
    expect(find.textContaining('Zum Home-Bildschirm'), findsOneWidget);
    expect(find.text('Schritt 1 von 5'), findsOneWidget);

    await tester.tap(find.byKey(onboardingNextKey));
    await tester.pumpAndSettle();
    expect(find.text('Deine Daten bleiben in diesem Browser'), findsOneWidget);
    expect(find.textContaining('Backup ist Pflicht'), findsOneWidget);
  });

  testWidgets(
    'Web: installiert läuft das Onboarding ohne Installationsschritt',
    (tester) async {
      final features = FakePlatformFeatures(isStandalone: true, isIos: false);
      final services = TestServices(onboardingDone: false, features: features);
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      expect(find.text('Als App installieren'), findsNothing);
      expect(find.text('Schritt 1 von 4'), findsOneWidget);
    },
  );

  testWidgets('Web: Kalenderdatei, Speicherstatus und CSP-Satz', (
    tester,
  ) async {
    final features = FakePlatformFeatures();
    final services = TestServices(features: features);
    await tester.pumpWidget(
      buildTestScreen(const SettingsScreen(), services: services),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(reminderCalendarKey), findsOneWidget);
    await tester.tap(find.byKey(reminderCalendarKey));
    await tester.pumpAndSettle();
    expect(features.downloads, hasLength(1));
    expect(features.downloads.single.hour, 21);
    expect(features.downloads.single.title, 'Zeit für deinen Eintrag');
    expect(find.textContaining('Kalenderdatei erstellt'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(storageTileKey),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Nicht zugesichert'), findsOneWidget);
    expect(find.textContaining('3.0 MB belegt, 100 MB frei'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Backup ist Pflicht'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Backup ist Pflicht'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Was dein Gerät verlässt: nichts.'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Content-Security-Policy'), findsOneWidget);
  });

  test('Eintrags-Route nimmt ID oder Argumente mit Sprungziel', () {
    expect(
      AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.entry, arguments: 'a'),
      ),
      isNotNull,
    );
    expect(
      AppRoutes.onGenerateRoute(
        const RouteSettings(
          name: AppRoutes.entry,
          arguments: EntryRouteArgs('a', jumpTo: Duration(seconds: 3)),
        ),
      ),
      isNotNull,
    );
    expect(
      AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.entry, arguments: 42),
      ),
      isNull,
    );
  });
}
