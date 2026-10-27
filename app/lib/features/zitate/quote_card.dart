import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../app/routes.dart';
import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/surface_card.dart';
import 'quote_library.dart';
import 'quote_providers.dart';

/// Widget-Keys für Tests.
const Key quoteCardKey = Key('quote-card');
const Key quoteFavoriteKey = Key('quote-favorite');

/// Karte "Zitat zum Tag" auf "Heute" (D20): ein leises Zitat, Autor und
/// Quelle, ein Herz zum Markieren. Ein Tipp öffnet den Zitatenschatz.
/// Erscheint nicht, wenn die Nutzerin Zitate ausgeschaltet hat.
class QuoteCard extends ConsumerWidget {
  const QuoteCard({super.key, this.now});

  /// Zeitpunkt (für Tests); sonst jetzt.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = now ?? DateTime.now();
    final day = DateTime(moment.year, moment.month, moment.day);
    final quote = ref.watch(quoteForProvider((day, quoteSlotFor(moment))));
    if (quote == null) return const SizedBox.shrink();
    final favorites =
        ref.watch(settingsProvider).value?.quoteFavorites ?? const {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: QuoteTile(
        key: quoteCardKey,
        quote: quote,
        favorite: favorites.contains(quote.id),
        onToggleFavorite: () =>
            ref.read(settingsProvider.notifier).toggleQuoteFavorite(quote.id),
        onTap: () => AppRoutes.openQuotes(context),
      ),
    );
  }
}

/// Darstellung eines Zitats als weiche Karte: großes Anführungszeichen,
/// Text, Autor mit Quelle, Herz.
class QuoteTile extends StatelessWidget {
  const QuoteTile({
    super.key,
    required this.quote,
    required this.favorite,
    required this.onToggleFavorite,
    this.onTap,
    this.onRemove,
  });

  final Quote quote;
  final bool favorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;

  /// Nur für eigene Zitate: entfernen.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final attribution = quote.source.isEmpty
        ? quote.author
        : '${quote.author} · ${quote.source}';
    return SurfaceCard(
      onTap: onTap,
      semanticLabel: onTap == null ? null : l10n.quoteOpenSemantics,
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '„${quote.text(lang)}“',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              Semantics(
                label: favorite
                    ? l10n.quoteUnfavoriteSemantics
                    : l10n.quoteFavoriteSemantics,
                child: IconButton(
                  key: quoteFavoriteKey,
                  tooltip: favorite ? l10n.quoteUnfavorite : l10n.quoteFavorite,
                  onPressed: onToggleFavorite,
                  icon: AnimatedSwitcher(
                    duration: Motion.quick,
                    switchInCurve: Motion.easeOut,
                    switchOutCurve: Motion.easeOut,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.85,
                        end: 1,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(favorite),
                      color: favorite
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  attribution,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: l10n.quoteRemoveOwn,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onRemove,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
