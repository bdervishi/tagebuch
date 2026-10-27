import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_keys/diary_keys.dart';

import 'indexed_db_store.dart';

/// Verschlüsselte JSON-Datensätze in IndexedDB (Ersatz für SQLCipher, D16).
///
/// Ein zufälliger Datensatz-Schlüssel (32 Byte) wird einmal erzeugt, mit dem
/// [DekWrapper] (Zweck [dekPurpose]) gewrappt im Store `meta` abgelegt und
/// beim Öffnen entpackt. Jeder Datensatz liegt unter dem Schlüssel
/// `<collection>/<id>` als `nonce(12) || AES-256-GCM(JSON-UTF-8)`; die
/// Zusatzdaten (AAD) sind genau dieser Schlüssel, damit ein Datensatz nicht
/// unter einen anderen Schlüssel verschoben werden kann.
class EncryptedRecordStore {
  EncryptedRecordStore._(this._db, this._aead, this._random, this._dek);

  /// Zweck beim Wrappen des Datensatz-Schlüssels.
  static const String dekPurpose = 'records-v1';

  /// Schlüssel des gewrappten Datensatz-Schlüssels im Store `meta`.
  static const String dekMetaKey = 'records-dek-v1';

  final IndexedDbStore _db;
  final Aead _aead;
  final RandomSource _random;
  final Uint8List _dek;
  final _changes = StreamController<String>.broadcast();
  bool _closed = false;

  /// Meldet die Sammlung, in der sich etwas geändert hat (für `watch…`).
  Stream<String> get changes => _changes.stream;

  /// Öffnet den Store: entpackt den Datensatz-Schlüssel oder legt ihn an.
  static Future<EncryptedRecordStore> open(
    IndexedDbStore db,
    DekWrapper wrapper, {
    Aead? aead,
    RandomSource? random,
  }) async {
    final rng = random ?? SecureRandomSource();
    final primitive = aead ?? CryptographyAead.aes256Gcm();
    final stored = await db.get(IndexedDbStore.metaStore, dekMetaKey);
    Uint8List dek;
    if (stored == null) {
      dek = rng.bytes(primitive.id.keyLength);
      final wrapped = await wrapper.wrap(dek, purpose: dekPurpose);
      await db.put(IndexedDbStore.metaStore, dekMetaKey, wrapped.toJS);
    } else {
      final wrapped = (stored as JSUint8Array).toDart;
      dek = await wrapper.unwrap(wrapped, purpose: dekPurpose);
    }
    return EncryptedRecordStore._(db, primitive, rng, dek);
  }

  static String recordKey(String collection, String id) {
    if (collection.contains('/') || collection.isEmpty || id.isEmpty) {
      throw ArgumentError('Ungültiger Datensatz-Schlüssel: $collection/$id');
    }
    return '$collection/$id';
  }

  /// Speichert [record] (JSON-fähige Map) unter `<collection>/<id>`.
  Future<void> put(
    String collection,
    String id,
    Map<String, Object?> record,
  ) async {
    _checkOpen();
    final key = recordKey(collection, id);
    final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(record)));
    final nonce = _random.bytes(_aead.id.nonceLength);
    final sealed = await _aead.seal(
      key: _dek,
      nonce: nonce,
      plaintext: plaintext,
      aad: _aad(key),
    );
    final blob = Uint8List(nonce.length + sealed.length)
      ..setAll(0, nonce)
      ..setAll(nonce.length, sealed);
    await _db.put(IndexedDbStore.recordsStore, key, blob.toJS);
    _notify(collection);
  }

  /// Liest den Datensatz oder `null`. Wirft [AuthenticationException], wenn
  /// der Inhalt nicht zu Schlüssel und AAD passt.
  Future<Map<String, Object?>?> get(String collection, String id) async {
    _checkOpen();
    final key = recordKey(collection, id);
    final stored = await _db.get(IndexedDbStore.recordsStore, key);
    if (stored == null) return null;
    return _decode(key, (stored as JSUint8Array).toDart);
  }

  /// Alle Datensätze einer Sammlung in Schlüsselreihenfolge.
  Future<List<Map<String, Object?>>> getAll(String collection) async {
    _checkOpen();
    // recordKey prüft die Sammlung; das Präfix endet mit dem Trenner.
    final prefix = recordKey(
      collection,
      '_',
    ).substring(0, collection.length + 1);
    final keys = await _db.getAllKeys(
      IndexedDbStore.recordsStore,
      prefix: prefix,
    );
    final values = await _db.getAll(
      IndexedDbStore.recordsStore,
      prefix: prefix,
    );
    final out = <Map<String, Object?>>[];
    for (var i = 0; i < keys.length && i < values.length; i++) {
      out.add(await _decode(keys[i], (values[i] as JSUint8Array).toDart));
    }
    return out;
  }

  Future<void> delete(String collection, String id) async {
    _checkOpen();
    await _db.delete(IndexedDbStore.recordsStore, recordKey(collection, id));
    _notify(collection);
  }

  /// Entfernt alle Datensätze (der Datensatz-Schlüssel bleibt; "Alles
  /// löschen" vernichtet zusätzlich den Master-Key).
  Future<void> clear() async {
    _checkOpen();
    await _db.clear(IndexedDbStore.recordsStore);
    _notify('*');
  }

  /// Nullt den Datensatz-Schlüssel; danach ist der Store unbenutzbar.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    zeroize(_dek);
    await _changes.close();
  }

  Future<Map<String, Object?>> _decode(String key, Uint8List blob) async {
    final n = _aead.id.nonceLength;
    if (blob.length <= n) {
      throw const AuthenticationException('Datensatz zu kurz');
    }
    final clear = await _aead.open(
      key: _dek,
      nonce: Uint8List.fromList(Uint8List.sublistView(blob, 0, n)),
      sealed: Uint8List.fromList(Uint8List.sublistView(blob, n)),
      aad: _aad(key),
    );
    final decoded = jsonDecode(utf8.decode(clear));
    if (decoded is! Map) {
      throw const FormatException('Datensatz ist kein JSON-Objekt');
    }
    return Map<String, Object?>.from(decoded);
  }

  static Uint8List _aad(String key) => Uint8List.fromList(utf8.encode(key));

  void _notify(String collection) {
    if (!_changes.isClosed) _changes.add(collection);
  }

  void _checkOpen() {
    if (_closed) throw StateError('EncryptedRecordStore ist geschlossen');
  }
}
