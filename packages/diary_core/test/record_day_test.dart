import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:test/test.dart';

class _Ids implements IdGenerator {
  int _n = 0;
  @override
  String next() => 'id${++_n}';
}

class _Entries implements EntryRepository {
  final Map<String, DiaryEntry> byDay = {};
  @override
  Future<DiaryEntry?> byId(String entryId) async =>
      byDay.values.where((e) => e.id == entryId).firstOrNull;
  @override
  Future<DiaryEntry?> findByDay(String journalId, LocalDay day) async =>
      byDay[day.iso];
  @override
  Future<DiaryEntry> getOrCreate(
    String journalId,
    LocalDay day,
    DateTime now,
  ) async => byDay.putIfAbsent(
    day.iso,
    () => DiaryEntry(
      id: 'e-${day.iso}',
      journalId: journalId,
      day: day,
      createdAt: now,
      updatedAt: now,
    ),
  );
  @override
  Future<void> update(DiaryEntry entry) async => byDay[entry.day.iso] = entry;
  @override
  Stream<List<DiaryEntry>> watchMonth(String journalId, int year, int month) =>
      Stream.value(byDay.values.toList());
  @override
  Future<List<String>> delete(String entryId) async => [];
  @override
  Future<List<DiaryEntry>> listAll(String journalId) async =>
      byDay.values.toList();
}

class _Recordings implements RecordingRepository {
  final List<Recording> items = [];
  @override
  Future<void> insert(Recording recording) async => items.add(recording);
  @override
  Future<List<Recording>> listForEntry(String entryId) async =>
      items.where((r) => r.entryId == entryId).toList();
  @override
  Future<List<Recording>> listAll() async => items;
  @override
  Future<void> markAudioDeleted(String recordingId) async {}
  @override
  Future<String?> delete(String recordingId) async {
    final i = items.indexWhere((r) => r.id == recordingId);
    if (i < 0) return null;
    return items.removeAt(i).fileName;
  }
}

class _Transcripts implements TranscriptRepository {
  final List<Transcript> items = [];
  @override
  Future<void> insert(Transcript transcript) async => items.add(transcript);
  @override
  Future<Transcript?> primaryForRecording(String recordingId) async =>
      items.where((t) => t.recordingId == recordingId).firstOrNull;
  @override
  Future<List<Transcript>> listForRecording(String recordingId) async =>
      items.where((t) => t.recordingId == recordingId).toList();
  @override
  Future<void> updateText(
    String transcriptId,
    String text, {
    required bool editedByUser,
  }) async {}
}

class _Session implements RecordingSession {
  final _frames = StreamController<PcmFrame>();
  final _levels = StreamController<double>.broadcast();
  int framesPushed = 0;
  void push() {
    framesPushed++;
    _frames.add(PcmFrame(Int16List(160), sampleRate: 16000));
  }

  @override
  Stream<PcmFrame> get frames => _frames.stream;
  @override
  Stream<double> get levels => _levels.stream;
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<RecordedAudio> stop() async {
    await _frames.close();
    await _levels.close();
    return RecordedAudio(
      fileName: 'id1.tgbc',
      fileKeyWrapped: Uint8List(72),
      sizeBytes: 1234,
      duration: const Duration(seconds: 3),
      codec: AudioCodec.aacLc,
      container: AudioContainer.m4a,
      sampleRate: 24000,
      bitrate: 32000,
      waveform: Uint8List(100),
      truncated: false,
    );
  }
}

class _Recorder implements AudioRecorderPort {
  final session = _Session();
  String? fileName;
  @override
  Future<RecordingSession> start({
    required String fileName,
    required int sampleRate,
  }) async {
    this.fileName = fileName;
    return session;
  }
}

class _Transcriber implements TranscriberPort {
  _Transcriber({this.fail = false});
  final bool fail;
  int framesSeen = 0;
  @override
  Future<TranscriptionResult> transcribe(
    Stream<PcmFrame> frames, {
    required String locale,
  }) async {
    await for (final _ in frames) {
      framesSeen++;
    }
    if (fail) throw const TranscriptionException('Modell fehlt');
    return TranscriptionResult(
      engine: 'fake',
      modelVersion: '1',
      locale: locale,
      text: 'Heute war ein guter Tag.',
      segments: const [
        TranscriptSegment(
          index: 0,
          start: Duration.zero,
          end: Duration(seconds: 3),
          text: 'Heute war ein guter Tag.',
          boundarySource: BoundarySource.vad,
        ),
      ],
    );
  }
}

void main() {
  RecordDayUseCase build(
    _Entries e,
    _Recordings r,
    _Transcripts t,
    _Recorder rec,
    _Transcriber tr,
    Clock clock,
  ) => RecordDayUseCase(
    journalId: 'j1',
    entries: e,
    recordings: r,
    transcripts: t,
    recorder: rec,
    transcriber: tr,
    clock: clock,
    ids: _Ids(),
  );

  test('Aufnahme, Transkription und Speicherung in einem Ablauf', () async {
    final e = _Entries(),
        r = _Recordings(),
        t = _Transcripts(),
        rec = _Recorder(),
        tr = _Transcriber();
    final clock = FixedClock(DateTime(2026, 9, 6, 21, 5));
    final useCase = build(e, r, t, rec, tr, clock);

    final active = await useCase.start(locale: 'de-DE');
    expect(rec.fileName, 'id1.tgbc');
    rec.session.push();
    rec.session.push();
    final result = await active.stop();

    expect(e.byDay.keys, ['2026-09-06']);
    expect(result.entryId, 'e-2026-09-06');
    expect(r.items.single.state, RecordingState.complete);
    expect(r.items.single.codec, AudioCodec.aacLc);
    expect(tr.framesSeen, 2);
    expect(result.transcript!.text, contains('guter Tag'));
    expect(t.items.single.recordingId, 'id1');
  });

  test('Nachtrag für gestern und fehlgeschlagene Transkription', () async {
    final e = _Entries(),
        r = _Recordings(),
        t = _Transcripts(),
        rec = _Recorder();
    final tr = _Transcriber(fail: true);
    final useCase = build(
      e,
      r,
      t,
      rec,
      tr,
      FixedClock(DateTime(2026, 9, 6, 8)),
    );

    final active = await useCase.start(
      locale: 'de-CH',
      day: const LocalDay(2026, 9, 5),
    );
    final result = await active.stop();

    expect(e.byDay.keys, ['2026-09-05']);
    expect(r.items, hasLength(1), reason: 'Audio bleibt erhalten');
    expect(result.transcript, isNull);
    expect(t.items, isEmpty);
  });

  group('Datei-Erkennung', fileTranscriberTests);
}

class _FileTranscriber implements AudioFileTranscriberPort {
  _FileTranscriber({this.fail = false, this.delay = Duration.zero});
  final bool fail;
  final Duration delay;
  Uint8List? bytes;
  String? mimeType;
  String? locale;

  @override
  Future<TranscriptionResult> transcribeAudio(
    Uint8List bytes, {
    required String mimeType,
    required String locale,
  }) async {
    this.bytes = bytes;
    this.mimeType = mimeType;
    this.locale = locale;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (fail) throw const TranscriptionException('Modell fehlt');
    return TranscriptionResult(
      engine: 'web_whisper_base',
      modelVersion: 'onnx-community/whisper-base',
      locale: locale,
      text: 'Aus der Datei erkannt.',
      segments: const [
        TranscriptSegment(
          index: 0,
          start: Duration.zero,
          end: Duration(seconds: 3),
          text: 'Aus der Datei erkannt.',
          boundarySource: BoundarySource.engine,
        ),
      ],
    );
  }
}

/// Aufnahmedienst, der die Bytes der Aufnahme im Speicher mitliefert
/// (wie `MediaRecorderCapture` im Browser).
class _BytesSession extends _Session {
  _BytesSession({this.withBytes = true});
  final bool withBytes;
  @override
  Future<RecordedAudio> stop() async {
    final base = await super.stop();
    return RecordedAudio(
      fileName: base.fileName,
      fileKeyWrapped: base.fileKeyWrapped,
      sizeBytes: base.sizeBytes,
      duration: base.duration,
      codec: AudioCodec.opus,
      container: AudioContainer.webm,
      sampleRate: 48000,
      bitrate: 32000,
      waveform: base.waveform,
      truncated: false,
      plaintextBytes: withBytes ? Uint8List.fromList([1, 2, 3, 4]) : null,
    );
  }
}

class _BytesRecorder implements AudioRecorderPort {
  _BytesRecorder({bool withBytes = true})
    : session = _BytesSession(withBytes: withBytes);
  final _BytesSession session;
  @override
  Future<RecordingSession> start({
    required String fileName,
    required int sampleRate,
  }) async => session;
}

void fileTranscriberTests() {
  final clock = FixedClock(DateTime(2026, 10, 27, 21, 5));

  test(
    'Datei-Erkennung bekommt Bytes und MIME-Typ, Stream bleibt ungenutzt',
    () async {
      final e = _Entries(), r = _Recordings(), t = _Transcripts();
      final rec = _BytesRecorder();
      final stream = _Transcriber();
      final file = _FileTranscriber();
      final useCase = RecordDayUseCase(
        journalId: 'j1',
        entries: e,
        recordings: r,
        transcripts: t,
        recorder: rec,
        transcriber: stream,
        fileTranscriber: file,
        clock: clock,
        ids: _Ids(),
      );
      final active = await useCase.start(locale: 'de-CH');
      rec.session.push();
      rec.session.push();
      final result = await active.stop();

      expect(file.bytes, [1, 2, 3, 4]);
      expect(file.mimeType, 'audio/webm');
      expect(file.locale, 'de-CH');
      expect(stream.framesSeen, 0, reason: 'Stream-Transkriber nicht genutzt');
      expect(result.transcript!.engine, 'web_whisper_base');
      expect(
        result.transcript!.segments.single.boundarySource,
        BoundarySource.engine,
      );
      expect(t.items.single.text, 'Aus der Datei erkannt.');
      expect(result.pendingTranscript, isNull);
    },
  );

  test(
    'Hintergrund: stop liefert sofort, Transkript folgt über die Future',
    () async {
      final e = _Entries(), r = _Recordings(), t = _Transcripts();
      final rec = _BytesRecorder();
      final file = _FileTranscriber(delay: const Duration(milliseconds: 20));
      final useCase = RecordDayUseCase(
        journalId: 'j1',
        entries: e,
        recordings: r,
        transcripts: t,
        recorder: rec,
        fileTranscriber: file,
        clock: clock,
        ids: _Ids(),
      );
      final active = await useCase.start(locale: 'de-DE');
      final result = await active.stop(awaitTranscript: false);

      expect(r.items, hasLength(1), reason: 'Aufnahme sofort gespeichert');
      expect(result.transcript, isNull);
      expect(t.items, isEmpty);
      final transcript = await result.pendingTranscript!;
      expect(transcript!.recordingId, result.recording.id);
      expect(t.items.single.id, transcript.id);
    },
  );

  test('Hintergrund-Fehler endet mit null, Aufnahme bleibt', () async {
    final e = _Entries(), r = _Recordings(), t = _Transcripts();
    final rec = _BytesRecorder();
    final useCase = RecordDayUseCase(
      journalId: 'j1',
      entries: e,
      recordings: r,
      transcripts: t,
      recorder: rec,
      fileTranscriber: _FileTranscriber(fail: true),
      clock: clock,
      ids: _Ids(),
    );
    final active = await useCase.start(locale: 'de-DE');
    final result = await active.stop(awaitTranscript: false);
    expect(await result.pendingTranscript, isNull);
    expect(r.items, hasLength(1));
    expect(t.items, isEmpty);
  });

  test('Ohne Bytes und ohne Erkennung entsteht kein Transkript', () async {
    final e = _Entries(), r = _Recordings(), t = _Transcripts();
    final rec = _BytesRecorder(withBytes: false);
    final file = _FileTranscriber();
    final useCase = RecordDayUseCase(
      journalId: 'j1',
      entries: e,
      recordings: r,
      transcripts: t,
      recorder: rec,
      fileTranscriber: file,
      clock: clock,
      ids: _Ids(),
    );
    final active = await useCase.start(locale: 'de-DE');
    final result = await active.stop();
    expect(result.transcript, isNull);
    expect(result.pendingTranscript, isNull);
    expect(file.bytes, isNull);
    expect(r.items, hasLength(1));

    final none = RecordDayUseCase(
      journalId: 'j1',
      entries: e,
      recordings: r,
      transcripts: t,
      recorder: _Recorder(),
      clock: clock,
      ids: _Ids(),
    );
    final active2 = await none.start(locale: 'de-DE');
    final result2 = await active2.stop();
    expect(result2.transcript, isNull);
    expect(t.items, isEmpty);
  });

  test('Verworfene Aufnahme bekommt kein verwaistes Transkript', () async {
    final e = _Entries(), r = _Recordings(), t = _Transcripts();
    final rec = _BytesRecorder();
    final useCase = RecordDayUseCase(
      journalId: 'j1',
      entries: e,
      recordings: r,
      transcripts: t,
      recorder: rec,
      fileTranscriber: _FileTranscriber(
        delay: const Duration(milliseconds: 20),
      ),
      clock: clock,
      ids: _Ids(),
    );
    final active = await useCase.start(locale: 'de-DE');
    final result = await active.stop(awaitTranscript: false);
    await r.delete(result.recording.id);
    expect(await result.pendingTranscript, isNull);
    expect(t.items, isEmpty);
  });

  test('MIME-Typ je Container', () {
    expect(AudioContainer.webm.mimeType, 'audio/webm');
    expect(AudioContainer.m4a.mimeType, 'audio/mp4');
    expect(AudioContainer.ogg.mimeType, 'audio/ogg');
    expect(AudioContainer.adts.mimeType, 'audio/aac');
  });
}
