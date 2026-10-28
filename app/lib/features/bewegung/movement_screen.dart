import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import 'movement_breaks_editor.dart';
import 'movement_calendar_sheet.dart';
import 'movement_library.dart';
import 'movement_providers.dart';
import 'movement_texts.dart';

/// Widget-Keys für Tests.
const Key movementScreenSwitchKey = Key('movement-screen-switch');
const Key movementScreenCalendarKey = Key('movement-screen-calendar');
const Key movementAddOwnKey = Key('movement-add-own');
const Key movementOwnTitleKey = Key('movement-own-title');
const Key movementOwnMinutesKey = Key('movement-own-minutes');
const Key movementOwnSaveKey = Key('movement-own-save');
Key movementOwnCategoryKey(String key) => Key('movement-own-category-$key');
Key movementOwnRemoveKey(String id) => Key('movement-own-remove-$id');
Key movementExerciseKey(String id) => Key('movement-exercise-$id');

/// Bildschirm "Bewegung" (D24, Route `/movement`): Schalter und Pausenzeiten
/// (dieselbe Widget-Datei wie in den Einstellungen), "In den Kalender", die
/// Übungen nach Kategorien mit kurzer Anleitung und Dauer, eigene Übungen
/// hinzufügen und entfernen, der Hinweis zu Schmerzen. Keine Zähler, keine
/// Pläne, keine Empfehlungen aus dem Netz.
class MovementScreen extends ConsumerWidget {
  const MovementScreen({super.key});

  Future<void> _addOwn(
    BuildContext context,
    WidgetRef ref,
    MovementLibrary library,
  ) async {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final title = TextEditingController();
    final minutes = TextEditingController();
    var category =
        library.categories.firstOrNull?.key ?? ExerciseCategory.other;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.movementAddOwn),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: movementOwnTitleKey,
                controller: title,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.movementOwnTitleHint,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: movementOwnMinutesKey,
                controller: minutes,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.movementOwnMinutesHint,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in library.categories)
                    ChoiceChip(
                      key: movementOwnCategoryKey(c.key),
                      label: Text(c.name(lang)),
                      selected: category == c.key,
                      onSelected: (_) => setState(() => category = c.key),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              key: movementOwnSaveKey,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.movementOwnSave),
            ),
          ],
        ),
      ),
    );
    final name = title.text.trim();
    if (saved != true || name.isEmpty) return;
    final services = await ref.read(appServicesProvider.future);
    final mins = double.tryParse(minutes.text.trim().replaceAll(',', '.'));
    await ref
        .read(settingsProvider.notifier)
        .addOwnExercise(
          Exercise(
            id: 'own-${services.ids.next()}',
            category: category,
            minutes: mins == null || mins < 0 ? 0 : mins,
            de: name,
            en: name,
            own: true,
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final features = ref.watch(platformFeaturesProvider);
    final library = ref.watch(exercisesProvider);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final keys = [
      for (final c in library?.categories ?? const <ExerciseCategory>[]) c.key,
      ExerciseCategory.other,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.movementTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Reveal(index: 0, child: Text(l10n.movementIntro, style: muted)),
            const SizedBox(height: 16),
            Reveal(
              index: 1,
              child: SurfaceCard(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      key: movementScreenSwitchKey,
                      title: Text(l10n.movementEnabled),
                      subtitle: Text(l10n.movementEnabledSubtitle),
                      value: settings.movementEnabled,
                      onChanged: notifier.setMovementEnabled,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: Text(
                        l10n.movementBreaksHeading,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                      child: MovementBreaksEditor(
                        enabled: settings.movementEnabled,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: OutlinedButton.icon(
                        key: movementScreenCalendarKey,
                        onPressed: () => showMovementCalendarSheet(
                          context,
                          features: features,
                          breaks: settings.movementBreaks,
                        ),
                        icon: const Icon(Icons.event_available),
                        label: Text(l10n.movementCalendarButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Reveal(
              index: 2,
              child: Text(
                l10n.movementExercisesHeading,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 6),
            if (library == null)
              Center(
                child: Semantics(
                  label: l10n.loadingLabel,
                  child: const CircularProgressIndicator(),
                ),
              )
            else ...[
              for (final (k, key) in keys.indexed)
                if (library.inCategory(key) case final list
                    when list.isNotEmpty)
                  Reveal(
                    index: 3 + k,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                            child: Text(
                              MovementTexts.category(l10n, library, key, lang),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          SurfaceCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final (i, e) in list.indexed) ...[
                                  if (i > 0)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: scheme.outlineVariant.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  _ExerciseRow(
                                    key: movementExerciseKey(e.id),
                                    exercise: e,
                                    onRemove: e.own
                                        ? () => notifier.removeOwnExercise(e.id)
                                        : null,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              Reveal(
                index: 3 + keys.length,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.movementOwnHeading,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    if (settings.ownExercises.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(l10n.movementOwnEmpty, style: muted),
                      ),
                    OutlinedButton.icon(
                      key: movementAddOwnKey,
                      onPressed: () => _addOwn(context, ref, library),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.movementAddOwn),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Reveal(
              index: 4 + keys.length,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.movementNotice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Übung: Titel, Anleitung, Dauer; eigene mit "entfernen".
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({super.key, required this.exercise, this.onRemove});

  final Exercise exercise;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final how = exercise.how(lang);
    final duration = MovementTexts.duration(l10n, exercise);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              exercise.own ? Icons.person_outline : Icons.directions_walk,
              size: 18,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.title(lang),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (duration.isNotEmpty)
                      Text(
                        duration,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (how.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    how,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              key: movementOwnRemoveKey(exercise.id),
              tooltip: l10n.movementRemoveOwn,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onRemove,
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}
