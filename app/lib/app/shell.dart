import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_lock.dart';
import '../features/einstellungen/settings_screen.dart';
import '../features/heute/quick_note_sheet.dart';
import '../features/heute/today_screen.dart';
import '../features/kalender/calendar_screen.dart';
import '../features/mehr/more_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/platform_features.dart';
import 'routes.dart';

/// Widget-Keys der Reiter in der unteren Leiste (für Tests).
const Key navTodayKey = Key('nav-today');
const Key navCalendarKey = Key('nav-calendar');
const Key navMoreKey = Key('nav-more');
const Key navSettingsKey = Key('nav-settings');

/// Hauptansicht mit unterer Leiste: Heute, Kalender (mit Suche), Mehr (Wege,
/// Lesebuch, Zitate, Woche, Backup) und Einstellungen.
/// Die Reiter behalten ihren Zustand über einen [IndexedStack]. Der Wechsel
/// selbst ist bewusst ohne Animation: Er passiert dutzende Male am Tag.
/// Die Leiste sitzt auf einer Haarlinie statt eines Schattens. Eine
/// Schnellaktion des Starts (Manifest-Shortcut "Aufnehmen", "Sprachnotiz",
/// "Kurznotiz" oder "Schreiben") öffnet nach dem ersten Frame direkt die
/// passende Route oder das Blatt; ist die App gesperrt (D23), wartet sie bis
/// nach dem Entsperren.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  /// Gemerkte Schnellaktion, bis die App entsperrt ist.
  StartAction? _pendingAction;

  @override
  void initState() {
    super.initState();
    final action = ref.read(platformFeaturesProvider).takeStartAction();
    if (action == null) return;
    _pendingAction = action;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPendingAction());
    ref.listenManual(appLockProvider, (_, _) => _runPendingAction());
  }

  /// Führt die gemerkte Aktion aus, sobald der Sperrzustand bekannt und die
  /// App nicht gesperrt ist; sonst bleibt sie gemerkt.
  void _runPendingAction() {
    final action = _pendingAction;
    if (action == null || !mounted) return;
    final lock = ref.read(appLockProvider).value;
    if (lock == null || (lock.enabled && lock.locked)) return;
    _pendingAction = null;
    // Nach dem Entsperren erst den Frame abwarten, in dem der Sperrbildschirm
    // verschwindet; die Route soll nicht unter ihm aufgehen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (action) {
        case StartAction.record:
          AppRoutes.openRecording(context);
        case StartAction.quickVoice:
          AppRoutes.openRecording(context, quick: true);
        case StartAction.quickText:
          showQuickNoteSheet(context);
        case StartAction.write:
          AppRoutes.openWrite(context, LocalDay.forMoment(DateTime.now()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          CalendarScreen(),
          MoreScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              key: navTodayKey,
              icon: const Icon(Icons.wb_twilight_outlined),
              selectedIcon: const Icon(Icons.wb_twilight),
              label: l10n.navToday,
            ),
            NavigationDestination(
              key: navCalendarKey,
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: l10n.navCalendar,
            ),
            NavigationDestination(
              key: navMoreKey,
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view),
              label: l10n.navMore,
            ),
            NavigationDestination(
              key: navSettingsKey,
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
