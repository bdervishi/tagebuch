import 'dart:async';

import 'package:diary_core/diary_core.dart';
import 'package:diary_epub/diary_epub.dart' as epub;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectionStatus;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../data/books_view.dart';
import '../../data/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/pressable.dart';
import '../lesebuch/book_detail_screen.dart' show quoteIdForPassage;
import '../lesebuch/passage_editor_sheet.dart';
import '../zitate/quote_library.dart';
import 'reader_blocks.dart';
import 'reader_sheets.dart';
import 'reader_theme.dart';

/// Widget-Keys für Tests.
const Key readerBackKey = Key('reader-back');
const Key readerContentsKey = Key('reader-contents');
const Key readerDisplayKey = Key('reader-display');
const Key readerBarKey = Key('reader-bar');
const Key readerProgressKey = Key('reader-progress');
const Key readerPassageQuoteKey = Key('reader-passage-quote');
const Key readerPassageEditKey = Key('reader-passage-edit');
const Key readerPassageDeleteKey = Key('reader-passage-delete');

/// Key der Seite eines Kapitels.
Key readerPageKey(int index) => Key('reader-page-$index');

/// Key eines Blocks (Kapitel, Block).
Key readerBlockKey(int chapter, int block) =>
    Key('reader-block-$chapter-$block');

/// Kennung des eigenen Zitats aus einer Markierung im Reader ohne Passage
/// (D20, D25): dieselbe Stelle wird nur einmal gemerkt.
String quoteIdForSelection(String bookId, String text) =>
    'reader-$bookId-${text.hashCode.toRadixString(16)}';

/// Der E-Reader (D25, Route `/read`): Vollbild ohne untere Leiste, ruhige
/// Fläche in der gewählten Farbstimmung, Kapitel als wischbare Seiten mit
/// Scroll innerhalb des Kapitels, dünner Fortschrittsbalken oben, Leiste
/// (Zurück, Titel, Kapitel x von y, Inhalt, Darstellung), die ein Tipp in
/// die Mitte ein- und ausblendet. Text ist markierbar; die Werkzeugleiste
/// bietet "Passage festhalten" und "Als Zitat merken". Markierte Passagen
/// erscheinen hinterlegt. Die Leseposition wird entprellt gespeichert.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.bookId});

  final String bookId;

  /// Wartezeit, bis eine geänderte Leseposition gespeichert wird.
  static const Duration saveDelay = Duration(milliseconds: 600);

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  PageController? _pages;
  int _chapter = 0;
  double _fraction = 0;
  int _block = 0;
  bool _barVisible = true;
  bool _hasSelection = false;
  bool _highlightTapped = false;
  bool _restored = false;
  Timer? _saveTimer;
  ReadingPosition? _lastSaved;
  ReadingPosition? _initial;
  Offset? _downPosition;
  DateTime? _downAt;

  /// Schreibende Aktionen, im `build` gemerkt: `ref` darf im `dispose`
  /// nicht mehr benutzt werden.
  late BookActions _actions;

  @override
  void dispose() {
    _saveTimer?.cancel();
    final pending = _position;
    // Beim Verlassen sofort merken und die Ansichten dahinter auffrischen;
    // auf das Ergebnis wartet niemand.
    unawaited(
      _actions.finishReading(
        widget.bookId,
        pending == _lastSaved ? null : pending,
      ),
    );
    _pages?.dispose();
    super.dispose();
  }

  ReadingPosition? _positionFor(int chapterCount) {
    if (chapterCount == 0) return null;
    final progress = ((_chapter + _fraction) / chapterCount).clamp(0.0, 1.0);
    return ReadingPosition(
      chapterIndex: _chapter,
      blockIndex: _block,
      progress: progress,
    );
  }

  int _chapterCount = 0;
  ReadingPosition? get _position => _positionFor(_chapterCount);

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(ReaderScreen.saveDelay, () {
      final position = _position;
      if (position == null || position == _lastSaved) return;
      _lastSaved = position;
      unawaited(_actions.saveReadingPosition(widget.bookId, position));
    });
  }

  void _onChapterChanged(int index) {
    setState(() {
      _chapter = index;
      _fraction = 0;
      _block = 0;
    });
    _scheduleSave();
  }

  void _onScroll(int chapter, int block, double fraction) {
    if (chapter != _chapter) return;
    final changed = (fraction - _fraction).abs() > 0.002 || block != _block;
    _fraction = fraction;
    _block = block;
    if (changed) {
      // Nur der Balken braucht den neuen Wert; die Seite scrollt selbst.
      setState(() {});
      _scheduleSave();
    }
  }

  void _goTo(int index) {
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    if (Motion.reduced(context)) {
      pages.jumpToPage(index);
    } else {
      pages.animateToPage(
        index,
        duration: Motion.page,
        curve: Motion.easeInOut,
      );
    }
  }

  void _toggleBar() => setState(() => _barVisible = !_barVisible);

  /// Wischen nach links oder rechts wechselt das Kapitel; ein kurzer Tipp in
  /// die Mitte blendet die Leiste um. Beides über rohe Zeigerereignisse,
  /// weil die markierbare Fläche (`SelectionArea`) auf Android waagerechte
  /// Züge für sich beansprucht und ein `PageView` darunter sie nie sähe.
  /// Tipps auf Hervorhebungen und zum Aufheben einer Markierung bleiben
  /// unberührt.
  void _onPointerUp(PointerUpEvent event, Size size) {
    final down = _downPosition;
    final at = _downAt;
    _downPosition = null;
    _downAt = null;
    if (down == null || at == null) return;
    final delta = event.position - down;
    final elapsed = DateTime.now().difference(at);
    if (delta.dx.abs() > _swipeDistance &&
        delta.dx.abs() > delta.dy.abs() * 2 &&
        elapsed < const Duration(milliseconds: 700)) {
      if (_hasSelection) return;
      final target = _chapter + (delta.dx < 0 ? 1 : -1);
      if (target >= 0 && target < _chapterCount) _goTo(target);
      return;
    }
    if (delta.distance > 10) return;
    if (elapsed > const Duration(milliseconds: 300)) return;
    final p = event.localPosition;
    final inCenter =
        p.dx > size.width * 0.2 &&
        p.dx < size.width * 0.8 &&
        p.dy > size.height * 0.25 &&
        p.dy < size.height * 0.75;
    if (!inCenter || _hasSelection) return;
    // Der Tipp-Erkenner einer Hervorhebung meldet sich im selben Durchlauf;
    // erst danach entscheiden.
    scheduleMicrotask(() {
      if (!mounted) return;
      if (!_highlightTapped) _toggleBar();
      _highlightTapped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _actions = ref.read(bookActionsProvider);
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final palette = ReaderPalette.of(
      settings.readerTheme,
      Theme.of(context).brightness,
    );
    final bookState = ref.watch(bookViewProvider(widget.bookId));
    final docState = ref.watch(readerDocumentProvider(widget.bookId));
    final view = bookState.value;
    final doc = docState.value;

    if (view != null && !_restored) {
      _restored = true;
      _initial = view.book.readingPosition;
      _chapter = _initial?.chapterIndex ?? 0;
      _lastSaved = _initial;
    }
    if (doc != null && _restored) {
      // Erst wenn Buch (Leseposition) und Datei da sind, damit die erste
      // Seite das Lesezeichen trifft.
      _chapterCount = doc.chapterCount;
      if (_chapter >= doc.chapterCount) _chapter = 0;
      _pages ??= PageController(initialPage: _chapter);
    }

    final Widget body;
    if (docState.hasError) {
      body = _Message(
        docState.error is epub.EpubException
            ? l10n.readerFileBroken
            : l10n.startError,
        palette: palette,
      );
    } else if (view == null || docState.isLoading) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: palette.muted),
            const SizedBox(height: 16),
            Text(l10n.readerOpening, style: TextStyle(color: palette.muted)),
          ],
        ),
      );
    } else if (doc == null) {
      body = _Message(l10n.readerNoFile, palette: palette);
    } else {
      final book = view.book;
      body = LayoutBuilder(
        builder: (context, constraints) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            _downPosition = e.position;
            _downAt = DateTime.now();
          },
          onPointerCancel: (_) {
            _downPosition = null;
            _downAt = null;
          },
          onPointerUp: (e) => _onPointerUp(e, constraints.biggest),
          child: PageView.builder(
            controller: _pages,
            // Der Wechsel kommt aus dem Listener oben (Wischen), nicht aus
            // der eigenen Geste des PageView.
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doc.chapterCount,
            onPageChanged: _onChapterChanged,
            itemBuilder: (context, index) => _ChapterPage(
              key: readerPageKey(index),
              book: book,
              document: doc,
              chapter: index,
              passages: view.passages,
              palette: palette,
              settings: settings,
              topInset: MediaQuery.paddingOf(context).top + _barHeight,
              initialFraction:
                  _initial != null && index == _initial!.chapterIndex
                  ? _initial!.progress * doc.chapterCount - index
                  : 0,
              onScroll: (block, fraction) => _onScroll(index, block, fraction),
              onSelectionChanged: (has) => _hasSelection = has,
              onHighlightTapped: () => _highlightTapped = true,
            ),
          ),
        ),
      );
    }

    final progress = doc == null || doc.chapterCount == 0
        ? 0.0
        : ((_chapter + _fraction) / doc.chapterCount).clamp(0.0, 1.0);
    final reduced = Motion.reduced(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          // Leiste oben: erscheint und verschwindet auf demselben Weg.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_barVisible,
              child: AnimatedSlide(
                offset: _barVisible || reduced
                    ? Offset.zero
                    : const Offset(0, -0.3),
                duration: Motion.enter,
                curve: Motion.easeOut,
                child: AnimatedOpacity(
                  opacity: _barVisible ? 1 : 0,
                  duration: Motion.enter,
                  curve: Motion.easeOut,
                  child: _ReaderBar(
                    key: readerBarKey,
                    palette: palette,
                    title: view?.book.title ?? '',
                    subtitle: doc == null
                        ? null
                        : l10n.readerChapterOf(_chapter + 1, doc.chapterCount),
                    progress: progress,
                    onBack: () => Navigator.of(context).maybePop(),
                    onContents: doc == null
                        ? null
                        : () async {
                            final target = await showReaderContents(
                              context,
                              book: doc.book,
                              current: _chapter,
                            );
                            if (target != null && mounted) _goTo(target);
                          },
                    onDisplay: () => showReaderDisplaySheet(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Höhe der oberen Leiste ohne Safe Area.
const double _barHeight = 64;

/// Mindestweg eines Wischens zum Kapitelwechsel.
const double _swipeDistance = 80;

class _Message extends StatelessWidget {
  const _Message(this.text, {required this.palette});

  final String text;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: palette.text),
      ),
    ),
  );
}

/// Obere Leiste: Zurück, Titel und Kapitel, Inhalt, Darstellung; darüber der
/// dünne Fortschrittsbalken.
class _ReaderBar extends StatelessWidget {
  const _ReaderBar({
    super.key,
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.onBack,
    required this.onContents,
    required this.onDisplay,
  });

  final ReaderPalette palette;
  final String title;
  final String? subtitle;
  final double progress;
  final VoidCallback onBack;
  final VoidCallback? onContents;
  final VoidCallback onDisplay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    return ColoredBox(
      color: palette.bar,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: l10n.readerProgress((progress * 100).round()),
              child: LinearProgressIndicator(
                key: readerProgressKey,
                value: progress,
                minHeight: 2,
                backgroundColor: palette.muted.withValues(alpha: 0.25),
                color: palette.text.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(
              height: _barHeight - 2,
              child: Row(
                children: [
                  Pressable(
                    child: IconButton(
                      key: readerBackKey,
                      tooltip: materialL10n.backButtonTooltip,
                      icon: const Icon(Icons.arrow_back),
                      color: palette.text,
                      onPressed: onBack,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: palette.text,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.muted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Pressable(
                    child: IconButton(
                      key: readerContentsKey,
                      tooltip: l10n.readerContents,
                      icon: const Icon(Icons.list),
                      color: palette.text,
                      onPressed: onContents,
                    ),
                  ),
                  Pressable(
                    child: IconButton(
                      key: readerDisplayKey,
                      tooltip: l10n.readerDisplay,
                      icon: const Icon(Icons.text_fields),
                      color: palette.text,
                      onPressed: onDisplay,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Kapitelseite: die Blöcke des Kapitels in einer Liste, markierbar;
/// Hervorhebungen aus den Passagen des Buchs; Werkzeugleiste mit "Passage
/// festhalten" und "Als Zitat merken"; meldet die Scrollposition.
class _ChapterPage extends ConsumerStatefulWidget {
  const _ChapterPage({
    super.key,
    required this.book,
    required this.document,
    required this.chapter,
    required this.passages,
    required this.palette,
    required this.settings,
    required this.topInset,
    required this.initialFraction,
    required this.onScroll,
    required this.onSelectionChanged,
    required this.onHighlightTapped,
  });

  final Book book;
  final epub.EpubDocument document;
  final int chapter;
  final List<Passage> passages;
  final ReaderPalette palette;
  final AppSettings settings;
  final double topInset;

  /// Anteil im Kapitel, zu dem beim ersten Aufbau gesprungen wird.
  final double initialFraction;
  final void Function(int block, double fraction) onScroll;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onHighlightTapped;

  @override
  ConsumerState<_ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends ConsumerState<_ChapterPage> {
  final ScrollController _scroll = ScrollController();
  final Map<int, SelectionListenerNotifier> _notifiers = {};
  List<epub.EpubBlock> _blocks = const [];
  bool _jumped = false;

  /// Zuletzt gemeldeter Text der Markierung (die Region selbst gibt ihn
  /// nicht heraus).
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _blocks = widget.document.blocksOf(widget.chapter);
    _scroll.addListener(_report);
    if (widget.initialFraction > 0.001) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
    } else {
      _jumped = true;
    }
  }

  void _restore() {
    if (!mounted || _jumped || !_scroll.hasClients) return;
    _jumped = true;
    final max = _scroll.position.maxScrollExtent;
    if (max > 0) {
      _scroll.jumpTo((widget.initialFraction.clamp(0.0, 1.0)) * max);
    }
  }

  void _report() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final fraction = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    final block = _blocks.isEmpty
        ? 0
        : (fraction * (_blocks.length - 1)).round();
    widget.onScroll(block, fraction);
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final n in _notifiers.values) {
      n.dispose();
    }
    super.dispose();
  }

  SelectionListenerNotifier _notifierFor(int block) =>
      _notifiers.putIfAbsent(block, SelectionListenerNotifier.new);

  /// Anker aus der Markierung: erster und letzter Block mit Auswahl samt
  /// Zeichen-Offsets; ersatzweise die erste Fundstelle des Texts.
  PassageAnchor? _anchorFor(String text) {
    int? firstBlock;
    int? lastBlock;
    var start = 0;
    var end = 0;
    final indices = _notifiers.keys.toList()..sort();
    for (final i in indices) {
      final n = _notifiers[i]!;
      if (!n.registered) continue;
      final selection = n.selection;
      if (selection.status == SelectionStatus.none) continue;
      final range = selection.range;
      if (range == null) continue;
      if (firstBlock == null) {
        firstBlock = i;
        start = range.startOffset;
      }
      lastBlock = i;
      end = range.endOffset;
    }
    final excerpt = text.length > 80 ? text.substring(0, 80) : text;
    if (firstBlock != null && lastBlock != null) {
      return PassageAnchor(
        chapterIndex: widget.chapter,
        blockIndex: firstBlock,
        start: start,
        end: end,
        endBlockIndex: lastBlock == firstBlock ? null : lastBlock,
        excerpt: excerpt,
      );
    }
    final needle = text.split('\n').first.trim();
    if (needle.isEmpty) return null;
    for (final (i, b) in _blocks.indexed) {
      final at = b.text.indexOf(needle);
      if (at >= 0) {
        return PassageAnchor(
          chapterIndex: widget.chapter,
          blockIndex: i,
          start: at,
          end: at + needle.length,
          excerpt: excerpt,
        );
      }
    }
    return null;
  }

  Future<void> _keepPassage(SelectableRegionState state) async {
    final text = _selectedText.trim();
    if (text.isEmpty) return;
    final anchor = _anchorFor(text);
    state.hideToolbar();
    state.clearSelection();
    final l10n = AppLocalizations.of(context);
    await showPassageEditorSheet(
      context,
      bookId: widget.book.id,
      initialText: text,
      initialPage: l10n.readerChapterPage(widget.chapter + 1),
      anchor: anchor,
    );
  }

  Future<void> _quoteSelection(SelectableRegionState state) async {
    final text = _selectedText.trim();
    if (text.isEmpty) return;
    state.hideToolbar();
    state.clearSelection();
    await _addQuote(quoteIdForSelection(widget.book.id, text), text);
  }

  Future<void> _addQuote(String id, String text) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final settings = await ref.read(settingsProvider.future);
    messenger.hideCurrentSnackBar();
    if (settings.ownQuotes.any((q) => q.id == id)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.passageQuotedAlready)),
      );
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .addOwnQuote(
          Quote(
            id: id,
            author: widget.book.attribution,
            de: text,
            en: text,
            own: true,
          ),
        );
    messenger.showSnackBar(SnackBar(content: Text(l10n.passageQuoted)));
  }

  Widget _toolbar(BuildContext context, SelectableRegionState state) {
    final l10n = AppLocalizations.of(context);
    final copy = state.contextMenuButtonItems
        .where((b) => b.type == ContextMenuButtonType.copy)
        .firstOrNull;
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: [
        ?copy,
        ContextMenuButtonItem(
          label: l10n.passageAdd,
          onPressed: () => _keepPassage(state),
        ),
        ContextMenuButtonItem(
          label: l10n.passageQuote,
          onPressed: () => _quoteSelection(state),
        ),
      ],
    );
  }

  Future<void> _showPassage(Passage passage) async {
    widget.onHighlightTapped();
    final action = await showModalBottomSheet<_PassageAction>(
      context: context,
      useSafeArea: true,
      builder: (context) => _PassageSheet(passage: passage),
    );
    if (!mounted) return;
    switch (action) {
      case _PassageAction.edit:
        await showPassageEditorSheet(
          context,
          bookId: widget.book.id,
          existing: passage,
        );
      case _PassageAction.quote:
        await _addQuote(quoteIdForPassage(passage.id), passage.text);
      case _PassageAction.delete:
        await ref.read(bookActionsProvider).deletePassage(passage.id);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final styles = ReaderTextStyles.of(
      theme.textTheme,
      widget.palette,
      fontScale: widget.settings.readerFontScale,
      lineHeight: widget.settings.readerLineHeight,
    );
    final highlights = highlightsFor(widget.passages, widget.chapter, _blocks);
    if (_blocks.isEmpty) {
      return _Message(l10n.readerEmptyChapter, palette: widget.palette);
    }
    return SelectionArea(
      contextMenuBuilder: _toolbar,
      onSelectionChanged: (content) {
        _selectedText = content?.plainText ?? '';
        widget.onSelectionChanged(_selectedText.isNotEmpty);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView.builder(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              24,
              widget.topInset + 8,
              24,
              MediaQuery.paddingOf(context).bottom + 48,
            ),
            itemCount: _blocks.length,
            itemBuilder: (context, i) {
              final block = _blocks[i];
              final view = ReaderBlockView(
                key: readerBlockKey(widget.chapter, i),
                block: block,
                styles: styles,
                palette: widget.palette,
                highlights: highlights[i] ?? const [],
                onHighlightTap: _showPassage,
              );
              if (block is! epub.EpubTextBlock) return view;
              return SelectionListener(
                selectionNotifier: _notifierFor(i),
                child: view,
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _PassageAction { edit, quote, delete }

/// Blatt zu einer hinterlegten Passage: Text, Seite, Gedanke; bearbeiten,
/// als Zitat merken, löschen. Liefert die gewählte Aktion; ausgeführt wird
/// sie von der Kapitelseite, deren Kontext bestehen bleibt.
class _PassageSheet extends ConsumerWidget {
  const _PassageSheet({required this.passage});

  final Passage passage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quoted =
        ref
            .watch(settingsProvider)
            .value
            ?.ownQuotes
            .any((q) => q.id == quoteIdForPassage(passage.id)) ??
        false;
    final thought = passage.thought;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.readerHighlightTitle, style: theme.textTheme.titleLarge),
          if (passage.page != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.passagePage(passage.page!),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            passage.text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
          if (thought != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    thought,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                key: readerPassageQuoteKey,
                onPressed: () =>
                    Navigator.of(context).pop(_PassageAction.quote),
                icon: Icon(
                  quoted ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                ),
                label: Text(l10n.passageQuote),
              ),
              const Spacer(),
              IconButton(
                key: readerPassageEditKey,
                tooltip: l10n.passageEdit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).pop(_PassageAction.edit),
              ),
              IconButton(
                key: readerPassageDeleteKey,
                tooltip: l10n.passageDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    Navigator.of(context).pop(_PassageAction.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
