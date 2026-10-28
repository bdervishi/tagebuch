import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../l10n/app_localizations.dart';
import 'movement_library.dart';
import 'movement_providers.dart';
import 'movement_texts.dart';

/// Widget-Keys für Tests.
const Key exerciseSheetKey = Key('exercise-sheet');
const Key exerciseFreeTextKey = Key('exercise-free-text');
const Key exerciseFreeTextSaveKey = Key('exercise-free-text-save');
Key exerciseRowKey(String id) => Key('exercise-row-$id');

/// Blatt "Welche Bewegung?" (D24): die ganze Übungsliste nach Kategorien,
/// eigene Übungen eingeschlossen, und ein Freitext. Ein Tipp liefert den
/// Text der Notiz zurück ("Nacken kreisen · 2 Min." oder der Freitext);
/// `null` bei Abbruch. Speichern übernimmt der Aufrufer.
Future<String?> showExerciseSheet(BuildContext context) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const ExerciseSheet(),
  );
}

class ExerciseSheet extends ConsumerStatefulWidget {
  const ExerciseSheet({super.key});

  @override
  ConsumerState<ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends ConsumerState<ExerciseSheet> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _saveFree() {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    Navigator.of(context).pop(t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final library = ref.watch(exercisesProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final keys = [
      for (final c in library?.categories ?? const <ExerciseCategory>[]) c.key,
      ExerciseCategory.other,
    ];
    return AnimatedPadding(
      duration: Motion.enter,
      curve: Motion.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        key: exerciseSheetKey,
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(l10n.movementPickTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key: exerciseFreeTextKey,
              controller: _text,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _saveFree(),
              decoration: InputDecoration(
                hintText: l10n.movementFreeTextHint,
                suffixIcon: IconButton(
                  key: exerciseFreeTextSaveKey,
                  tooltip: l10n.movementFreeTextSave,
                  icon: const Icon(Icons.check),
                  onPressed: _text.text.trim().isEmpty ? null : _saveFree,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (library != null)
              for (final key in keys)
                if (library.inCategory(key) case final list
                    when list.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      MovementTexts.category(l10n, library, key, lang),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final e in list)
                    ListTile(
                      key: exerciseRowKey(e.id),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        e.own ? Icons.person_outline : Icons.directions_walk,
                        color: scheme.primary,
                      ),
                      title: Text(e.title(lang)),
                      subtitle: e.how(lang).isEmpty
                          ? null
                          : Text(
                              e.how(lang),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: Text(MovementTexts.duration(l10n, e)),
                      onTap: () =>
                          Navigator.of(context)
                              .pop(MovementTexts.noteText(l10n, e, lang)),
                    ),
                ],
            const SizedBox(height: 12),
            Text(l10n.movementNotice, style: muted),
          ],
        ),
      ),
    );
  }
}
