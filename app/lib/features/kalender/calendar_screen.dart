import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/day.dart';
import '../../data/entry_view.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/entry_tile.dart';
import '../lesebuch/book_search_tile.dart';
import 'month_grid.dart';

/// Key des Suchfelds (für Tests).
const Key searchFieldKey = Key('calendar-search');

/// Key der Schaltfläche "Woche" (Wochenrückblick, D17).
const Key weekButtonKey = Key('calendar-week');

/// Kalender und Suche: Monatsraster mit markierten Tagen, darunter die
/// Einträge des Monats oder des gewählten Tags; ein Suchtext fragt das
/// `SearchRepository` (Web: Index im Speicher, nativ später FTS5).
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.initialMonth});

  /// Anfangs angezeigter Monat (für Tests); sonst der aktuelle.
  final DateTime? initialMonth;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = monthOf(widget.initialMonth ?? DateTime.now());
  DateTime? _selectedDay;
  final TextEditingController _searchController = TextEditingController();

  String get _query => _searchController.text;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _selectedDay = null;
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = _selectedDay != null && isSameDay(_selectedDay!, day)
          ? null
          : day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final searching = _query.trim().isNotEmpty;
    final monthViews = ref.watch(
      monthViewsProvider((_month.year, _month.month)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextField(
              key: searchFieldKey,
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: l10n.searchClear,
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (searching)
              ..._buildSearchResults(context)
            else ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: weekButtonKey,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.week),
                  icon: const Icon(Icons.view_week_outlined),
                  label: Text(l10n.weekButton),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.previousMonth,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _shiftMonth(-1),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        materialL10n.formatMonthYear(_month),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.nextMonth,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _shiftMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MonthGrid(
                month: _month,
                markedDays: {
                  for (final v in monthViews.value ?? const <EntryView>[])
                    v.entry.day.day,
                },
                selectedDay: _selectedDay,
                onDaySelected: _selectDay,
              ),
              const SizedBox(height: 24),
              ..._buildMonthList(context, monthViews),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final results = ref.watch(searchViewsProvider(_query.trim()));
    return switch (results) {
      AsyncData(value: final list) when list.isEmpty => [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            l10n.noSearchResults,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
      AsyncData(value: final list) => [
        Text(
          l10n.searchResultCount(list.length),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final result in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: switch (result) {
              EntrySearchResult() => EntryTile(
                view: result.view,
                showDate: true,
                snippet: result.snippet,
                jumpTo: result.jumpTo,
              ),
              BookSearchResult() => BookSearchTile(
                book: result.book,
                snippet: result.snippet,
              ),
            },
          ),
      ],
      AsyncError() => [Text(l10n.startError)],
      _ => [
        Center(
          child: Semantics(
            label: l10n.loadingLabel,
            child: const CircularProgressIndicator(),
          ),
        ),
      ],
    };
  }

  List<Widget> _buildMonthList(
    BuildContext context,
    AsyncValue<List<EntryView>> monthViews,
  ) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selectedDay;
    final all = monthViews.value ?? const <EntryView>[];
    final list = selected == null
        ? all
        : all.where((v) => isSameDay(v.day, selected)).toList();
    final heading = selected == null
        ? materialL10n.formatMonthYear(_month)
        : materialL10n.formatFullDate(selected);
    return [
      Row(
        children: [
          Expanded(child: Text(heading, style: theme.textTheme.titleSmall)),
          if (selected != null)
            TextButton(
              onPressed: () => setState(() => _selectedDay = null),
              child: Text(l10n.showWholeMonth),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (monthViews.isLoading && !monthViews.hasValue)
        Center(
          child: Semantics(
            label: l10n.loadingLabel,
            child: const CircularProgressIndicator(),
          ),
        )
      else if (list.isEmpty)
        Text(
          selected == null ? l10n.noEntriesThisMonth : l10n.noEntriesThisDay,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      else
        for (final view in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EntryTile(view: view, showDate: selected == null),
          ),
    ];
  }
}
