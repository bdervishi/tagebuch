import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_lock.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/reveal.dart';
import 'lock_screen.dart';

/// Widget-Keys für Tests.
const Key privacyVeilKey = Key('privacy-veil');

/// Legt Sichtschutz und Sperrbildschirm über den Navigator der App (D23).
/// Sitzt in `MaterialApp.builder`, damit alle Routen darunter liegen, nicht
/// nur die Start-Route.
///
/// * Hintergrund (`inactive`, `hidden`, `paused`): sofort ein neutraler
///   Schleier mit dem App-Namen, damit der App-Switcher nichts zeigt. Die
///   Hintergrundzeit der Sperre läuft nur bei `hidden`/`paused`, nicht bei
///   bloßem Fokusverlust (ein Berechtigungsdialog soll nicht sperren).
/// * Gesperrt: Die App bleibt aufgebaut, aber [Offstage] (kein Layout, keine
///   Berührung, keine Semantik); darüber der [LockScreen]. Beim Entsperren
///   wird nichts neu geladen.
/// * Zustand noch unbekannt (Dienste laden): Schleier statt Inhalt, damit
///   vor der Entscheidung kein Eintrag aufblitzt.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _veiled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(appLockProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        notifier.foregrounded();
        if (_veiled) setState(() => _veiled = false);
      case AppLifecycleState.inactive:
        if (!_veiled) setState(() => _veiled = true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (!_veiled) setState(() => _veiled = true);
        notifier.backgrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    final state = lock.value;
    final unknown = state == null && lock.isLoading;
    final enabled = state?.enabled ?? false;
    final locked = enabled && state!.locked;
    final veil = unknown || (enabled && _veiled && !locked);
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: locked || unknown, child: widget.child),
        if (veil) const _PrivacyVeil(),
        if (locked) ...[
          // Feste Fläche hinter dem einblendenden Sperrbildschirm, damit
          // währenddessen nichts durchscheint.
          ColoredBox(color: scheme.surface),
          // Eigenes Overlay: Der Sperrbildschirm liegt außerhalb des
          // App-Navigators, sein Textfeld ("LÖSCHEN" tippen) braucht aber
          // eines. `Overlay.wrap` verwaltet den Eintrag über Neuaufbauten.
          Reveal(child: Overlay.wrap(child: const LockScreen())),
        ],
      ],
    );
  }
}

/// Neutraler Schleier: Fläche in `surface`, nur der App-Name.
class _PrivacyVeil extends StatelessWidget {
  const _PrivacyVeil();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: ColoredBox(
        key: privacyVeilKey,
        color: theme.colorScheme.surface,
        child: Center(
          child: Text(
            l10n.appTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
