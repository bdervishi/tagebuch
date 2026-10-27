import 'package:diary_core/diary_core.dart';

import '../../l10n/app_localizations.dart';

/// Texte der vier Impulse des geführten Rückblicks (D17) aus den ARB-Dateien.
/// Die Schlüssel kommen aus [ReviewPrompts]; unbekannte Schlüssel (ältere
/// oder künftige Fassungen) zeigen den Schlüssel selbst.
abstract final class PromptTexts {
  /// Sekunden, nach denen ein Impuls während der Aufnahme von selbst zum
  /// nächsten wechselt (eigene Festlegung, im Beta-Test prüfen).
  static const Duration autoAdvance = Duration(seconds: 45);

  /// Die Frage, wie sie beim Sprechen und Schreiben steht.
  static String title(AppLocalizations l10n, String key) => switch (key) {
    ReviewPrompts.free => l10n.promptFreeTitle,
    ReviewPrompts.good => l10n.promptGoodTitle,
    ReviewPrompts.lesson => l10n.promptLessonTitle,
    ReviewPrompts.next => l10n.promptNextTitle,
    _ => key,
  };

  /// Kleiner Hinweis unter der Frage oder `null`.
  static String? hint(AppLocalizations l10n, String key) => switch (key) {
    ReviewPrompts.good => l10n.promptGoodHint,
    ReviewPrompts.lesson => l10n.promptLessonHint,
    ReviewPrompts.next => l10n.promptNextHint,
    _ => null,
  };

  /// Kurzes Etikett für Listen, Chips und den Wochenrückblick.
  static String label(AppLocalizations l10n, String key) => switch (key) {
    ReviewPrompts.free => l10n.promptLabelFree,
    ReviewPrompts.good => l10n.promptLabelGood,
    ReviewPrompts.lesson => l10n.promptLabelLesson,
    ReviewPrompts.next => l10n.promptLabelNext,
    _ => key,
  };

  /// Wort zur Stimmungsstufe 1 bis 5 (emoji-frei, D17).
  static String mood(AppLocalizations l10n, int value) => switch (value) {
    1 => l10n.moodHeavy,
    2 => l10n.moodTired,
    3 => l10n.moodNeutral,
    4 => l10n.moodGood,
    _ => l10n.moodLight,
  };
}
