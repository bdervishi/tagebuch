import 'package:meta/meta.dart';

/// Ein Projekt, an dem die Nutzerin über längere Zeit arbeitet (D26). Je Tag
/// kann sie dazu festhalten, was sie gemacht hat und was gut lief; beides
/// sind gewöhnliche [EntryNote]s am Tageseintrag mit `projectId`, so dass
/// sie im Tagebuch stehen und das Projekt sie nur bündelt. Aktiv ist ein
/// Projekt, das nicht zur Seite gelegt ist; eine Grenze gibt es nicht.
@immutable
class Project {
  const Project({
    required this.id,
    required this.journalId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.sortIndex,
    this.about,
    this.archivedAt,
  });

  final String id;
  final String journalId;
  final String name;

  /// Ein Satz, worum es geht; optional.
  final String? about;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Zeitpunkt des Zur-Seite-Legens (abgeschlossen oder ruhend).
  final DateTime? archivedAt;

  /// Reihenfolge auf dem Bildschirm "Projekte".
  final int sortIndex;

  bool get isActive => archivedAt == null;

  /// [clearAbout] entfernt die Beschreibung; [clearArchived] macht das
  /// Projekt wieder aktiv.
  Project copyWith({
    String? name,
    String? about,
    DateTime? updatedAt,
    DateTime? archivedAt,
    int? sortIndex,
    bool clearAbout = false,
    bool clearArchived = false,
  }) => Project(
    id: id,
    journalId: journalId,
    name: name ?? this.name,
    about: clearAbout ? null : (about ?? this.about),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
    sortIndex: sortIndex ?? this.sortIndex,
  );
}
