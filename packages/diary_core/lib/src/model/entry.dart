import 'package:meta/meta.dart';

import 'local_day.dart';

/// Ein Tageseintrag: Klammer um alle Aufnahmen eines Kalendertags (A4).
@immutable
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.journalId,
    required this.day,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.mood,
    this.pinned = false,
  });

  final String id;
  final String journalId;
  final LocalDay day;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;

  /// Vom Nutzer gesetzt, nie aus der Stimme abgeleitet (Nicht-Ziel in docs/00).
  final String? mood;
  final bool pinned;

  /// [clearMood] entfernt die Selbsteinschätzung wieder.
  DiaryEntry copyWith({
    String? title,
    String? mood,
    bool? pinned,
    DateTime? updatedAt,
    bool clearMood = false,
  }) => DiaryEntry(
    id: id,
    journalId: journalId,
    day: day,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    title: title ?? this.title,
    mood: clearMood ? null : (mood ?? this.mood),
    pinned: pinned ?? this.pinned,
  );
}
