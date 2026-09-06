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
}

class _Recordings implements RecordingRepository {
  final List<Recording> items = [];
  @override
  Future<void> insert(Recording recording) async => items.add(recording);
  @override
  Future<List<Recording>> listForEntry(String entryId) async =>
      items.where((r) => r.entryId == entryId).toList();
  @override
  Future<void> markAudioDeleted(String recordingId) async {}
}

class _Transcripts implements TranscriptRepository {
  final List<Transcript> items = [];
  @override
  Future<void> insert(Transcript transcript) async => items.add(transcript);
  @override
  Future<Transcript?> primaryForRecording(String recordingId) async =>
      items.where((t) => t.recordingId == recordingId).firstOrNull;
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
}
