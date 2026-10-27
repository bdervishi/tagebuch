import 'package:diary_core/diary_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_services.dart';

/// Ein Tageseintrag mit seinen Aufnahmen und Transkripten, wie ihn die
/// Oberfläche zeigt. Aus den Repositories zusammengesetzt (`load`).
class EntryView {
  const EntryView({
    required this.entry,
    required this.recordings,
    required this.transcripts,
  });

  final DiaryEntry entry;

  /// Älteste zuerst.
  final List<Recording> recordings;

  /// Primäres Transkript je Aufnahme-ID (fehlt, wenn die Erkennung
  /// fehlschlug).
  final Map<String, Transcript?> transcripts;

  String get id => entry.id;

  /// Der Kalendertag als lokale Mitternacht (für Datumsformatierung).
  DateTime get day => entry.day.startOfDay;

  DateTime get recordedAt =>
      recordings.isEmpty ? entry.createdAt : recordings.first.startedAt;

  Duration get duration =>
      recordings.fold(Duration.zero, (sum, r) => sum + r.duration);

  /// Alle Transkripttexte, durch Leerzeilen getrennt.
  String get text => recordings
      .map((r) => transcripts[r.id]?.text.trim() ?? '')
      .where((t) => t.isNotEmpty)
      .join('\n\n');

  bool get hasAudio =>
      recordings.any((r) => r.state != RecordingState.audioDeleted);

  /// Erste Aufnahme mit Audio (für den Player).
  Recording? get playable => recordings
      .where((r) => r.state != RecordingState.audioDeleted)
      .firstOrNull;

  /// Sprache des ersten Transkripts (BCP-47) oder `null`.
  String? get language => recordings
      .map((r) => transcripts[r.id]?.locale)
      .whereType<String>()
      .firstOrNull;

  /// Wahr, wenn der Eintrag nachträglich für einen früheren Tag entstand.
  bool get isBackdated =>
      recordings.isNotEmpty &&
      LocalDay.forMoment(recordings.first.startedAt) != entry.day;

  static Future<EntryView> load(AppServices s, DiaryEntry entry) async {
    final recordings = await s.recordings.listForEntry(entry.id);
    final transcripts = <String, Transcript?>{};
    for (final r in recordings) {
      transcripts[r.id] = await s.transcripts.primaryForRecording(r.id);
    }
    return EntryView(
      entry: entry,
      recordings: recordings,
      transcripts: transcripts,
    );
  }
}

/// Zähler, der nach jeder Änderung an Einträgen erhöht wird; die lesenden
/// Provider hängen daran und laden neu.
class DataVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final dataVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

/// Der heutige Eintrag oder `null`.
final todayViewProvider = FutureProvider<EntryView?>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final day = LocalDay.forMoment(s.clock.now());
  final entry = await s.entries.findByDay(s.journalId, day);
  return entry == null ? null : EntryView.load(s, entry);
});

/// Einträge eines Monats `(Jahr, Monat)`, neueste zuerst.
final monthViewsProvider = FutureProvider.family<List<EntryView>, (int, int)>((
  ref,
  month,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final entries = await s.entries
      .watchMonth(s.journalId, month.$1, month.$2)
      .first;
  return [for (final e in entries) await EntryView.load(s, e)];
});

/// Ein Eintrag nach ID oder `null`.
final entryViewProvider = FutureProvider.family<EntryView?, String>((
  ref,
  entryId,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final entry = await s.entries.byId(entryId);
  return entry == null ? null : EntryView.load(s, entry);
});

/// Suchtreffer als Einträge (je Eintrag einmal, neueste zuerst) mit dem
/// Sprungziel des ersten Treffers.
final searchViewsProvider = FutureProvider.family<List<SearchResult>, String>((
  ref,
  query,
) async {
  ref.watch(dataVersionProvider);
  if (query.trim().isEmpty) return const [];
  final s = await ref.watch(appServicesProvider.future);
  final hits = await s.search.search(query, journalId: s.journalId);
  final seen = <String>{};
  final results = <SearchResult>[];
  for (final hit in hits) {
    if (!seen.add(hit.entryId)) continue;
    final entry = await s.entries.byId(hit.entryId);
    if (entry == null) continue;
    results.add(
      SearchResult(
        view: await EntryView.load(s, entry),
        snippet: hit.snippet,
        jumpTo: hit.jumpTo,
      ),
    );
  }
  return results;
});

class SearchResult {
  const SearchResult({required this.view, required this.snippet, this.jumpTo});
  final EntryView view;
  final String snippet;
  final Duration? jumpTo;
}
