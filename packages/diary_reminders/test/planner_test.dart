import 'package:diary_core/diary_core.dart';
import 'package:diary_reminders/diary_reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = ReminderPlanner();
  const settings = ReminderSettings(hour: 21, minute: 0);

  test('heute 21:00, wenn noch vor 21:00', () {
    final next = planner.next(settings, now: DateTime(2026, 9, 7, 8, 0));
    expect(next, DateTime(2026, 9, 7, 21, 0));
  });

  test('morgen, wenn 21:00 vorbei ist', () {
    final next = planner.next(settings, now: DateTime(2026, 9, 7, 21, 0));
    expect(next, DateTime(2026, 9, 8, 21, 0));
  });

  test('aus = kein Termin', () {
    expect(
      planner.next(
        settings.copyWith(enabled: false),
        now: DateTime(2026, 9, 7),
      ),
      isNull,
    );
  });

  test('nur Werktage: Freitagabend springt auf Montag', () {
    final werktage = settings.copyWith(weekdays: {1, 2, 3, 4, 5});
    // 11. 9. 2026 ist ein Freitag.
    final next = planner.next(werktage, now: DateTime(2026, 9, 11, 22, 0));
    expect(next, DateTime(2026, 9, 14, 21, 0));
    expect(next!.weekday, DateTime.monday);
  });

  test('Pause bis Datum überspringt einschließlich', () {
    final paused = planner.pauseUntil(settings, const LocalDay(2026, 9, 10));
    final next = planner.next(paused, now: DateTime(2026, 9, 7, 8, 0));
    expect(next, DateTime(2026, 9, 11, 21, 0));
    expect(planner.resume(paused).pausedUntil, isNull);
  });

  test('Heute nicht und bereits aufgenommen', () {
    final now = DateTime(2026, 9, 7, 8, 0);
    expect(
      planner.next(settings, now: now, skipDay: const LocalDay(2026, 9, 7)),
      DateTime(2026, 9, 8, 21, 0),
    );
    expect(
      planner.next(
        settings,
        now: now,
        recordedToday: const LocalDay(2026, 9, 7),
      ),
      DateTime(2026, 9, 8, 21, 0),
    );
  });

  test('Snooze verschiebt um eine Stunde', () {
    expect(
      planner.snooze(DateTime(2026, 9, 7, 21, 0)),
      DateTime(2026, 9, 7, 22, 0),
    );
  });

  test('Koordinator plant genau einen Termin und ersetzt ihn', () async {
    final scheduler = FakeReminderScheduler();
    final clock = FixedClock(DateTime(2026, 9, 7, 8, 0));
    final coordinator = ReminderCoordinator(scheduler, clock);
    await coordinator.apply(settings);
    await coordinator.apply(settings.copyWith(hour: 7, minute: 30));
    expect(scheduler.scheduled, hasLength(1));
    expect(scheduler.scheduled.single.fireAt, DateTime(2026, 9, 8, 7, 30));
    final at = await coordinator.snooze(settings);
    expect(at, DateTime(2026, 9, 7, 9, 0));
    expect(scheduler.scheduled.last.oneShot, isTrue);
  });
}
