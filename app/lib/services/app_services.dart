import 'dart:math';

import 'package:diary_audio/diary_audio.dart';
import 'package:diary_core/diary_core.dart';
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
    this.clock = const SystemClock(),
    IdGenerator? ids,
  }) : ids = ids ?? RandomIdGenerator();

  final String journalId;
  final EntryRepository entries;
  final RecordingRepository recordings;
  final TranscriptRepository transcripts;
  final SettingsRepository settings;
  final SearchRepository search;
  final AudioRecorderPort recorder;
  final TranscriberPort transcriber;

  /// Liefert einen Player für eine Aufnahme (Dateischlüssel, Format und Dauer
  /// stehen im Datensatz).
  final DiaryPlayer Function(Recording recording) playerFor;

  /// Entfernt Audiodateien nach dem Löschen ihrer Datensätze
  /// (Crypto-Shredding, D5).
  final Future<void> Function(List<String> fileNames) deleteFiles;

  final PlatformFeatures features;
  final Clock clock;
  final IdGenerator ids;

  /// Der Kernablauf (Aufnahme, Erkennung, Speichern) mit diesen Ports.
  RecordDayUseCase recordDay() => RecordDayUseCase(
    journalId: journalId,
    entries: entries,
    recordings: recordings,
    transcripts: transcripts,
    recorder: recorder,
    transcriber: transcriber,
    clock: clock,
    ids: ids,
  );
}

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
