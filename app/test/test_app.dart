import 'dart:typed_data';

import 'package:diary_audio/diary_audio.dart';
import 'package:diary_core/diary_core.dart';
import 'package:diary_stt/diary_stt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/app/app.dart';
import 'package:tagebuch_app/app/routes.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';
import 'package:tagebuch_app/features/zitate/quote_library.dart';
import 'package:tagebuch_app/features/zitate/quote_providers.dart';
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
    this.withRecording = true,
    this.notes = const {},
    this.quickNotes = const [],
    this.mood,
  });

  final String id;
  final DateTime day;
  final String transcript;
  final Duration duration;
  final List<String>? segments;

  /// Ohne Aufnahme: ein nur geschriebener Tag (D17).
  final bool withRecording;

  /// Notizen als Impuls-Schlüssel (oder `'free'`-fremder Schlüssel `''` für
  /// freien Text) auf Text; Reihenfolge ist Anlagereihenfolge.
  final Map<String, String> notes;

  /// Kurznotizen über den Tag (D22), ab 9 Uhr im Abstand von zwei Stunden;
  /// Kennung `note-<id>-quick-<index>`.
  final List<String> quickNotes;

  /// Stimmung 1 bis 5.
  final int? mood;
}

SeedEntry testEntry({
  required String id,
  required DateTime day,
  String transcript = fakeTranscript,
  Duration duration = const Duration(seconds: 90),
  List<String>? segments,
  bool withRecording = true,
  Map<String, String> notes = const {},
  List<String> quickNotes = const [],
  int? mood,
}) => SeedEntry(
  id: id,
  day: day,
  transcript: transcript,
  duration: duration,
  segments: segments,
  withRecording: withRecording,
  notes: notes,
  quickNotes: quickNotes,
  mood: mood,
);

/// Dienste mit In-Memory-Fakes; die Repositories bleiben für Prüfungen
/// zugänglich.
class TestServices {
  TestServices({
    bool onboardingDone = true,
    List<SeedEntry> seed = const [],
    PlatformFeatures features = const NativePlatformFeatures(),
    this.sttEngine,
    this.fileTranscriber,
    this.quoteLibrary,
  }) {
    final entryItems = <DiaryEntry>[];
    final recordingItems = <Recording>[];
    final transcriptItems = <Transcript>[];
    final noteItems = <EntryNote>[];
    for (final s in seed) {
      final startedAt = s.day.add(const Duration(hours: 21));
      entryItems.add(
        DiaryEntry(
          id: s.id,
          journalId: testJournalId,
          day: LocalDay.forMoment(s.day),
          createdAt: startedAt,
          updatedAt: startedAt,
          mood: s.mood == null ? null : MoodScale.encode(s.mood!),
        ),
      );
      var noteIndex = 0;
      for (final n in s.notes.entries) {
        final at = startedAt.add(Duration(minutes: 10 + noteIndex));
        noteItems.add(
          EntryNote(
            id: 'note-${s.id}-${n.key.isEmpty ? 'free-text' : n.key}',
            entryId: s.id,
            createdAt: at,
            updatedAt: at,
            text: n.value,
            promptKey: n.key.isEmpty ? null : n.key,
          ),
        );
        noteIndex++;
      }
      for (final (i, text) in s.quickNotes.indexed) {
        final at = s.day.add(Duration(hours: 9 + 2 * i));
        noteItems.add(
          EntryNote(
            id: 'note-${s.id}-quick-$i',
            entryId: s.id,
            createdAt: at,
            updatedAt: at,
            text: text,
            promptKey: ReviewPrompts.quick,
          ),
        );
      }
      if (!s.withRecording) continue;
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
    notes = InMemoryNoteRepository(initial: noteItems);
    goals = InMemoryGoalRepository();
    books = InMemoryBookRepository();
    entries = InMemoryEntryRepository(
      ids,
      initial: entryItems,
      recordings: recordings,
      notes: notes,
    );
    settings = InMemorySettingsRepository(
      values: {if (onboardingDone) AppSettings.keyOnboardingDone: 'true'},
    );
    services = AppServices(
      journalId: testJournalId,
      entries: entries,
      recordings: recordings,
      transcripts: transcripts,
      notes: notes,
      goals: goals,
      books: books,
      settings: settings,
      search: InMemorySearchRepository(
        entries,
        recordings,
        transcripts,
        notes: notes,
        books: books,
      ),
      recorder: SimulatedRecorder(),
      transcriber: FakeSttEngine(text: fakeTranscript),
      sttEngine: sttEngine,
      fileTranscriber: fileTranscriber,
      playerFor: (r) => SimulatedPlayer(
        duration: r.duration,
        tick: const Duration(milliseconds: 100),
      ),
      deleteFiles: (names) async => deletedFiles.addAll(names),
      features: features,
      audioFiles: audioFiles,
      // Schnelle Argon2id-Parameter, damit Backup-Tests nicht Sekunden dauern.
      argon2Params: Argon2Params.testing,
      ids: ids,
    );
  }

  final RandomIdGenerator ids = RandomIdGenerator();
  final List<String> deletedFiles = [];

  /// Engine für den Abschnitt "Spracherkennung" (null: nicht eingebaut).
  final SttEngine? sttEngine;

  /// Datei-Erkennung für "Erneut transkribieren" und den Aufnahmeablauf.
  final AudioFileTranscriberPort? fileTranscriber;

  /// Zitatenschatz für Tests (D20); ohne Angabe leer, also keine Zitatkarte.
  final QuoteLibrary? quoteLibrary;
  final InMemoryAudioFiles audioFiles = InMemoryAudioFiles();
  late final InMemoryEntryRepository entries;
  late final InMemoryRecordingRepository recordings;
  late final InMemoryTranscriptRepository transcripts;
  late final InMemoryNoteRepository notes;
  late final InMemoryGoalRepository goals;
  late final InMemoryBookRepository books;
  late final InMemorySettingsRepository settings;
  late final AppServices services;

  /// Provider-Überschreibungen (der Typ `Override` wird von flutter_riverpod
  /// nicht exportiert, deshalb aus den Elementen abgeleitet).
  // ignore: strict_top_level_inference
  get overrides => [
    appServicesProvider.overrideWith((ref) => services),
    // Zitatenschatz: das Laden aus dem Asset ist in Widget-Tests nicht
    // deterministisch; deshalb bekommt jeder Test einen festen Schatz,
    // standardmäßig leer (keine Karte, "Heute" bleibt kurz).
    quoteLibraryProvider.overrideWith(
      (ref) async => quoteLibrary ?? const QuoteLibrary(quotes: [], themes: []),
    ),
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

  /// Gespeicherte Containerdateien (Name, Bytes) aus Backup und Transfer.
  final List<(String, Uint8List)> savedFiles = [];

  /// Geöffnete externe Links (Kalender, D18).
  final List<Uri> openedLinks = [];
  bool canOpenLinksValue = true;

  /// Datei, die die nächste Dateiauswahl liefert (`null` = abgebrochen).
  Uint8List? fileToPick;

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

  @override
  bool get canOpenLinks => canOpenLinksValue;

  @override
  void openExternalLink(Uri url) => openedLinks.add(url);

  @override
  Future<void> saveContainerFile(String fileName, Uint8List bytes) async =>
      savedFiles.add((fileName, bytes));

  @override
  Future<Uint8List?> pickContainerFile() async => fileToPick;

  /// Schnellaktion für den nächsten Start (einmalig abgeholt).
  StartAction? startAction;

  @override
  bool get canScanQr => false;

  @override
  StartAction? takeStartAction() {
    final action = startAction;
    startAction = null;
    return action;
  }

  @override
  QrScanner? createQrScanner() => null;
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
      // Benannte Routen, damit ein Bildschirm im Test weiternavigieren kann
      // (zum Beispiel vom Eintrag oder Suchtreffer zum Buch).
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: screen,
    ),
  );
}

/// Scrollt die Liste von "Heute", bis [finder] sichtbar ist. Die Liste baut
/// nur den sichtbaren Teil; seit Zitat, Schritt, Wegen und Lesebuch (D17 bis
/// D21) liegt der heutige Eintrag unterhalb des ersten Bildschirms.
Future<void> scrollTodayTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(TodayScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// Pumpt eine Routenanimation zu Ende, ohne auf laufende Timer zu warten
/// (die Aufnahme hat periodische Timer, `pumpAndSettle` würde nicht enden).
Future<void> pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Bytefolge fester Länge mit Muster (für Audio-Fixtures).
// ignore: non_constant_identifier_names
Uint8List Uint8ListOf(int length, int seed) =>
    Uint8List.fromList(List.generate(length, (i) => (i * seed + 1) & 0xff));
