import 'package:diary_core/diary_core.dart';

import 'planner.dart';

/// Was die Plattform planen soll. Der Text der Benachrichtigung enthält nie
/// Tagebuchinhalt (D5); Aktionen: Aufnehmen, In 1 Stunde, Heute nicht.
class PlannedReminder {
  const PlannedReminder({
    required this.fireAt,
    required this.timeSensitive,
    this.oneShot = false,
  });
  final DateTime fireAt;
  final bool timeSensitive;

  /// Einmalig (z. B. "In 1 Stunde") statt täglich wiederkehrend.
  final bool oneShot;

  @override
  String toString() =>
      'PlannedReminder($fireAt, timeSensitive: $timeSensitive, oneShot: $oneShot)';
}

/// Plattform-Schnittstelle. Umsetzung in Spike S7 (iOS Notifications,
/// Android AlarmManager mit SCHEDULE_EXACT_ALARM und Rückfall auf setWindow).
abstract interface class ReminderScheduler {
  Future<void> schedule(PlannedReminder reminder);
  Future<void> cancelAll();

  /// Ob exakte Termine möglich sind (Android: `canScheduleExactAlarms`);
  /// sonst zeigt die Oberfläche den ±10-Minuten-Hinweis (docs/04 8.2).
  Future<bool> get exactSchedulingAvailable;
}

/// Hält Termine nur fest; für Tests und für die Oberfläche ohne Plattformcode.
class FakeReminderScheduler implements ReminderScheduler {
  final List<PlannedReminder> scheduled = [];
  bool exact = true;

  @override
  Future<void> schedule(PlannedReminder reminder) async =>
      scheduled.add(reminder);

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  Future<bool> get exactSchedulingAvailable async => exact;
}

/// Verbindet Einstellungen, Planung und Scheduler: nach jeder Änderung wird
/// genau ein nächster Termin geplant.
class ReminderCoordinator {
  ReminderCoordinator(
    this._scheduler,
    this._clock, [
    this._planner = const ReminderPlanner(),
  ]);

  final ReminderScheduler _scheduler;
  final Clock _clock;
  final ReminderPlanner _planner;

  Future<DateTime?> apply(
    ReminderSettings settings, {
    LocalDay? skipDay,
    LocalDay? recordedToday,
  }) async {
    await _scheduler.cancelAll();
    final next = _planner.next(
      settings,
      now: _clock.now(),
      skipDay: skipDay,
      recordedToday: recordedToday,
    );
    if (next != null) {
      await _scheduler.schedule(
        PlannedReminder(fireAt: next, timeSensitive: settings.timeSensitive),
      );
    }
    return next;
  }

  Future<DateTime> snooze(ReminderSettings settings) async {
    final at = _planner.snooze(_clock.now());
    await _scheduler.schedule(
      PlannedReminder(
        fireAt: at,
        timeSensitive: settings.timeSensitive,
        oneShot: true,
      ),
    );
    return at;
  }
}
