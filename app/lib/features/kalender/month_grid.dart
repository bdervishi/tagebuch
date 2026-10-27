import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../data/day.dart';
import '../../l10n/app_localizations.dart';

/// Key der Zelle eines Tages: `calendar-day-JJJJ-MM-TT`.
Key calendarDayKey(DateTime day) => Key('calendar-day-${dayKey(day)}');

/// Key der Markierung eines Tages mit Eintrag: `calendar-marker-JJJJ-MM-TT`.
Key calendarMarkerKey(DateTime day) => Key('calendar-marker-${dayKey(day)}');

/// Monatsraster ohne Fremdpaket. Tage mit Eintrag sind farbig hinterlegt,
/// fett und mit einem Punkt versehen (Farbe ist nie der einzige Träger,
/// docs/03 Abschnitt 9, Punkt 5); der Screenreader hört "Eintrag vorhanden".
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.markedDays,
    required this.onDaySelected,
    this.selectedDay,
  });

  /// Erster Tag des angezeigten Monats.
  final DateTime month;

  /// Tage (1 bis 31) mit mindestens einem Eintrag.
  final Set<int> markedDays;

  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final materialL10n = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final todayDay = dayOf(DateTime.now());

    final firstWeekday = materialL10n.firstDayOfWeekIndex; // 0 = Sonntag
    final weekdayLabels = [
      for (var i = 0; i < 7; i++)
        materialL10n.narrowWeekdays[(firstWeekday + i) % 7],
    ];
    // DateTime.weekday: 1 = Montag ... 7 = Sonntag; auf 0 = Sonntag abbilden.
    final leadingBlanks = ((month.weekday % 7) - firstWeekday + 7) % 7;
    final dayCount = daysInMonth(month);
    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= dayCount; day++)
        _DayCell(
          date: DateTime(month.year, month.month, day),
          marked: markedDays.contains(day),
          isToday: isSameDay(todayDay, DateTime(month.year, month.month, day)),
          isSelected:
              selectedDay != null &&
              isSameDay(selectedDay!, DateTime(month.year, month.month, day)),
          onTap: onDaySelected,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: cells,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.calendarLegend,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.marked,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool marked;
  final bool isToday;
  final bool isSelected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = materialL10n.formatFullDate(date);
    final semanticsLabel = marked
        ? l10n.calendarDayWithEntry(dateLabel)
        : l10n.calendarDayWithoutEntry(dateLabel);

    final background = isSelected
        ? scheme.primary
        : marked
        ? scheme.primaryContainer
        : Colors.transparent;
    final foreground = isSelected
        ? scheme.onPrimary
        : marked
        ? scheme.onPrimaryContainer
        : scheme.onSurface;

    return Semantics(
      key: calendarDayKey(date),
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: background,
            animationDuration: Motion.quick,
            shape: CircleBorder(
              side: isToday
                  ? BorderSide(color: scheme.primary, width: 1.5)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onTap(date),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: marked ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    height: 8,
                    child: marked
                        ? Container(
                            key: calendarMarkerKey(date),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: foreground,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
