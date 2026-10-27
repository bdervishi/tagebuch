import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'segments.dart';

/// Nachricht aus dem Worker (`stt_worker.js`), siehe Protokoll dort.
extension type WorkerMessage._(JSObject _) implements JSObject {
  external String? get type;
  external String? get id;
  external String? get message;
  external String? get text;
  external num? get loaded;
  external num? get total;
  external String? get file;
  external String? get device;
  external JSArray<WorkerChunkMessage>? get chunks;
}

extension type WorkerChunkMessage._(JSObject _) implements JSObject {
  external String? get text;
  external num? get start;
  external num? get end;
}

/// Ereignisse des Workers in Dart-Form.
sealed class WorkerEvent {
  const WorkerEvent();
}

class WorkerProgress extends WorkerEvent {
  const WorkerProgress({required this.loaded, required this.total, this.file});
  final int loaded;
  final int total;
  final String? file;
}

class WorkerReady extends WorkerEvent {
  const WorkerReady({this.device});
  final String? device;
}

/// Fehler ohne `id` betreffen das Laden (Modell fehlt, Worker nicht ladbar).
class WorkerFailure extends WorkerEvent {
  const WorkerFailure(this.message);
  final String message;
}

/// Ergebnis einer Transkription.
class WorkerResult {
  const WorkerResult({required this.text, required this.chunks});
  final String text;
  final List<WorkerChunk> chunks;
}

/// Brücke zum Web Worker: startet ihn als ES-Modul, sendet `init` und
/// `transcribe`, ordnet Antworten über `id` zu und meldet Lade-Ereignisse
/// als Strom. Kennt kein Modell und keine Oberfläche.
class SttWorkerClient {
  SttWorkerClient(this.scriptUrl);

  /// Pfad des Worker-Skripts relativ zur Seite (`stt/stt_worker.js`) oder
  /// eine Blob-URL (Tests).
  final String scriptUrl;

  web.Worker? _worker;
  final _events = StreamController<WorkerEvent>.broadcast();
  final Map<String, Completer<WorkerResult>> _pending = {};
  int _nextId = 0;

  Stream<WorkerEvent> get events => _events.stream;
  bool get isStarted => _worker != null;

  /// Startet den Worker und schickt `init`. [dtype] ist `null` (Worker wählt
  /// nach Gerät), ein Name (`q8`) oder eine Zuordnung je Datei.
  void start({required String model, Object? dtype}) {
    if (_worker != null) return;
    final web.Worker worker;
    try {
      worker = web.Worker(scriptUrl.toJS, web.WorkerOptions(type: 'module'));
    } catch (e) {
      _events.add(WorkerFailure('Worker konnte nicht gestartet werden: $e'));
      return;
    }
    _worker = worker;
    worker.onmessage = ((web.MessageEvent event) {
      _onMessage(event.data);
    }).toJS;
    worker.onerror = ((web.Event event) {
      final message = event.isA<web.ErrorEvent>()
          ? (event as web.ErrorEvent).message
          : 'unbekannter Fehler';
      _failAll('Worker-Fehler: $message');
    }).toJS;
    worker.onmessageerror = ((web.Event _) {
      _failAll('Nachricht des Workers nicht lesbar');
    }).toJS;
    worker.postMessage(
      {'type': 'init', 'model': model, 'dtype': dtype}.jsify(),
    );
  }

  /// Schickt 16-kHz-Mono-PCM an den Worker; der Puffer wird übertragen
  /// (transferable), nicht kopiert.
  Future<WorkerResult> transcribe(
    Float32List audio, {
    required String language,
  }) {
    final worker = _worker;
    if (worker == null) {
      return Future.error(StateError('Worker nicht gestartet'));
    }
    final id = 't${++_nextId}';
    final completer = Completer<WorkerResult>();
    _pending[id] = completer;
    final audioJs = audio.toJS;
    final message = JSObject()
      ..setProperty('type'.toJS, 'transcribe'.toJS)
      ..setProperty('id'.toJS, id.toJS)
      ..setProperty('language'.toJS, language.toJS)
      ..setProperty('audio'.toJS, audioJs);
    final buffer = audioJs.getProperty<JSArrayBuffer>('buffer'.toJS);
    worker.postMessage(message, [buffer].toJS);
    return completer.future;
  }

  void _onMessage(JSAny? data) {
    if (data == null || !data.isA<JSObject>()) return;
    final msg = data as WorkerMessage;
    switch (msg.type) {
      case 'progress':
        _events.add(
          WorkerProgress(
            loaded: msg.loaded?.toInt() ?? 0,
            total: msg.total?.toInt() ?? 0,
            file: msg.file,
          ),
        );
      case 'ready':
        _events.add(WorkerReady(device: msg.device));
      case 'result':
        final completer = _pending.remove(msg.id);
        if (completer == null) return;
        final chunks = msg.chunks?.toDart ?? const [];
        completer.complete(
          WorkerResult(
            text: msg.text ?? '',
            chunks: [
              for (final c in chunks)
                WorkerChunk(
                  text: c.text ?? '',
                  start: c.start?.toDouble(),
                  end: c.end?.toDouble(),
                ),
            ],
          ),
        );
      case 'error':
        final message = msg.message ?? 'unbekannter Fehler';
        final id = msg.id;
        if (id == null) {
          _failAll(message);
        } else {
          _pending.remove(id)?.completeError(WorkerFailure(message));
        }
    }
  }

  void _failAll(String message) {
    _events.add(WorkerFailure(message));
    for (final c in _pending.values) {
      c.completeError(WorkerFailure(message));
    }
    _pending.clear();
  }

  /// Beendet den Worker; offene Transkriptionen enden mit Fehler.
  void dispose() {
    _failAll('Worker beendet');
    _worker?.terminate();
    _worker = null;
    _events.close();
  }
}
