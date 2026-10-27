import 'package:diary_keys/diary_keys.dart' show PinRules;
import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/pressable.dart';

/// Widget-Keys für Tests.
const Key pinSubmitKey = Key('pin-submit');
const Key pinBackspaceKey = Key('pin-backspace');

/// Key der Zifferntaste [digit] (Tests).
Key pinDigitKey(int digit) => Key('pin-digit-$digit');

/// Ziffernfeld der App-Sperre (D23): große Tasten (mindestens 56 dp hoch),
/// Rückmeldung beim Drücken über [Pressable] und Ink mit [Motion.press],
/// Reduce-Motion-tauglich (dann nur Deckkraft). Reihen 1 bis 9, darunter
/// Löschen, 0 und Bestätigen.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    this.enabled = true,
    this.submitEnabled = true,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  /// Alle Tasten gesperrt (Wartezeit, Prüfung läuft).
  final bool enabled;

  /// Ob "Bestätigen" bedienbar ist (genug Ziffern).
  final bool submitEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Row(
              children: [
                for (final d in row)
                  Expanded(
                    child: _PinKey(
                      key: pinDigitKey(d),
                      enabled: enabled,
                      onTap: () => onDigit(d),
                      child: Text('$d'),
                    ),
                  ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: _PinKey(
                  key: pinBackspaceKey,
                  enabled: enabled,
                  semanticLabel: l10n.pinBackspace,
                  onTap: onBackspace,
                  child: const Icon(Icons.backspace_outlined),
                ),
              ),
              Expanded(
                child: _PinKey(
                  key: pinDigitKey(0),
                  enabled: enabled,
                  onTap: () => onDigit(0),
                  child: const Text('0'),
                ),
              ),
              Expanded(
                child: _PinKey(
                  key: pinSubmitKey,
                  enabled: enabled && submitEnabled,
                  primary: true,
                  semanticLabel: l10n.pinSubmit,
                  onTap: onSubmit,
                  child: const Icon(Icons.check),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Eine Taste des Ziffernfelds: Radius 14 (docs/12 Abschnitt 7), Fläche
/// `surfaceContainerHigh`, die Hauptaktion in `primary`.
class _PinKey extends StatelessWidget {
  const _PinKey({
    super.key,
    required this.child,
    required this.onTap,
    required this.enabled,
    this.primary = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final bool primary;
  final String? semanticLabel;

  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final background = primary ? scheme.primary : scheme.surfaceContainerHigh;
    final foreground = primary ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        child: Pressable(
          enabled: enabled,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.4,
            duration: Motion.quick,
            curve: Motion.easeOut,
            child: Material(
              color: background,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              animationDuration: Motion.press,
              child: InkWell(
                onTap: enabled ? onTap : null,
                child: SizedBox(
                  height: _height,
                  child: Center(
                    child: IconTheme.merge(
                      data: IconThemeData(color: foreground, size: 26),
                      child: DefaultTextStyle.merge(
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: foreground,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Punkte für die eingegebenen Ziffern: ein gefüllter Punkt je Ziffer, leere
/// Punkte bis zur Standardlänge, damit das Feld nicht springt. Für den
/// Screenreader zählt eine Beschriftung die Ziffern.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final slots = count > PinRules.defaultLength
        ? count
        : PinRules.defaultLength;
    return Semantics(
      label: l10n.pinDigitsEntered(count),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < slots; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: AnimatedContainer(
                  duration: Motion.quick,
                  curve: Motion.easeOut,
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < count ? scheme.primary : Colors.transparent,
                    border: Border.all(
                      color: i < count ? scheme.primary : scheme.outline,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Eingabefeld der Sperre: Hinweis, Punkte, Meldung, Ziffernfeld und
/// Fortschritt während Argon2id läuft. Hält die eingegebenen Ziffern und
/// liefert sie bei "Bestätigen" oder bei der Höchstlänge über [onSubmit].
class PinEntryPanel extends StatefulWidget {
  const PinEntryPanel({
    super.key,
    required this.hint,
    required this.onSubmit,
    this.message,
    this.messageIsError = false,
    this.busy = false,
    this.busyLabel,
    this.enabled = true,
    this.resetToken = 0,
  });

  /// Was gerade einzugeben ist ("PIN eingeben", "PIN wiederholen").
  final String hint;

  /// Rückmeldung unter den Punkten (Fehler oder Wartezeit).
  final String? message;
  final bool messageIsError;

  /// Prüfung oder Speichern läuft: Fortschritt statt Meldung, Feld gesperrt.
  final bool busy;
  final String? busyLabel;

  /// Falsch: Wartezeit läuft, nichts geht.
  final bool enabled;

  /// Ändert sich der Wert, wird die Eingabe geleert (nach einem Schritt).
  final int resetToken;

  final ValueChanged<String> onSubmit;

  @override
  State<PinEntryPanel> createState() => _PinEntryPanelState();
}

class _PinEntryPanelState extends State<PinEntryPanel> {
  String _entered = '';

  @override
  void didUpdateWidget(covariant PinEntryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) _entered = '';
  }

  void _digit(int d) {
    if (_entered.length >= PinRules.maxLength) return;
    setState(() => _entered += '$d');
    if (_entered.length == PinRules.maxLength) _submit();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _submit() {
    if (_entered.length < PinRules.minLength) return;
    final pin = _entered;
    setState(() => _entered = '');
    widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = widget.enabled && !widget.busy;
    final message = widget.message;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.hint,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        PinDots(count: _entered.length),
        const SizedBox(height: 16),
        // Feste Höhe, damit Meldung und Fortschritt das Feld nicht verschieben.
        SizedBox(
          height: 44,
          child: Center(
            child: widget.busy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      if (widget.busyLabel != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          widget.busyLabel!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  )
                : message == null
                ? null
                : Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.messageIsError
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        PinPad(
          enabled: active,
          submitEnabled: _entered.length >= PinRules.minLength,
          onDigit: _digit,
          onBackspace: _backspace,
          onSubmit: _submit,
        ),
      ],
    );
  }
}
