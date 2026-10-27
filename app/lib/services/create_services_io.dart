import 'package:diary_audio/diary_audio.dart';
import 'package:diary_stt/diary_stt.dart';

import 'app_services.dart';
import 'memory_repositories.dart';
import 'platform_features.dart';

/// Text der Fake-Erkennung, bis eine lokale Engine angebunden ist (W1/W5;
/// Spikes S1/S2). Er wird als Transkript gespeichert, nicht übersetzt.
const String fakeTranscriptText = 'Transkription folgt (experimentell)';

/// Native App ohne Speicherschicht und Mikrofon-Brücke (bis zu den Spikes):
/// In-Memory-Repositories, `SimulatedRecorder`, `SimulatedPlayer`,
/// `FakeSttEngine`.
Future<AppServices> createAppServices() async {
  final ids = RandomIdGenerator();
  final transcripts = InMemoryTranscriptRepository();
  final recordings = InMemoryRecordingRepository(transcripts: transcripts);
  final entries = InMemoryEntryRepository(ids, recordings: recordings);
  return AppServices(
    journalId: 'journal-default',
    entries: entries,
    recordings: recordings,
    transcripts: transcripts,
    settings: InMemorySettingsRepository(),
    search: InMemorySearchRepository(entries, recordings, transcripts),
    recorder: SimulatedRecorder(),
    transcriber: FakeSttEngine(text: fakeTranscriptText),
    // Noch keine lokale Engine (Spikes S1/S2): Status "nicht eingebaut".
    sttEngine: null,
    fileTranscriber: null,
    playerFor: (recording) => SimulatedPlayer(duration: recording.duration),
    deleteFiles: (_) async {},
    features: const NativePlatformFeatures(),
    audioFiles: InMemoryAudioFiles(),
    ids: ids,
  );
}

PlatformFeatures createPlatformFeatures() => const NativePlatformFeatures();
