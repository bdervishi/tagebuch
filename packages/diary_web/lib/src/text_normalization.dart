/// Textnormalisierung für die Suche im Browser.
///
/// Kopie der Regeln aus `packages/diary_storage/lib/src/search/
/// text_normalization.dart` (`ß → ss`, Kleinschreibung, Diakritika des
/// lateinischen Alphabets entfernt, wie der FTS5-Tokenizer `unicode61
/// remove_diacritics 2`). `diary_storage` zieht drift und sqlite3 nach, die
/// im Browser nicht laufen; beide Dateien sind gemeinsam zu pflegen.
library;

/// `ß → ss`, `ẞ → SS`.
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

/// Faltet [input] für den Abgleich: Kleinschreibung, `ß → ss`, Diakritika
/// entfernt. "Straße" und "STRASSE" werden beide zu "strasse".
String foldForMatch(String input) => foldWithMap(input).folded;

/// Gefalteter Text mit Rückabbildung: [originalOffset] gibt für jede
/// Code-Unit des gefalteten Texts den Code-Unit-Offset im Original an
/// (plus einen Endeintrag), damit Treffer im gefalteten Text als Ausschnitt
/// des Originals gezeigt werden können.
final class FoldedText {
  const FoldedText(this.folded, this.originalOffset);

  final String folded;
  final List<int> originalOffset;

  /// Offset im Original zu einem Offset im gefalteten Text.
  int toOriginal(int foldedOffset) {
    if (foldedOffset <= 0) return 0;
    if (foldedOffset >= originalOffset.length) return originalOffset.last;
    return originalOffset[foldedOffset];
  }
}

FoldedText foldWithMap(String input) {
  final buffer = StringBuffer();
  final offsets = <int>[];
  var position = 0;
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final lower = normalizeSharpS(char).toLowerCase();
    final mapped = StringBuffer();
    for (final r in lower.runes) {
      mapped.write(_foldTable[r] ?? String.fromCharCode(r));
    }
    final piece = mapped.toString();
    for (var i = 0; i < piece.length; i++) {
      offsets.add(position);
    }
    buffer.write(piece);
    position += char.length;
  }
  offsets.add(position);
  return FoldedText(buffer.toString(), offsets);
}
