import 'package:diary_core/diary_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_services.dart';
import 'entry_view.dart';

/// Ein Ziel mit seinen Etappen, wie es die Oberfläche zeigt (D19, "Wege").
class GoalView {
  const GoalView({required this.goal, required this.milestones});

  final Goal goal;

  /// Nach `sortIndex`.
  final List<Milestone> milestones;

  String get id => goal.id;

  /// "3 von 7": erledigt von allen, kein Prozent (D19).
  GoalProgress get progress => GoalProgress.of(milestones);

  /// Die erste offene Etappe oder `null`.
  Milestone? get nextOpen => milestones.where((m) => !m.isDone).firstOrNull;

  static Future<GoalView> load(AppServices s, Goal goal) async =>
      GoalView(goal: goal, milestones: await s.goals.listMilestones(goal.id));
}

/// Aktive Wege (höchstens drei), nach Reihenfolge.
final activeGoalsProvider = FutureProvider<List<GoalView>>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  return [
    for (final g in await s.goals.listActive(s.journalId))
      await GoalView.load(s, g),
  ];
});

/// Abgeschlossene und archivierte Wege, zuletzt beendete zuerst.
final archivedGoalsProvider = FutureProvider<List<GoalView>>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  return [
    for (final g in await s.goals.listArchived(s.journalId))
      await GoalView.load(s, g),
  ];
});

/// Ein Weg nach Kennung oder `null`.
final goalViewProvider = FutureProvider.family<GoalView?, String>((
  ref,
  goalId,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final goal = await s.goals.goalById(goalId);
  return goal == null ? null : GoalView.load(s, goal);
});

/// Ob noch ein Weg angelegt werden darf (D19: höchstens drei aktive).
final canCreateGoalProvider = FutureProvider<bool>((ref) async {
  final active = await ref.watch(activeGoalsProvider.future);
  return active.length < GoalsUseCase.maxActive;
});

/// "Wege diese Woche": je Weg die in den letzten sieben Tagen (heute
/// eingeschlossen) erledigten Etappen; Wege ohne solche fehlen.
final weekGoalsProvider = FutureProvider<List<(Goal, List<Milestone>)>>((
  ref,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final today = LocalDay.forMoment(s.clock.now());
  final since = today.addDays(-6).startOfDay;
  final done = await s.goalsUseCase().doneSince(since);
  return [for (final e in done.entries) (e.key, e.value)];
});

/// Schreibende Aktionen für Wege und Etappen. Jede Änderung erhöht den
/// Datenzähler, damit "Heute", "Wege" und der Wochenrückblick neu laden.
class GoalActions {
  const GoalActions(this.ref);
  final Ref ref;

  Future<GoalsUseCase> _useCase() async =>
      (await ref.read(appServicesProvider.future)).goalsUseCase();

  void _bump() => ref.read(dataVersionProvider.notifier).bump();

  /// Wirft [GoalLimitReachedException], wenn schon drei Wege aktiv sind.
  Future<Goal> create({
    required String title,
    String? why,
    List<String> milestoneTitles = const [],
  }) async {
    final goal = await (await _useCase()).createGoal(
      title: title,
      why: why,
      milestoneTitles: milestoneTitles,
    );
    _bump();
    return goal;
  }

  Future<void> edit(String goalId, {required String title, String? why}) async {
    await (await _useCase()).editGoal(goalId, title: title, why: why);
    _bump();
  }

  Future<Milestone?> addMilestone(String goalId, String title) async {
    final m = await (await _useCase()).addMilestone(goalId, title);
    if (m != null) _bump();
    return m;
  }

  Future<void> setMilestoneDone(String milestoneId, bool done) async {
    await (await _useCase()).setMilestoneDone(milestoneId, done);
    _bump();
  }

  Future<void> deleteMilestone(String milestoneId) async {
    await (await _useCase()).deleteMilestone(milestoneId);
    _bump();
  }

  Future<void> complete(String goalId) async {
    await (await _useCase()).completeGoal(goalId);
    _bump();
  }

  Future<void> archive(String goalId) async {
    await (await _useCase()).archiveGoal(goalId);
    _bump();
  }

  /// Wirft [GoalLimitReachedException], wenn kein Platz ist.
  Future<void> reopen(String goalId) async {
    await (await _useCase()).reopenGoal(goalId);
    _bump();
  }

  Future<void> delete(String goalId) async {
    await (await _useCase()).deleteGoal(goalId);
    _bump();
  }
}

final goalActionsProvider = Provider<GoalActions>((ref) => GoalActions(ref));
