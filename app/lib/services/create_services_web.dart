import 'dart:async';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:diary_web/diary_web.dart';

import 'app_services.dart';
import 'platform_features.dart';

/// Text der Fake-Erkennung, bis die Browser-Erkennung aus Spike W1 eingebaut
/// ist (W5). Er wird als Transkript gespeichert, nicht übersetzt.
const String fakeTranscriptText = 'Transkription folgt (experimentell)';

/// Web-Fassung (D16): Master-Key in WebCrypto, Datensätze und Audiodateien
/// verschlüsselt in IndexedDB, Aufnahme über MediaRecorder, Wiedergabe über
/// ein Audio-Element. Fordert beim Start dauerhaften Speicher an.
Future<AppServices> createAppServices() async {
  final db = await IndexedDbStore.open();
  final keys = WebMasterKeyStore(db);
  final records = await EncryptedRecordStore.open(db, keys);
  final files = EncryptedFileStore(db, keys);
  final ids = RandomIdGenerator();
  final journal = await WebJournalRepository(records)
      .ensureDefault(defaultLocale: 'de-DE');
  unawaited(const WebStorageInfo().persist());
  return AppServices(
    journalId: journal.id,
    entries: WebEntryRepository(records, ids),
    recordings: WebRecordingRepository(records),
    transcripts: WebTranscriptRepository(records),
    settings: WebSettingsRepository(records),
    search: WebSearchRepository(records),
    recorder: MediaRecorderCapture(files),
    transcriber: FakeSttEngine(text: fakeTranscriptText),
    playerFor: (recording) => WebAudioPlayer(
      files,
      fileKeyWrapped: recording.fileKeyWrapped,
      mimeType: _mimeTypeFor(recording),
      knownDuration: recording.duration,
    ),
    deleteFiles: (names) async {
      for (final name in names) {
        await files.delete(name);
      }
    },
    features: const WebPlatformFeatures(),
    ids: ids,
  );
}

PlatformFeatures createPlatformFeatures() => const WebPlatformFeatures();

String _mimeTypeFor(Recording recording) => switch (recording.container) {
  AudioContainer.webm => 'audio/webm',
  AudioContainer.ogg => 'audio/ogg',
  AudioContainer.m4a || AudioContainer.adts => 'audio/mp4',
};

/// Plattformfunktionen der PWA über `diary_web`.
class WebPlatformFeatures implements PlatformFeatures {
  const WebPlatformFeatures();

  static const _info = WebStorageInfo();

  @override
  bool get isWeb => true;

  @override
  bool get isStandalone => _info.isStandalone();

  @override
  bool get isIos => _info.isIos();

  @override
  bool get recordsRealAudio => true;

  @override
  Future<StorageStatus?> storageStatus() async {
    final estimate = await _info.estimate();
    if (estimate == null) return null;
    return StorageStatus(
      persisted: await _info.persisted(),
      usageBytes: estimate.usageBytes,
      quotaBytes: estimate.quotaBytes,
    );
  }

  @override
  Future<bool> requestPersistentStorage() => _info.persist();

  @override
  void downloadReminderCalendar({
    required int hour,
    required int minute,
    required String title,
    String? description,
  }) {
    downloadText(
      IcsReminder.fileName,
      IcsReminder.build(
        hour: hour,
        minute: minute,
        title: title,
        description: description,
      ),
      mimeType: IcsReminder.mimeType,
    );
  }
}
