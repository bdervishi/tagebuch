import 'package:diary_storage/diary_storage.dart';
import 'package:test/test.dart';

void main() {
  group('buildFtsMatchExpression', () {
    test('maskiert Begriffe als Phrasen mit Präfix', () {
      expect(buildFtsMatchExpression('Zahnarzt Park'), '"Zahnarzt"* "Park"*');
      expect(buildFtsMatchExpression('Zahnarzt', prefix: false), '"Zahnarzt"');
    });

    test('normalisiert ß wie der Index', () {
      expect(buildFtsMatchExpression('Straße'), '"Strasse"*');
      expect(buildFtsMatchExpression('GROẞ'), '"GROSS"*');
    });

    test('neutralisiert Operatoren und Sonderzeichen', () {
      expect(buildFtsMatchExpression('AND OR NOT'), '"AND"* "OR"* "NOT"*');
      expect(buildFtsMatchExpression('zahn:arzt'), '"zahn:arzt"*');
      expect(buildFtsMatchExpression('(zahn)'), '"(zahn)"*');
      expect(buildFtsMatchExpression('a"b'), '"a""b"*');
      expect(buildFtsMatchExpression('^zahn'), '"^zahn"*');
    });

    test('behandelt ein angehängtes * als Präfixwunsch', () {
      expect(buildFtsMatchExpression('zahn*', prefix: false), '"zahn"*');
      expect(buildFtsMatchExpression('zahn**', prefix: false), '"zahn"*');
      expect(buildFtsMatchExpression('*', prefix: false), isNull);
    });

    test('lässt Begriffe ohne Buchstaben oder Ziffern weg', () {
      expect(buildFtsMatchExpression(''), isNull);
      expect(buildFtsMatchExpression('   '), isNull);
      expect(buildFtsMatchExpression('- ... "'), isNull);
      expect(buildFtsMatchExpression('- Park'), '"Park"*');
      expect(buildFtsMatchExpression('100%'), '"100%"*');
    });

    test('begrenzt die Zahl der Begriffe', () {
      expect(buildFtsMatchExpression('a b c d', maxTerms: 2), '"a"* "b"*');
    });
  });

  group('Faltung für den Segmentabgleich', () {
    test('foldForMatch faltet Groß-/Kleinschreibung, ß und Diakritika', () {
      expect(foldForMatch('Straße Bär Müller Café'), 'strasse bar muller cafe');
      expect(foldForMatch('Łódź Ærø Œuvre'), 'lodz aero oeuvre');
      expect(foldForMatch('ohne Diakritika 123'), 'ohne diakritika 123');
    });

    test('foldedSearchTerms folgt der Begriffsaufteilung', () {
      expect(foldedSearchTerms('Zahn* Straße ...'), ['zahn', 'strasse']);
      expect(foldedSearchTerms(''), isEmpty);
    });

    test('normalizeSharpS ersetzt beide Formen', () {
      expect(normalizeSharpS('Straße GROẞ'), 'Strasse GROSS');
    });
  });

  group('Datumshelfer', () {
    test('formatIsoDay füllt auf', () {
      expect(formatIsoDay(DateTime(2026, 9, 6)), '2026-09-06');
      expect(formatIsoDay(DateTime(999, 1, 1)), '0999-01-01');
    });

    test('isIsoDay prüft nur die Form', () {
      expect(isIsoDay('2026-09-06'), isTrue);
      expect(isIsoDay('2026-9-6'), isFalse);
      expect(isIsoDay('06.09.2026'), isFalse);
    });
  });
}
