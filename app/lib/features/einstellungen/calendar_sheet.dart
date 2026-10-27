import 'package:diary_reminders/diary_reminders.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/platform_features.dart';

/// Widget-Keys für Tests.
const Key reminderCalendarGoogleKey = Key('reminder-calendar-google');
const Key reminderCalendarOutlookKey = Key('reminder-calendar-outlook');
const Key reminderCalendarOfficeKey = Key('reminder-calendar-office');
const Key reminderCalendarIcsKey = Key('reminder-calendar-ics');

/// Blatt "Kalendereintrag erstellen" (D18): Google Kalender, Outlook.com,
/// Microsoft 365 als vorbefüllte Links (nur wenn die Plattform Links öffnen
/// kann) und die Kalenderdatei (.ics) für Apple Kalender und alle anderen.
/// Übertragen werden nur Titel und Uhrzeit der Erinnerung; das Blatt sagt
/// das, bevor etwas geöffnet wird.
Future<void> showReminderCalendarSheet(
  BuildContext context, {
  required PlatformFeatures features,
  required int hour,
  required int minute,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _CalendarSheet(features: features, hour: hour, minute: minute),
  );
}

class _CalendarSheet extends StatelessWidget {
  const _CalendarSheet({
    required this.features,
    required this.hour,
    required this.minute,
  });

  final PlatformFeatures features;
  final int hour;
  final int minute;

  void _open(BuildContext context, CalendarService service) {
    final l10n = AppLocalizations.of(context);
    features.openExternalLink(
      CalendarLinks.build(
        service,
        hour: hour,
        minute: minute,
        title: l10n.reminderIcsTitle,
        description: l10n.reminderIcsDescription,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          CalendarLinks.repeatsDaily(service)
              ? l10n.reminderCalendarOpened
              : l10n.reminderCalendarOpenedSetRepeat,
        ),
      ),
    );
  }

  void _download(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    features.downloadReminderCalendar(
      hour: hour,
      minute: minute,
      title: l10n.reminderIcsTitle,
      description: l10n.reminderIcsDescription,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.reminderCalendarCreated)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                l10n.reminderCalendarSheetTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (features.canOpenLinks) ...[
              ListTile(
                key: reminderCalendarGoogleKey,
                leading: const Icon(Icons.event_repeat),
                title: Text(l10n.reminderCalendarGoogle),
                subtitle: Text(l10n.reminderCalendarGoogleSubtitle),
                onTap: () => _open(context, CalendarService.google),
              ),
              ListTile(
                key: reminderCalendarOutlookKey,
                leading: const Icon(Icons.event),
                title: Text(l10n.reminderCalendarOutlook),
                subtitle: Text(l10n.reminderCalendarOutlookSubtitle),
                onTap: () => _open(context, CalendarService.outlookPersonal),
              ),
              ListTile(
                key: reminderCalendarOfficeKey,
                leading: const Icon(Icons.work_outline),
                title: Text(l10n.reminderCalendarOffice),
                subtitle: Text(l10n.reminderCalendarOutlookSubtitle),
                onTap: () => _open(context, CalendarService.outlookWork),
              ),
            ],
            ListTile(
              key: reminderCalendarIcsKey,
              leading: const Icon(Icons.file_download_outlined),
              title: Text(l10n.reminderCalendarIcs),
              subtitle: Text(l10n.reminderCalendarIcsSubtitle),
              onTap: () => _download(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(l10n.reminderCalendarPrivacyNote, style: muted),
            ),
          ],
        ),
      ),
    );
  }
}
