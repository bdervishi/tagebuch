import 'package:diary_core/diary_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_view.dart';
import '../../data/settings_notifier.dart';
import '../../services/app_services.dart';
import 'movement_library.dart';

/// Gebündelte Übungsliste, einmal geladen (Tests überschreiben den Provider
/// mit einer festen Liste, weil `rootBundle` dort nicht deterministisch
/// lädt).
final movementLibraryProvider = FutureProvider<MovementLibrary>(
  (ref) => MovementLibrary.load(),
);

/// Liste plus eigene Übungen aus den Einstellungen; `null`, solange die
/// Datei lädt.
final exercisesProvider = Provider<MovementLibrary?>((ref) {
  final library = ref.watch(movementLibraryProvider).value;
  if (library == null) return null;
  final own = ref.watch(settingsProvider).value?.ownExercises ?? const [];
  return own.isEmpty ? library : library.withOwn(own);
});

/// Zustand der Karte "Zeit für Bewegung" (D24): die fällige Pause und die
/// drei Vorschläge dazu.
class MovementCardState {
  const MovementCardState({
    required this.breakIndex,
    required this.movementBreak,
    required this.suggestions,
  });

  final int breakIndex;
  final MovementBreak movementBreak;
  final List<Exercise> suggestions;
}

/// Die fällige Pause oder `null`: Pausen aus, heute keine Pause fällig,
/// "Heute nicht" gewählt oder seit der Pausenzeit schon eine Bewegung
/// notiert. Die Karte bleibt bis zur nächsten Pause oder zum Tagesende.
final movementCardProvider = FutureProvider<MovementCardState?>((ref) async {
  ref.watch(dataVersionProvider);
  final settings = ref.watch(settingsProvider).value;
  if (settings == null || !settings.movementEnabled) return null;
  final library = ref.watch(exercisesProvider);
  if (library == null) return null;
  final s = await ref.watch(appServicesProvider.future);
  final now = s.clock.now();
  final index = MovementSchedule.dueIndex(settings.movementBreaks, now);
  if (index == null) return null;
  final today = LocalDay.forMoment(now);
  if (settings.isMovementDismissed(today, index)) return null;
  final b = settings.movementBreaks[index];
  final view = await EntryView.forDay(s, today);
  final since = b.at(now);
  final done =
      view?.notes.any(
        (n) =>
            n.promptKey == ReviewPrompts.movement &&
            !n.createdAt.isBefore(since),
      ) ??
      false;
  if (done) return null;
  return MovementCardState(
    breakIndex: index,
    movementBreak: b,
    suggestions: library.suggestionsFor(today.startOfDay, index),
  );
});

/// Zustand für die Zeile "Bewegung" auf "Mehr": nächste Pause und die Zahl
/// der heute notierten Bewegungen.
class MovementSummary {
  const MovementSummary({
    required this.enabled,
    required this.next,
    required this.todayCount,
  });

  final bool enabled;

  /// Nächste Pause oder `null`, wenn keine Pause einen Wochentag hat.
  final DateTime? next;
  final int todayCount;
}

final movementSummaryProvider = FutureProvider<MovementSummary?>((ref) async {
  ref.watch(dataVersionProvider);
  final settings = ref.watch(settingsProvider).value;
  if (settings == null) return null;
  final s = await ref.watch(appServicesProvider.future);
  final now = s.clock.now();
  final view = await EntryView.forDay(s, LocalDay.forMoment(now));
  return MovementSummary(
    enabled: settings.movementEnabled,
    next: MovementSchedule.nextAfter(settings.movementBreaks, now),
    todayCount:
        view?.notes
            .where((n) => n.promptKey == ReviewPrompts.movement)
            .length ??
        0,
  );
});

/// Schreibende Aktionen: Bewegung notieren, Pause für heute überspringen.
class MovementActions {
  const MovementActions(this.ref);
  final Ref ref;

  /// Legt die Notiz `movement` mit [text] am heutigen Eintrag an (der
  /// Eintrag entsteht, falls noch keiner da ist). Leerer Text tut nichts.
  Future<EntryNote?> log(String text) async {
    final body = text.trim();
    if (body.isEmpty) return null;
    final s = await ref.read(appServicesProvider.future);
    final now = s.clock.now();
    final entry = await s.entries.getOrCreate(
      s.journalId,
      LocalDay.forMoment(now),
      now,
    );
    final note = EntryNote(
      id: s.ids.next(),
      entryId: entry.id,
      createdAt: now,
      updatedAt: now,
      text: body,
      promptKey: ReviewPrompts.movement,
    );
    await s.notes.insert(note);
    ref.read(dataVersionProvider.notifier).bump();
    return note;
  }

  /// "Heute nicht" für die Pause [breakIndex]: nur Tageszustand, kein
  /// Eintrag.
  Future<void> dismiss(int breakIndex) async {
    final s = await ref.read(appServicesProvider.future);
    await ref
        .read(settingsProvider.notifier)
        .dismissMovementBreak(LocalDay.forMoment(s.clock.now()), breakIndex);
  }
}

final movementActionsProvider = Provider<MovementActions>(
  (ref) => MovementActions(ref),
);
