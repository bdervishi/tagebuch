import '../model/local_day.dart';
import '../model/recording.dart';
import '../model/transcript.dart';
import '../ports/clock.dart';
import '../ports/repositories.dart';
import '../ports/services.dart';

/// Ergebnis eines abgeschlossenen Tagesablaufs.
class RecordDayResult {
  const RecordDayResult({
    required this.entryId,
    required this.recording,
    required this.transcript,
  });
  final String entryId;
  final Recording recording;

  /// Null, wenn die Transkription fehlgeschlagen ist; die Aufnahme ist dann
  /// trotzdem gespeichert (Audio ist die Wahrheit, docs/03 Abschnitt 6).
  final Transcript? transcript;
}

/// Der Kernablauf (M1, M3, M4): Aufnahme starten, PCM parallel an die lokale
/// Spracherkennung geben, nach dem Stopp Aufnahme und Transkript speichern.
///
/// Der Ablauf kennt keine Plattform; alle Seiteneffekte laufen über Ports.
class RecordDayUseCase {
  RecordDayUseCase({
    required this.journalId,
    required this.entries,
    required this.recordings,
    required this.transcripts,
    required this.recorder,
    required this.transcriber,
    required this.clock,
    required this.ids,
    this.sampleRate = 16000,
    this.dayRolloverHour = 0,
  });

  final String journalId;
  final EntryRepository entries;
  final RecordingRepository recordings;
  final TranscriptRepository transcripts;
  final AudioRecorderPort recorder;
  final TranscriberPort transcriber;
  final Clock clock;
  final IdGenerator ids;
  final int sampleRate;
  final int dayRolloverHour;

  /// Startet eine Aufnahme. [day] erlaubt Nachträge für vergangene Tage (A3).
  Future<ActiveRecording> start({required String locale, LocalDay? day}) async {
    final now = clock.now();
    final targetDay =
        day ?? LocalDay.forMoment(now, rolloverHour: dayRolloverHour);
    final entry = await entries.getOrCreate(journalId, targetDay, now);
    final recordingId = ids.next();
    final session = await recorder.start(
      fileName: '$recordingId.tgbc',
      sampleRate: sampleRate,
    );
    final transcription = transcriber.transcribe(
      session.frames,
      locale: locale,
    );
    // Fehler werden in stop() behandelt; bis dahin gilt die Future als
    // beobachtet, damit kein unbehandelter Fehler entsteht, falls die App
    // vorher abbricht.
    transcription.then((_) {}, onError: (Object _) {});
    return ActiveRecording._(
      this,
      entry.id,
      recordingId,
      now,
      session,
      transcription,
      locale,
    );
  }
}

/// Laufende Aufnahme; `stop` schließt Datei, wartet auf das Transkript und
/// speichert beides.
class ActiveRecording {
  ActiveRecording._(
    this._useCase,
    this.entryId,
    this.recordingId,
    this._startedAt,
    this._session,
    this._transcription,
    this._locale,
  );

  final RecordDayUseCase _useCase;
  final String entryId;
  final String recordingId;
  final DateTime _startedAt;
  final RecordingSession _session;
  final Future<TranscriptionResult> _transcription;
  final String _locale;

  Stream<double> get levels => _session.levels;

  Future<RecordDayResult> stop() async {
    final audio = await _session.stop();
    final recording = Recording(
      id: recordingId,
      entryId: entryId,
      startedAt: _startedAt,
      duration: audio.duration,
      codec: audio.codec,
      container: audio.container,
      sampleRate: audio.sampleRate,
      bitrate: audio.bitrate,
      fileName: audio.fileName,
      fileKeyWrapped: audio.fileKeyWrapped,
      sizeBytes: audio.sizeBytes,
      state: audio.truncated
          ? RecordingState.truncated
          : RecordingState.complete,
      waveform: audio.waveform,
    );
    await _useCase.recordings.insert(recording);

    Transcript? transcript;
    try {
      final result = await _transcription;
      transcript = Transcript(
        id: _useCase.ids.next(),
        recordingId: recordingId,
        engine: result.engine,
        modelVersion: result.modelVersion,
        locale: result.locale.isEmpty ? _locale : result.locale,
        createdAt: _useCase.clock.now(),
        text: result.text,
        segments: result.segments,
        words: result.words,
      );
      await _useCase.transcripts.insert(transcript);
    } on Exception {
      // Aufnahme bleibt erhalten; die Oberfläche bietet "erneut transkribieren" an.
      transcript = null;
    }
    return RecordDayResult(
      entryId: entryId,
      recording: recording,
      transcript: transcript,
    );
  }
}
