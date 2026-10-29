import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/settings_notifier.dart';
import '../../data/transcription_jobs.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/surface_card.dart';

/// Widget-Keys für Tests.
const Key sttStatusCardKey = Key('stt-status-card');
const Key sttRetryKey = Key('stt-retry');

/// Leise Karte auf "Heute", solange die Spracherkennung noch nicht bereit
/// ist: beim einmaligen Laden des Modells mit Fortschritt ("danach ohne
/// Internet") und wenn das Laden scheiterte, mit Grund und "Erneut
/// versuchen" (ohne Netz: Hinweis, dass der erste Download Internet
/// braucht). Bereit, aus oder nicht eingebaut: nichts. Die Karte ist der
/// Grund, warum eine frische Aufnahme noch keinen Text zeigt; deshalb steht
/// sie nahe der Aufnahmetaste.
class SttStatusCard extends ConsumerWidget {
  const SttStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(sttStatusProvider).value;
    final enabled =
        ref.watch(settingsProvider).value?.transcriptionEnabled ?? true;
    if (status == null || !enabled) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Widget body;
    switch (status.phase) {
      case SttPhase.loading:
        final percent = (status.progress * 100).round();
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title(icon: Icons.downloading, text: l10n.sttCardLoadingTitle),
            const SizedBox(height: 8),
            Text(
              l10n.sttCardLoadingBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: status.progress.clamp(0.0, 1.0)),
                duration: Motion.quick,
                curve: Motion.easeOut,
                builder: (context, value, _) =>
                    LinearProgressIndicator(value: value, minHeight: 6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.sttStatusLoading(percent),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        );
      case SttPhase.unavailable:
        final online = ref.watch(platformFeaturesProvider).isOnline;
        final raw = status.reason;
        // Technische Gründe der Engine in einen Satz übersetzen; unbekannte
        // bleiben wörtlich (die Einstellungen zeigen sie immer wörtlich).
        final reason = raw == null
            ? null
            : (friendlySttReason(l10n, raw) ?? raw);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title(
              icon: Icons.mic_off_outlined,
              text: l10n.sttCardUnavailableTitle,
            ),
            const SizedBox(height: 8),
            Text(
              !online
                  ? l10n.sttCardOfflineBody
                  : reason == null
                  ? l10n.sttCardUnavailableBody
                  : l10n.sttCardUnavailableReason(reason),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: sttRetryKey,
                onPressed: () => ref.read(sttRetryProvider.notifier).retry(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.sttRetry),
              ),
            ),
          ],
        );
      case SttPhase.none:
      case SttPhase.idle:
      case SttPhase.ready:
        return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        key: sttStatusCardKey,
        color: scheme.surfaceContainerLow,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: body,
      ),
    );
  }
}

/// Übersetzt bekannte Fehlertexte der Browser-Erkennung (transformers.js,
/// fetch) in einen verständlichen Satz; `null` für unbekannte.
String? friendlySttReason(AppLocalizations l10n, String reason) {
  final r = reason.toLowerCase();
  if (r.contains('not found locally') || r.contains('404')) {
    return l10n.sttReasonMissingFiles;
  }
  if (r.contains('failed to fetch') ||
      r.contains('load failed') ||
      r.contains('networkerror') ||
      r.contains('network error')) {
    return l10n.sttReasonNetwork;
  }
  return null;
}

class _Title extends StatelessWidget {
  const _Title({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
      ],
    );
  }
}
