import 'dart:async';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_view.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import 'transfer_support.dart';

/// Widget-Keys für Tests.
const Key restoreChooseFileKey = Key('restore-choose-file');
const Key restorePassphraseKey = Key('restore-passphrase');
const Key restoreOpenKey = Key('restore-open');
const Key restoreConfirmKey = Key('restore-confirm');

/// "Backup wiederherstellen" (docs/06 6.2): Datei wählen, Passphrase, dann
/// Zusammenfassung aus dem Manifest, erst nach Bestätigung der Import.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _passphrase = TextEditingController();
  bool _obscure = true;
  Uint8List? _file;
  OpenedContainer? _opened;
  ImportResult? _result;
  TransferProgress? _progress;
  String? _error;

  @override
  void dispose() {
    _passphrase.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    final services = await ref.read(appServicesProvider.future);
    final bytes = await services.features.pickContainerFile();
    if (!mounted || bytes == null) return;
    setState(() {
      _file = bytes;
      _opened = null;
      _result = null;
      _error = null;
    });
  }

  Future<void> _open() async {
    final file = _file;
    if (file == null || _passphrase.text.isEmpty) return;
    setState(() {
      _error = null;
      _opened = null;
      _progress = const TransferProgress(TransferPhase.derivingKey);
    });
    await Future<void>.delayed(const Duration(milliseconds: 30));
    try {
      final useCase = await ref.read(transferUseCaseProvider.future);
      final opened = await useCase.openWithPassphrase(
        file,
        _passphrase.text,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _progress = null;
        _opened = opened;
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

  Future<void> _import() async {
    final opened = _opened;
    if (opened == null) return;
    setState(() {
      _error = null;
      _progress = const TransferProgress(TransferPhase.importing);
    });
    try {
      final useCase = await ref.read(transferUseCaseProvider.future);
      final result = await useCase.import(
        opened,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      ref.read(dataVersionProvider.notifier).bump();
      if (!mounted) return;
      setState(() {
        _progress = null;
        _opened = null;
        _file = null;
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _error = describeTransferError(AppLocalizations.of(context), e);
      });
    }
  }

  static String _megabytes(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = _progress != null;
    final file = _file;
    final opened = _opened;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.restoreTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ExplainerText(l10n.restoreIntro),
            const SizedBox(height: 20),
            if (result == null) ...[
              OutlinedButton.icon(
                key: restoreChooseFileKey,
                onPressed: busy ? null : _chooseFile,
                icon: const Icon(Icons.folder_open),
                label: Text(l10n.chooseFile),
              ),
              const SizedBox(height: 8),
              Text(
                file == null
                    ? l10n.noFileChosen
                    : l10n.fileChosen(_megabytes(file.length)),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              PassphraseField(
                fieldKey: restorePassphraseKey,
                controller: _passphrase,
                label: l10n.passphraseLabel,
                obscure: _obscure,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onSubmitted: (_) => busy ? null : _open(),
              ),
              const SizedBox(height: 20),
              if (busy)
                TransferProgressView(_progress!)
              else if (opened == null)
                FilledButton.icon(
                  key: restoreOpenKey,
                  onPressed: file == null ? null : _open,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: Text(l10n.restoreOpen),
                ),
            ],
            if (opened != null && !busy) ...[
              ManifestSummary(opened.manifest),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: restoreConfirmKey,
                onPressed: _import,
                icon: const Icon(Icons.download_done),
                label: Text(l10n.importConfirm),
              ),
            ],
            if (result != null) ...[
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.importDoneTitle),
                  subtitle: Text(
                    l10n.importDone(
                      result.entriesCreated,
                      result.entriesMerged,
                      result.recordingsImported,
                      result.recordingsSkipped,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.backToSettings),
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
