/// Aufbau sicherer FTS5-MATCH-Ausdrücke aus Nutzereingaben.
library;

import 'text_normalization.dart';

final RegExp _whitespace = RegExp(r'\s+');
final RegExp _trailingStars = RegExp(r'\*+$');
final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Übersetzt die Eingabe [input] in einen FTS5-MATCH-Ausdruck.
///
/// Jeder durch Leerraum getrennte Begriff wird zu einem Phrasen-String in
/// doppelten Anführungszeichen (innere `"` werden verdoppelt). Damit haben
/// FTS5-Operatoren (`AND`, `OR`, `NOT`, `NEAR`, Klammern, Doppelpunkt) keine
/// Wirkung; Begriffe werden implizit UND-verknüpft. Mit [prefix] (Vorgabe:
/// an) oder einem angehängten `*` wird ein Begriff zur Präfixsuche
/// (`"zahn"*` findet "Zahnarzt"). `ß` wird wie im Index zu `ss`.
///
/// Begriffe ohne Buchstaben oder Ziffern entfallen. Höchstens [maxTerms]
/// Begriffe werden übernommen. Bleibt nichts übrig, ist das Ergebnis `null`
/// und der Aufrufer liefert keine Treffer.
String? buildFtsMatchExpression(
  String input, {
  bool prefix = true,
  int maxTerms = 16,
}) {
  final terms = <String>[];
  for (final raw in normalizeSharpS(input).split(_whitespace)) {
    if (raw.isEmpty) {
      continue;
    }
    var term = raw;
    var termPrefix = prefix;
    if (term.endsWith('*')) {
      termPrefix = true;
      term = term.replaceFirst(_trailingStars, '');
    }
    if (!_letterOrDigit.hasMatch(term)) {
      continue;
    }
    final quoted = '"${term.replaceAll('"', '""')}"';
    terms.add(termPrefix ? '$quoted*' : quoted);
    if (terms.length >= maxTerms) {
      break;
    }
  }
  return terms.isEmpty ? null : terms.join(' ');
}

/// Zerlegt [input] in gefaltete Begriffe für den Segmentabgleich
/// (siehe [foldForMatch]); Reihenfolge wie in [buildFtsMatchExpression].
List<String> foldedSearchTerms(String input, {int maxTerms = 16}) {
  final terms = <String>[];
  for (final raw in input.split(_whitespace)) {
    final term = raw.replaceFirst(_trailingStars, '');
    if (term.isEmpty || !_letterOrDigit.hasMatch(term)) {
      continue;
    }
    terms.add(foldForMatch(term));
    if (terms.length >= maxTerms) {
      break;
    }
  }
  return terms;
}
