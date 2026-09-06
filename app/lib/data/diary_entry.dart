import 'package:flutter/foundation.dart';

import 'day.dart';

/// Ein Tagebucheintrag im In-Memory-Modell.
///
/// Platzhalter für das spätere Domänenmodell aus `diary_core`; bewusst klein:
/// Kalendertag, Aufnahmezeitpunkt, Dauer, Transkript, Sprache, Audio-Flag.
@immutable
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.day,
    required this.recordedAt,
    required this.duration,
    required this.transcript,
    required this.language,
    this.hasAudio = true,
  });

  final String id;

  /// Der Kalendertag, zu dem der Eintrag gehört (bei Nachträgen ungleich dem
  /// Aufnahmetag).
  final DateTime day;

  final DateTime recordedAt;
  final Duration duration;
  final String transcript;

  /// BCP-47-Kennung wie `de-DE` oder `en`.
  final String language;

  final bool hasAudio;

  /// Wahr, wenn der Eintrag nachträglich für einen früheren Tag entstand.
  bool get isBackdated => !isSameDay(day, recordedAt);

  @override
  bool operator ==(Object other) => other is DiaryEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Abfragen über eine Liste von Einträgen (reine Funktionen, leicht testbar).
extension DiaryEntryQueries on Iterable<DiaryEntry> {
  /// Einträge des Kalendertags [day], älteste zuerst.
  List<DiaryEntry> onDay(DateTime day) =>
      where((e) => isSameDay(e.day, day)).toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  /// Einträge im Monat von [month], neueste zuerst.
  List<DiaryEntry> inMonth(DateTime month) =>
      where((e) => e.day.year == month.year && e.day.month == month.month)
          .toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  /// Tage (1 bis 31) im Monat von [month], die einen Eintrag haben.
  Set<int> daysWithEntriesIn(DateTime month) =>
      inMonth(month).map((e) => e.day.day).toSet();

  /// Einfache Volltextsuche über das Transkript (Groß-/Kleinschreibung egal).
  /// Platzhalter für FTS5; leerer Suchtext liefert alle Einträge.
  List<DiaryEntry> search(String query) {
    final needle = query.trim().toLowerCase();
    final result = needle.isEmpty
        ? toList()
        : where((e) => e.transcript.toLowerCase().contains(needle)).toList();
    return result..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }
}

/// Der heutige Kalendertag (lokale Zeit).
DateTime today() => dayOf(DateTime.now());
