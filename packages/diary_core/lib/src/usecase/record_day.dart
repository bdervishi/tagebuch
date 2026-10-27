import 'dart:async';

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
    this.pendingTranscript,
  });
  final String entryId;
  final Recording recording;

  /// Null, wenn die Transkription fehlgeschlagen ist, keine Erkennung
  /// eingerichtet ist oder sie noch im Hintergrund läuft
  /// ([pendingTranscript]); die Aufnahme ist dann trotzdem gespeichert
  /// (Audio ist die Wahrheit, docs/03 Abschnitt 6).
  final Transcript? transcript;

  /// Gesetzt, wenn `stop(awaitTranscript: false)` aufgerufen wurde und eine
  /// Erkennung läuft: wird mit dem gespeicherten Transkript oder `null`
  /// (Fehler) abgeschlossen, nie mit einem Fehler.
  final Future<Transcript?>? pendingTranscript;
}

/// Der Kernablauf (M1, M3, M4): Aufnahme starten, PCM parallel an die lokale
/// Spracherkennung geben, nach dem Stopp Aufnahme und Transkript speichern.
///
/// Zwei Wege der Erkennung: [transcriber] arbeitet mitlaufend auf den
/// PCM-Blöcken (iOS SpeechTranscriber, Android sherpa-onnx);
/// [fileTranscriber] arbeitet nach der Aufnahme auf der komprimierten Datei
/// im Arbeitsspeicher (Web: Whisper im Browser, D16 Punkt 4). Ist
/// [fileTranscriber] gesetzt, bleibt [transcriber] ungenutzt. Sind beide
/// `null`, entsteht kein Transkript (Nutzer hat die Erkennung abgeschaltet).
///
/// Der Ablauf kennt keine Plattform; alle Seiteneffekte laufen über Ports.
class RecordDayUseCase {
  RecordDayUseCase({
    required this.journalId,
    required this.entries,
    required this.recordings,
    required this.transcripts,
    required this.recorder,
    required this.clock,
    required this.ids,
    this.transcriber,
    this.fileTranscriber,
    this.sampleRate = 16000,
    this.dayRolloverHour = 0,
  });

  final String journalId;
  final EntryRepository entries;
  final RecordingRepository recordings;
  final TranscriptRepository transcripts;
  final AudioRecorderPort recorder;
  final TranscriberPort? transcriber;
  final AudioFileTranscriberPort? fileTranscriber;
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
    Future<TranscriptionResult>? transcription;
    final streamTranscriber = transcriber;
    if (fileTranscriber == null && streamTranscriber != null) {
      transcription = streamTranscriber.transcribe(
        session.frames,
        locale: locale,
      );
      // Fehler werden in stop() behandelt; bis dahin gilt die Future als
      // beobachtet, damit kein unbehandelter Fehler entsteht, falls die App
      // vorher abbricht.
      transcription.then((_) {}, onError: (Object _) {});
    } else {
      // Ohne Hörer würden die PCM-Blöcke bis zum Stopp im Speicher
      // gepuffert; deshalb werden sie verworfen.
      unawaited(session.frames.drain<void>().catchError((Object _) {}));
    }
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
  final Future<TranscriptionResult>? _transcription;
  final String _locale;

  Stream<double> get levels => _session.levels;

  /// Hält die Aufnahme an (Zeit zählt nicht weiter).
  Future<void> pause() => _session.pause();

  /// Setzt eine pausierte Aufnahme fort.
  Future<void> resume() => _session.resume();

  /// Beendet die Aufnahme und speichert sie. Mit [awaitTranscript] wartet der
  /// Aufruf auf die Erkennung; sonst läuft sie im Hintergrund weiter und das
  /// Ergebnis steht in [RecordDayResult.pendingTranscript] (die Aufnahme
  /// blockiert so nicht auf ein langsames Modell, D16 Punkt 4).
  Future<RecordDayResult> stop({bool awaitTranscript = true}) async {
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

    final transcription = _resultFor(audio);
    if (transcription == null) {
      return RecordDayResult(
        entryId: entryId,
        recording: recording,
        transcript: null,
      );
    }
    final saved = _save(transcription);
    if (!awaitTranscript) {
      return RecordDayResult(
        entryId: entryId,
        recording: recording,
        transcript: null,
        pendingTranscript: saved,
      );
    }
    return RecordDayResult(
      entryId: entryId,
      recording: recording,
      transcript: await saved,
    );
  }

  /// Wählt den Erkennungsweg: Datei-Erkennung, wenn eingerichtet und die
  /// Aufnahme ihre Bytes liefert; sonst die mitlaufende Erkennung; sonst keine.
  Future<TranscriptionResult>? _resultFor(RecordedAudio audio) {
    final fileTranscriber = _useCase.fileTranscriber;
    if (fileTranscriber != null) {
      final bytes = audio.plaintextBytes;
      if (bytes == null) return null;
      return fileTranscriber.transcribeAudio(
        bytes,
        mimeType: audio.mimeType,
        locale: _locale,
      );
    }
    return _transcription;
  }

  /// Speichert das Transkript; bei Fehlern `null` (Aufnahme bleibt erhalten,
  /// die Oberfläche bietet "erneut transkribieren" an).
  Future<Transcript?> _save(Future<TranscriptionResult> transcription) async {
    try {
      final result = await transcription;
      // Wurde die Aufnahme inzwischen verworfen (Hintergrund-Erkennung),
      // darf kein verwaistes Transkript entstehen.
      final stillThere = await _useCase.recordings.listForEntry(entryId);
      if (!stillThere.any((r) => r.id == recordingId)) return null;
      final transcript = Transcript(
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
      return transcript;
    } catch (_) {
      // Auch Fehler außerhalb von TranscriptionException (z. B. aus einer
      // JS-Brücke) dürfen die gespeicherte Aufnahme nicht gefährden.
      return null;
    }
  }
}
