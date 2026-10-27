import 'package:meta/meta.dart';

/// Ein Vorhaben mit Etappen (D19, Oberflächenname "Weg"). Aktiv ist ein
/// Ziel, das weder abgeschlossen noch archiviert ist; höchstens drei davon
/// gleichzeitig (`GoalsUseCase.maxActive`).
@immutable
class Goal {
  const Goal({
    required this.id,
    required this.journalId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.sortIndex,
    this.why,
    this.completedAt,
    this.archivedAt,
  });

  final String id;
  final String journalId;
  final String title;

  /// Ein Satz, warum dieses Vorhaben zählt; optional.
  final String? why;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Zeitpunkt des Abschließens (alle Etappen oder bewusst beendet).
  final DateTime? completedAt;

  /// Zeitpunkt des Archivierens (ohne Abschluss zur Seite gelegt).
  final DateTime? archivedAt;

  /// Reihenfolge auf dem Bildschirm "Wege".
  final int sortIndex;

  bool get isActive => completedAt == null && archivedAt == null;

  /// Datum für den Abschnitt "Abgeschlossen": Abschluss vor Archivierung.
  DateTime? get closedAt => completedAt ?? archivedAt;

  /// [clearWhy] entfernt das "Warum"; [clearCompleted] und [clearArchived]
  /// machen ein Ziel wieder aktiv.
  Goal copyWith({
    String? title,
    String? why,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? archivedAt,
    int? sortIndex,
    bool clearWhy = false,
    bool clearCompleted = false,
    bool clearArchived = false,
  }) => Goal(
    id: id,
    journalId: journalId,
    title: title ?? this.title,
    why: clearWhy ? null : (why ?? this.why),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
    archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
    sortIndex: sortIndex ?? this.sortIndex,
  );
}

/// Eine Etappe eines Ziels: ein kleiner, abhakbarer Schritt.
@immutable
class Milestone {
  const Milestone({
    required this.id,
    required this.goalId,
    required this.title,
    required this.sortIndex,
    required this.createdAt,
    this.doneAt,
  });

  final String id;
  final String goalId;
  final String title;

  /// Reihenfolge innerhalb des Ziels.
  final int sortIndex;
  final DateTime createdAt;

  /// Zeitpunkt des Abhakens oder `null`, solange offen.
  final DateTime? doneAt;

  bool get isDone => doneAt != null;

  /// [clearDone] macht die Etappe wieder offen.
  Milestone copyWith({
    String? title,
    int? sortIndex,
    DateTime? doneAt,
    bool clearDone = false,
  }) => Milestone(
    id: id,
    goalId: goalId,
    title: title ?? this.title,
    sortIndex: sortIndex ?? this.sortIndex,
    createdAt: createdAt,
    doneAt: clearDone ? null : (doneAt ?? this.doneAt),
  );
}

/// Fortschritt als "erledigt von allen" (D19: kein Prozent, keine Punkte).
@immutable
class GoalProgress {
  const GoalProgress({required this.done, required this.total});

  factory GoalProgress.of(Iterable<Milestone> milestones) {
    var done = 0;
    var total = 0;
    for (final m in milestones) {
      total++;
      if (m.isDone) done++;
    }
    return GoalProgress(done: done, total: total);
  }

  final int done;
  final int total;

  /// Wahr, wenn es Etappen gibt und alle erledigt sind.
  bool get allDone => total > 0 && done == total;
}
