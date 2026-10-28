import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/features/bewegung/movement_library.dart';

/// Gebündelte Übungsliste (D24): Datei vollständig, Vorschläge
/// deterministisch, Zeitplan der Pausen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MovementLibrary library;
  setUpAll(() async {
    library = await MovementLibrary.load();
  });

  test('Datei: rund 16 Übungen, alle Felder, bekannte Kategorien, Hinweis', () {
    expect(library.exercises.length, greaterThanOrEqualTo(16));
    final keys = {for (final c in library.categories) c.key};
    expect(keys, containsAll(['stretch', 'walk', 'strength', 'breathe']));
    final ids = <String>{};
    for (final e in library.exercises) {
      expect(ids.add(e.id), isTrue, reason: 'doppelte ID ${e.id}');
      expect(keys, contains(e.category), reason: '${e.id}: ${e.category}');
      expect(e.minutes, greaterThan(0), reason: e.id);
      expect(e.de.trim(), isNotEmpty, reason: e.id);
      expect(e.en.trim(), isNotEmpty, reason: e.id);
      expect(e.howDe.trim(), isNotEmpty, reason: e.id);
      expect(e.howEn.trim(), isNotEmpty, reason: e.id);
      expect(e.own, isFalse);
      // Keine Wirkungsversprechen in den Anleitungen.
      for (final word in ['heilt', 'senkt', 'verbrennt', 'cures', 'burns']) {
        expect(e.howDe.toLowerCase(), isNot(contains(word)), reason: e.id);
        expect(e.howEn.toLowerCase(), isNot(contains(word)), reason: e.id);
      }
    }
    expect(library.notice('de'), contains('Bei Schmerzen abbrechen'));
    expect(library.notice('en'), contains('medical advice'));
    expect(library.byId('m001')?.de, 'Nacken kreisen');
    expect(library.byId('m008')?.seconds, 30);
  });

  test('Vorschläge: drei verschiedene, deterministisch, je Pause anders', () {
    final day = DateTime(2026, 10, 27);
    final a = library.suggestionsFor(day, 0);
    expect(a, hasLength(3));
    expect(a.toSet(), hasLength(3));
    expect(library.suggestionsFor(day, 0), a);
    final b = library.suggestionsFor(day, 1);
    expect(b, isNot(a));
    expect(library.suggestionsFor(DateTime(2026, 10, 28), 0), isNot(a));
    // Eigene Übungen nehmen teil; eine Liste mit zwei Übungen liefert zwei.
    const own = Exercise(
      id: 'own-1',
      category: 'walk',
      minutes: 5,
      de: 'Runde um den Block',
      en: 'Lap around the block',
      own: true,
    );
    final small = const MovementLibrary(
      exercises: [],
      categories: [],
    ).withOwn([own, library.exercises.first]);
    expect(small.suggestionsFor(day, 0), hasLength(2));
    expect(small.inCategory('walk'), contains(own));
    expect(
      const MovementLibrary(
        exercises: [],
        categories: [],
      ).suggestionsFor(day, 0),
      isEmpty,
    );
  });

  test('JSON-Rundlauf: Pausen und eigene Übungen', () {
    const breaks = [
      MovementBreak(hour: 10, minute: 0),
      MovementBreak(hour: 15, minute: 30, weekdays: {6, 7}),
    ];
    final back = MovementBreak.decodeList(MovementBreak.encodeList(breaks));
    expect(back, breaks);
    expect(MovementBreak.decodeList(null), MovementBreak.defaults);
    expect(MovementBreak.decodeList('kaputt'), MovementBreak.defaults);
    expect(MovementBreak.defaults.first.weekdays, {1, 2, 3, 4, 5});

    const own = Exercise(
      id: 'own-2',
      category: 'strength',
      minutes: 0.5,
      de: 'Planke',
      en: 'Planke',
      own: true,
    );
    final e = Exercise.decodeList(Exercise.encodeList([own])).single;
    expect(e, own);
    expect(e.own, isTrue);
    expect(e.minutes, 0.5);
    expect(Exercise.decodeList(''), isEmpty);
  });

  test('Zeitplan: fällige Pause bis zur nächsten, nächste Pause', () {
    const breaks = [
      MovementBreak(hour: 10, minute: 0),
      MovementBreak(hour: 15, minute: 0),
    ];
    // Dienstag, 27. 10. 2026.
    expect(
      MovementSchedule.dueIndex(breaks, DateTime(2026, 10, 27, 9)),
      isNull,
    );
    expect(MovementSchedule.dueIndex(breaks, DateTime(2026, 10, 27, 10)), 0);
    expect(
      MovementSchedule.dueIndex(breaks, DateTime(2026, 10, 27, 14, 59)),
      0,
    );
    expect(MovementSchedule.dueIndex(breaks, DateTime(2026, 10, 27, 15)), 1);
    expect(MovementSchedule.dueIndex(breaks, DateTime(2026, 10, 27, 23)), 1);
    // Samstag: keine Pause gilt.
    expect(
      MovementSchedule.dueIndex(breaks, DateTime(2026, 10, 31, 12)),
      isNull,
    );

    expect(
      MovementSchedule.nextAfter(breaks, DateTime(2026, 10, 27, 11)),
      DateTime(2026, 10, 27, 15),
    );
    // Freitagabend: nächste Pause am Montag.
    expect(
      MovementSchedule.nextAfter(breaks, DateTime(2026, 10, 30, 16)),
      DateTime(2026, 11, 2, 10),
    );
    expect(
      MovementSchedule.nextAfter([
        const MovementBreak(hour: 9, minute: 0, weekdays: {}),
      ], DateTime(2026, 10, 27)),
      isNull,
    );
  });
}
