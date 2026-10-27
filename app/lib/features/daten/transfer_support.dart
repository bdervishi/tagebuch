import 'dart:convert';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_view.dart';
import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';

/// Backup und Gerätewechsel mit den Ports der App.
final transferUseCaseProvider = FutureProvider<TransferUseCase>(
  (ref) async => (await ref.watch(appServicesProvider.future)).transfer(),
);

/// Zeitpunkt des letzten Backups oder `null`.
final lastBackupProvider = FutureProvider<DateTime?>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final raw = await s.settings.get(AppSettings.keyLastBackupAt);
  return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
});

/// Ob die Karte "Zeit für ein Backup" auf "Mehr" erscheint (D16 Punkt 3):
/// ab dem dritten Eintrag, wenn das letzte Backup fehlt oder älter als
/// sieben Tage ist und die Erinnerung nicht zurückgestellt wurde.
final backupReminderProvider = FutureProvider<BackupReminder?>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final count = (await s.entries.listAll(s.journalId)).length;
  if (count < BackupReminder.minEntries) return null;
  final now = s.clock.now();
  final remindAfter = await s.settings.get(AppSettings.keyBackupRemindAfter);
  if (remindAfter != null) {
    final until = DateTime.tryParse(remindAfter)?.toLocal();
    if (until != null && now.isBefore(until)) return null;
  }
  final last = await ref.watch(lastBackupProvider.future);
  if (last != null && now.difference(last) < BackupReminder.maxAge) {
    return null;
  }
  return BackupReminder(entryCount: count, hadBackup: last != null);
});

class BackupReminder {
  const BackupReminder({required this.entryCount, required this.hadBackup});

  static const int minEntries = 3;
  static const Duration maxAge = Duration(days: 7);

  final int entryCount;

  /// Wahr, wenn es schon einmal ein Backup gab (dann "älter als eine Woche").
  final bool hadBackup;
}

/// Merkt sich das Backup bzw. das Zurückstellen und lädt die Provider neu.
class BackupBookkeeping {
  const BackupBookkeeping(this.ref);
  final Ref ref;

  Future<void> markBackupDone() async {
    final s = await ref.read(appServicesProvider.future);
    await s.settings.set(
      AppSettings.keyLastBackupAt,
      s.clock.now().toUtc().toIso8601String(),
    );
    ref.read(dataVersionProvider.notifier).bump();
  }

  Future<void> snooze() async {
    final s = await ref.read(appServicesProvider.future);
    await s.settings.set(
      AppSettings.keyBackupRemindAfter,
      s.clock.now().add(BackupReminder.maxAge).toUtc().toIso8601String(),
    );
    ref.read(dataVersionProvider.notifier).bump();
  }

  /// Gespeicherte Empfangssitzung des Gerätewechsels oder `null`.
  Future<ReceiveSession?> loadReceiveSession() async {
    final s = await ref.read(appServicesProvider.future);
    final raw = await s.settings.get(AppSettings.keyTransferSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ReceiveSession.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      return null;
    }
  }

  Future<void> saveReceiveSession(ReceiveSession? session) async {
    final s = await ref.read(appServicesProvider.future);
    await s.settings.set(
      AppSettings.keyTransferSession,
      session == null ? '' : jsonEncode(session.toJson()),
    );
  }
}

final backupBookkeepingProvider = Provider<BackupBookkeeping>(
  BackupBookkeeping.new,
);

/// Lesbare Meldung zu einem Fehler beim Öffnen oder Importieren.
String describeTransferError(
  AppLocalizations l10n,
  Object error, {
  bool passphrase = false,
}) {
  if (error is ContainerException) {
    return switch (error.error) {
      ContainerError.notContainer => l10n.errorNotContainer,
      ContainerError.unsupported => l10n.errorUnsupported,
      ContainerError.truncated => l10n.errorTruncated,
      ContainerError.tampered => l10n.errorTampered,
      ContainerError.wrongKey =>
        passphrase ? l10n.errorWrongPassphrase : l10n.errorWrongKey,
      ContainerError.wrongSession => l10n.errorWrongSession,
      ContainerError.manifestMismatch => l10n.errorManifestMismatch,
    };
  }
  return l10n.transferFailed(error.toString());
}

/// Text zur Fortschrittsphase.
String describeProgress(AppLocalizations l10n, TransferPhase phase) =>
    switch (phase) {
      TransferPhase.collecting => l10n.progressCollecting,
      TransferPhase.derivingKey => l10n.progressDerivingKey,
      TransferPhase.encrypting => l10n.progressEncrypting,
      TransferPhase.decrypting => l10n.progressDecrypting,
      TransferPhase.importing => l10n.progressImporting,
    };

/// Fortschrittsanzeige mit Phasentext.
class TransferProgressView extends StatelessWidget {
  const TransferProgressView(this.progress, {super.key});

  final TransferProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: progress.fraction),
        const SizedBox(height: 8),
        Text(describeProgress(l10n, progress.phase)),
      ],
    );
  }
}

/// Zusammenfassung aus dem Manifest vor dem Import (docs/06 5.6 Schritt 4).
class ManifestSummary extends StatelessWidget {
  const ManifestSummary(this.manifest, {super.key});

  final ContainerManifest manifest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    String day(String iso) =>
        materialL10n.formatMediumDate(LocalDay.parse(iso).startOfDay);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.summaryTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${l10n.summaryEntries(manifest.entryCount)}, '
              '${l10n.summaryRecordings(manifest.recordingCount)}',
              style: theme.textTheme.bodyLarge,
            ),
            if (manifest.firstDay != null && manifest.lastDay != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.summaryPeriod(
                  day(manifest.firstDay!),
                  day(manifest.lastDay!),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              l10n.summaryCreatedAt(
                materialL10n.formatMediumDate(manifest.createdAt.toLocal()),
                manifest.appVersion,
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget-Keys der Zeilen in [ImportSummary] (für Tests): `import-line-<kind>`.
Key importLineKey(String kind) => Key('import-line-$kind');

/// Zusammenfassung nach dem Einspielen (Backup wiederherstellen und
/// Gerätewechsel): je Art eine Zeile mit der übernommenen Zahl, dahinter die
/// übersprungene, wenn es welche gab. Arten ohne beides entfallen; war
/// nichts zu übernehmen, steht das in einem Satz.
class ImportSummary extends StatelessWidget {
  const ImportSummary(this.result, {super.key});

  final ImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String withSkipped(String imported, int skipped) => skipped == 0
        ? imported
        : '$imported, ${l10n.importLineSkipped(skipped)}';
    final lines = <(String, String)>[
      if (result.entriesCreated > 0 || result.entriesMerged > 0)
        (
          'entries',
          result.entriesMerged == 0
              ? l10n.importLineEntries(result.entriesCreated)
              : result.entriesCreated == 0
              ? l10n.importLineEntriesMerged(result.entriesMerged)
              : '${l10n.importLineEntries(result.entriesCreated)}, '
                    '${l10n.importLineEntriesMerged(result.entriesMerged)}',
        ),
      if (result.recordingsImported > 0 || result.recordingsSkipped > 0)
        (
          'recordings',
          withSkipped(
            l10n.importLineRecordings(result.recordingsImported),
            result.recordingsSkipped,
          ),
        ),
      if (result.transcriptsImported > 0 || result.transcriptsSkipped > 0)
        (
          'transcripts',
          withSkipped(
            l10n.importLineTranscripts(result.transcriptsImported),
            result.transcriptsSkipped,
          ),
        ),
      if (result.notesImported > 0 || result.notesSkipped > 0)
        (
          'notes',
          withSkipped(
            l10n.importLineNotes(result.notesImported),
            result.notesSkipped,
          ),
        ),
      if (result.goalsImported > 0 || result.goalsSkipped > 0)
        (
          'goals',
          withSkipped(
            l10n.importLineGoals(result.goalsImported),
            result.goalsSkipped,
          ),
        ),
      if (result.milestonesImported > 0 || result.milestonesSkipped > 0)
        (
          'milestones',
          withSkipped(
            l10n.importLineMilestones(result.milestonesImported),
            result.milestonesSkipped,
          ),
        ),
      if (result.booksImported > 0 || result.booksSkipped > 0)
        (
          'books',
          withSkipped(
            l10n.importLineBooks(result.booksImported),
            result.booksSkipped,
          ),
        ),
      if (result.passagesImported > 0 || result.passagesSkipped > 0)
        (
          'passages',
          withSkipped(
            l10n.importLinePassages(result.passagesImported),
            result.passagesSkipped,
          ),
        ),
      if (result.settingsImported > 0 || result.settingsSkipped > 0)
        (
          'settings',
          withSkipped(
            l10n.importLineSettings(result.settingsImported),
            result.settingsSkipped,
          ),
        ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: scheme.primary),
                const SizedBox(width: 12),
                Text(l10n.importDoneTitle, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            if (lines.isEmpty)
              Text(l10n.importNothing, style: theme.textTheme.bodyMedium)
            else
              for (final (kind, text) in lines)
                Padding(
                  key: importLineKey(kind),
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(text, style: theme.textTheme.bodyMedium),
                ),
          ],
        ),
      ),
    );
  }
}

/// Passphrase-Feld mit Anzeigen/Verbergen.
class PassphraseField extends StatelessWidget {
  const PassphraseField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
    this.errorText,
    this.fieldKey,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? errorText;
  final Key? fieldKey;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      key: fieldKey,
      controller: controller,
      obscureText: obscure,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: obscure ? l10n.passphraseShow : l10n.passphraseHide,
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}

/// Erklärender Fließtext.
class ExplainerText extends StatelessWidget {
  const ExplainerText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }
}
