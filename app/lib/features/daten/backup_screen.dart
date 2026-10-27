import 'dart:async';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import 'transfer_support.dart';

/// Widget-Keys für Tests.
const Key backupPassphraseKey = Key('backup-passphrase');
const Key backupPassphraseRepeatKey = Key('backup-passphrase-repeat');
const Key backupStartKey = Key('backup-start');

/// "Backup erstellen" (docs/06 Abschnitt 6.1): Passphrase zweimal eingeben,
/// Datei erzeugen, herunterladen. Der Zeitpunkt des Backups landet im
/// `SettingsRepository` für die Erinnerung.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _passphrase = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;
  bool _touched = false;
  TransferProgress? _progress;
  String? _doneFileName;
  String? _error;

  @override
  void dispose() {
    _passphrase.dispose();
    _repeat.dispose();
    super.dispose();
  }

  String? _passphraseError(AppLocalizations l10n) {
    if (!_touched) return null;
    if (_passphrase.text.length < TransferUseCase.minPassphraseLength) {
      return l10n.passphraseTooShort(TransferUseCase.minPassphraseLength);
    }
    return null;
  }

  String? _repeatError(AppLocalizations l10n) {
    if (!_touched) return null;
    if (_repeat.text != _passphrase.text) return l10n.passphraseMismatch;
    return null;
  }

  bool get _valid =>
      _passphrase.text.length >= TransferUseCase.minPassphraseLength &&
      _repeat.text == _passphrase.text;

  Future<void> _start() async {
    setState(() => _touched = true);
    if (!_valid) return;
    setState(() {
      _error = null;
      _doneFileName = null;
      _progress = const TransferProgress(TransferPhase.collecting);
    });
    // Ein Frame, damit die Fortschrittsanzeige steht, bevor Argon2id den
    // Thread belegt (im Browser gibt es keine Isolates).
    await Future<void>.delayed(const Duration(milliseconds: 30));
    try {
      final services = await ref.read(appServicesProvider.future);
      final useCase = services.transfer();
      final bytes = await useCase.exportWithPassphrase(
        _passphrase.text,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      final fileName = TransferUseCase.backupFileName(
        LocalDay.forMoment(services.clock.now()),
      );
      await services.features.saveContainerFile(fileName, bytes);
      await ref.read(backupBookkeepingProvider).markBackupDone();
      if (!mounted) return;
      setState(() {
        _progress = null;
        _doneFileName = fileName;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _error = describeTransferError(
          AppLocalizations.of(context),
          e,
          passphrase: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = _progress != null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ExplainerText(l10n.backupIntro),
            const SizedBox(height: 20),
            PassphraseField(
              fieldKey: backupPassphraseKey,
              controller: _passphrase,
              label: l10n.passphraseLabel,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              errorText: _passphraseError(l10n),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            PassphraseField(
              fieldKey: backupPassphraseRepeatKey,
              controller: _repeat,
              label: l10n.passphraseRepeatLabel,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              errorText: _repeatError(l10n),
              onSubmitted: (_) => busy ? null : _start(),
            ),
            const SizedBox(height: 8),
            ExplainerText(l10n.passphraseHint),
            const SizedBox(height: 8),
            ExplainerText(l10n.argon2Hint),
            const SizedBox(height: 20),
            if (busy)
              TransferProgressView(_progress!)
            else
              FilledButton.icon(
                key: backupStartKey,
                onPressed: _start,
                icon: const Icon(Icons.lock_outline),
                label: Text(l10n.backupStart),
              ),
            if (_doneFileName != null) ...[
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.backupDone(_doneFileName!)),
                  subtitle: Text(l10n.backupDoneHint),
                  isThreeLine: true,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
