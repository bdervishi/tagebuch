import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/day.dart';
import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../services/platform_features.dart';
import '../daten/transfer_support.dart';
import 'calendar_sheet.dart';
import 'transcription_section.dart';

/// Widget-Keys für Tests.
const Key reminderCalendarKey = Key('settings-reminder-calendar');
const Key storageTileKey = Key('settings-storage');
const Key backupCreateKey = Key('settings-backup-create');
const Key backupRestoreKey = Key('settings-backup-restore');
const Key deviceTransferKey = Key('settings-device-transfer');
const Key guidedReviewKey = Key('settings-guided-review');
const Key quotesEnabledKey = Key('settings-quotes-enabled');
const Key quotesManageKey = Key('settings-quotes-manage');

/// Speicherstatus der Plattform (Web: `navigator.storage`).
final storageStatusProvider = FutureProvider<StorageStatus?>(
  (ref) => ref.watch(platformFeaturesProvider).storageStatus(),
);

/// Einstellungen: Erinnerung, Transkription, Audio, Schutz, Daten,
/// Datenschutz. Alles Seltene an einem Ort (docs/03 Abschnitt 3). Auf dem Web
/// zusätzlich: Kalenderdatei statt Benachrichtigung, Speicherstatus, Hinweis
/// auf den Browser-Speicher und die CSP.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final features = ref.watch(platformFeaturesProvider);
    final alwaysUse24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
    final day = dayOf(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _SectionHeader(l10n.sectionReminder),
            SwitchListTile(
              title: Text(l10n.reminderEnabled),
              value: settings.reminderEnabled,
              onChanged: notifier.setReminderEnabled,
            ),
            ListTile(
              enabled: settings.reminderEnabled,
              leading: const Icon(Icons.schedule),
              title: Text(l10n.reminderTime),
              trailing: Text(
                materialL10n.formatTimeOfDay(
                  settings.reminderTime,
                  alwaysUse24HourFormat: alwaysUse24Hour,
                ),
                style: theme.textTheme.titleMedium,
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: settings.reminderTime,
                );
                if (picked != null) await notifier.setReminderTime(picked);
              },
            ),
            ListTile(
              enabled: settings.reminderEnabled && !settings.isSkippedOn(day),
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(l10n.reminderSkipToday),
              subtitle: Text(
                settings.isSkippedOn(day)
                    ? l10n.reminderSkippedToday
                    : l10n.reminderSkipTodaySubtitle,
              ),
              onTap: () => notifier.skipReminderOn(day),
            ),
            ListTile(
              enabled: settings.reminderEnabled,
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(l10n.reminderPause),
              subtitle: Text(
                settings.reminderPausedUntil == null
                    ? l10n.reminderPauseNone
                    : l10n.reminderPausedUntil(
                        materialL10n.formatMediumDate(
                          settings.reminderPausedUntil!,
                        ),
                      ),
              ),
              trailing: settings.reminderPausedUntil == null
                  ? null
                  : IconButton(
                      tooltip: l10n.reminderPauseClear,
                      icon: const Icon(Icons.close),
                      onPressed: () => notifier.pauseReminderUntil(null),
                    ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: settings.reminderPausedUntil ?? day,
                  firstDate: day,
                  lastDate: day.add(const Duration(days: 365)),
                );
                if (picked != null) await notifier.pauseReminderUntil(picked);
              },
            ),
            if (features.isWeb) ...[
              ListTile(
                key: reminderCalendarKey,
                leading: const Icon(Icons.event_available),
                title: Text(l10n.reminderCreateCalendar),
                subtitle: Text(l10n.reminderCreateCalendarSubtitle),
                onTap: () => showReminderCalendarSheet(
                  context,
                  features: features,
                  hour: settings.reminderTime.hour,
                  minute: settings.reminderTime.minute,
                ),
              ),
              _Note(l10n.reminderWebNote),
            ] else
              _Note(l10n.reminderPlaceholderNote),
            const Divider(),
            _SectionHeader(l10n.sectionTranscription),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l10n.transcriptionLanguage),
              subtitle: Text(_languageName(l10n, settings.language)),
              trailing: Text(settings.language.tag),
              onTap: () => _pickLanguage(context, ref, settings.language),
            ),
            _Note(l10n.languageHint),
            const Divider(),
            const TranscriptionEngineSection(),
            const Divider(),
            _SectionHeader(l10n.sectionReview),
            SwitchListTile(
              key: guidedReviewKey,
              title: Text(l10n.guidedReview),
              subtitle: Text(l10n.guidedReviewSubtitle),
              value: settings.guidedReview,
              onChanged: notifier.setGuidedReview,
            ),
            SwitchListTile(
              key: quotesEnabledKey,
              title: Text(l10n.quotesEnabled),
              subtitle: Text(l10n.quotesEnabledSubtitle),
              value: settings.quotesEnabled,
              onChanged: notifier.setQuotesEnabled,
            ),
            ListTile(
              key: quotesManageKey,
              leading: const Icon(Icons.format_quote_outlined),
              title: Text(l10n.quotesManage),
              subtitle: Text(l10n.quotesManageSubtitle),
              onTap: () => AppRoutes.openQuotes(context),
            ),
            const Divider(),
            _SectionHeader(l10n.sectionAudio),
            SwitchListTile(
              title: Text(l10n.keepAudio),
              subtitle: Text(l10n.keepAudioSubtitle),
              value: settings.keepAudio,
              onChanged: notifier.setKeepAudio,
            ),
            const Divider(),
            _SectionHeader(l10n.sectionProtection),
            SwitchListTile(
              title: Text(l10n.appLock),
              subtitle: Text(l10n.appLockSubtitle),
              value: settings.appLockEnabled,
              onChanged: notifier.setAppLockEnabled,
            ),
            const Divider(),
            _SectionHeader(l10n.sectionData),
            if (features.isWeb) ...[
              const _StorageTile(),
              _Note(l10n.webDataNote),
            ],
            const _BackupTile(),
            ListTile(
              key: backupRestoreKey,
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(l10n.backupRestore),
              subtitle: Text(l10n.backupRestoreSubtitle),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.restore),
            ),
            _Note(l10n.backupExplanation),
            ListTile(
              key: deviceTransferKey,
              leading: const Icon(Icons.qr_code_2),
              title: Text(l10n.deviceTransfer),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.transfer),
            ),
            _Note(l10n.deviceTransferExplanation),
            const Divider(),
            _SectionHeader(l10n.sectionPrivacy),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.privacyPromiseTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        features.isWeb
                            ? '${l10n.privacyPromiseBody} '
                                  '${l10n.privacyCspSentence}'
                            : l10n.privacyPromiseBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.showOnboardingAgain),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.onboarding),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    TranscriptionLanguage current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDialog<TranscriptionLanguage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.transcriptionLanguage),
        children: [
          RadioGroup<TranscriptionLanguage>(
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final language in TranscriptionLanguage.values)
                  RadioListTile<TranscriptionLanguage>(
                    value: language,
                    title: Text(_languageName(l10n, language)),
                    subtitle: Text(language.tag),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setLanguage(picked);
    }
  }

  static String _languageName(
    AppLocalizations l10n,
    TranscriptionLanguage language,
  ) {
    return switch (language) {
      TranscriptionLanguage.deDE => l10n.languageDeDE,
      TranscriptionLanguage.deAT => l10n.languageDeAT,
      TranscriptionLanguage.deCH => l10n.languageDeCH,
      TranscriptionLanguage.en => l10n.languageEn,
    };
  }
}

/// "Backup erstellen" mit Datum des letzten Backups.
class _BackupTile extends ConsumerWidget {
  const _BackupTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final last = ref.watch(lastBackupProvider).value;
    return ListTile(
      key: backupCreateKey,
      leading: const Icon(Icons.save_alt),
      title: Text(l10n.backupCreate),
      subtitle: Text(
        last == null
            ? l10n.backupNever
            : l10n.backupLast(materialL10n.formatMediumDate(last)),
      ),
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.backup),
    );
  }
}

/// Speicherstatus der PWA: zugesichert oder nicht, belegt und frei.
class _StorageTile extends ConsumerWidget {
  const _StorageTile();

  static String _megabytes(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(storageStatusProvider);
    final value = status.value;
    final String subtitle;
    if (status.isLoading) {
      subtitle = l10n.loadingLabel;
    } else if (value == null) {
      subtitle = l10n.storageUnknown;
    } else {
      subtitle =
          '${value.persisted ? l10n.storagePersisted : l10n.storageNotPersisted}\n'
          '${l10n.storageUsage(_megabytes(value.usageBytes), _megabytes(value.freeBytes))}';
    }
    return ListTile(
      key: storageTileKey,
      leading: Icon(
        value?.persisted ?? false ? Icons.verified_outlined : Icons.storage,
      ),
      title: Text(l10n.storageTitle),
      subtitle: Text(subtitle),
      isThreeLine: true,
      onTap: () => ref.invalidate(storageStatusProvider),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Erklärender Fließtext unter einem Listeneintrag.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}
