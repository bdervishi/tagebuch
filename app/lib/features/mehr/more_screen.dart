import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/books_view.dart';
import '../../data/goals_view.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/backup_reminder_card.dart';
import '../../widgets/reveal.dart';
import '../../widgets/surface_card.dart';
import '../daten/transfer_support.dart';
import '../zitate/quote_providers.dart';

/// Widget-Keys der Zeilen (für Tests).
const Key moreGoalsRowKey = Key('more-goals');
const Key moreBooksRowKey = Key('more-books');
const Key moreQuotesRowKey = Key('more-quotes');
const Key moreWeekRowKey = Key('more-week');
const Key moreBackupRowKey = Key('more-backup');

/// Reiter "Mehr": alles, was nicht täglich gebraucht wird, als ruhige Liste
/// von Zeilen mit Symbol, Titel, einer Zeile Zustand und Pfeil: Wege (D19),
/// Lesebuch (D21), Zitate (D20), Wochenrückblick (D17) und Backup samt
/// Gerätewechsel (D6, D16). Darunter bei Bedarf die Karte "Zeit für ein
/// Backup". Ein Tipp öffnet die bestehenden Routen. Die Zeilen erscheinen
/// gestaffelt (docs/12); kein Zähler drängt, der Zustand informiert nur.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Reveal(
              index: 0,
              child: _MoreRow(
                key: moreGoalsRowKey,
                icon: Icons.route_outlined,
                title: l10n.goalsTitle,
                state: _goalsState(ref, l10n),
                onTap: () => AppRoutes.openGoals(context),
              ),
            ),
            Reveal(
              index: 1,
              child: _MoreRow(
                key: moreBooksRowKey,
                icon: Icons.menu_book_outlined,
                title: l10n.booksTitle,
                state: _readingState(ref, l10n),
                onTap: () => AppRoutes.openBooks(context),
              ),
            ),
            Reveal(
              index: 2,
              child: _MoreRow(
                key: moreQuotesRowKey,
                icon: Icons.format_quote_outlined,
                title: l10n.quotesTitle,
                state: _quoteState(context, ref, l10n),
                onTap: () => AppRoutes.openQuotes(context),
              ),
            ),
            Reveal(
              index: 3,
              child: _MoreRow(
                key: moreWeekRowKey,
                icon: Icons.view_week_outlined,
                title: l10n.weekButton,
                state: l10n.moreWeekSubtitle,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.week),
              ),
            ),
            Reveal(
              index: 4,
              child: _MoreRow(
                key: moreBackupRowKey,
                icon: Icons.save_alt,
                title: l10n.moreBackupTitle,
                state: _backupState(context, ref, l10n),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.backup),
              ),
            ),
            const SizedBox(height: 8),
            const Reveal(index: 5, child: BackupReminderCard()),
          ],
        ),
      ),
    );
  }

  /// "2 aktive Wege · Nächste Etappe: Kapitel 1"; ohne Wege der leise Hinweis.
  /// Während des Ladens leer, damit nichts springt.
  String? _goalsState(WidgetRef ref, AppLocalizations l10n) {
    final goals = ref.watch(activeGoalsProvider).value;
    if (goals == null) return null;
    if (goals.isEmpty) return l10n.moreGoalsEmpty;
    final next = goals.map((g) => g.nextOpen).nonNulls.firstOrNull;
    final nextText = next == null
        ? l10n.moreGoalsNoOpen
        : l10n.moreGoalsNext(next.title);
    return '${l10n.moreGoalsActive(goals.length)} · $nextText';
  }

  /// "Lese ich: Titel · 2 Passagen"; ohne Buch in Arbeit die leise Frage.
  String? _readingState(WidgetRef ref, AppLocalizations l10n) {
    final state = ref.watch(readingBookProvider);
    if (state.isLoading && !state.hasValue) return null;
    final view = state.value;
    if (view == null) return l10n.moreReadingEmpty;
    return '${l10n.moreReadingLabel(view.book.title)} · '
        '${l10n.bookPassageCount(view.passages.length)}';
  }

  /// Das Zitat des Tages in einer Zeile (die Zeile kürzt mit Auslassung);
  /// ohne Zitat (ausgeschaltet oder leerer Schatz) eine Beschreibung.
  String _quoteState(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final now =
        ref.watch(appServicesProvider).value?.clock.now() ?? DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final quote = ref.watch(quoteForProvider((day, quoteSlotFor(now))));
    if (quote == null) return l10n.moreQuotesEmpty;
    final lang = Localizations.localeOf(context).languageCode;
    return '„${quote.text(lang)}“ · ${quote.author}';
  }

  /// "Letztes Backup: Datum", mit Hinweis ab sieben Tagen, oder "noch keins".
  String? _backupState(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final backup = ref.watch(lastBackupProvider);
    if (backup.isLoading && !backup.hasValue) return null;
    final last = backup.value;
    if (last == null) return l10n.moreBackupNone;
    final now =
        ref.watch(appServicesProvider).value?.clock.now() ?? DateTime.now();
    final date = MaterialLocalizations.of(context).formatMediumDate(last);
    return now.difference(last) >= BackupReminder.maxAge
        ? l10n.moreBackupStale(date)
        : l10n.backupLast(date);
  }
}

/// Eine Zeile der Liste: Symbol, Titel, eine Zeile Zustand, Pfeil. Die
/// ganze Karte ist tippbar (Ink plus Druck-Rückmeldung aus [SurfaceCard]).
class _MoreRow extends StatelessWidget {
  const _MoreRow({
    super.key,
    required this.icon,
    required this.title,
    required this.state,
    required this.onTap,
  });

  final IconData icon;
  final String title;

  /// Zustand in einer Zeile; `null`, solange er lädt.
  final String? state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = this.state;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  if (state != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      state,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
