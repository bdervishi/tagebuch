import 'dart:typed_data';

import 'package:diary_audio/diary_audio.dart';
import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/app/app.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/l10n/app_localizations.dart';
import 'package:tagebuch_app/services/app_services.dart';
import 'package:tagebuch_app/services/memory_repositories.dart';
import 'package:tagebuch_app/services/platform_features.dart';

/// Tagebuch-ID der Test-Dienste.
const String testJournalId = 'journal-default';

/// Text der Fake-Erkennung in Tests.
const String fakeTranscript = 'Transkription folgt (experimentell)';

/// Ein vorbereiteter Eintrag (ein Tag, eine Aufnahme, ein Transkript).
class SeedEntry {
  const SeedEntry({
    required this.id,
    required this.day,
    this.transcript = fakeTranscript,
    this.duration = const Duration(seconds: 90),
    this.segments,
  });

  final String id;
  final DateTime day;
  final String transcript;
  final Duration duration;
  final List<String>? segments;
}

SeedEntry testEntry({
  required String id,
  required DateTime day,
  String transcript = fakeTranscript,
  Duration duration = const Duration(seconds: 90),
  List<String>? segments,
}) => SeedEntry(
  id: id,
  day: day,
  transcript: transcript,
  duration: duration,
  segments: segments,
);

/// Dienste mit In-Memory-Fakes; die Repositories bleiben für Prüfungen
/// zugänglich.
class TestServices {
  TestServices({
    bool onboardingDone = true,
    List<SeedEntry> seed = const [],
    PlatformFeatures features = const NativePlatformFeatures(),
  }) {
    final entryItems = <DiaryEntry>[];
    final recordingItems = <Recording>[];
    final transcriptItems = <Transcript>[];
    for (final s in seed) {
      final startedAt = s.day.add(const Duration(hours: 21));
      entryItems.add(
        DiaryEntry(
          id: s.id,
          journalId: testJournalId,
          day: LocalDay.forMoment(s.day),
          createdAt: startedAt,
          updatedAt: startedAt,
        ),
      );
      recordingItems.add(
        Recording(
          id: 'rec-${s.id}',
          entryId: s.id,
          startedAt: startedAt,
          duration: s.duration,
          codec: AudioCodec.aacLc,
          container: AudioContainer.m4a,
          sampleRate: 24000,
          bitrate: 32000,
          fileName: 'rec-${s.id}.tgbc',
          fileKeyWrapped: Uint8List(72),
          sizeBytes: 1000,
          state: RecordingState.complete,
          waveform: Uint8List.fromList(List.generate(100, (i) => i * 2)),
        ),
      );
      final parts = s.segments ?? [s.transcript];
      final segLength = Duration(
        milliseconds: s.duration.inMilliseconds ~/ parts.length,
      );
      transcriptItems.add(
        Transcript(
          id: 'tr-${s.id}',
          recordingId: 'rec-${s.id}',
          engine: 'fake',
          modelVersion: '0',
          locale: 'de-DE',
          createdAt: startedAt,
          text: s.transcript,
          segments: [
            for (var i = 0; i < parts.length; i++)
              TranscriptSegment(
                index: i,
                start: segLength * i,
                end: segLength * (i + 1),
                text: parts[i],
                boundarySource: BoundarySource.vad,
              ),
          ],
        ),
      );
    }
    transcripts = InMemoryTranscriptRepository(initial: transcriptItems);
    recordings = InMemoryRecordingRepository(
      initial: recordingItems,
      transcripts: transcripts,
    );
    entries = InMemoryEntryRepository(
      ids,
      initial: entryItems,
      recordings: recordings,
    );
    settings = InMemorySettingsRepository(
      values: {if (onboardingDone) AppSettings.keyOnboardingDone: 'true'},
    );
    services = AppServices(
      journalId: testJournalId,
      entries: entries,
      recordings: recordings,
      transcripts: transcripts,
      settings: settings,
      search: InMemorySearchRepository(entries, recordings, transcripts),
      recorder: SimulatedRecorder(),
      transcriber: FakeSttEngine(text: fakeTranscript),
      playerFor: (r) => SimulatedPlayer(
        duration: r.duration,
        tick: const Duration(milliseconds: 100),
      ),
      deleteFiles: (names) async => deletedFiles.addAll(names),
      features: features,
      ids: ids,
    );
  }

  final RandomIdGenerator ids = RandomIdGenerator();
  final List<String> deletedFiles = [];
  late final InMemoryEntryRepository entries;
  late final InMemoryRecordingRepository recordings;
  late final InMemoryTranscriptRepository transcripts;
  late final InMemorySettingsRepository settings;
  late final AppServices services;

  /// Provider-Überschreibungen (der Typ `Override` wird von flutter_riverpod
  /// nicht exportiert, deshalb aus den Elementen abgeleitet).
  // ignore: strict_top_level_inference
  get overrides => [
    appServicesProvider.overrideWith((ref) => services),
    platformFeaturesProvider.overrideWithValue(services.features),
  ];
}

/// Plattformfunktionen für Web-Oberflächentests ohne Browser.
class FakePlatformFeatures implements PlatformFeatures {
  FakePlatformFeatures({
    this.isWeb = true,
    this.isStandalone = false,
    this.isIos = true,
    this.storage = const StorageStatus(
      persisted: false,
      usageBytes: 3 * 1024 * 1024,
      quotaBytes: 103 * 1024 * 1024,
    ),
  });

  @override
  final bool isWeb;
  @override
  final bool isStandalone;
  @override
  final bool isIos;
  final StorageStatus? storage;
  final List<({int hour, int minute, String title})> downloads = [];

  @override
  bool get recordsRealAudio => isWeb;

  @override
  Future<StorageStatus?> storageStatus() async => storage;

  @override
  Future<bool> requestPersistentStorage() async => true;

  @override
  void downloadReminderCalendar({
    required int hour,
    required int minute,
    required String title,
    String? description,
  }) => downloads.add((hour: hour, minute: minute, title: title));
}

/// Baut die ganze App mit festgelegter Sprache und Vorbelegung.
Widget buildTestApp({
  Locale locale = const Locale('de'),
  bool onboardingDone = true,
  List<SeedEntry> seed = const [],
  TestServices? services,
}) {
  final s =
      services ?? TestServices(onboardingDone: onboardingDone, seed: seed);
  return ProviderScope(
    overrides: s.overrides,
    child: TagebuchApp(locale: locale),
  );
}

/// Bettet einen einzelnen Bildschirm in eine lokalisierte MaterialApp ein.
Widget buildTestScreen(
  Widget screen, {
  Locale locale = const Locale('de'),
  List<SeedEntry> seed = const [],
  TestServices? services,
}) {
  final s = services ?? TestServices(seed: seed);
  return ProviderScope(
    overrides: s.overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
}

/// Pumpt eine Routenanimation zu Ende, ohne auf laufende Timer zu warten
/// (die Aufnahme hat periodische Timer, `pumpAndSettle` würde nicht enden).
Future<void> pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
