import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/features/einstellungen/settings_screen.dart';
import 'package:tagebuch_app/features/zitate/quote_card.dart';
import 'package:tagebuch_app/features/zitate/quote_library.dart';
import 'package:tagebuch_app/features/zitate/quotes_screen.dart';

import 'test_app.dart';

/// Zitat zum Tag (D20): Karte auf "Heute", Herz, Themen, eigene Zitate,
/// Abschalten in den Einstellungen.
void main() {
  late QuoteLibrary library;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    library = await QuoteLibrary.load();
  });

  testWidgets('"Heute" zeigt das Zitat des Tages, Herz merkt es', (
    tester,
  ) async {
    final services = TestServices(quoteLibrary: library);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    expect(find.byKey(quoteCardKey), findsOneWidget);
    final now = DateTime.now();
    final expected = library.forDay(
      DateTime(now.year, now.month, now.day),
      slot: now.hour < 16 ? QuoteLibrary.slotMorning : QuoteLibrary.slotEvening,
    )!;
    expect(find.textContaining(expected.de), findsOneWidget);
    expect(find.textContaining(expected.author), findsOneWidget);

    await tester.tap(find.byKey(quoteFavoriteKey));
    await tester.pumpAndSettle();
    expect(
      await services.settings.get(AppSettings.keyQuoteFavorites),
      expected.id,
    );
    await tester.tap(find.byKey(quoteFavoriteKey));
    await tester.pumpAndSettle();
    expect(await services.settings.get(AppSettings.keyQuoteFavorites), '');
  });

  testWidgets(
    'Zitatenschatz: Themen wählen, eigenes Zitat anlegen und löschen',
    (tester) async {
      final services = TestServices(quoteLibrary: library);
      await tester.pumpWidget(
        buildTestScreen(const QuotesScreen(), services: services),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zitate'), findsOneWidget);
      // Die Liste baut nur den sichtbaren Teil; zu den Abschnitten scrollen.
      await tester.scrollUntilVisible(
        find.byKey(quotesThemeChipKey('gratitude')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(quotesThemeChipKey('gratitude')));
      await tester.pumpAndSettle();
      expect(
        await services.settings.get(AppSettings.keyQuoteThemes),
        'gratitude',
      );

      await tester.scrollUntilVisible(
        find.byKey(quotesAddOwnKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Noch nichts markiert und nichts Eigenes.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(quotesAddOwnKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(quotesOwnTextKey),
        'Langsam ist schnell.',
      );
      await tester.enterText(find.byKey(quotesOwnAuthorKey), 'Oma');
      await tester.tap(find.byKey(quotesOwnSaveKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Langsam ist schnell.'), findsOneWidget);
      expect(find.text('Oma'), findsOneWidget);
      final stored = await services.settings.get(AppSettings.keyOwnQuotes);
      expect(stored, contains('Langsam ist schnell.'));
      // Genau ein Zitat gespeichert (die Datei trug es früher doppelt; der
      // Text steht je Zitat zweimal, für `de` und `en`).
      expect('"own":true'.allMatches(stored!), hasLength(1));

      await tester.tap(find.byTooltip('Eigenes Zitat entfernen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Langsam ist schnell.'), findsNothing);
      expect(await services.settings.get(AppSettings.keyOwnQuotes), '[]');
    },
  );

  testWidgets('Einstellung aus: keine Karte auf "Heute"', (tester) async {
    final services = TestServices(quoteLibrary: library);
    await services.settings.set(AppSettings.keyQuotesEnabled, 'false');
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    expect(find.byKey(quoteCardKey), findsNothing);

    // In den Einstellungen wieder einschalten.
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(quotesEnabledKey),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(quotesEnabledKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heute').last);
    await tester.pumpAndSettle();
    expect(find.byKey(quoteCardKey), findsOneWidget);
  });
}
