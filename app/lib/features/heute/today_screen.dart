import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/diary_entry.dart';
import '../../data/entries_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/entry_tile.dart';

/// Widget-Key der großen Aufnahmetaste (für Tests).
const Key recordButtonKey = Key('record-button');

/// Startbildschirm: große Aufnahmetaste, darunter der heutige Eintrag.
/// Zustand statt Mahnung: kein Zähler, keine Kette (docs/03 Abschnitt 3).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final day = today();
    final todaysEntries = ref.watch(entriesProvider).onDay(day);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              materialL10n.formatFullDate(day),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: _RecordButton(
                onPressed: () => AppRoutes.openRecording(context),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ExcludeSemantics(
                child: Text(
                  l10n.recordButtonLabel,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.localOnlyHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (todaysEntries.isEmpty)
              Text(
                l10n.todayNoEntry,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(l10n.todayEntriesHeading, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final entry in todaysEntries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EntryTile(entry: entry),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Die eine große Taste: deutlich größer als 48 dp, mit Semantik-Label.
class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l10n.recordButtonSemantics,
      child: Material(
        key: recordButtonKey,
        color: scheme.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 144,
            height: 144,
            child: ExcludeSemantics(
              child: Icon(Icons.mic, size: 64, color: scheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
