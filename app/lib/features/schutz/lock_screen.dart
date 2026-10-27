import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_lock.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/surface_card.dart';
import 'pin_pad.dart';

/// Widget-Keys für Tests.
const Key lockScreenKey = Key('lock-screen');
const Key lockForgotKey = Key('lock-forgot');
const Key lockResetFieldKey = Key('lock-reset-field');
const Key lockResetButtonKey = Key('lock-reset-button');
const Key lockResetBackKey = Key('lock-reset-back');

/// Sperrbildschirm der App-Sperre (D23): nur App-Name, Schloss, Ziffernfeld;
/// keine Inhalte. Zu viele Fehlversuche sperren das Feld für die Wartezeit
/// aus dem Zustand. "PIN vergessen?" öffnet die Erklärung mit "App
/// zurücksetzen" (Wort tippen), ohne Dialog, weil der Bildschirm außerhalb
/// des Navigators über allen Routen liegt.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _forgot = false;
  bool _lastWrong = false;
  bool _resetting = false;
  int _resetToken = 0;
  Timer? _waitTimer;
  final TextEditingController _confirm = TextEditingController();

  @override
  void dispose() {
    _waitTimer?.cancel();
    _confirm.dispose();
    super.dispose();
  }

  /// Nach Ablauf der Wartezeit einmal neu bauen, damit das Feld wieder
  /// bedienbar wird (kein periodischer Timer: nichts tickt, nichts blinkt).
  void _armWaitTimer(Duration remaining) {
    if (remaining <= Duration.zero) return;
    if (_waitTimer != null) return;
    _waitTimer = Timer(remaining, () {
      _waitTimer = null;
      if (mounted) setState(() {});
    });
  }

  Future<void> _submit(String pin) async {
    final result = await ref.read(appLockProvider.notifier).verify(pin);
    if (!mounted) return;
    setState(() {
      _lastWrong = result != PinResult.ok;
      _resetToken++;
    });
  }

  Future<void> _reset() async {
    setState(() => _resetting = true);
    await ref.read(appLockProvider.notifier).resetApp();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lock = ref.watch(appLockProvider).value;
    final clock = ref.watch(appServicesProvider).value?.clock;
    final now = clock?.now() ?? DateTime.now();
    final remaining = lock?.remainingWait(now) ?? Duration.zero;
    final waiting = remaining > Duration.zero;
    if (waiting) {
      _armWaitTimer(remaining);
    }
    final failures = lock?.failedAttempts ?? 0;

    String? message;
    if (waiting) {
      // Aufrunden, damit nie "0 Sekunden" steht, solange gewartet wird.
      final seconds = (remaining.inMilliseconds + 999) ~/ 1000;
      message = l10n.pinWait(seconds);
    } else if (_lastWrong && failures > 0) {
      message = '${l10n.pinWrong} ${l10n.pinAttempts(failures)}';
    }

    return Scaffold(
      key: lockScreenKey,
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Semantics(
          label: l10n.lockScreenSemantics,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 36, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (_forgot)
                    _ForgotPanel(
                      controller: _confirm,
                      resetting: _resetting,
                      onBack: () => setState(() => _forgot = false),
                      onReset: _reset,
                    )
                  else ...[
                    PinEntryPanel(
                      hint: l10n.pinEnterHint,
                      message: message,
                      messageIsError: !waiting && _lastWrong,
                      busy: lock?.busy ?? false,
                      busyLabel: l10n.pinChecking,
                      enabled: !waiting && lock != null,
                      resetToken: _resetToken,
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      key: lockForgotKey,
                      onPressed: () => setState(() => _forgot = true),
                      child: Text(l10n.pinForgot),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "PIN vergessen": Erklärung ohne Hintertür und "App zurücksetzen" nach dem
/// Tippen des Wortes.
class _ForgotPanel extends StatelessWidget {
  const _ForgotPanel({
    required this.controller,
    required this.resetting,
    required this.onBack,
    required this.onReset,
  });

  final TextEditingController controller;
  final bool resetting;
  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final word = l10n.pinResetWord;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.pinForgotTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pinForgotBody,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final ready = value.text.trim() == word;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: lockResetFieldKey,
                      controller: controller,
                      enabled: !resetting,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.pinResetFieldLabel(word),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      key: lockResetButtonKey,
                      onPressed: ready && !resetting ? onReset : null,
                      icon: resetting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever_outlined),
                      label: Text(l10n.pinResetButton),
                      style: FilledButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            TextButton(
              key: lockResetBackKey,
              onPressed: resetting ? null : onBack,
              child: Text(l10n.pinResetBack),
            ),
          ],
        ),
      ),
    );
  }
}
