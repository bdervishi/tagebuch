import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/l10n/app_localizations.dart';

import 'test_app.dart';

void main() {
  test('Deutsche und englische Übersetzungen werden geladen', () async {
    final de = await AppLocalizations.delegate.load(const Locale('de'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(de.navToday, 'Heute');
    expect(en.navToday, 'Today');
    expect(de.transcriptPending, 'Transkription folgt');
    expect(en.transcriptPending, 'Transcription to follow');
    expect(de.searchResultCount(1), '1 Eintrag');
    expect(de.searchResultCount(3), '3 Einträge');
    expect(en.searchResultCount(2), '2 entries');
    expect(
      AppLocalizations.supportedLocales,
      containsAll([const Locale('de'), const Locale('en')]),
    );
  });

  testWidgets('App läuft auf Deutsch', (tester) async {
    await tester.pumpWidget(buildTestApp(locale: const Locale('de')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Heute'),
      ),
      findsOneWidget,
    );
    expect(find.text('Alles bleibt auf diesem Gerät.'), findsOneWidget);
  });

  testWidgets('App läuft auf Englisch', (tester) async {
    await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Today'),
      ),
      findsOneWidget,
    );
    expect(find.text('Everything stays on this device.'), findsOneWidget);
  });
}
