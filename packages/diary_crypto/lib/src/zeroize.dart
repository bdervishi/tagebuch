import 'dart:typed_data';

/// Überschreibt Schlüsselmaterial nach Gebrauch (Speicherhygiene, docs/05).
/// Dart garantiert kein sofortiges Freigeben; das Nullen verkürzt aber das
/// Fenster, in dem ein Speicherabbild Schlüssel enthält.
void zeroize(Uint8List bytes) {
  bytes.fillRange(0, bytes.length, 0);
}

/// Vergleich in konstanter Zeit (für Fingerabdrücke und Prüfcodes, D6).
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
