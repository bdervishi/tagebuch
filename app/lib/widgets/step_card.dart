import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/entry_view.dart';
import '../l10n/app_localizations.dart';

/// Widget-Keys für Tests.
const Key stepCardKey = Key('step-card');
const Key stepDoneKey = Key('step-done');

/// Karte "Dein Schritt für heute" auf "Heute" (D17): die gestrige Antwort auf
/// "Der eine Schritt für morgen" mit einem Häkchen. Kein Streak, kein
/// Vorwurf: Ohne gestrigen Schritt erscheint nichts, und ein nicht gesetztes
/// Häkchen bleibt einfach leer.
class StepCard extends ConsumerWidget {
  const StepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stepCardProvider).value;
    if (state == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      key: stepCardKey,
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: scheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Text(l10n.stepCardTitle, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.stepCardFrom,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: state.done ? TextDecoration.lineThrough : null,
                color: state.done
                    ? scheme.onTertiaryContainer.withValues(alpha: 0.7)
                    : scheme.onTertiaryContainer,
              ),
            ),
            Semantics(
              label: l10n.stepCardDoneSemantics,
              child: CheckboxListTile(
                key: stepDoneKey,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.stepCardDone),
                value: state.done,
                onChanged: (v) =>
                    ref.read(reviewActionsProvider).setStepDone(v ?? false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
