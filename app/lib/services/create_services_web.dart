import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:diary_stt_web/diary_stt_web.dart';
import 'package:diary_web/diary_web.dart';

import 'app_services.dart';
import 'platform_features.dart';

/// Text der Fake-Erkennung als Rückfall, wenn die Browser-Erkennung nicht
/// verfügbar ist (Modell fehlt, Browser ohne WebAssembly). Er wird als
/// Transkript gespeichert, nicht übersetzt.
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
  // Whisper im Browser (W5, experimentell): Worker `stt/stt_worker.js`,
  // Modell und Laufzeit vom eigenen Origin. Geladen wird erst, wenn die
  // Einstellungen oder die erste Erkennung es anstoßen.
  final stt = WasmSttEngine();
  return AppServices(
    journalId: journal.id,
    entries: WebEntryRepository(records, ids),
    recordings: WebRecordingRepository(records),
    transcripts: WebTranscriptRepository(records),
    notes: WebNoteRepository(records),
    goals: WebGoalRepository(records),
    books: WebBookRepository(records),
    settings: WebSettingsRepository(records),
    search: WebSearchRepository(records),
    recorder: MediaRecorderCapture(files),
    transcriber: FakeSttEngine(text: fakeTranscriptText),
    sttEngine: stt,
    fileTranscriber: stt,
    fileTranscriberCheck: () => stt.status.phase != WasmSttPhase.failed,
    sttDeviceInfo: () => stt.status.device,
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
    audioFiles: WebAudioFilesPort(files),
    ids: ids,
  );
}

PlatformFeatures createPlatformFeatures() => const WebPlatformFeatures();

/// Audiodateien für Export und Import über den [EncryptedFileStore].
class WebAudioFilesPort extends WebAudioFiles implements AudioFiles {
  WebAudioFilesPort(super.files);
}

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
  bool get canOpenLinks => true;

  @override
  void openExternalLink(Uri url) => openInNewTab(url);

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

  @override
  Future<void> saveContainerFile(String fileName, Uint8List bytes) async =>
      downloadBytes(fileName, bytes);

  @override
  Future<Uint8List?> pickContainerFile() =>
      pickFile(accept: '.${TransferUseCase.fileExtension}');

  @override
  bool get canScanQr => QrCameraScanner.isSupported;

  /// Aus `?start=aufnahme|schreiben` der Startadresse (Manifest-Shortcuts).
  static StartAction? _startAction =
      switch (Uri.base.queryParameters['start']) {
        'aufnahme' => StartAction.record,
        'schreiben' => StartAction.write,
        _ => null,
      };

  @override
  StartAction? takeStartAction() {
    final action = _startAction;
    _startAction = null;
    return action;
  }

  @override
  QrScanner? createQrScanner() =>
      canScanQr ? _WebQrScanner(QrCameraScanner()) : null;
}

class _WebQrScanner implements QrScanner {
  _WebQrScanner(this._scanner);
  final QrCameraScanner _scanner;

  @override
  String get viewType => _scanner.viewType;
  @override
  Stream<String> get codes => _scanner.codes;
  @override
  Future<void> start() => _scanner.start();
  @override
  Future<void> stop() => _scanner.stop();
}
