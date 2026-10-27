import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_notifier.dart';
import 'quote_library.dart';

/// Gebündelter Zitatenschatz, einmal geladen.
final quoteLibraryProvider = FutureProvider<QuoteLibrary>(
  (ref) => QuoteLibrary.load(),
);

/// Schatz plus eigene Zitate aus den Einstellungen.
final quotesProvider = Provider<QuoteLibrary?>((ref) {
  final library = ref.watch(quoteLibraryProvider).value;
  if (library == null) return null;
  final own = ref.watch(settingsProvider).value?.ownQuotes ?? const [];
  return own.isEmpty ? library : library.withOwn(own);
});

/// Platz des Tages: bis 16 Uhr das Morgenzitat, danach das Abendzitat.
int quoteSlotFor(DateTime now) =>
    now.hour < 16 ? QuoteLibrary.slotMorning : QuoteLibrary.slotEvening;

/// Zitat für [day] und [slot] nach den gewählten Themen; `null`, solange der
/// Schatz lädt oder die Nutzerin Zitate ausgeschaltet hat.
final quoteForProvider = Provider.family<Quote?, (DateTime, int)>((ref, arg) {
  final settings = ref.watch(settingsProvider).value;
  if (settings == null || !settings.quotesEnabled) return null;
  final library = ref.watch(quotesProvider);
  if (library == null) return null;
  final (day, slot) = arg;
  return library.forDay(day, selectedThemes: settings.quoteThemes, slot: slot);
});
