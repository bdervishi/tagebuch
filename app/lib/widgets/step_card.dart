import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/motion.dart';
import '../data/entry_view.dart';
import '../l10n/app_localizations.dart';
import 'surface_card.dart';

/// Widget-Keys für Tests.
const Key stepCardKey = Key('step-card');
const Key stepDoneKey = Key('step-done');

/// Karte "Dein Schritt für heute" auf "Heute" (D17): die gestrige Antwort auf
/// "Der eine Schritt für morgen" mit einem Häkchen. Kein Streak, kein
/// Vorwurf: Ohne gestrigen Schritt erscheint nichts, und ein nicht gesetztes
/// Häkchen bleibt einfach leer. Das Durchstreichen blendet in 160 ms über,
/// damit der Wechsel nicht springt.
class StepCard extends ConsumerWidget {
  const StepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stepCardProvider).value;
    if (state == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onColor = scheme.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        key: stepCardKey,
        color: scheme.tertiaryContainer,
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 20, color: onColor),
                const SizedBox(width: 8),
                Text(
                  l10n.stepCardTitle,
                  style: theme.textTheme.titleMedium?.copyWith(color: onColor),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              l10n.stepCardFrom,
              style: theme.textTheme.labelSmall?.copyWith(
                color: onColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedDefaultTextStyle(
              duration: Motion.quick,
              curve: Motion.easeOut,
              style: theme.textTheme.bodyLarge!.copyWith(
                decoration: state.done ? TextDecoration.lineThrough : null,
                decorationColor: onColor.withValues(alpha: 0.7),
                color: state.done ? onColor.withValues(alpha: 0.65) : onColor,
              ),
              child: Text(state.text),
            ),
            const SizedBox(height: 4),
            Semantics(
              label: l10n.stepCardDoneSemantics,
              child: Theme(
                data: theme.copyWith(
                  checkboxTheme: theme.checkboxTheme.copyWith(
                    side: BorderSide(color: onColor, width: 2),
                  ),
                ),
                child: CheckboxListTile(
                  key: stepDoneKey,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    l10n.stepCardDone,
                    style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
                  ),
                  value: state.done,
                  onChanged: (v) =>
                      ref.read(reviewActionsProvider).setStepDone(v ?? false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
