import 'package:diary_core/diary_core.dart';
import 'package:diary_epub/diary_epub.dart' as epub;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'reader_theme.dart';

/// Schriftstile des Readers (D25): aus dem `TextTheme` der App abgeleitet
/// (eine Schrift, Hierarchie über Gewicht und Größe, docs/12 Abschnitt 6),
/// skaliert mit der Einstellung `readerFontScale` und mit der gewählten
/// Zeilenhöhe. Die Systemschriftgröße wirkt zusätzlich über den
/// `textScaler`; 200 % müssen tragen.
@immutable
class ReaderTextStyles {
  const ReaderTextStyles({
    required this.body,
    required this.quote,
    required this.heading1,
    required this.heading2,
    required this.heading3,
    required this.caption,
  });

  factory ReaderTextStyles.of(
    TextTheme theme,
    ReaderPalette palette, {
    required double fontScale,
    required double lineHeight,
  }) {
    final baseSize = (theme.bodyLarge?.fontSize ?? 16) * fontScale;
    final body = (theme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: baseSize,
      height: lineHeight,
      color: palette.text,
    );
    TextStyle heading(double factor) =>
        (theme.titleLarge ?? const TextStyle()).copyWith(
          fontSize: baseSize * factor,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: palette.text,
        );
    return ReaderTextStyles(
      body: body,
      quote: body.copyWith(fontStyle: FontStyle.italic, color: palette.muted),
      heading1: heading(1.5),
      heading2: heading(1.3),
      heading3: heading(1.15),
      caption: body.copyWith(fontSize: baseSize * 0.85, color: palette.muted),
    );
  }

  final TextStyle body;
  final TextStyle quote;
  final TextStyle heading1;
  final TextStyle heading2;
  final TextStyle heading3;
  final TextStyle caption;

  TextStyle headingFor(int level) => switch (level) {
    1 => heading1,
    2 => heading2,
    _ => heading3,
  };
}

/// Eine hinterlegte Stelle in einem Block: Zeichen-Offsets und die Passage,
/// die beim Tipp erscheint.
@immutable
class HighlightRange {
  const HighlightRange({
    required this.start,
    required this.end,
    required this.passage,
  });

  final int start;
  final int end;
  final Passage passage;
}

/// Verteilt die Anker aller Passagen eines Kapitels auf Blockindizes. Ein
/// Anker über mehrere Blöcke hinterlegt den Startblock ab `start`, die
/// Blöcke dazwischen ganz und den Endblock bis `end`.
Map<int, List<HighlightRange>> highlightsFor(
  Iterable<Passage> passages,
  int chapterIndex,
  List<epub.EpubBlock> blocks,
) {
  final map = <int, List<HighlightRange>>{};
  for (final p in passages) {
    final a = p.anchor;
    if (a == null || a.chapterIndex != chapterIndex) continue;
    final first = a.blockIndex;
    final last = a.lastBlockIndex;
    if (first < 0 || first >= blocks.length) continue;
    for (var i = first; i <= last && i < blocks.length; i++) {
      final length = blocks[i].text.length;
      final start = i == first ? a.start.clamp(0, length) : 0;
      final end = i == last ? a.end.clamp(0, length) : length;
      if (end <= start) continue;
      map
          .putIfAbsent(i, () => [])
          .add(HighlightRange(start: start, end: end, passage: p));
    }
  }
  return map;
}

/// Ein Block des Kapitels als Widget. Textblöcke bauen ihre Spans mit
/// Hervorhebungen; ein Tipp auf eine Hervorhebung ruft [onHighlightTap].
class ReaderBlockView extends StatefulWidget {
  const ReaderBlockView({
    super.key,
    required this.block,
    required this.styles,
    required this.palette,
    required this.highlights,
    required this.onHighlightTap,
  });

  final epub.EpubBlock block;
  final ReaderTextStyles styles;
  final ReaderPalette palette;
  final List<HighlightRange> highlights;
  final ValueChanged<Passage> onHighlightTap;

  @override
  State<ReaderBlockView> createState() => _ReaderBlockViewState();
}

class _ReaderBlockViewState extends State<ReaderBlockView> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final block = widget.block;
    final styles = widget.styles;
    final palette = widget.palette;
    return switch (block) {
      epub.Heading(:final level) => Padding(
        padding: EdgeInsets.only(top: level == 1 ? 24 : 18, bottom: 8),
        child: _rich(block, styles.headingFor(level)),
      ),
      epub.Paragraph() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _rich(block, styles.body),
      ),
      epub.Quote() => Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: palette.muted.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: _rich(block, styles.quote),
          ),
        ),
      ),
      epub.ListItem(:final ordinal) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectionContainer.disabled(
              child: SizedBox(
                width: 28,
                child: Text(
                  ordinal == null ? '•' : '$ordinal.',
                  style: styles.body,
                ),
              ),
            ),
            Expanded(child: _rich(block, styles.body)),
          ],
        ),
      ),
      epub.ImageBlock(:final bytes, :final alt) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Semantics(
          image: true,
          label: alt ?? AppLocalizations.of(context).readerImage,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) => Text(
                alt ?? AppLocalizations.of(context).readerImage,
                style: styles.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      epub.Divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
        child: Container(
          height: 1,
          color: palette.muted.withValues(alpha: 0.6),
        ),
      ),
    };
  }

  Widget _rich(epub.EpubTextBlock block, TextStyle base) => Text.rich(
    TextSpan(
      style: base,
      children: buildReaderSpans(
        block.spans,
        widget.highlights,
        highlightColor: widget.palette.highlight,
        onHighlightTap: widget.onHighlightTap,
        recognizers: _recognizers,
      ),
    ),
  );
}

/// Baut die Inline-Spans eines Blocks: Auszeichnung aus dem Buch (fett,
/// kursiv, Link als Unterstreichung ohne Ziel) und darüber die Hervorhebungen
/// als Hintergrund mit Tipp-Erkenner. Die erzeugten Erkenner landen in
/// [recognizers]; der Aufrufer entsorgt sie.
List<InlineSpan> buildReaderSpans(
  List<epub.EpubSpan> spans,
  List<HighlightRange> highlights, {
  required Color highlightColor,
  required ValueChanged<Passage> onHighlightTap,
  required List<TapGestureRecognizer> recognizers,
}) {
  // Schnittpunkte: Grenzen der Spans und der Hervorhebungen.
  final cuts = <int>{0};
  var pos = 0;
  final spanStarts = <int>[];
  for (final s in spans) {
    spanStarts.add(pos);
    pos += s.text.length;
    cuts.add(pos);
  }
  final total = pos;
  for (final h in highlights) {
    cuts.add(h.start.clamp(0, total));
    cuts.add(h.end.clamp(0, total));
  }
  final sorted = cuts.toList()..sort();
  final out = <InlineSpan>[];
  for (var i = 0; i + 1 < sorted.length; i++) {
    final a = sorted[i];
    final b = sorted[i + 1];
    if (b <= a) continue;
    // Span, der a enthält.
    var spanIndex = 0;
    for (var k = spans.length - 1; k >= 0; k--) {
      if (spanStarts[k] <= a) {
        spanIndex = k;
        break;
      }
    }
    final span = spans[spanIndex];
    final text = span.text.substring(
      a - spanStarts[spanIndex],
      b - spanStarts[spanIndex],
    );
    final highlight = highlights
        .where((h) => h.start <= a && h.end >= b)
        .firstOrNull;
    TapGestureRecognizer? recognizer;
    if (highlight != null) {
      recognizer = TapGestureRecognizer()
        ..onTap = () => onHighlightTap(highlight.passage);
      recognizers.add(recognizer);
    }
    out.add(
      TextSpan(
        text: text,
        recognizer: recognizer,
        style: span.isPlain && highlight == null
            ? null
            : TextStyle(
                fontWeight: span.bold ? FontWeight.w600 : null,
                fontStyle: span.italic ? FontStyle.italic : null,
                decoration: span.link ? TextDecoration.underline : null,
                backgroundColor: highlight == null ? null : highlightColor,
              ),
      ),
    );
  }
  return out;
}
