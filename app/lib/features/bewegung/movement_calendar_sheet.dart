import 'package:diary_reminders/diary_reminders.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/platform_features.dart';
import 'movement_library.dart';
import 'movement_texts.dart';

/// Widget-Keys für Tests.
const Key movementCalendarIcsKey = Key('movement-calendar-ics');
Key movementCalendarGoogleKey(int index) =>
    Key('movement-calendar-google-$index');
Key movementCalendarOutlookKey(int index) =>
    Key('movement-calendar-outlook-$index');
Key movementCalendarOfficeKey(int index) =>
    Key('movement-calendar-office-$index');

/// Blatt "Bewegungspausen in den Kalender" (D24, nach dem Muster von D18):
/// je Pause eine Zeile mit Uhrzeit und Wochentagen und den Links für Google
/// Kalender (mit `BYDAY`), Outlook.com und Microsoft 365 (ohne Wiederholung
/// im Link), darunter eine Kalenderdatei mit allen Pausen als mehrere
/// Termine. Je Pause ein Link, weil Google je Aufruf nur einen Termin anlegt.
/// Übertragen werden nur Titel, Uhrzeit und Wochentage; das Blatt sagt das.
Future<void> showMovementCalendarSheet(
  BuildContext context, {
  required PlatformFeatures features,
  required List<MovementBreak> breaks,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _MovementCalendarSheet(
      features: features,
      breaks: [
        for (final b in breaks)
          if (b.weekdays.isNotEmpty) b,
      ],
    ),
  );
}

class _MovementCalendarSheet extends StatelessWidget {
  const _MovementCalendarSheet({required this.features, required this.breaks});

  final PlatformFeatures features;

  /// Nur Pausen mit mindestens einem Wochentag.
  final List<MovementBreak> breaks;

  void _open(BuildContext context, CalendarService service, MovementBreak b) {
    final l10n = AppLocalizations.of(context);
    features.openExternalLink(
      CalendarLinks.build(
        service,
        hour: b.hour,
        minute: b.minute,
        title: l10n.movementIcsTitle,
        description: l10n.movementIcsDescription,
        byDay: b.weekdays,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          CalendarLinks.repeatsDaily(service)
              ? l10n.reminderCalendarOpened
              : l10n.movementCalendarOpenedSetRepeat,
        ),
      ),
    );
  }

  void _download(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    features.downloadCalendarFile('tagebuch-bewegung.ics', [
      for (final b in breaks)
        CalendarEventSpec(
          hour: b.hour,
          minute: b.minute,
          title: l10n.movementIcsTitle,
          description: l10n.movementIcsDescription,
          weekdays: b.weekdays,
        ),
    ]);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.movementCalendarCreated)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              l10n.movementCalendar,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (breaks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(l10n.movementCalendarNoBreaks, style: muted),
            ),
          if (features.canOpenLinks)
            for (final (i, b) in breaks.indexed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${MovementTexts.time(context, b)} · '
                      '${MovementTexts.weekdays(context, b.weekdays)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          key: movementCalendarGoogleKey(i),
                          onPressed: () =>
                              _open(context, CalendarService.google, b),
                          icon: const Icon(Icons.event_repeat, size: 18),
                          label: Text(l10n.reminderCalendarGoogle),
                        ),
                        TextButton.icon(
                          key: movementCalendarOutlookKey(i),
                          onPressed: () => _open(
                            context,
                            CalendarService.outlookPersonal,
                            b,
                          ),
                          icon: const Icon(Icons.event, size: 18),
                          label: Text(l10n.reminderCalendarOutlook),
                        ),
                        TextButton.icon(
                          key: movementCalendarOfficeKey(i),
                          onPressed: () =>
                              _open(context, CalendarService.outlookWork, b),
                          icon: const Icon(Icons.work_outline, size: 18),
                          label: Text(l10n.reminderCalendarOffice),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          if (breaks.isNotEmpty)
            ListTile(
              key: movementCalendarIcsKey,
              leading: const Icon(Icons.file_download_outlined),
              title: Text(l10n.movementCalendarIcsAll),
              subtitle: Text(l10n.movementCalendarIcsSubtitle),
              onTap: () => _download(context),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.movementCalendarPrivacyNote, style: muted),
          ),
        ],
      ),
    );
  }
}
