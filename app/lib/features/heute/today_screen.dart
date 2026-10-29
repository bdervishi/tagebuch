import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/day.dart';
import '../../data/entry_view.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/entry_tile.dart';
import '../../widgets/record_button.dart';
import '../../widgets/reveal.dart';
import '../../widgets/step_card.dart';
import '../bewegung/movement_card.dart';
import '../zitate/quote_card.dart';
import 'day_timeline.dart';
import 'quick_note_sheet.dart';
import 'stt_status_card.dart';

export '../../widgets/record_button.dart' show recordButtonKey;

/// Widget-Key der kleineren Aktion "Schreiben" (D17).
const Key writeButtonKey = Key('write-button');

/// Widget-Keys der kleinen Aktionen "Sprachnotiz" und "Kurznotiz" (D22).
const Key quickVoiceKey = Key('quick-voice');
const Key quickTextKey = Key('quick-text');

/// Startbildschirm: große Aufnahmetaste und die kleinere Aktion "Schreiben",
/// darunter die kleinen Aktionen "Sprachnotiz" und "Kurznotiz" (D22), die
/// Karte der Spracherkennung, solange das Modell lädt oder fehlt (W5), das
/// Zitat zum Tag (D20), "Dein Schritt für heute", die fällige Bewegungspause
/// "Zeit für Bewegung" (D24), der Tag als Zeitleiste
/// "Dein Tag" aus den Stücken des heutigen Eintrags (D22) und die Rückblicke
/// "Vor einem Jahr" und "Vor einem Monat". Wege, Lesebuch, Zitatenschatz,
/// Wochenrückblick und die Backup-Erinnerung liegen auf dem Reiter "Mehr",
/// damit der Start beim Sprechen bleibt. Zustand statt Mahnung: kein Zähler,
/// keine Kette (docs/03 Abschnitt 3, D17). Die Abschnitte erscheinen beim
/// Öffnen gestaffelt (einmal am Tag gesehen, blockiert nichts; docs/12).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = dayOf(DateTime.now());
    final today = ref.watch(todayViewProvider);
    final lookbacks = ref.watch(lookbackProvider).value ?? const <Lookback>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Reveal(
              index: 0,
              child: Column(
                children: [
                  Text(
                    materialL10n.formatFullDate(day),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  RecordButton(
                    onPressed: () {
                      // Mikrofon sofort in der Geste anfragen (Safari).
                      ref
                          .read(platformFeaturesProvider)
                          .requestMicrophoneEarly();
                      AppRoutes.openRecording(context);
                    },
                    semanticLabel: l10n.recordButtonSemantics,
                  ),
                  const SizedBox(height: 4),
                  ExcludeSemantics(
                    child: Text(
                      l10n.recordButtonLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.localOnlyHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Reveal(
              index: 1,
              child: Center(
                child: OutlinedButton.icon(
                  key: writeButtonKey,
                  onPressed: () => AppRoutes.openWrite(
                    context,
                    LocalDay.forMoment(DateTime.now()),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    l10n.writeButtonLabel,
                    semanticsLabel: l10n.writeButtonSemantics,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Stücke über den Tag (D22): klein und nebeneinander, damit die
            // Aufnahmetaste die Hauptaktion bleibt.
            Reveal(
              index: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    key: quickVoiceKey,
                    onPressed: () {
                      ref
                          .read(platformFeaturesProvider)
                          .requestMicrophoneEarly();
                      AppRoutes.openRecording(context, quick: true);
                    },
                    icon: const Icon(Icons.mic_none, size: 18),
                    label: Text(
                      l10n.quickVoiceButton,
                      semanticsLabel: l10n.quickVoiceSemantics,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    key: quickTextKey,
                    onPressed: () => showQuickNoteSheet(context),
                    icon: const Icon(Icons.short_text, size: 18),
                    label: Text(
                      l10n.quickTextButton,
                      semanticsLabel: l10n.quickTextSemantics,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Modell lädt oder fehlt (W5); bereit: nichts.
            const Reveal(index: 3, child: SttStatusCard()),
            const Reveal(index: 4, child: QuoteCard()),
            const Reveal(index: 5, child: StepCard()),
            // Fällige Bewegungspause (D24); fehlt ohne Pause.
            const Reveal(index: 6, child: MovementCard()),
            Reveal(
              index: 7,
              child: switch (today) {
                // Ohne Stücke (kein Eintrag oder nur interne Notizen wie
                // das Häkchen am Schritt) bleibt die leise Zeile.
                AsyncData(value: null) ||
                AsyncData(value: EntryView(items: [])) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.todayNoEntry,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AsyncData(value: final view?) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(l10n.todayTimelineHeading),
                    const SizedBox(height: 10),
                    DayTimeline(view: view),
                  ],
                ),
                AsyncError() => Text(
                  l10n.startError,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                _ => Center(
                  child: Semantics(
                    label: l10n.loadingLabel,
                    child: const CircularProgressIndicator(),
                  ),
                ),
              },
            ),
            for (final (i, lookback) in lookbacks.indexed)
              Reveal(
                index: 8 + i,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(switch (lookback.kind) {
                        LookbackKind.yearAgo => l10n.lookbackYearTitle,
                        LookbackKind.monthAgo => l10n.lookbackMonthTitle,
                      }, key: Key('lookback-${lookback.kind.name}')),
                      const SizedBox(height: 10),
                      EntryTile(view: lookback.view, showDate: true),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Abschnittsüberschrift: klein, gedämpft, leicht gesperrt.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
