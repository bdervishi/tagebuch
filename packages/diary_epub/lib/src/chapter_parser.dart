import 'dart:typed_data';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import 'model.dart';

/// Liefert die Bytes einer Ressource (Bild) zu einem `href` relativ zur
/// Kapiteldatei oder `null`, wenn sie fehlt.
typedef ResourceResolver = Uint8List? Function(String href);

/// Macht aus dem XHTML eines Kapitels eine Liste von [EpubBlock]s (D25).
///
/// Block-Elemente (`p`, `h1` bis `h6`, `blockquote`, `li`, `hr`, `img`,
/// `pre`, Tabellenzellen) werden zu Blöcken, Inline-Elemente (`em`, `i`,
/// `strong`, `b`, `a`, `span`, `code`, `sup`, `sub`) zu Spans. `script`,
/// `style`, `head`, `svg` ohne Bild und alles Unbekannte ohne Text werden
/// ignoriert. Der HTML-Parser löst Entitäten auf; Leerraum wird auf ein
/// Zeichen zusammengezogen und an Blockgrenzen entfernt.
class ChapterParser {
  const ChapterParser({required this.resolveResource});

  final ResourceResolver resolveResource;

  List<EpubBlock> parse(String xhtml) {
    final doc = html.parse(xhtml);
    final body = doc.body ?? doc.documentElement;
    final out = _Collector(resolveResource);
    if (body != null) out.walk(body, const _Style());
    out.flush();
    return out.blocks;
  }
}

/// Gerade wirksame Inline-Auszeichnung beim Abstieg in den Baum.
class _Style {
  const _Style({this.bold = false, this.italic = false, this.link = false});
  final bool bold;
  final bool italic;
  final bool link;

  _Style copyWith({bool? bold, bool? italic, bool? link}) => _Style(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    link: link ?? this.link,
  );
}

/// Welcher Block gerade entsteht.
enum _Kind { paragraph, heading, quote, listItem }

class _Collector {
  _Collector(this._resolve);

  final ResourceResolver _resolve;
  final List<EpubBlock> blocks = [];
  final List<EpubSpan> _spans = [];
  _Kind _kind = _Kind.paragraph;
  int _headingLevel = 1;
  int? _ordinal;
  int _quoteDepth = 0;

  /// Zähler der umgebenden geordneten Listen (innerste zuletzt).
  final List<int?> _listCounters = [];

  static const _skip = {
    'script',
    'style',
    'head',
    'title',
    'meta',
    'link',
    'noscript',
    'template',
    'iframe',
    'object',
    'audio',
    'video',
    'canvas',
    'math',
  };

  static const _blockish = {
    'p',
    'div',
    'section',
    'article',
    'aside',
    'header',
    'footer',
    'main',
    'nav',
    'figure',
    'figcaption',
    'address',
    'dl',
    'dt',
    'dd',
    'table',
    'thead',
    'tbody',
    'tfoot',
    'tr',
    'td',
    'th',
    'caption',
    'details',
    'summary',
    'center',
    'body',
    'html',
  };

  void walk(dom.Node node, _Style style) {
    if (node is dom.Text) {
      _addText(node.data, style);
      return;
    }
    if (node is! dom.Element) {
      for (final child in node.nodes) {
        walk(child, style);
      }
      return;
    }
    final tag = (node.localName ?? '').toLowerCase();
    if (_skip.contains(tag)) return;
    switch (tag) {
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        flush();
        _kind = _Kind.heading;
        _headingLevel = (int.parse(tag.substring(1))).clamp(1, 3);
        _children(node, style);
        flush();
      case 'blockquote':
        flush();
        _quoteDepth++;
        _children(node, style);
        flush();
        _quoteDepth--;
      case 'ol':
        flush();
        _listCounters.add(_startOf(node));
        _children(node, style);
        flush();
        _listCounters.removeLast();
      case 'ul':
        flush();
        _listCounters.add(null);
        _children(node, style);
        flush();
        _listCounters.removeLast();
      case 'li':
        flush();
        _kind = _Kind.listItem;
        if (_listCounters.isNotEmpty) {
          final n = _listCounters.last;
          if (n != null) {
            _ordinal = n;
            _listCounters[_listCounters.length - 1] = n + 1;
          }
        }
        _children(node, style);
        flush();
      case 'hr':
        flush();
        blocks.add(const Divider());
      case 'br':
        // Zeilenumbruch im Absatz: als Leerzeichen, der Reader fließt neu.
        _addText(' ', style);
      case 'img':
        _image(node.attributes['src'], node.attributes['alt']);
      case 'image':
        // SVG-Bild: `xlink:href` oder `href`.
        String? href;
        for (final entry in node.attributes.entries) {
          final key = entry.key.toString();
          if (key == 'href' || key.endsWith(':href') || key.endsWith('href')) {
            href = entry.value;
          }
        }
        _image(href, null);
      case 'svg':
        // Nur eingebettete Bilder daraus; Vektorgrafik selbst wird nicht
        // gezeichnet.
        for (final img in node.querySelectorAll('image')) {
          walk(img, style);
        }
      case 'pre':
        flush();
        _children(node, style, preformatted: true);
        flush();
      case 'em' || 'i' || 'cite' || 'dfn' || 'var':
        _children(node, style.copyWith(italic: true));
      case 'strong' || 'b':
        _children(node, style.copyWith(bold: true));
      case 'a':
        _children(
          node,
          style.copyWith(link: node.attributes.containsKey('href')),
        );
      default:
        if (_blockish.contains(tag)) {
          flush();
          _children(node, style);
          flush();
        } else {
          // span, small, sup, sub, code, abbr, q, mark, u, s, …
          _children(node, style);
        }
    }
  }

  void _children(dom.Element e, _Style style, {bool preformatted = false}) {
    for (final child in e.nodes) {
      if (preformatted && child is dom.Text) {
        // Vorformatierter Text: Zeilen als eigene Absätze.
        final lines = child.data.split('\n');
        for (final (i, line) in lines.indexed) {
          if (i > 0) flush();
          if (line.trim().isNotEmpty) _spans.add(EpubSpan(line.trimRight()));
        }
        continue;
      }
      walk(child, style);
    }
  }

  static int _startOf(dom.Element ol) {
    final s = ol.attributes['start'];
    return s == null ? 1 : (int.tryParse(s.trim()) ?? 1);
  }

  void _image(String? src, String? alt) {
    if (src == null || src.trim().isEmpty) return;
    if (src.startsWith('data:') || src.contains('://')) return;
    final bytes = _resolve(src.trim());
    if (bytes == null || bytes.isEmpty) return;
    flush();
    final cleanAlt = alt == null ? null : _collapse(alt);
    blocks.add(
      ImageBlock(
        bytes: bytes,
        mimeType: _mimeFor(src),
        alt: cleanAlt == null || cleanAlt.isEmpty ? null : cleanAlt,
      ),
    );
  }

  static String? _mimeFor(String src) {
    final lower = src.toLowerCase().split('?').first;
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return null;
  }

  void _addText(String raw, _Style style) {
    // Leerraum normalisieren: beliebige Folgen zu einem Leerzeichen.
    var text = raw.replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return;
    if (_spans.isEmpty) {
      text = text.trimLeft();
      if (text.isEmpty) return;
    } else if (text == ' ' && _spans.last.text.endsWith(' ')) {
      return;
    }
    final last = _spans.isEmpty ? null : _spans.last;
    final span = EpubSpan(
      text,
      bold: style.bold,
      italic: style.italic,
      link: style.link,
    );
    if (last != null &&
        last.bold == span.bold &&
        last.italic == span.italic &&
        last.link == span.link) {
      _spans[_spans.length - 1] = last.copyWith(text: last.text + text);
    } else {
      _spans.add(span);
    }
  }

  /// Schließt den entstehenden Block ab, wenn er Text hat.
  void flush() {
    if (_spans.isNotEmpty) {
      final last = _spans.last;
      final trimmed = last.text.trimRight();
      if (trimmed.isEmpty) {
        _spans.removeLast();
      } else if (trimmed.length != last.text.length) {
        _spans[_spans.length - 1] = last.copyWith(text: trimmed);
      }
    }
    if (_spans.isNotEmpty) {
      final spans = List<EpubSpan>.unmodifiable(_spans);
      final EpubBlock block = switch (_kind) {
        _Kind.heading => Heading(_headingLevel, spans),
        _Kind.listItem => ListItem(spans, ordinal: _ordinal),
        _Kind.quote => Quote(spans),
        _Kind.paragraph => _quoteDepth > 0 ? Quote(spans) : Paragraph(spans),
      };
      blocks.add(block);
    }
    _spans.clear();
    _kind = _Kind.paragraph;
    _ordinal = null;
  }

  static String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
