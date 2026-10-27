import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_keys/diary_keys.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

import 'indexed_db_store.dart';

/// Parameter für `generateKey` (AES-GCM, 256 Bit).
extension type _AesKeyGenParams._(JSObject _) implements JSObject {
  external factory _AesKeyGenParams({
    required String name,
    required int length,
  });
}

/// Parameter für `encrypt`/`decrypt` (AES-GCM mit IV, Zusatzdaten, 128-Bit-Tag).
extension type _AesGcmParams._(JSObject _) implements JSObject {
  external factory _AesGcmParams({
    required String name,
    required JSUint8Array iv,
    required JSUint8Array additionalData,
    required int tagLength,
  });
}

/// Master-Key der Web-Fassung (D16, Punkt 2): ein WebCrypto-Schlüssel
/// AES-256-GCM mit `extractable: false`, einmal erzeugt und als
/// `CryptoKey`-Objekt in IndexedDB (Store `keys`, Schlüssel `master-v1`)
/// abgelegt. JavaScript kann den Schlüssel benutzen, aber nicht auslesen.
///
/// [wrap] liefert `nonce(12) || AES-GCM(dek, aad = purpose als UTF-8)`,
/// genau das Layout von `KeyWrap` mit `AeadId.aes256Gcm`, damit die Blobs im
/// Kopf der Chunk-Dateien zur Dart-Referenz passen. [unwrap] wirft bei
/// falschem Zweck oder verändertem Blob [AuthenticationException].
class WebMasterKeyStore implements DekWrapper {
  WebMasterKeyStore(this._db, {RandomSource? random, this.keyId = 'master-v1'})
    : _random = random ?? SecureRandomSource();

  static const String _algorithm = 'AES-GCM';
  static const int nonceLength = 12;
  static const int tagLength = 16;

  final IndexedDbStore _db;
  final RandomSource _random;
  final String keyId;
  web.CryptoKey? _cached;

  web.SubtleCrypto get _subtle => web.window.crypto.subtle;

  /// Ob bereits ein Master-Key existiert (Onboarding vs. Rückkehr).
  Future<bool> get exists async {
    if (_cached != null) return true;
    final stored = await _db.get(IndexedDbStore.keysStore, keyId);
    return stored != null;
  }

  /// Liefert den Schlüssel, legt ihn beim ersten Aufruf an.
  Future<web.CryptoKey> _key() async {
    final cached = _cached;
    if (cached != null) return cached;
    final stored = await _db.get(IndexedDbStore.keysStore, keyId);
    if (stored != null) {
      return _cached = stored as web.CryptoKey;
    }
    final generated = await _subtle
        .generateKey(
          _AesKeyGenParams(name: _algorithm, length: 256),
          false,
          ['encrypt'.toJS, 'decrypt'.toJS].toJS,
        )
        .toDart;
    final key = generated as web.CryptoKey;
    await _db.put(IndexedDbStore.keysStore, keyId, key);
    return _cached = key;
  }

  /// Das `CryptoKey`-Objekt selbst (nicht exportierbar); nur für Tests, die
  /// `extractable` und das Scheitern von `exportKey` prüfen.
  @visibleForTesting
  Future<web.CryptoKey> cryptoKey() => _key();

  @override
  Future<Uint8List> wrap(Uint8List dek, {required String purpose}) async {
    final key = await _key();
    final nonce = _random.bytes(nonceLength);
    final sealed = await _subtle
        .encrypt(
          _AesGcmParams(
            name: _algorithm,
            iv: nonce.toJS,
            additionalData: _aad(purpose),
            tagLength: tagLength * 8,
          ),
          key,
          dek.toJS,
        )
        .toDart;
    final ciphertext = (sealed as JSArrayBuffer).toDart.asUint8List();
    final out = Uint8List(nonce.length + ciphertext.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, ciphertext);
    return out;
  }

  @override
  Future<Uint8List> unwrap(Uint8List wrapped, {required String purpose}) async {
    if (wrapped.length <= nonceLength + tagLength) {
      throw const AuthenticationException('Gewrappter Schlüssel zu kurz');
    }
    final key = await _key();
    final nonce = Uint8List.sublistView(wrapped, 0, nonceLength);
    final sealed = Uint8List.sublistView(wrapped, nonceLength);
    try {
      final clear = await _subtle
          .decrypt(
            _AesGcmParams(
              name: _algorithm,
              iv: Uint8List.fromList(nonce).toJS,
              additionalData: _aad(purpose),
              tagLength: tagLength * 8,
            ),
            key,
            Uint8List.fromList(sealed).toJS,
          )
          .toDart;
      return Uint8List.fromList((clear as JSArrayBuffer).toDart.asUint8List());
    } catch (_) {
      // WebCrypto meldet jeden Fehlschlag als OperationError ohne Details.
      throw const AuthenticationException();
    }
  }

  /// "Alles löschen": entfernt den Master-Key; alle damit gewrappten
  /// Schlüssel und damit alle Daten werden unlesbar (Crypto-Shredding).
  Future<void> destroy() async {
    _cached = null;
    await _db.delete(IndexedDbStore.keysStore, keyId);
  }

  static JSUint8Array _aad(String purpose) =>
      Uint8List.fromList(utf8.encode(purpose)).toJS;
}
