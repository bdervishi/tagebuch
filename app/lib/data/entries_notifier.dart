import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'day.dart';
import 'diary_entry.dart';

/// Hält alle Einträge im Arbeitsspeicher. Platzhalter für die spätere
/// verschlüsselte Datenbank; die Bildschirme kennen nur diesen Notifier.
class EntriesNotifier extends Notifier<List<DiaryEntry>> {
  EntriesNotifier({this._initial = const [], DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final List<DiaryEntry> _initial;
  final DateTime Function() _now;
  int _counter = 0;

  @override
  List<DiaryEntry> build() => List.unmodifiable(_initial);

  /// Legt nach einer (simulierten) Aufnahme einen Eintrag an.
  ///
  /// [day] erlaubt Nachträge für vergangene Tage; ohne Angabe gilt heute.
  DiaryEntry addRecording({
    required Duration duration,
    required String transcript,
    required String language,
    DateTime? day,
    bool hasAudio = true,
  }) {
    final recordedAt = _now();
    _counter++;
    final entry = DiaryEntry(
      id: 'entry-$_counter-${recordedAt.microsecondsSinceEpoch}',
      day: dayOf(day ?? recordedAt),
      recordedAt: recordedAt,
      duration: duration,
      transcript: transcript,
      language: language,
      hasAudio: hasAudio,
    );
    state = List.unmodifiable([...state, entry]);
    return entry;
  }

  /// Sucht einen Eintrag; `null`, wenn er nicht (mehr) existiert.
  DiaryEntry? byId(String id) {
    for (final entry in state) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}

final entriesProvider = NotifierProvider<EntriesNotifier, List<DiaryEntry>>(
  EntriesNotifier.new,
);

/// Ein einzelner Eintrag nach ID; `null`, wenn unbekannt.
final entryByIdProvider = Provider.family<DiaryEntry?, String>((ref, id) {
  final entries = ref.watch(entriesProvider);
  for (final entry in entries) {
    if (entry.id == id) return entry;
  }
  return null;
});
