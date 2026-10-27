import 'dart:math';

import 'package:diary_audio/diary_audio.dart';
import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_services.dart';
import 'platform_features.dart';

/// Bündel aller Ports, mit denen die Oberfläche arbeitet. Welche Umsetzung
/// dahinter steckt, entscheidet `create_services.dart` beim Start: im Browser
/// die Web-Umsetzungen aus `diary_web` (verschlüsselt in IndexedDB, echtes
/// Mikrofon), sonst die In-Memory-Fakes und der `SimulatedRecorder`.
class AppServices {
  AppServices({
    required this.journalId,
    required this.entries,
    required this.recordings,
    required this.transcripts,
    required this.settings,
    required this.search,
    required this.recorder,
    required this.transcriber,
    required this.playerFor,
    required this.deleteFiles,
    required this.features,
    required this.audioFiles,
    this.sttEngine,
    this.fileTranscriber,
    this.fileTranscriberCheck,
    this.sttDeviceInfo,
    this.clock = const SystemClock(),
    this.argon2Params = Argon2Params.standard,
    IdGenerator? ids,
  }) : ids = ids ?? RandomIdGenerator();

  /// Versionskennung im Manifest des Containers.
  static const String appVersion = '0.1.0';

  final String journalId;
  final EntryRepository entries;
  final RecordingRepository recordings;
  final TranscriptRepository transcripts;
  final SettingsRepository settings;
  final SearchRepository search;
  final AudioRecorderPort recorder;

  /// Mitlaufende Erkennung (nativ) und Rückfall, wenn die Datei-Erkennung
  /// nicht nutzbar ist (Fake bis zu den Spikes).
  final TranscriberPort transcriber;

  /// Engine für Status und Modell-Laden in den Einstellungen; `null`, wenn
  /// die Plattform noch keine lokale Engine hat.
  final SttEngine? sttEngine;

  /// Erkennung nach der Aufnahme aus der Datei (Web: Whisper im Browser).
  final AudioFileTranscriberPort? fileTranscriber;

  /// Ob [fileTranscriber] gerade einsetzbar ist (Modell nicht als
  /// nicht verfügbar gemeldet); sonst greift [transcriber].
  final bool Function()? fileTranscriberCheck;

  /// Beschleunigung der Engine (`webgpu`, `wasm`) für die Anzeige.
  final String? Function()? sttDeviceInfo;

  /// Liefert einen Player für eine Aufnahme (Dateischlüssel, Format und Dauer
  /// stehen im Datensatz).
  final DiaryPlayer Function(Recording recording) playerFor;

  /// Entfernt Audiodateien nach dem Löschen ihrer Datensätze
  /// (Crypto-Shredding, D5).
  final Future<void> Function(List<String> fileNames) deleteFiles;

  /// Audiodateien lesen (Export) und schreiben (Import) für Backup und
  /// Gerätewechsel (D6).
  final AudioFiles audioFiles;

  /// Argon2id-Parameter des Backups (Tests: `Argon2Params.testing`).
  final Argon2Params argon2Params;

  final PlatformFeatures features;
  final Clock clock;
  final IdGenerator ids;

  /// Ob die Datei-Erkennung für die nächste Aufnahme genutzt wird.
  bool get fileTranscriberUsable =>
      fileTranscriber != null && (fileTranscriberCheck?.call() ?? true);

  /// Der Kernablauf (Aufnahme, Erkennung, Speichern) mit diesen Ports.
  /// [transcribe] false: keine Erkennung (Einstellung "Transkription aktiv").
  RecordDayUseCase recordDay({bool transcribe = true}) {
    final useFile = transcribe && fileTranscriberUsable;
    return RecordDayUseCase(
      journalId: journalId,
      entries: entries,
      recordings: recordings,
      transcripts: transcripts,
      recorder: recorder,
      transcriber: transcribe && !useFile ? transcriber : null,
      fileTranscriber: useFile ? fileTranscriber : null,
      clock: clock,
      ids: ids,
    );
  }

  /// Backup und Gerätewechsel mit diesen Ports.
  TransferUseCase transfer() => TransferUseCase(
    journalId: journalId,
    entries: entries,
    recordings: recordings,
    transcripts: transcripts,
    settings: settings,
    audioSource: audioFiles,
    audioSink: audioFiles,
    ids: ids,
    clock: clock,
    appVersion: appVersion,
    argon2Params: argon2Params,
  );
}

/// Lesen und Schreiben von Audiodateien in einem Port.
abstract interface class AudioFiles implements AudioFileSource, AudioFileSink {}

/// Zufällige, nicht ratbare Kennungen (128 Bit als Hex).
class RandomIdGenerator implements IdGenerator {
  RandomIdGenerator([Random? random]) : _random = random ?? Random.secure();
  final Random _random;

  @override
  String next() {
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

/// Die Dienste der App; im Browser öffnet das die Datenbank, deshalb
/// asynchron. Tests überschreiben den Provider mit In-Memory-Fakes.
final appServicesProvider = FutureProvider<AppServices>(
  (ref) => createAppServices(),
);

/// Plattformfunktionen (Web: Installation, Speicherstatus, ICS), synchron
/// verfügbar.
final platformFeaturesProvider = Provider<PlatformFeatures>(
  (ref) => createPlatformFeatures(),
);
