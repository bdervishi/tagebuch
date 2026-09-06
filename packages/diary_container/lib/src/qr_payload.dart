import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Inhalt des QR-Codes beim Gerätewechsel (D6): unter 200 Byte, nur
/// Schlüsselmaterial und Sitzungsdaten, nie Tagebuchinhalt.
///
/// Textform (für QR im Byte-Modus und zum Vorlesen/Abtippen als Rückfall):
/// `tgb1:<base64url(version u8 | platform u8 | sessionId 16 | publicKey 32)>`.
@immutable
class QrPayload {
  const QrPayload({
    required this.platform,
    required this.sessionId,
    required this.publicKey,
    this.version = 1,
  }) : assert(sessionId.length == 16),
       assert(publicKey.length == 32);

  static const prefix = 'tgb1:';

  final int version;

  /// 1 = iOS, 2 = Android, 0 = unbekannt; nur zur Anzeige der Übergabewege.
  final int platform;
  final Uint8List sessionId;
  final Uint8List publicKey;

  String encode() {
    final raw = Uint8List.fromList([
      version,
      platform,
      ...sessionId,
      ...publicKey,
    ]);
    return prefix + base64Url.encode(raw).replaceAll('=', '');
  }

  static QrPayload decode(String text) {
    if (!text.startsWith(prefix)) {
      throw const FormatException('Kein Tagebuch-QR-Code');
    }
    var b64 = text.substring(prefix.length);
    while (b64.length % 4 != 0) {
      b64 += '=';
    }
    final raw = base64Url.decode(b64);
    if (raw.length != 50) {
      throw FormatException('QR-Nutzlast hat ${raw.length} Byte, erwartet 50');
    }
    if (raw[0] != 1) {
      throw FormatException('QR-Version ${raw[0]} wird nicht unterstützt');
    }
    return QrPayload(
      version: raw[0],
      platform: raw[1],
      sessionId: Uint8List.fromList(raw.sublist(2, 18)),
      publicKey: Uint8List.fromList(raw.sublist(18, 50)),
    );
  }

  /// Kurzer Prüfcode (6 Ziffern) aus dem öffentlichen Schlüssel, den beide
  /// Geräte anzeigen; verhindert, dass ein untergeschobener Container
  /// unbemerkt importiert wird (Red-Team-Befund, docs/06 Abschnitt 8).
  String verificationCode() {
    var acc = 0;
    for (final b in publicKey) {
      acc = (acc * 31 + b) % 1000000;
    }
    return acc.toString().padLeft(6, '0');
  }
}
