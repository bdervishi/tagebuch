import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/zitate/quote_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuoteLibrary library;
  setUpAll(() async {
    library = await QuoteLibrary.load();
  });

  test('Datei: über 100 Zitate, alle Felder, nur bekannte Themen', () {
    expect(library.quotes.length, greaterThanOrEqualTo(100));
    final themeKeys = {for (final t in library.themes) t.key};
    final ids = <String>{};
    for (final q in library.quotes) {
      expect(ids.add(q.id), isTrue, reason: 'doppelte ID ${q.id}');
      expect(q.author, isNotEmpty);
      expect(q.de.trim(), isNotEmpty);
      expect(q.en.trim(), isNotEmpty);
      expect(q.themes, isNotEmpty, reason: q.id);
      for (final t in q.themes) {
        expect(themeKeys, contains(t), reason: '${q.id}: $t');
      }
      expect(q.own, isFalse);
    }
    expect(themeKeys, containsAll(['calm', 'gratitude', 'courage', 'goals']));
  });

  test(
    'Zitat des Tages ist deterministisch, morgens und abends verschieden',
    () {
      final day = DateTime(2026, 10, 27);
      final a = library.forDay(day);
      final b = library.forDay(day);
      expect(a, isNotNull);
      expect(a, b);
      final evening = library.forDay(day, slot: QuoteLibrary.slotEvening);
      expect(evening, isNot(a));
      // Benachbarte Tage: nicht dasselbe Zitat.
      final next = library.forDay(DateTime(2026, 10, 28));
      expect(next, isNot(a));
    },
  );

  test('Themenfilter wirkt; eigene Zitate bleiben immer im Topf', () {
    const own = Quote(
      id: 'own-1',
      author: 'Ich',
      de: 'Mein Satz.',
      en: 'My sentence.',
      own: true,
    );
    final lib = library.withOwn([own]);
    final pool = lib.pool({'gratitude'});
    expect(pool, contains(own));
    for (final q in pool.where((q) => !q.own)) {
      expect(q.themes, contains('gratitude'));
    }
    // Unbekanntes Thema: Rückfall auf alle.
    expect(lib.pool({'gibt-es-nicht'}).length, lib.quotes.length);
  });

  test('Sprache: de oder en; JSON-Rundlauf eigener Zitate', () {
    final q = library.quotes.first;
    expect(q.text('de'), q.de);
    expect(q.text('en'), q.en);
    const own = Quote(
      id: 'own-2',
      author: 'Oma',
      de: 'Langsam ist schnell.',
      en: 'Slow is fast.',
      own: true,
    );
    final back = Quote.fromJson(own.toJson());
    expect(back, own);
    expect(back.own, isTrue);
    expect(back.author, 'Oma');
  });
}
