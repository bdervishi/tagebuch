/// Tägliche Erinnerung (D7): reine Planungslogik plus Scheduler-Schnittstelle.
///
/// Die Plattform-Umsetzung (iOS `UNCalendarNotificationTrigger`, Android
/// `AlarmManager.setAlarmClock`) folgt in Spike S7; bis dahin gibt es einen
/// Fake, der geplante Termine nur festhält.
library;

export 'src/planner.dart';
export 'src/scheduler.dart';
