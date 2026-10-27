import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/routes.dart';
import '../features/daten/transfer_support.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import 'surface_card.dart';

/// Widget-Keys für Tests.
const Key backupReminderCardKey = Key('backup-reminder');
const Key backupReminderLaterKey = Key('backup-reminder-later');
const Key backupReminderNowKey = Key('backup-reminder-now');

/// Karte "Zeit für ein Backup" auf "Heute" (D16 Punkt 3): ab dem dritten
/// Eintrag und wenn das letzte Backup älter als sieben Tage ist. Kein
/// Zähler, kein Vorwurf; "Später" stellt eine Woche zurück.
class BackupReminderCard extends ConsumerWidget {
  const BackupReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(backupReminderProvider).value;
    if (reminder == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWeb = ref.watch(platformFeaturesProvider).isWeb;
    final body = reminder.hadBackup
        ? l10n.backupReminderOverdue
        : isWeb
        ? l10n.backupReminderBodyWeb(reminder.entryCount)
        : l10n.backupReminderBodyNative(reminder.entryCount);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        key: backupReminderCardKey,
        color: scheme.secondaryContainer,
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.save_alt,
                  size: 20,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.backupReminderTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: backupReminderLaterKey,
                  onPressed: () => ref.read(backupBookkeepingProvider).snooze(),
                  child: Text(l10n.backupReminderLater),
                ),
                const SizedBox(width: 4),
                FilledButton.tonal(
                  key: backupReminderNowKey,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.backup),
                  child: Text(l10n.backupReminderNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
