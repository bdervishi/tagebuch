import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/day.dart';
import '../../data/diary_entry.dart';
import '../../data/entries_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/entry_tile.dart';
import 'month_grid.dart';

/// Key des Suchfelds (für Tests).
const Key searchFieldKey = Key('calendar-search');

/// Kalender und Suche: Monatsraster mit markierten Tagen, darunter die
/// Einträge des Monats oder des gewählten Tags; ein Suchtext filtert über
/// alle Transkripte (In-Memory-Platzhalter für FTS5).
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
    final entries = ref.watch(entriesProvider);
    final searching = _query.trim().isNotEmpty;

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
              ..._buildSearchResults(context, entries.search(_query))
            else ...[
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
                markedDays: entries.daysWithEntriesIn(_month),
                selectedDay: _selectedDay,
                onDaySelected: _selectDay,
              ),
              const SizedBox(height: 24),
              ..._buildMonthList(context, entries),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults(
    BuildContext context,
    List<DiaryEntry> results,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (results.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            l10n.noSearchResults,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ];
    }
    return [
      Text(
        l10n.searchResultCount(results.length),
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      for (final entry in results)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EntryTile(entry: entry, showDate: true),
        ),
    ];
  }

  List<Widget> _buildMonthList(BuildContext context, List<DiaryEntry> entries) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selectedDay;
    final list = selected == null
        ? entries.inMonth(_month)
        : entries.onDay(selected);
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
      if (list.isEmpty)
        Text(
          selected == null ? l10n.noEntriesThisMonth : l10n.noEntriesThisDay,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      else
        for (final entry in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EntryTile(entry: entry, showDate: selected == null),
          ),
    ];
  }
}
