/// Textnormalisierung für die Suche.
library;

/// Dieselbe Ersetzung, die die FTS-Trigger auf den indizierten Text anwenden
/// (`ß → ss`, `ẞ → SS`). Suchbegriffe müssen sie ebenfalls durchlaufen.
String normalizeSharpS(String input) =>
    input.replaceAll('ß', 'ss').replaceAll('ẞ', 'SS');

const Map<String, String> _foldGroups = {
  'a': 'àáâãäåāăą',
  'c': 'çćĉċč',
  'd': 'ďđ',
  'e': 'èéêëēĕėęě',
  'g': 'ĝğġģ',
  'h': 'ĥħ',
  'i': 'ìíîïĩīĭįı',
  'j': 'ĵ',
  'k': 'ķ',
  'l': 'ĺļľŀł',
  'n': 'ñńņň',
  'o': 'òóôõöøōŏő',
  'r': 'ŕŗř',
  's': 'śŝşš',
  't': 'ţťŧ',
  'u': 'ùúûüũūŭůűų',
  'w': 'ŵ',
  'y': 'ýÿŷ',
  'z': 'źżž',
  'ae': 'æ',
  'oe': 'œ',
};

final Map<int, String> _foldTable = {
  for (final entry in _foldGroups.entries)
    for (final rune in entry.value.runes) rune: entry.key,
};

/// Faltet [input] für den Abgleich in Dart ähnlich wie der Tokenizer
/// `unicode61 remove_diacritics 2`: Kleinschreibung, `ß → ss`, Diakritika
/// des lateinischen Alphabets entfernt.
///
/// Wird genutzt, um zu einem FTS-Treffer das erste passende Segment zu
/// finden; kleine Abweichungen zum Tokenizer kosten höchstens den Sprungpunkt,
/// nie den Treffer.
String foldForMatch(String input) {
  final lower = normalizeSharpS(input).toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final mapped = _foldTable[rune];
    if (mapped != null) {
      buffer.write(mapped);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
