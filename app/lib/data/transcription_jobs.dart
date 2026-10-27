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

/// Zustand der Engine: lädt das Modell, sobald die Transkription aktiv ist
/// oder der Nutzer das Laden anstößt, und meldet Fortschritt, Bereitschaft
/// oder den Grund der Nichtverfügbarkeit (`prepare` der Engine endet dann
/// mit einer [TranscriptionException]).
final sttStatusProvider = StreamProvider<SttStatus>((ref) async* {
  final services = await ref.watch(appServicesProvider.future);
  final engine = services.sttEngine;
  if (engine == null) {
    yield const SttStatus(SttPhase.none);
    return;
  }
  final settings = await ref.watch(settingsProvider.future);
  final locale = settings.language.tag;
  final load =
      settings.transcriptionEnabled || ref.watch(sttLoadRequestedProvider);
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

/// Laufende Transkriptionen (Aufnahme-IDs): nach dem Speichern im
/// Hintergrund (`stop(awaitTranscript: false)`) und bei "Erneut
/// transkribieren". Der Eintrag zeigt dafür "Transkription läuft …"; nach
/// Abschluss laden die Ansichten neu.
class TranscriptionJobs extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool isRunning(String recordingId) => state.contains(recordingId);

  /// Verfolgt eine Hintergrund-Erkennung aus dem Aufnahmeablauf.
  void track(String recordingId, Future<Transcript?> pending) {
    _add(recordingId);
    unawaited(pending.whenComplete(() => _finish(recordingId)));
  }

  /// Liest das Audio der Aufnahme entschlüsselt in den Speicher, erkennt es
  /// mit der Datei-Engine und speichert das Transkript. Liefert `false`,
  /// wenn keine Engine oder kein Audio vorhanden ist oder die Erkennung
  /// fehlschlägt; die Aufnahme bleibt in jedem Fall erhalten.
  Future<bool> retranscribe(
    Recording recording, {
    required String locale,
  }) async {
    final services = await ref.read(appServicesProvider.future);
    final transcriber = services.fileTranscriber;
    if (transcriber == null) return false;
    _add(recording.id);
    try {
      final bytes = await services.audioFiles.read(recording);
      if (bytes == null) return false;
      final result = await transcriber.transcribeAudio(
        bytes,
        mimeType: recording.container.mimeType,
        locale: locale,
      );
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
    } catch (_) {
      return false;
    } finally {
      _finish(recording.id);
    }
  }

  void _add(String recordingId) => state = {...state, recordingId};

  void _finish(String recordingId) {
    state = {...state}..remove(recordingId);
    ref.read(dataVersionProvider.notifier).bump();
  }
}

final transcriptionJobsProvider =
    NotifierProvider<TranscriptionJobs, Set<String>>(TranscriptionJobs.new);
