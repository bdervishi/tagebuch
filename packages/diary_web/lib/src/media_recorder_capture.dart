import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:diary_audio/diary_audio.dart';
import 'package:diary_core/diary_core.dart';
import 'package:web/web.dart' as web;

import 'encrypted_file_store.dart';

/// Aufnahme im Browser über `MediaRecorder` (D16, Punkt 5).
///
/// Das Mikrofon wird ohne Echo- und Rauschunterdrückung geöffnet, der
/// komprimierte Strom (Chrome: WebM/Opus, Safari: MP4/AAC) in Teilen von
/// `timeslice` gesammelt und nach dem Stopp als Chunk-AEAD-Datei über den
/// [EncryptedFileStore] geschrieben. Parallel liest ein `AnalyserNode` alle
/// [levelInterval] den Zeitbereich: daraus entstehen der Pegel (Spitzenwert,
/// für Anzeige und Wellenform) und ein PCM-Block (Int16, auf die Zielrate
/// resampelt) für die Spracherkennung.
///
/// Grenze dieses Abgriffs: Der `AnalyserNode` liefert Momentaufnahmen, keinen
/// lückenlosen Strom; die PCM-Blöcke decken die Aufnahmedauer näherungsweise
/// ab und reichen für Pegel, Wellenform und die Fake-Erkennung. Für die
/// echte Erkennung (W5) ersetzt ein `AudioWorklet` diesen Abgriff.
class MediaRecorderCapture implements AudioRecorderPort {
  MediaRecorderCapture(
    this._files, {
    this.levelInterval = const Duration(milliseconds: 100),
    this.timeslice = const Duration(seconds: 1),
    this.bitrate = 32000,
  });

  /// MIME-Typen in Vorzugsreihenfolge (D4: Opus ist die Speicher-Optimierung,
  /// AAC-LC der Standard; im Browser entscheidet die Unterstützung).
  static const List<String> candidateMimeTypes = [
    'audio/webm;codecs=opus',
    'audio/mp4;codecs=mp4a.40.2',
    'audio/mp4',
  ];

  final EncryptedFileStore _files;
  final Duration levelInterval;
  final Duration timeslice;

  /// Nennwert in Bit/s; MediaRecorder behandelt ihn als Wunsch.
  final int bitrate;

  /// Erster Kandidat aus [candidateMimeTypes], der in [supported] vorkommt
  /// (reine Funktion, testbar ohne Browser-API).
  static String? pickMimeType(List<String> supported) {
    for (final candidate in candidateMimeTypes) {
      if (supported.contains(candidate)) return candidate;
    }
    return null;
  }

  /// Ob dieser Browser `MediaRecorder` und `getUserMedia` anbietet.
  static bool get isSupported =>
      web.window.has('MediaRecorder') &&
      web.window.navigator.has('mediaDevices');

  /// Die vom Browser unterstützten Kandidaten.
  static List<String> supportedMimeTypes() => [
    for (final type in candidateMimeTypes)
      if (web.MediaRecorder.isTypeSupported(type)) type,
  ];

  /// Codec und Container, die zu einem MIME-Typ gehören.
  static (AudioCodec, AudioContainer) formatFor(String mimeType) =>
      mimeType.startsWith('audio/webm')
      ? (AudioCodec.opus, AudioContainer.webm)
      : (AudioCodec.aacLc, AudioContainer.m4a);

  @override
  Future<RecordingSession> start({
    required String fileName,
    required int sampleRate,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'MediaRecorder ist in diesem Browser nicht verfügbar',
      );
    }
    final mimeType = pickMimeType(supportedMimeTypes());
    if (mimeType == null) {
      throw UnsupportedError(
        'Kein unterstütztes Audioformat (WebM/Opus, MP4/AAC)',
      );
    }
    final stream = await web.window.navigator.mediaDevices
        .getUserMedia(
          web.MediaStreamConstraints(
            audio: web.MediaTrackConstraints(
              echoCancellation: false.toJS,
              noiseSuppression: false.toJS,
            ),
          ),
        )
        .toDart;
    final recorder = web.MediaRecorder(
      stream,
      web.MediaRecorderOptions(mimeType: mimeType, audioBitsPerSecond: bitrate),
    );
    final context = web.AudioContext();
    final analyser = context.createAnalyser();
    // Fenster groß genug für ein Pegelintervall bei 48 kHz (8192 Samples sind
    // rund 170 ms); Zweierpotenz ist Pflicht.
    analyser.fftSize = 8192;
    context.createMediaStreamSource(stream).connect(analyser);
    final session = _MediaRecorderSession(
      files: _files,
      fileName: fileName,
      stream: stream,
      recorder: recorder,
      context: context,
      analyser: analyser,
      mimeType: mimeType,
      targetSampleRate: sampleRate,
      levelInterval: levelInterval,
      bitrate: bitrate,
    );
    session._begin(timeslice);
    return session;
  }
}

class _MediaRecorderSession implements RecordingSession {
  _MediaRecorderSession({
    required this.files,
    required this.fileName,
    required this.stream,
    required this.recorder,
    required this.context,
    required this.analyser,
    required this.mimeType,
    required this.targetSampleRate,
    required this.levelInterval,
    required this.bitrate,
  }) : _resampler = LinearResampler(
         inputRate: context.sampleRate.round(),
         outputRate: targetSampleRate,
       );

  final EncryptedFileStore files;
  final String fileName;
  final web.MediaStream stream;
  final web.MediaRecorder recorder;
  final web.AudioContext context;
  final web.AnalyserNode analyser;
  final String mimeType;
  final int targetSampleRate;
  final Duration levelInterval;
  final int bitrate;

  final LinearResampler _resampler;
  final _frames = StreamController<PcmFrame>();
  final _levels = StreamController<double>.broadcast();
  final List<double> _levelHistory = [];
  final List<web.Blob> _parts = [];
  final Stopwatch _active = Stopwatch();
  Completer<void>? _stopped;
  Timer? _timer;
  bool _paused = false;
  bool _finished = false;

  void _begin(Duration timeslice) {
    recorder.ondataavailable = ((web.BlobEvent event) {
      if (event.data.size > 0) _parts.add(event.data);
    }).toJS;
    recorder.onstop = ((web.Event _) {
      final c = _stopped;
      if (c != null && !c.isCompleted) c.complete();
    }).toJS;
    recorder.onerror = ((web.Event _) {
      final c = _stopped;
      if (c != null && !c.isCompleted) {
        c.completeError(StateError('MediaRecorder meldet einen Fehler'));
      }
    }).toJS;
    recorder.start(timeslice.inMilliseconds);
    _active.start();
    _timer = Timer.periodic(levelInterval, (_) => _sample());
  }

  void _sample() {
    if (_paused || _finished) return;
    final window = analyser.fftSize;
    final buffer = Float32List(window).toJS;
    analyser.getFloatTimeDomainData(buffer);
    final data = buffer.toDart;
    final wanted = (context.sampleRate * levelInterval.inMilliseconds / 1000)
        .round()
        .clamp(1, window);
    final start = window - wanted;
    final pcm = Int16List(wanted);
    var peak = 0.0;
    for (var i = 0; i < wanted; i++) {
      final v = data[start + i].clamp(-1.0, 1.0);
      final a = v.abs();
      if (a > peak) peak = a;
      pcm[i] = (v * 32767).round();
    }
    _levelHistory.add(peak);
    if (!_levels.isClosed) _levels.add(peak);
    if (!_frames.isClosed) {
      _frames.add(
        PcmFrame(_resampler.process(pcm), sampleRate: targetSampleRate),
      );
    }
  }

  @override
  Stream<PcmFrame> get frames => _frames.stream;

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Future<void> pause() async {
    if (_paused || _finished) return;
    _paused = true;
    _active.stop();
    if (recorder.state == 'recording') recorder.pause();
  }

  @override
  Future<void> resume() async {
    if (!_paused || _finished) return;
    _paused = false;
    _active.start();
    if (recorder.state == 'paused') recorder.resume();
  }

  @override
  Future<RecordedAudio> stop() async {
    if (_finished) throw StateError('Aufnahme ist bereits beendet');
    _finished = true;
    _timer?.cancel();
    _active.stop();
    try {
      if (recorder.state != 'inactive') {
        final stopped = _stopped = Completer<void>();
        recorder.stop();
        await stopped.future;
      }
    } finally {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
      await context.close().toDart;
    }
    final (codec, container) = MediaRecorderCapture.formatFor(mimeType);
    final blob = web.Blob(
      [for (final part in _parts) part as JSAny].toJS,
      web.BlobPropertyBag(type: mimeType.split(';').first),
    );
    _parts.clear();
    final buffer = await blob.arrayBuffer().toDart;
    final bytes = buffer.toDart.asUint8List();
    final written = await files.write(fileName, bytes);
    // Ohne Hörer (keine Erkennung) würde das Schließen der Einzel-Quelle
    // nie abschließen; deshalb nicht abwarten.
    unawaited(_frames.close());
    await _levels.close();
    return RecordedAudio(
      fileName: fileName,
      fileKeyWrapped: written.fileKeyWrapped,
      sizeBytes: written.sizeBytes,
      duration: _active.elapsed,
      codec: codec,
      container: container,
      sampleRate: context.sampleRate.round(),
      bitrate: bitrate,
      waveform: Waveform.downsample(_levelHistory),
      truncated: false,
    );
  }
}
