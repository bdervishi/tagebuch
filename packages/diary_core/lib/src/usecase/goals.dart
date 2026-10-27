import '../model/goal.dart';
import '../ports/clock.dart';
import '../ports/repositories.dart';
import '../ports/services.dart';

/// Mehr als [GoalsUseCase.maxActive] aktive Ziele gibt es nicht; die
/// Oberfläche sagt das freundlich und bietet an, erst einen Weg abzuschließen.
class GoalLimitReachedException implements Exception {
  const GoalLimitReachedException(this.maxActive);
  final int maxActive;

  @override
  String toString() => 'Höchstens $maxActive aktive Ziele';
}

/// Ziele mit Etappen (D19): anlegen, Etappen hinzufügen und abhaken,
/// abschließen, archivieren, bearbeiten, löschen. Fortschritt ist allein
/// "erledigt von allen" ([GoalProgress]); kein Prozent, keine Punkte.
class GoalsUseCase {
  const GoalsUseCase({
    required this.journalId,
    required this.goals,
    required this.ids,
    required this.clock,
  });

  /// Höchstens drei aktive Ziele gleichzeitig (D19).
  static const int maxActive = 3;

  final String journalId;
  final GoalRepository goals;
  final IdGenerator ids;
  final Clock clock;

  /// Wahr, wenn noch ein Ziel angelegt werden darf.
  Future<bool> canCreate() async =>
      (await goals.listActive(journalId)).length < maxActive;

  /// Legt ein Ziel mit optionalen ersten Etappen an. Leere Etappentitel
  /// werden übergangen. Wirft [GoalLimitReachedException], wenn schon
  /// [maxActive] Ziele aktiv sind.
  Future<Goal> createGoal({
    required String title,
    String? why,
    List<String> milestoneTitles = const [],
  }) async {
    final active = await goals.listActive(journalId);
    if (active.length >= maxActive) {
      throw const GoalLimitReachedException(maxActive);
    }
    final now = clock.now();
    final trimmedWhy = why?.trim();
    final goal = Goal(
      id: ids.next(),
      journalId: journalId,
      title: title.trim(),
      why: trimmedWhy == null || trimmedWhy.isEmpty ? null : trimmedWhy,
      createdAt: now,
      updatedAt: now,
      sortIndex: active.isEmpty
          ? 0
          : active.map((g) => g.sortIndex).reduce((a, b) => a > b ? a : b) + 1,
    );
    await goals.insertGoal(goal);
    var index = 0;
    for (final t in milestoneTitles) {
      final trimmed = t.trim();
      if (trimmed.isEmpty) continue;
      await goals.insertMilestone(
        Milestone(
          id: ids.next(),
          goalId: goal.id,
          title: trimmed,
          sortIndex: index++,
          createdAt: now,
        ),
      );
    }
    return goal;
  }

  /// Ändert Titel und "Warum" (leer entfernt das Warum).
  Future<Goal?> editGoal(
    String goalId, {
    required String title,
    String? why,
  }) async {
    final goal = await goals.goalById(goalId);
    if (goal == null) return null;
    final trimmedWhy = why?.trim() ?? '';
    final updated = goal.copyWith(
      title: title.trim(),
      why: trimmedWhy.isEmpty ? null : trimmedWhy,
      clearWhy: trimmedWhy.isEmpty,
      updatedAt: clock.now(),
    );
    await goals.updateGoal(updated);
    return updated;
  }

  /// Hängt eine offene Etappe hinten an; leerer Titel: nichts passiert.
  Future<Milestone?> addMilestone(String goalId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    final m = Milestone(
      id: ids.next(),
      goalId: goalId,
      title: trimmed,
      sortIndex: await _nextSortIndex(goalId),
      createdAt: clock.now(),
    );
    await goals.insertMilestone(m);
    return m;
  }

  /// Legt eine bereits erledigte Etappe an: aus dem abgehakten Schritt für
  /// heute (D19 Punkt 3). Nur für aktive Ziele; sonst `null`.
  Future<Milestone?> addDoneMilestone(String goalId, String title) async {
    final goal = await goals.goalById(goalId);
    if (goal == null || !goal.isActive) return null;
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;
    final now = clock.now();
    final m = Milestone(
      id: ids.next(),
      goalId: goalId,
      title: trimmed,
      sortIndex: await _nextSortIndex(goalId),
      createdAt: now,
      doneAt: now,
    );
    await goals.insertMilestone(m);
    return m;
  }

  Future<int> _nextSortIndex(String goalId) async {
    final existing = await goals.listMilestones(goalId);
    return existing.isEmpty
        ? 0
        : existing.map((m) => m.sortIndex).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Hakt eine Etappe ab oder macht sie wieder offen.
  Future<void> setMilestoneDone(String milestoneId, bool done) async {
    final m = await goals.milestoneById(milestoneId);
    if (m == null || m.isDone == done) return;
    await goals.updateMilestone(
      done ? m.copyWith(doneAt: clock.now()) : m.copyWith(clearDone: true),
    );
  }

  Future<void> renameMilestone(String milestoneId, String title) async {
    final trimmed = title.trim();
    final m = await goals.milestoneById(milestoneId);
    if (m == null || trimmed.isEmpty) return;
    await goals.updateMilestone(m.copyWith(title: trimmed));
  }

  Future<void> deleteMilestone(String milestoneId) =>
      goals.deleteMilestone(milestoneId);

  /// Schließt ein Ziel ab; jederzeit erlaubt, auch mit offenen Etappen.
  Future<void> completeGoal(String goalId) async {
    final goal = await goals.goalById(goalId);
    if (goal == null) return;
    final now = clock.now();
    await goals.updateGoal(goal.copyWith(completedAt: now, updatedAt: now));
  }

  /// Legt ein Ziel ohne Abschluss zur Seite.
  Future<void> archiveGoal(String goalId) async {
    final goal = await goals.goalById(goalId);
    if (goal == null) return;
    final now = clock.now();
    await goals.updateGoal(goal.copyWith(archivedAt: now, updatedAt: now));
  }

  /// Macht ein abgeschlossenes oder archiviertes Ziel wieder aktiv; wirft
  /// [GoalLimitReachedException], wenn kein Platz ist.
  Future<void> reopenGoal(String goalId) async {
    final goal = await goals.goalById(goalId);
    if (goal == null || goal.isActive) return;
    if (!await canCreate()) {
      throw const GoalLimitReachedException(maxActive);
    }
    await goals.updateGoal(
      goal.copyWith(
        clearCompleted: true,
        clearArchived: true,
        updatedAt: clock.now(),
      ),
    );
  }

  /// Löscht Ziel und Etappen.
  Future<void> deleteGoal(String goalId) => goals.deleteGoal(goalId);

  Future<GoalProgress> progress(String goalId) async =>
      GoalProgress.of(await goals.listMilestones(goalId));

  /// Etappen, die seit [since] (einschließlich) erledigt wurden, je Ziel;
  /// Ziele ohne solche Etappen fehlen. Grundlage für "Wege diese Woche".
  Future<Map<Goal, List<Milestone>>> doneSince(DateTime since) async {
    final byGoal = <String, List<Milestone>>{};
    for (final m in await goals.listAllMilestones()) {
      final at = m.doneAt;
      if (at == null || at.isBefore(since)) continue;
      byGoal.putIfAbsent(m.goalId, () => []).add(m);
    }
    final out = <Goal, List<Milestone>>{};
    for (final g in await goals.listAllGoals(journalId)) {
      final list = byGoal[g.id];
      if (list == null) continue;
      list.sort((a, b) => a.doneAt!.compareTo(b.doneAt!));
      out[g] = list;
    }
    return out;
  }
}
