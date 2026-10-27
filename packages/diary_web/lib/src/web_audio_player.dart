import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:diary_audio/diary_audio.dart';
import 'package:web/web.dart' as web;

import 'encrypted_file_store.dart';

/// Wiedergabe im Browser: Die Chunk-Datei wird in den Speicher entschlüsselt,
/// als `Blob` mit Objekt-URL einem `HTMLAudioElement` übergeben und nach
/// [dispose] wieder freigegeben. Es entsteht keine Datei auf dem Dateisystem
/// (die Blob-URL verweist auf Speicher des Dokuments).
///
/// Hinweis: WebM aus `MediaRecorder` trägt oft keine Dauer im Kopf; dann
/// liefert das Element `Infinity`, und [duration] greift auf [knownDuration]
/// aus dem Aufnahme-Datensatz zurück. Sprünge funktionieren in Chrome auch
/// ohne Cue-Tabelle, weil die ganze Datei vorliegt.
class WebAudioPlayer implements DiaryPlayer {
  WebAudioPlayer(
    this._files, {
    required Uint8List fileKeyWrapped,
    required String mimeType,
    Duration? knownDuration,
  }) : _fileKeyWrapped = fileKeyWrapped, // ignore: prefer_initializing_formals
       _mimeType = mimeType, // ignore: prefer_initializing_formals
       _knownDuration = knownDuration ?? Duration.zero;

  /// Wartezeit auf die Metadaten, bevor [open] trotzdem zurückkehrt.
  static const Duration metadataTimeout = Duration(seconds: 5);

  final EncryptedFileStore _files;
  final Uint8List _fileKeyWrapped;
  final String _mimeType;
  final Duration _knownDuration;
  final _position = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  web.HTMLAudioElement? _audio;
  String? _url;
  Duration? _mediaDuration;
  bool _disposed = false;

  @override
  Future<void> open({required String fileName}) async {
    if (_disposed) throw StateError('WebAudioPlayer ist freigegeben');
    final bytes = await _files.read(fileName, _fileKeyWrapped);
    final blob = web.Blob(
      [bytes.toJS as JSAny].toJS,
      web.BlobPropertyBag(type: _mimeType),
    );
    final url = _url = web.URL.createObjectURL(blob);
    final audio = _audio = web.HTMLAudioElement()..preload = 'auto';
    final metadata = Completer<void>();
    void done() {
      if (!metadata.isCompleted) metadata.complete();
    }

    audio.onloadedmetadata = ((web.Event _) {
      _readDuration(audio);
      done();
    }).toJS;
    audio.ondurationchange = ((web.Event _) => _readDuration(audio)).toJS;
    audio.onerror = ((web.Event _) => done()).toJS;
    audio.ontimeupdate = ((web.Event _) => _emitPosition(audio)).toJS;
    audio.onplay = ((web.Event _) => _emitPlaying(true)).toJS;
    audio.onpause = ((web.Event _) => _emitPlaying(false)).toJS;
    audio.onended = ((web.Event _) {
      _emitPosition(audio);
      _emitPlaying(false);
    }).toJS;
    audio.src = url;
    audio.load();
    await metadata.future.timeout(metadataTimeout, onTimeout: () {});
  }

  void _readDuration(web.HTMLAudioElement audio) {
    final d = audio.duration;
    if (d.isFinite && d > 0) {
      _mediaDuration = Duration(milliseconds: (d * 1000).round());
    }
  }

  void _emitPosition(web.HTMLAudioElement audio) {
    if (_position.isClosed) return;
    _position.add(Duration(milliseconds: (audio.currentTime * 1000).round()));
  }

  void _emitPlaying(bool value) {
    if (!_playing.isClosed) _playing.add(value);
  }

  web.HTMLAudioElement get _element {
    final a = _audio;
    if (a == null) throw StateError('open() wurde nicht aufgerufen');
    return a;
  }

  @override
  Future<void> play() => _element.play().toDart.then((_) {});

  @override
  Future<void> pause() async => _element.pause();

  @override
  Future<void> seek(Duration position) async {
    final audio = _element;
    final clamped = position < Duration.zero ? Duration.zero : position;
    audio.currentTime = clamped.inMilliseconds / 1000;
    _emitPosition(audio);
  }

  @override
  Future<void> setSpeed(double speed) async =>
      _element.playbackRate = PlaybackSpeeds.clamp(speed);

  @override
  Stream<Duration> get position => _position.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Duration get duration => _mediaDuration ?? _knownDuration;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final audio = _audio;
    if (audio != null) {
      audio.pause();
      audio.removeAttribute('src');
      audio.load();
    }
    final url = _url;
    if (url != null) web.URL.revokeObjectURL(url);
    _audio = null;
    _url = null;
    await _position.close();
    await _playing.close();
  }
}
