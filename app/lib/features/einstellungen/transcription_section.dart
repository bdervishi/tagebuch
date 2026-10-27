import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_notifier.dart';
import '../../data/transcription_jobs.dart';
import '../../l10n/app_localizations.dart';

/// Widget-Keys für Tests.
const Key transcriptionSwitchKey = Key('settings-transcription-enabled');
const Key sttStatusTileKey = Key('settings-stt-status');
const Key sttLoadButtonKey = Key('settings-stt-load');

/// Abschnitt "Spracherkennung (experimentell)" der Einstellungen (W5):
/// Schalter "Transkription aktiv", Status der Engine (bereit, lädt mit
/// Fortschritt, nicht verfügbar mit Grund) und Hinweis auf Dauer und
/// Modellgröße. Eigene Datei, damit der Einstellungs-Bildschirm nur eine
/// Zeile ändert.
class TranscriptionEngineSection extends ConsumerWidget {
  const TranscriptionEngineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final status = ref.watch(sttStatusProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Semantics(
            header: true,
            child: Text(
              l10n.sectionSpeechRecognition,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        SwitchListTile(
          key: transcriptionSwitchKey,
          title: Text(l10n.transcriptionEnabled),
          subtitle: Text(l10n.transcriptionEnabledSubtitle),
          value: settings.transcriptionEnabled,
          onChanged: notifier.setTranscriptionEnabled,
        ),
        _StatusTile(status: status),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            l10n.sttModelNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends ConsumerWidget {
  const _StatusTile({required this.status});

  final SttStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = status;
    final String subtitle;
    IconData icon = Icons.hourglass_empty;
    Widget? trailing;
    if (s == null) {
      subtitle = l10n.loadingLabel;
    } else {
      switch (s.phase) {
        case SttPhase.none:
          subtitle = l10n.sttStatusNone;
          icon = Icons.mic_none;
        case SttPhase.idle:
          subtitle = l10n.sttStatusIdle;
          icon = Icons.download_outlined;
          trailing = TextButton(
            key: sttLoadButtonKey,
            onPressed: () =>
                ref.read(sttLoadRequestedProvider.notifier).request(),
            child: Text(l10n.sttLoadNow),
          );
        case SttPhase.loading:
          subtitle = l10n.sttStatusLoading((s.progress * 100).round());
          icon = Icons.downloading;
          // Bestimmt (kein Endlos-Kreisel), damit die Anzeige ruhig bleibt.
          trailing = SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: s.progress.clamp(0.0, 1.0),
              strokeWidth: 3,
            ),
          );
        case SttPhase.ready:
          final device = switch (s.device) {
            'webgpu' => l10n.sttDeviceWebGpu,
            'wasm' => l10n.sttDeviceWasm,
            _ => null,
          };
          subtitle = device == null
              ? l10n.sttStatusReady
              : l10n.sttStatusReadyDevice(device);
          icon = Icons.check_circle_outline;
        case SttPhase.unavailable:
          final reason = s.reason;
          subtitle = reason == null
              ? l10n.sttStatusUnavailable
              : l10n.sttStatusUnavailableReason(reason);
          icon = Icons.error_outline;
      }
    }
    return ListTile(
      key: sttStatusTileKey,
      leading: Icon(
        icon,
        color: s?.phase == SttPhase.unavailable ? scheme.error : null,
      ),
      title: Text(l10n.sttStatusTitle),
      subtitle: Text(subtitle),
      trailing: trailing,
      isThreeLine:
          s?.phase == SttPhase.unavailable || s?.phase == SttPhase.none,
    );
  }
}
