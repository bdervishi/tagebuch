import 'dart:async';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_services.dart';
import 'entry_view.dart';
import 'settings_notifier.dart';

/// Ladezustand der lokalen Spracherkennung, wie die Einstellungen ihn zeigen.
enum SttPhase {
  /// Keine Engine auf dieser Plattform (nativ bis zu den Spikes S1/S2).
  none,

  /// Engine vorhanden, Modell noch nicht geladen (Transkription aus).
  idle,
  loading,
  ready,
  unavailable,
}

class SttStatus {
  const SttStatus(this.phase, {this.progress = 0, this.device, this.reason});

  final SttPhase phase;

  /// 0 bis 1 beim Laden.
  final double progress;

  /// `webgpu` oder `wasm`, falls die Engine es meldet.
  final String? device;

  /// Grund bei [SttPhase.unavailable].
  final String? reason;
}

/// Lässt das Modell auch laden, wenn "Transkription aktiv" aus ist
/// ("Modell jetzt laden" in den Einstellungen).
class SttLoadRequested extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;
}

final sttLoadRequestedProvider = NotifierProvider<SttLoadRequested, bool>(
  SttLoadRequested.new,
);

/// Zähler der Neuversuche nach "nicht verfügbar" ("Erneut versuchen" auf
/// "Heute" und in den Einstellungen, außerdem vor "Erneut transkribieren").
/// Jeder Versuch setzt die Engine zurück ([AppServices.sttReset]) und baut
/// [sttStatusProvider] neu auf.
class SttRetry extends Notifier<int> {
  @override
  int build() => 0;

  void retry() => state = state + 1;
}

final sttRetryProvider = NotifierProvider<SttRetry, int>(SttRetry.new);

/// Zustand der Engine: lädt das Modell, sobald die Transkription aktiv ist
/// oder der Nutzer das Laden anstößt, und meldet Fortschritt, Bereitschaft
/// oder den Grund der Nichtverfügbarkeit (`prepare` der Engine endet dann
/// mit einer [TranscriptionException]). Die Hauptansicht hört von Anfang an
/// zu, damit das Modell beim Start lädt und nicht erst, wenn die erste
/// Aufnahme auf Text wartet.
final sttStatusProvider = StreamProvider<SttStatus>((ref) async* {
  final services = await ref.watch(appServicesProvider.future);
  final engine = services.sttEngine;
  if (engine == null) {
    yield const SttStatus(SttPhase.none);
    return;
  }
  final retries = ref.watch(sttRetryProvider);
  final settings = await ref.watch(settingsProvider.future);
  final locale = settings.language.tag;
  if (retries > 0 &&
      await engine.availability(locale) != EngineAvailability.ready) {
    // Neuer Anlauf nach einem Fehlschlag: Engine zurücksetzen, dann laden.
    await services.sttReset?.call();
  }
  final load =
      retries > 0 ||
      settings.transcriptionEnabled ||
      ref.watch(sttLoadRequestedProvider);
  if (!load) {
    yield switch (await engine.availability(locale)) {
      EngineAvailability.ready => SttStatus(
        SttPhase.ready,
        progress: 1,
        device: services.sttDeviceInfo?.call(),
      ),
      EngineAvailability.needsDownload => const SttStatus(SttPhase.idle),
      EngineAvailability.unavailable => const SttStatus(SttPhase.unavailable),
    };
    return;
  }
  yield const SttStatus(SttPhase.loading);
  try {
    await for (final progress in engine.prepare(locale)) {
      yield SttStatus(SttPhase.loading, progress: progress);
    }
    yield SttStatus(
      SttPhase.ready,
      progress: 1,
      device: services.sttDeviceInfo?.call(),
    );
  } on TranscriptionException catch (e) {
    yield SttStatus(SttPhase.unavailable, reason: e.message);
  }
});

/// Letzter Fehlergrund je Aufnahme (Aufnahme-ID → Text), gesetzt von
/// [TranscriptionJobs] nach einer fehlgeschlagenen Erkennung und beim
/// nächsten Versuch gelöscht. Der Eintrag zeigt ihn unter "Kein Text".
class TranscriptionFailures extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void set(String recordingId, String reason) =>
      state = {...state, recordingId: reason};

  void clear(String recordingId) => state = {...state}..remove(recordingId);
}

final transcriptionFailuresProvider =
    NotifierProvider<TranscriptionFailures, Map<String, String>>(
      TranscriptionFailures.new,
    );

/// Laufende Transkriptionen (Aufnahme-IDs): nach dem Speichern im
/// Hintergrund (`stop(awaitTranscript: false)`), bei "Erneut
/// transkribieren" und beim Nachholen ([TranscriptionCatchUp]). Der Eintrag
/// zeigt dafür "Transkription läuft …"; nach Abschluss laden die Ansichten
/// neu.
class TranscriptionJobs extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool isRunning(String recordingId) => state.contains(recordingId);

  /// Verfolgt eine Hintergrund-Erkennung aus dem Aufnahmeablauf. Endet sie
  /// ohne Transkript, steht der Grund bei der Aufnahme.
  void track(String recordingId, Future<Transcript?> pending) {
    _add(recordingId);
    ref.read(transcriptionFailuresProvider.notifier).clear(recordingId);
    unawaited(
      pending
          .then((transcript) {
            if (transcript == null) {
              ref
                  .read(transcriptionFailuresProvider.notifier)
                  .set(recordingId, _reasonFromStatus());
            }
          })
          .catchError((Object e) {
            ref
                .read(transcriptionFailuresProvider.notifier)
                .set(recordingId, _describe(e));
          })
          .whenComplete(() => _finish(recordingId)),
    );
  }

  /// Liest das Audio der Aufnahme entschlüsselt in den Speicher, erkennt es
  /// mit der Datei-Engine und speichert das Transkript als primäres; ein
  /// vorhandenes (etwa der frühere Platzhalter der Fake-Erkennung) bleibt
  /// als ältere Fassung erhalten, aber nicht mehr primär. Liefert `false`,
  /// wenn keine Engine oder kein Audio vorhanden ist oder die Erkennung
  /// fehlschlägt; die Aufnahme bleibt in jedem Fall erhalten, der Grund
  /// steht in [transcriptionFailuresProvider].
  Future<bool> retranscribe(
    Recording recording, {
    required String locale,
  }) async {
    final services = await ref.read(appServicesProvider.future);
    final transcriber = services.fileTranscriber;
    if (transcriber == null) return false;
    if (state.contains(recording.id)) return false;
    final failures = ref.read(transcriptionFailuresProvider.notifier);
    failures.clear(recording.id);
    // Hängt die Engine in "nicht verfügbar", bekommt sie einen neuen Anlauf,
    // bevor die Erkennung auf sie wartet.
    if (ref.read(sttStatusProvider).value?.phase == SttPhase.unavailable) {
      ref.read(sttRetryProvider.notifier).retry();
    }
    _add(recording.id);
    try {
      final bytes = await services.audioFiles.read(recording);
      if (bytes == null) {
        failures.set(recording.id, 'Kein Audio gespeichert');
        return false;
      }
      final result = await transcriber.transcribeAudio(
        bytes,
        mimeType: recording.container.mimeType,
        locale: locale,
      );
      final previous = await services.transcripts.primaryForRecording(
        recording.id,
      );
      if (previous != null) {
        await services.transcripts.insert(previous.copyWith(isPrimary: false));
      }
      await services.transcripts.insert(
        Transcript(
          id: services.ids.next(),
          recordingId: recording.id,
          engine: result.engine,
          modelVersion: result.modelVersion,
          locale: result.locale.isEmpty ? locale : result.locale,
          createdAt: services.clock.now(),
          text: result.text,
          segments: result.segments,
          words: result.words,
        ),
      );
      return true;
    } catch (e) {
      failures.set(recording.id, _describe(e));
      return false;
    } finally {
      _finish(recording.id);
    }
  }

  String _describe(Object e) => switch (e) {
    TranscriptionException(:final message) => message,
    _ => e.toString(),
  };

  /// Grund, wenn der Aufnahmeablauf ohne Transkript endete: meist der der
  /// Engine (Modell nicht ladbar), sonst allgemein.
  String _reasonFromStatus() {
    final status = ref.read(sttStatusProvider).value;
    return status?.reason ?? 'Erkennung ohne Ergebnis';
  }

  void _add(String recordingId) => state = {...state, recordingId};

  void _finish(String recordingId) {
    state = {...state}..remove(recordingId);
    ref.read(dataVersionProvider.notifier).bump();
  }
}

final transcriptionJobsProvider =
    NotifierProvider<TranscriptionJobs, Set<String>>(TranscriptionJobs.new);

/// Holt Erkennungen nach, die verloren gingen: Aufnahmen mit Audio, aber
/// ohne Text (die App wurde geschlossen, bevor das Modell geladen oder die
/// Erkennung fertig war; das Modell war beim ersten Versuch nicht ladbar),
/// und Aufnahmen, deren einziger Text der Platzhalter der Fake-Erkennung
/// ist. Läuft, sobald die Engine bereit meldet, je Aufnahme einmal pro
/// Sitzung, neueste zuerst und nacheinander (die Engine arbeitet ohnehin
/// eine Aufnahme nach der anderen ab).
class TranscriptionCatchUp extends Notifier<Set<String>> {
  /// Höchstens so viele Aufnahmen je Lauf, damit ein alter Bestand das Gerät
  /// nicht minutenlang beschäftigt; der Rest folgt beim nächsten Start.
  static const int maxPerRun = 20;

  @override
  Set<String> build() => const {};

  /// Startet das Nachholen; liefert die Zahl der angestoßenen Aufnahmen.
  Future<int> run() async {
    final services = await ref.read(appServicesProvider.future);
    if (services.fileTranscriber == null) return 0;
    final settings = await ref.read(settingsProvider.future);
    if (!settings.transcriptionEnabled) return 0;
    // Der Platzhalter wird nur ersetzt, wenn eine echte Engine da ist; sonst
    // würde die Fake-Erkennung sich selbst endlos ersetzen.
    final realEngine =
        services.sttEngine != null && services.sttEngine!.id != EngineIds.fake;
    final jobs = ref.read(transcriptionJobsProvider.notifier);
    final candidates = <Recording>[];
    final all = await services.recordings.listAll()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    for (final r in all) {
      if (r.state == RecordingState.audioDeleted) continue;
      if (state.contains(r.id) || jobs.isRunning(r.id)) continue;
      final transcript = await services.transcripts.primaryForRecording(r.id);
      final missing =
          transcript == null ||
          transcript.text.trim().isEmpty ||
          (realEngine && transcript.engine == EngineIds.fake);
      if (!missing) continue;
      candidates.add(r);
      if (candidates.length >= maxPerRun) break;
    }
    if (candidates.isEmpty) return 0;
    state = {...state, for (final r in candidates) r.id};
    unawaited(_runAll(candidates, jobs, settings.language.tag));
    return candidates.length;
  }

  Future<void> _runAll(
    List<Recording> candidates,
    TranscriptionJobs jobs,
    String locale,
  ) async {
    for (final r in candidates) {
      await jobs.retranscribe(r, locale: locale);
    }
  }
}

final transcriptionCatchUpProvider =
    NotifierProvider<TranscriptionCatchUp, Set<String>>(
      TranscriptionCatchUp.new,
    );
