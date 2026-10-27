import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/reveal.dart';
import 'quote_card.dart';
import 'quote_library.dart';
import 'quote_providers.dart';

/// Widget-Keys für Tests.
const Key quotesAddOwnKey = Key('quotes-add-own');
const Key quotesOwnTextKey = Key('quotes-own-text');
const Key quotesOwnAuthorKey = Key('quotes-own-author');
const Key quotesOwnSaveKey = Key('quotes-own-save');
Key quotesThemeChipKey(String key) => Key('quotes-theme-$key');

/// Zitatenschatz (D20): die beiden Zitate des Tages, Themenwahl, markierte
/// und eigene Zitate. Alles gebündelt oder verschlüsselt lokal; kein Netz.
class QuotesScreen extends ConsumerWidget {
  const QuotesScreen({super.key, this.now});

  final DateTime? now;

  Future<void> _addOwn(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final text = TextEditingController();
    final author = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.quoteAddOwnTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: quotesOwnTextKey,
              controller: text,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.quoteOwnTextHint),
            ),
            const SizedBox(height: 12),
            TextField(
              key: quotesOwnAuthorKey,
              controller: author,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(hintText: l10n.quoteOwnAuthorHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            key: quotesOwnSaveKey,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.quoteOwnSave),
          ),
        ],
      ),
    );
    final body = text.text.trim();
    if (saved != true || body.isEmpty) return;
    final services = await ref.read(appServicesProvider.future);
    final who = author.text.trim();
    await ref
        .read(settingsProvider.notifier)
        .addOwnQuote(
          Quote(
            id: 'own-${services.ids.next()}',
            author: who.isEmpty ? l10n.quoteOwnAuthorFallback : who,
            de: body,
            en: body,
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
    final library = ref.watch(quotesProvider);
    final moment = now ?? DateTime.now();
    final day = DateTime(moment.year, moment.month, moment.day);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget tile(Quote q, {VoidCallback? onRemove}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: QuoteTile(
        quote: q,
        favorite: settings.quoteFavorites.contains(q.id),
        onToggleFavorite: () => notifier.toggleQuoteFavorite(q.id),
        onRemove: onRemove,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quotesTitle)),
      body: SafeArea(
        child: library == null
            ? Center(
                child: Semantics(
                  label: l10n.loadingLabel,
                  child: const CircularProgressIndicator(),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Reveal(index: 0, child: Text(l10n.quotesIntro, style: muted)),
                  const SizedBox(height: 20),
                  Reveal(index: 1, child: _Heading(l10n.quotesTodayHeading)),
                  const SizedBox(height: 10),
                  for (final slot in [
                    QuoteLibrary.slotMorning,
                    QuoteLibrary.slotEvening,
                  ])
                    if (library.forDay(
                          day,
                          selectedThemes: settings.quoteThemes,
                          slot: slot,
                        )
                        case final q?)
                      Reveal(index: 2 + slot, child: tile(q)),
                  const SizedBox(height: 14),
                  Reveal(index: 4, child: _Heading(l10n.quotesThemesHeading)),
                  const SizedBox(height: 4),
                  Reveal(
                    index: 4,
                    child: Text(l10n.quotesThemesHint, style: muted),
                  ),
                  const SizedBox(height: 10),
                  Reveal(
                    index: 5,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in library.themes)
                          FilterChip(
                            key: quotesThemeChipKey(t.key),
                            label: Text(t.name(lang)),
                            selected: settings.quoteThemes.contains(t.key),
                            onSelected: (on) {
                              final next = {...settings.quoteThemes};
                              if (on) {
                                next.add(t.key);
                              } else {
                                next.remove(t.key);
                              }
                              notifier.setQuoteThemes(next);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Reveal(index: 6, child: _Heading(l10n.quotesMineHeading)),
                  const SizedBox(height: 10),
                  Reveal(
                    index: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final q in settings.ownQuotes)
                          tile(
                            q,
                            onRemove: () => notifier.removeOwnQuote(q.id),
                          ),
                        for (final id in settings.quoteFavorites)
                          if (library.byId(id) case final q? when !q.own)
                            tile(q),
                        if (settings.ownQuotes.isEmpty &&
                            settings.quoteFavorites.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(l10n.quotesMineEmpty, style: muted),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            key: quotesAddOwnKey,
                            onPressed: () => _addOwn(context, ref),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.quoteAddOwn),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Reveal(
                    index: 8,
                    child: Text(l10n.quotesLicenseNote, style: muted),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleSmall);
}
