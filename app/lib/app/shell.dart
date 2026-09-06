import 'package:flutter/material.dart';

import '../features/einstellungen/settings_screen.dart';
import '../features/heute/today_screen.dart';
import '../features/kalender/calendar_screen.dart';
import '../l10n/app_localizations.dart';

/// Hauptansicht mit unterer Leiste: Heute, Kalender (mit Suche), Einstellungen.
/// Die Reiter behalten ihren Zustand über einen [IndexedStack].
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [TodayScreen(), CalendarScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_twilight_outlined),
            selectedIcon: const Icon(Icons.wb_twilight),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
