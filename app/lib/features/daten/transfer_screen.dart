import 'dart:async';

import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_view.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../services/platform_features.dart';
import 'qr_code_view.dart';
import 'transfer_support.dart';

/// Widget-Keys für Tests.
const Key transferRoleNewKey = Key('transfer-role-new');
const Key transferRoleOldKey = Key('transfer-role-old');
const Key transferTextCodeKey = Key('transfer-text-code');
const Key transferCodeFieldKey = Key('transfer-code-field');
const Key transferCreateFileKey = Key('transfer-create-file');
const Key transferReceiveFileKey = Key('transfer-receive-file');
const Key transferConfirmKey = Key('transfer-confirm');
const Key transferNewSessionKey = Key('transfer-new-session');

enum _Role { newDevice, oldDevice }

/// "Auf neues Gerät übertragen" (docs/06 Abschnitt 4 und 5): Rolle wählen,
/// dann entweder Code zeigen und Datei empfangen (neues Gerät) oder Code
/// lesen und Datei erzeugen (altes Gerät). Beide Seiten zeigen den
/// sechsstelligen Prüfcode.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  _Role? _role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferTitle)),
      body: SafeArea(
        child: switch (_role) {
          null => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ExplainerText(l10n.transferIntro),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  key: transferRoleNewKey,
                  leading: const Icon(Icons.phone_iphone),
                  title: Text(l10n.transferRoleNew),
                  subtitle: Text(l10n.transferRoleNewSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _role = _Role.newDevice),
                ),
              ),
              Card(
                child: ListTile(
                  key: transferRoleOldKey,
                  leading: const Icon(Icons.qr_code_scanner),
                  title: Text(l10n.transferRoleOld),
                  subtitle: Text(l10n.transferRoleOldSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _role = _Role.oldDevice),
                ),
              ),
            ],
          ),
          _Role.newDevice => const _ReceivePanel(),
          _Role.oldDevice => const _SendPanel(),
        },
      ),
    );
  }
}

/// Neues Gerät: QR-Code anzeigen, Datei entgegennehmen und importieren.
class _ReceivePanel extends ConsumerStatefulWidget {
  const _ReceivePanel();

  @override
  ConsumerState<_ReceivePanel> createState() => _ReceivePanelState();
}

class _ReceivePanelState extends ConsumerState<_ReceivePanel> {
  ReceiveSession? _session;
  OpenedContainer? _opened;
  ImportResult? _result;
  TransferProgress? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSession());
  }

  Future<void> _loadSession({bool fresh = false}) async {
    final bookkeeping = ref.read(backupBookkeepingProvider);
    var session = fresh ? null : await bookkeeping.loadReceiveSession();
    if (session == null) {
      final useCase = await ref.read(transferUseCaseProvider.future);
      final features = ref.read(platformFeaturesProvider);
      session = await useCase.createReceiveSession(
        platform: features.isWeb ? 0 : (features.isIos ? 1 : 2),
      );
      await bookkeeping.saveReceiveSession(session);
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _opened = null;
      _error = null;
    });
  }

  Future<void> _receiveFile() async {
    final session = _session;
    if (session == null) return;
    final services = await ref.read(appServicesProvider.future);
    final Uint8List? bytes = await services.features.pickContainerFile();
    if (!mounted || bytes == null) return;
    setState(() {
      _error = null;
      _progress = const TransferProgress(TransferPhase.derivingKey);
    });
    try {
      final opened = await services.transfer().openAsRecipient(
        bytes,
        session,
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
        _error = describeTransferError(AppLocalizations.of(context), e);
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
      // Sitzung ist verbraucht: privaten Schlüssel vernichten.
      _session?.keyPair.dispose();
      await ref.read(backupBookkeepingProvider).saveReceiveSession(null);
      ref.read(dataVersionProvider.notifier).bump();
      if (!mounted) return;
      setState(() {
        _progress = null;
        _opened = null;
        _session = null;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final session = _session;
    final opened = _opened;
    final result = _result;
    final busy = _progress != null;
    if (result != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ImportSummary(result),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.backToSettings),
          ),
        ],
      );
    }
    if (session == null) {
      return Center(
        child: Semantics(
          label: l10n.loadingLabel,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    final code = session.qrPayload.encode();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (opened == null) ...[
          ExplainerText(l10n.transferShowCode),
          const SizedBox(height: 16),
          Center(
            child: QrCodeView(
              data: code,
              semanticsLabel: l10n.transferShowCode,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.verificationCode(session.verificationCode),
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 4),
          Center(child: ExplainerText(l10n.verificationHint)),
          const SizedBox(height: 16),
          ExplainerText(l10n.transferTextCode),
          const SizedBox(height: 8),
          SelectableText(
            code,
            key: transferTextCodeKey,
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.transferCodeCopied)));
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.transferCopyCode),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.transferSessionAge(
              materialL10n.formatMediumDate(session.createdAt),
            ),
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 32),
          if (busy)
            TransferProgressView(_progress!)
          else ...[
            FilledButton.icon(
              key: transferReceiveFileKey,
              onPressed: _receiveFile,
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.transferReceiveFile),
            ),
            TextButton(
              key: transferNewSessionKey,
              onPressed: () => _loadSession(fresh: true),
              child: Text(l10n.transferNewSession),
            ),
          ],
        ] else ...[
          Center(
            child: Text(
              l10n.verificationCode(session.verificationCode),
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 4),
          Center(child: ExplainerText(l10n.verificationHint)),
          const SizedBox(height: 16),
          ManifestSummary(opened.manifest),
          const SizedBox(height: 12),
          if (busy)
            TransferProgressView(_progress!)
          else
            FilledButton.icon(
              key: transferConfirmKey,
              onPressed: _import,
              icon: const Icon(Icons.download_done),
              label: Text(l10n.importConfirm),
            ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 20),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}

/// Altes Gerät: Code lesen oder eintippen, Prüfcode zeigen, Datei erzeugen.
class _SendPanel extends ConsumerStatefulWidget {
  const _SendPanel();

  @override
  ConsumerState<_SendPanel> createState() => _SendPanelState();
}

class _SendPanelState extends ConsumerState<_SendPanel> {
  final _codeField = TextEditingController();
  QrPayload? _recipient;
  QrScanner? _scanner;
  StreamSubscription<String>? _codes;
  bool _scannerStarting = false;
  TransferProgress? _progress;
  String? _doneFileName;
  String? _codeError;
  String? _error;

  @override
  void dispose() {
    _codeField.dispose();
    unawaited(_stopScanner());
    super.dispose();
  }

  void _applyCode(String text) {
    final l10n = AppLocalizations.of(context);
    try {
      final payload = QrPayload.decode(text.trim());
      setState(() {
        _recipient = payload;
        _codeError = null;
        _codeField.text = text.trim();
      });
      unawaited(_stopScanner());
    } on FormatException {
      setState(() {
        _recipient = null;
        _codeError = l10n.transferCodeInvalid;
      });
    }
  }

  Future<void> _startScanner() async {
    final features = ref.read(platformFeaturesProvider);
    final scanner = features.createQrScanner();
    if (scanner == null) return;
    setState(() {
      _scannerStarting = true;
      _error = null;
    });
    try {
      await scanner.start();
      _codes = scanner.codes.listen((text) {
        if (text.startsWith(QrPayload.prefix) && mounted) _applyCode(text);
      });
      if (!mounted) return;
      setState(() {
        _scanner = scanner;
        _scannerStarting = false;
      });
    } catch (_) {
      await scanner.stop();
      if (!mounted) return;
      setState(() {
        _scannerStarting = false;
        _error = AppLocalizations.of(context).transferCameraError;
      });
    }
  }

  Future<void> _stopScanner() async {
    await _codes?.cancel();
    _codes = null;
    final scanner = _scanner;
    _scanner = null;
    await scanner?.stop();
    if (mounted) setState(() {});
  }

  Future<void> _createFile() async {
    final recipient = _recipient;
    if (recipient == null) return;
    setState(() {
      _error = null;
      _doneFileName = null;
      _progress = const TransferProgress(TransferPhase.collecting);
    });
    await Future<void>.delayed(const Duration(milliseconds: 30));
    try {
      final services = await ref.read(appServicesProvider.future);
      final export = await services.transfer().exportForRecipient(
        recipient,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      final fileName = TransferUseCase.transferFileName(
        LocalDay.forMoment(services.clock.now()),
      );
      await services.features.saveContainerFile(fileName, export.bytes);
      if (!mounted) return;
      setState(() {
        _progress = null;
        _doneFileName = fileName;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _error = describeTransferError(AppLocalizations.of(context), e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final features = ref.watch(platformFeaturesProvider);
    final recipient = _recipient;
    final busy = _progress != null;
    final scanner = _scanner;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (scanner != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 280,
              child: HtmlElementView(viewType: scanner.viewType),
            ),
          ),
          TextButton.icon(
            onPressed: _stopScanner,
            icon: const Icon(Icons.close),
            label: Text(l10n.transferScanStop),
          ),
        ] else if (features.canScanQr && recipient == null)
          OutlinedButton.icon(
            onPressed: _scannerStarting ? null : _startScanner,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.transferScan),
          )
        else if (recipient == null)
          ExplainerText(l10n.transferScanUnavailable),
        const SizedBox(height: 16),
        TextField(
          key: transferCodeFieldKey,
          controller: _codeField,
          enabled: !busy,
          autocorrect: false,
          enableSuggestions: false,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            labelText: l10n.transferEnterCode,
            hintText: '${QrPayload.prefix}…',
            errorText: _codeError,
            border: const OutlineInputBorder(),
          ),
          onChanged: (text) {
            if (text.trim().length > QrPayload.prefix.length) {
              _applyCode(text);
            } else if (_recipient != null || _codeError != null) {
              setState(() {
                _recipient = null;
                _codeError = null;
              });
            }
          },
        ),
        if (recipient != null) ...[
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
            ),
            title: Text(l10n.transferCodeRead),
            subtitle: Text(
              l10n.verificationCode(recipient.verificationCode()),
              style: theme.textTheme.headlineSmall,
            ),
          ),
          ExplainerText(l10n.verificationHint),
          const SizedBox(height: 16),
          if (busy)
            TransferProgressView(_progress!)
          else
            FilledButton.icon(
              key: transferCreateFileKey,
              onPressed: _createFile,
              icon: const Icon(Icons.lock_outline),
              label: Text(l10n.transferCreateFile),
            ),
        ],
        if (_doneFileName != null) ...[
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(l10n.transferFileReady(_doneFileName!)),
              subtitle: Text(l10n.transferFileReadyHint),
              isThreeLine: true,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 20),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }
}
