import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import 'movement_library.dart';
import 'movement_texts.dart';

/// Widget-Keys für Tests.
const Key movementBreakAddKey = Key('movement-break-add');
Key movementBreakTimeKey(int index) => Key('movement-break-time-$index');
Key movementBreakRemoveKey(int index) => Key('movement-break-remove-$index');
Key movementBreakDayKey(int index, int weekday) =>
    Key('movement-break-$index-day-$weekday');

/// Pausenzeiten (D24): je Pause eine Zeile mit Uhrzeit (Tipp öffnet den
/// Zeitwähler) und Wochentags-Chips Montag bis Sonntag, dazu "Pause
/// hinzufügen" bis zur Grenze von drei und "entfernen" ab der zweiten.
/// Dieselbe Datei dient den Einstellungen und dem Bildschirm "Bewegung".
/// Änderungen gehen sofort in die Einstellung `movementBreaks`.
class MovementBreaksEditor extends ConsumerWidget {
  const MovementBreaksEditor({super.key, this.enabled = true});

  /// Ausgeschaltet (Schalter aus): Zeilen gedämpft und nicht bedienbar.
  final bool enabled;

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    List<MovementBreak> breaks,
    int index,
  ) async {
    final b = breaks[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: b.hour, minute: b.minute),
    );
    if (picked == null) return;
    final next = [...breaks];
    next[index] = b.copyWith(hour: picked.hour, minute: picked.minute);
    await ref.read(settingsProvider.notifier).setMovementBreaks(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final breaks =
        ref.watch(settingsProvider).value?.movementBreaks ??
        MovementBreak.defaults;
    final notifier = ref.read(settingsProvider.notifier);
    final muted = scheme.onSurfaceVariant;
    return AnimatedOpacity(
      duration: Motion.quick,
      curve: Motion.easeOut,
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, b) in breaks.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Semantics(
                          button: true,
                          label: l10n.movementBreakTimeSemantics,
                          child: TextButton.icon(
                            key: movementBreakTimeKey(i),
                            onPressed: () => _pickTime(context, ref, breaks, i),
                            icon: const Icon(Icons.schedule, size: 20),
                            label: Text(
                              MovementTexts.time(context, b),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (breaks.length > 1)
                          IconButton(
                            key: movementBreakRemoveKey(i),
                            tooltip: l10n.movementBreakRemove,
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => notifier.setMovementBreaks([
                              for (final (j, x) in breaks.indexed)
                                if (j != i) x,
                            ]),
                          ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                          FilterChip(
                            key: movementBreakDayKey(i, d),
                            label: Text(MovementTexts.weekdayShort(locale, d)),
                            selected: b.weekdays.contains(d),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            onSelected: (on) {
                              final days = {...b.weekdays};
                              if (on) {
                                days.add(d);
                              } else {
                                days.remove(d);
                              }
                              final next = [...breaks];
                              next[i] = b.copyWith(weekdays: days);
                              notifier.setMovementBreaks(next);
                            },
                          ),
                      ],
                    ),
                    if (b.weekdays.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          l10n.movementBreakNoDays,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (breaks.length < MovementBreak.maxCount)
              TextButton.icon(
                key: movementBreakAddKey,
                onPressed: () => notifier.setMovementBreaks([
                  ...breaks,
                  // Neue Pause: eine Stunde nach der letzten, gleiche Tage.
                  (breaks.lastOrNull ?? MovementBreak.defaults.first).copyWith(
                    hour: ((breaks.lastOrNull?.hour ?? 9) + 1) % 24,
                  ),
                ]),
                icon: const Icon(Icons.add),
                label: Text(l10n.movementBreakAdd),
              ),
          ],
        ),
      ),
    );
  }
}
