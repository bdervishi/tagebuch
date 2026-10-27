import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Fehler aus IndexedDB (Öffnen, Transaktion, Anfrage). Die Meldung stammt
/// aus der `DOMException` des Browsers und enthält keine Nutzdaten.
class IndexedDbException implements Exception {
  const IndexedDbException(this.message);
  final String message;

  @override
  String toString() => 'IndexedDbException: $message';
}

/// Kleine Promise-/Event-Brücke zu IndexedDB (D16, Punkt 1).
///
/// Eine Datenbank mit vier Object Stores, alle mit expliziten
/// Zeichenketten-Schlüsseln (kein `keyPath`):
///
/// * `keys`: der nicht exportierbare WebCrypto-Master-Key (`CryptoKey`-Objekt),
/// * `records`: verschlüsselte JSON-Datensätze (`EncryptedRecordStore`),
/// * `files`: verschlüsselte Chunk-Dateien (`EncryptedFileStore`),
/// * `meta`: gewrappte Datensatz-Schlüssel und Formatkennungen.
///
/// Schreibende Aufrufe warten auf `complete` der Transaktion, nicht nur auf
/// `success` der Anfrage, damit die Daten beim Rückkehren dauerhaft sind.
class IndexedDbStore {
  IndexedDbStore._(this._db, this.name);

  /// Name der App-Datenbank.
  static const String databaseName = 'tagebuch';

  /// Schemaversion. Neue Object Stores oder Indizes erhöhen die Zahl und
  /// werden in [_upgrade] angelegt.
  static const int schemaVersion = 1;

  static const String keysStore = 'keys';
  static const String recordsStore = 'records';
  static const String filesStore = 'files';
  static const String metaStore = 'meta';

  static const List<String> storeNames = [
    keysStore,
    recordsStore,
    filesStore,
    metaStore,
  ];

  final web.IDBDatabase _db;
  final String name;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Öffnet (oder legt an) die Datenbank [name] in Version [schemaVersion].
  static Future<IndexedDbStore> open({String name = databaseName}) {
    final completer = Completer<IndexedDbStore>();
    final request = web.window.indexedDB.open(name, schemaVersion);
    request.onupgradeneeded = ((web.IDBVersionChangeEvent event) {
      final db = request.result as web.IDBDatabase;
      _upgrade(db, event.oldVersion);
    }).toJS;
    request.onsuccess = ((web.Event _) {
      final db = request.result as web.IDBDatabase;
      // Wird die Datenbank anderswo (zweiter Tab) hochgestuft oder gelöscht,
      // schließen wir diese Verbindung, damit die andere nicht blockiert.
      db.onversionchange = ((web.Event _) => db.close()).toJS;
      completer.complete(IndexedDbStore._(db, name));
    }).toJS;
    request.onerror = ((web.Event _) {
      completer.completeError(
        IndexedDbException(request.error?.message ?? 'open fehlgeschlagen'),
      );
    }).toJS;
    request.onblocked = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const IndexedDbException(
            'Datenbank durch eine andere Verbindung blockiert',
          ),
        );
      }
    }).toJS;
    return completer.future;
  }

  static void _upgrade(web.IDBDatabase db, int oldVersion) {
    // Version 0 -> 1: alle vier Stores. Spätere Versionen hängen hier an.
    for (final store in storeNames) {
      if (!db.objectStoreNames.contains(store)) {
        db.createObjectStore(store);
      }
    }
  }

  /// Löscht die Datenbank vollständig ("Alles löschen", Tests). Offene
  /// Verbindungen müssen vorher geschlossen sein, sonst blockiert der Browser.
  static Future<void> deleteDatabase({String name = databaseName}) {
    final completer = Completer<void>();
    final request = web.window.indexedDB.deleteDatabase(name);
    request.onsuccess = ((web.Event _) => completer.complete()).toJS;
    request.onerror = ((web.Event _) {
      completer.completeError(
        IndexedDbException(request.error?.message ?? 'delete fehlgeschlagen'),
      );
    }).toJS;
    request.onblocked = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const IndexedDbException(
            'Löschen blockiert: Datenbank ist noch geöffnet',
          ),
        );
      }
    }).toJS;
    return completer.future;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _db.close();
  }

  /// Liest den Wert zu [key] oder `null`.
  Future<JSAny?> get(String store, String key) =>
      _read(store, (s) => s.get(key.toJS));

  /// Schreibt [value] unter [key] (ersetzt einen vorhandenen Wert).
  Future<void> put(String store, String key, JSAny? value) =>
      _write(store, (s) => s.put(value, key.toJS));

  /// Entfernt [key]; fehlende Schlüssel sind kein Fehler.
  Future<void> delete(String store, String key) =>
      _write(store, (s) => s.delete(key.toJS));

  /// Leert den Store.
  Future<void> clear(String store) => _write(store, (s) => s.clear());

  /// Alle Schlüssel des Stores, optional nur die mit [prefix].
  Future<List<String>> getAllKeys(String store, {String? prefix}) async {
    final result = await _read(
      store,
      (s) => prefix == null ? s.getAllKeys() : s.getAllKeys(_range(prefix)),
    );
    final array = result as JSArray<JSString>;
    return array.toDart.map((k) => k.toDart).toList(growable: false);
  }

  /// Alle Werte des Stores, optional nur die mit Schlüsselpräfix [prefix],
  /// in Schlüsselreihenfolge.
  Future<List<JSAny?>> getAll(String store, {String? prefix}) async {
    final result = await _read(
      store,
      (s) => prefix == null ? s.getAll() : s.getAll(_range(prefix)),
    );
    return (result as JSArray<JSAny?>).toDart;
  }

  /// Schlüsselbereich aller Zeichenketten, die mit [prefix] beginnen.
  static web.IDBKeyRange _range(String prefix) =>
      web.IDBKeyRange.bound(prefix.toJS, '$prefix￿'.toJS);

  Future<JSAny?> _read(
    String store,
    web.IDBRequest Function(web.IDBObjectStore store) action,
  ) {
    _checkOpen();
    final tx = _db.transaction(store.toJS, 'readonly');
    final request = action(tx.objectStore(store));
    return _awaitRequest(request);
  }

  Future<void> _write(
    String store,
    web.IDBRequest Function(web.IDBObjectStore store) action,
  ) {
    _checkOpen();
    final completer = Completer<void>();
    final tx = _db.transaction(store.toJS, 'readwrite');
    tx.oncomplete = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    tx.onerror = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          IndexedDbException(tx.error?.message ?? 'Transaktion fehlgeschlagen'),
        );
      }
    }).toJS;
    tx.onabort = ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          IndexedDbException(tx.error?.message ?? 'Transaktion abgebrochen'),
        );
      }
    }).toJS;
    final request = action(tx.objectStore(store));
    request.onerror = ((web.Event event) {
      // Fehler der Anfrage brechen die Transaktion ab; die Meldung kommt über
      // onabort. Hier nur verhindern, dass der Browser den Fehler als
      // unbehandelt meldet.
      event.preventDefault();
    }).toJS;
    return completer.future;
  }

  static Future<JSAny?> _awaitRequest(web.IDBRequest request) {
    final completer = Completer<JSAny?>();
    request.onsuccess = ((web.Event _) => completer.complete(
      request.result,
    )).toJS;
    request.onerror = ((web.Event _) {
      completer.completeError(
        IndexedDbException(request.error?.message ?? 'Anfrage fehlgeschlagen'),
      );
    }).toJS;
    return completer.future;
  }

  void _checkOpen() {
    if (_closed) throw StateError('IndexedDbStore ist geschlossen');
  }
}
