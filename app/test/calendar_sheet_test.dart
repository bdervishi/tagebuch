import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/einstellungen/calendar_sheet.dart';
import 'package:tagebuch_app/features/einstellungen/settings_screen.dart';

import 'test_app.dart';

/// Kalender-Links (D18): Google öffnet einen Link mit täglicher Wiederholung,
/// Outlook ohne (mit Hinweis), ohne Link-Fähigkeit bleibt nur die Datei.
void main() {
  Future<FakePlatformFeatures> open(
    WidgetTester tester, {
    bool canOpenLinks = true,
  }) async {
    final features = FakePlatformFeatures()..canOpenLinksValue = canOpenLinks;
    await tester.pumpWidget(
      buildTestScreen(
        const SettingsScreen(),
        services: TestServices(features: features),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(reminderCalendarKey));
    await tester.pumpAndSettle();
    return features;
  }

  testWidgets('Google: Link mit Titel, 21:00 und täglicher Wiederholung', (
    tester,
  ) async {
    final features = await open(tester);
    expect(find.textContaining('nie Tagebuchinhalte'), findsOneWidget);
    await tester.tap(find.byKey(reminderCalendarGoogleKey));
    await tester.pumpAndSettle();
    expect(features.openedLinks, hasLength(1));
    final uri = features.openedLinks.single;
    expect(uri.host, 'calendar.google.com');
    expect(uri.queryParameters['text'], 'Zeit für deinen Eintrag');
    expect(uri.queryParameters['dates'], contains('T210000/'));
    expect(uri.queryParameters['recur'], 'RRULE:FREQ=DAILY');
    expect(features.downloads, isEmpty);
    expect(find.textContaining('Kalender geöffnet'), findsOneWidget);
  });

  testWidgets('Outlook privat und Microsoft 365: Hinweis auf Wiederholung', (
    tester,
  ) async {
    final features = await open(tester);
    await tester.tap(find.byKey(reminderCalendarOutlookKey));
    await tester.pumpAndSettle();
    expect(features.openedLinks.single.host, 'outlook.live.com');
    expect(
      features.openedLinks.single.queryParameters['startdt'],
      endsWith('T21:00:00'),
    );
    expect(find.textContaining('Wiederholen: täglich'), findsOneWidget);

    await tester.tap(find.byKey(reminderCalendarKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(reminderCalendarOfficeKey));
    await tester.pumpAndSettle();
    expect(features.openedLinks.last.host, 'outlook.office.com');
  });

  testWidgets('Ohne Link-Fähigkeit nur die Kalenderdatei', (tester) async {
    await open(tester, canOpenLinks: false);
    expect(find.byKey(reminderCalendarGoogleKey), findsNothing);
    expect(find.byKey(reminderCalendarOutlookKey), findsNothing);
    expect(find.byKey(reminderCalendarIcsKey), findsOneWidget);
  });
}
