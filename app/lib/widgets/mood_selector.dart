import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';

import '../features/rueckblick/prompts.dart';
import '../l10n/app_localizations.dart';

/// Widget-Keys für Tests.
const Key moodSliderKey = Key('mood-slider');
const Key moodClearKey = Key('mood-clear');

/// Stimmung als Schieber 1 bis 5 mit Wörtern statt Emojis (D17). Die
/// Nutzerin setzt sie selbst; die App leitet nichts ab (D8). Ungesetzt steht
/// der Schieber in der Mitte und ist gedämpft; ein Zug setzt den Wert.
class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.showNote = false,
  });

  /// 1 bis 5 oder `null`.
  final int? value;
  final ValueChanged<int?> onChanged;

  /// Zeigt den Satz, dass nichts aus der Stimme abgeleitet wird.
  final bool showNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = value;
    final word = current == null
        ? l10n.moodNotSet
        : PromptTexts.mood(l10n, current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.moodHeading, style: theme.textTheme.titleSmall),
            const SizedBox(width: 12),
            Text(
              word,
              key: const Key('mood-word'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: current == null
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
            const Spacer(),
            if (current != null)
              IconButton(
                key: moodClearKey,
                tooltip: l10n.moodClear,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onChanged(null),
              ),
          ],
        ),
        Semantics(
          label: l10n.moodSemantics(word),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: current == null ? scheme.outlineVariant : null,
              thumbColor: current == null ? scheme.outline : null,
            ),
            child: Slider(
              key: moodSliderKey,
              value: (current ?? 3).toDouble(),
              min: MoodScale.min.toDouble(),
              max: MoodScale.max.toDouble(),
              divisions: MoodScale.max - MoodScale.min,
              label: word,
              onChanged: (v) => onChanged(v.round()),
              // Ein Tipp auf die Mitte ändert den Wert des Schiebers nicht;
              // ungesetzt soll er trotzdem "neutral" setzen.
              onChangeEnd: current == null ? (v) => onChanged(v.round()) : null,
            ),
          ),
        ),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = MoodScale.min; i <= MoodScale.max; i++)
                Text(
                  PromptTexts.mood(l10n, i),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: i == current
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    fontWeight: i == current ? FontWeight.w700 : null,
                  ),
                ),
            ],
          ),
        ),
        if (showNote) ...[
          const SizedBox(height: 4),
          Text(
            l10n.moodNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
