import 'package:diary_epub/diary_epub.dart' as epub;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import 'reader_theme.dart';

/// Widget-Keys für Tests.
const Key readerFontSmallerKey = Key('reader-font-smaller');
const Key readerFontLargerKey = Key('reader-font-larger');
const Key readerLineTighterKey = Key('reader-line-tighter');
const Key readerLineLooserKey = Key('reader-line-looser');

/// Key eines Kapitels im Inhaltsverzeichnis.
Key readerTocItemKey(int index) => Key('reader-toc-$index');

/// Key eines Farbschemas im Blatt "Darstellung".
Key readerThemeKey(ReaderTheme theme) => Key('reader-theme-${theme.name}');

/// Titel eines Kapitels für die Anzeige: aus NAV/NCX oder "Kapitel n".
String chapterTitle(AppLocalizations l10n, epub.EpubBook book, int index) =>
    book.chapters[index].title ?? l10n.readerChapterFallback(index + 1);

/// Blatt "Inhalt" (D25): alle Kapitel, das aktuelle hervorgehoben; ein Tipp
/// liefert den Kapitelindex.
Future<int?> showReaderContents(
  BuildContext context, {
  required epub.EpubBook book,
  required int current,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                l10n.readerContents,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: book.chapters.length,
                itemBuilder: (context, i) => ListTile(
                  key: readerTocItemKey(i),
                  selected: i == current,
                  leading: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  title: Text(chapterTitle(l10n, book, i)),
                  onTap: () => Navigator.of(context).pop(i),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Blatt "Darstellung" (D25): Schriftgröße (A-/A+), Zeilenabstand und
/// Farben. Jede Änderung wirkt sofort im Reader und wird als Einstellung
/// gespeichert.
Future<void> showReaderDisplaySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => const _DisplaySheet(),
  );
}

class _DisplaySheet extends ConsumerWidget {
  const _DisplaySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final labelStyle = theme.textTheme.titleSmall;
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.readerDisplay, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _StepperRow(
            label: l10n.readerFontSize,
            labelStyle: labelStyle,
            value: '${(settings.readerFontScale * 100).round()} %',
            valueStyle: valueStyle,
            decreaseKey: readerFontSmallerKey,
            increaseKey: readerFontLargerKey,
            decreaseTooltip: l10n.readerFontSmaller,
            increaseTooltip: l10n.readerFontLarger,
            decreaseIcon: Icons.text_decrease,
            increaseIcon: Icons.text_increase,
            canDecrease:
                settings.readerFontScale > AppSettings.readerFontScaleMin,
            canIncrease:
                settings.readerFontScale < AppSettings.readerFontScaleMax,
            onDecrease: () => notifier.setReaderFontScale(
              settings.readerFontScale - AppSettings.readerFontScaleStep,
            ),
            onIncrease: () => notifier.setReaderFontScale(
              settings.readerFontScale + AppSettings.readerFontScaleStep,
            ),
          ),
          const SizedBox(height: 8),
          _StepperRow(
            label: l10n.readerLineHeight,
            labelStyle: labelStyle,
            value: settings.readerLineHeight.toStringAsFixed(1),
            valueStyle: valueStyle,
            decreaseKey: readerLineTighterKey,
            increaseKey: readerLineLooserKey,
            decreaseTooltip: l10n.readerLineTighter,
            increaseTooltip: l10n.readerLineLooser,
            decreaseIcon: Icons.density_small,
            increaseIcon: Icons.density_large,
            canDecrease:
                settings.readerLineHeight > AppSettings.readerLineHeightMin,
            canIncrease:
                settings.readerLineHeight < AppSettings.readerLineHeightMax,
            onDecrease: () => notifier.setReaderLineHeight(
              settings.readerLineHeight - AppSettings.readerLineHeightStep,
            ),
            onIncrease: () => notifier.setReaderLineHeight(
              settings.readerLineHeight + AppSettings.readerLineHeightStep,
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.readerColors, style: labelStyle),
          const SizedBox(height: 8),
          SegmentedButton<ReaderTheme>(
            segments: [
              for (final t in ReaderTheme.values)
                ButtonSegment(
                  value: t,
                  label: Text(_themeLabel(l10n, t), key: readerThemeKey(t)),
                ),
            ],
            selected: {settings.readerTheme},
            showSelectedIcon: false,
            onSelectionChanged: (s) => notifier.setReaderTheme(s.first),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(AppLocalizations l10n, ReaderTheme t) =>
      switch (t) {
        ReaderTheme.system => l10n.readerThemeSystem,
        ReaderTheme.light => l10n.readerThemeLight,
        ReaderTheme.dark => l10n.readerThemeDark,
        ReaderTheme.sepia => l10n.readerThemeSepia,
      };
}

/// Eine Zeile: Beschriftung, Wert, Minus- und Plus-Taste (mindestens 48 dp).
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.labelStyle,
    required this.value,
    required this.valueStyle,
    required this.decreaseKey,
    required this.increaseKey,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.decreaseIcon,
    required this.increaseIcon,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final TextStyle? labelStyle;
  final String value;
  final TextStyle? valueStyle;
  final Key decreaseKey;
  final Key increaseKey;
  final String decreaseTooltip;
  final String increaseTooltip;
  final IconData decreaseIcon;
  final IconData increaseIcon;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: decreaseKey,
          tooltip: decreaseTooltip,
          icon: Icon(decreaseIcon),
          onPressed: canDecrease ? onDecrease : null,
        ),
        IconButton.filledTonal(
          key: increaseKey,
          tooltip: increaseTooltip,
          icon: Icon(increaseIcon),
          onPressed: canIncrease ? onIncrease : null,
        ),
      ],
    );
  }
}
