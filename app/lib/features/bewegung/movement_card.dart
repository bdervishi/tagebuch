import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/surface_card.dart';
import 'exercise_sheet.dart';
import 'movement_providers.dart';
import 'movement_texts.dart';

/// Widget-Keys für Tests.
const Key movementCardKey = Key('movement-card');
const Key movementOtherKey = Key('movement-other');
const Key movementSkipKey = Key('movement-skip');
Key movementSuggestionKey(String id) => Key('movement-suggestion-$id');

/// Karte "Zeit für Bewegung" auf "Heute" (D24): erscheint ab der fälligen
/// Pausenzeit bis zur nächsten Pause oder zum Tagesende, mit drei
/// vorgeschlagenen Übungen als Chips. Ein Tipp speichert die Notiz
/// `movement` am heutigen Eintrag und schließt die Karte; "Etwas anderes"
/// öffnet die ganze Liste, "Heute nicht" schließt die Karte ohne Eintrag.
/// Leise Fläche, kein Zähler, kein Vorwurf.
class MovementCard extends ConsumerWidget {
  const MovementCard({super.key});

  Future<void> _other(BuildContext context, WidgetRef ref) async {
    final text = await showExerciseSheet(context);
    if (text == null) return;
    await ref.read(movementActionsProvider).log(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(movementCardProvider).value;
    if (state == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final actions = ref.read(movementActionsProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        key: movementCardKey,
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.movementCardTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  l10n.movementCardBreakAt(
                    MovementTexts.time(context, state.movementBreak),
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.movementCardHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in state.suggestions)
                  Semantics(
                    label: l10n.exerciseOpenSemantics,
                    child: ActionChip(
                      key: movementSuggestionKey(e.id),
                      label: Text(MovementTexts.noteText(l10n, e, lang)),
                      onPressed: () =>
                          actions.log(MovementTexts.noteText(l10n, e, lang)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton(
                  key: movementOtherKey,
                  onPressed: () => _other(context, ref),
                  child: Text(l10n.movementOther),
                ),
                const Spacer(),
                TextButton(
                  key: movementSkipKey,
                  onPressed: () => actions.dismiss(state.breakIndex),
                  child: Text(l10n.movementSkip),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
