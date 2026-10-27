import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_lock.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import 'pin_pad.dart';

/// Welche Abfolge das Blatt führt (D23 Punkt 7).
enum PinFlowKind {
  /// Einschalten: neuen PIN wählen, wiederholen.
  setup,

  /// Ändern: aktuellen PIN, neuen wählen, wiederholen.
  change,

  /// Ausschalten: aktuellen PIN.
  disable,
}

enum _Step { current, chooseNew, repeatNew }

/// Blatt für PIN-Vergabe, -Änderung und Ausschalten aus den Einstellungen.
/// Liefert `true`, wenn der Ablauf abgeschlossen wurde, sonst `null`.
class PinFlowScreen extends ConsumerStatefulWidget {
  const PinFlowScreen({super.key, required this.kind});

  final PinFlowKind kind;

  @override
  ConsumerState<PinFlowScreen> createState() => _PinFlowScreenState();
}

class _PinFlowScreenState extends ConsumerState<PinFlowScreen> {
  late _Step _step = widget.kind == PinFlowKind.setup
      ? _Step.chooseNew
      : _Step.current;
  String? _firstPin;
  String? _message;
  bool _error = false;
  bool _saving = false;
  int _resetToken = 0;

  void _go(_Step step, {String? message, bool error = false}) {
    setState(() {
      _step = step;
      _message = message;
      _error = error;
      _resetToken++;
    });
  }

  Future<void> _submit(String pin) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(appLockProvider.notifier);
    switch (_step) {
      case _Step.current:
        final result = await notifier.verify(pin, unlock: false);
        if (!mounted) return;
        switch (result) {
          case PinResult.ok:
            if (widget.kind == PinFlowKind.disable) {
              setState(() => _saving = true);
              await notifier.disable();
              if (mounted) Navigator.of(context).pop(true);
            } else {
              _go(_Step.chooseNew);
            }
          case PinResult.wrong:
            final failures = ref.read(appLockProvider).value?.failedAttempts;
            _go(
              _Step.current,
              message: failures == null
                  ? l10n.pinWrong
                  : '${l10n.pinWrong} ${l10n.pinAttempts(failures)}',
              error: true,
            );
          case PinResult.waiting:
            _go(_Step.current, message: _waitMessage(l10n));
        }
      case _Step.chooseNew:
        _firstPin = pin;
        _go(_Step.repeatNew);
      case _Step.repeatNew:
        if (pin != _firstPin) {
          _firstPin = null;
          _go(_Step.chooseNew, message: l10n.pinMismatch, error: true);
          return;
        }
        setState(() => _saving = true);
        if (widget.kind == PinFlowKind.setup) {
          await notifier.enable(pin);
        } else {
          await notifier.setPin(pin);
        }
        _firstPin = null;
        if (mounted) Navigator.of(context).pop(true);
    }
  }

  String? _waitMessage(AppLocalizations l10n) {
    final lock = ref.read(appLockProvider).value;
    final clock = ref.read(appServicesProvider).value?.clock;
    if (lock == null || clock == null) return null;
    final remaining = lock.remainingWait(clock.now());
    if (remaining <= Duration.zero) return null;
    return l10n.pinWait((remaining.inMilliseconds + 999) ~/ 1000);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lock = ref.watch(appLockProvider).value;
    final clock = ref.watch(appServicesProvider).value?.clock;
    final waiting =
        lock != null &&
        clock != null &&
        lock.remainingWait(clock.now()) > Duration.zero;
    final title = switch (widget.kind) {
      PinFlowKind.setup => l10n.pinSetupTitle,
      PinFlowKind.change => l10n.pinChangeTitle,
      PinFlowKind.disable => l10n.pinDisableTitle,
    };
    final hint = switch (_step) {
      _Step.current =>
        widget.kind == PinFlowKind.disable
            ? l10n.pinDisableHint
            : l10n.pinEnterCurrent,
      _Step.chooseNew => l10n.pinChooseNew,
      _Step.repeatNew => l10n.pinRepeatNew,
    };
    final message = waiting && _step == _Step.current
        ? _waitMessage(l10n)
        : _message;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: PinEntryPanel(
              hint: hint,
              message: message,
              messageIsError: _error && !waiting,
              busy: _saving || (lock?.busy ?? false),
              busyLabel: _saving ? l10n.pinSaving : l10n.pinChecking,
              enabled: !waiting || _step != _Step.current,
              resetToken: _resetToken,
              onSubmit: _submit,
            ),
          ),
        ),
      ),
    );
  }
}
