import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'chapter_parser.dart';
import 'model.dart';

/// Ein geöffnetes EPUB (D25): Metadaten, Kapitel in Spine-Reihenfolge und
/// der einmal entpackte ZIP-Inhalt im Speicher. Kapitel werden erst beim
/// ersten Zugriff geparst und dann gehalten ([blocksOf]).
///
/// Es wird nichts auf das Dateisystem geschrieben; die Bytes kommen aus dem
/// verschlüsselten Dateispeicher der App und bleiben im Arbeitsspeicher.
class EpubDocument {
  EpubDocument._(this.book, this._files);

  /// Höchstens 50 MB je Datei (D25 Punkt 2).
  static const int maxFileBytes = 50 * 1024 * 1024;

  final EpubBook book;
  final Map<String, ArchiveFile> _files;
  final Map<int, List<EpubBlock>> _cache = {};

  int get chapterCount => book.chapters.length;

  /// Öffnet ein EPUB aus [bytes]. Wirft [EpubException] mit
  /// [EpubError.tooLarge] über [maxBytes], [EpubError.encrypted] bei
  /// kopiergeschützten Inhalten und [EpubError.invalid] bei allem, was kein
  /// lesbares EPUB ist.
  static EpubDocument open(Uint8List bytes, {int maxBytes = maxFileBytes}) {
    if (bytes.length > maxBytes) {
      throw const EpubException(
        EpubError.tooLarge,
        'Datei ist größer als erlaubt',
      );
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } on Object catch (e) {
      throw EpubException(EpubError.invalid, 'Kein lesbares ZIP: $e');
    }
    final files = <String, ArchiveFile>{};
    for (final f in archive) {
      if (!f.isFile) continue;
      files[normalizePath(f.name)] = f;
    }
    if (files.isEmpty) {
      throw const EpubException(EpubError.invalid, 'ZIP ist leer');
    }
    _checkEncryption(files);
    final opfPath = _findOpfPath(files);
    final opfDir = _dirOf(opfPath);
    final XmlDocument opf;
    try {
      opf = XmlDocument.parse(_utf8(files[opfPath]!));
    } on Object catch (e) {
      throw EpubException(EpubError.invalid, 'OPF nicht lesbar: $e');
    }
    final book = _readOpf(opf, files, opfDir);
    return EpubDocument._(book, files);
  }

  /// Die Blöcke des Kapitels [index]; beim ersten Aufruf geparst.
  List<EpubBlock> blocksOf(int index) {
    final cached = _cache[index];
    if (cached != null) return cached;
    final chapter = book.chapters[index];
    final file = _files[chapter.href];
    final blocks = file == null
        ? const <EpubBlock>[]
        : ChapterParser(
            resolveResource: (href) => _resource(chapter.href, href),
          ).parse(_utf8(file));
    _cache[index] = blocks;
    return blocks;
  }

  /// Ob das Kapitel schon geparst wurde (für Tests und die Anzeige).
  bool isParsed(int index) => _cache.containsKey(index);

  /// Rohbytes einer Ressource relativ zur Datei [fromHref] oder `null`.
  Uint8List? _resource(String fromHref, String href) {
    final path = resolveHref(_dirOf(fromHref), href);
    final file = _files[path];
    if (file == null) return null;
    final content = file.content;
    return content is Uint8List
        ? content
        : Uint8List.fromList(content as List<int>);
  }

  // ----- Kopf: container.xml, OPF -----------------------------------------

  static void _checkEncryption(Map<String, ArchiveFile> files) {
    final enc = files['META-INF/encryption.xml'];
    if (enc == null) return;
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(_utf8(enc));
    } on Object {
      // Unlesbares encryption.xml: lieber ablehnen als raten.
      throw const EpubException(
        EpubError.encrypted,
        'encryption.xml ist nicht lesbar',
      );
    }
    for (final ref in doc.findAllElements('CipherReference', namespace: '*')) {
      final uri = ref.getAttribute('URI') ?? '';
      if (!_isFontPath(uri)) {
        throw EpubException(
          EpubError.encrypted,
          'Inhaltsdatei "$uri" ist verschlüsselt (DRM)',
        );
      }
    }
    // Nur verschleierte Schriften (IDPF-Verfahren): kein DRM, lesbar, weil die
    // App die Schriften des Buchs ohnehin nicht verwendet.
  }

  static bool _isFontPath(String uri) {
    final lower = uri.toLowerCase().split('?').first;
    return lower.endsWith('.otf') ||
        lower.endsWith('.ttf') ||
        lower.endsWith('.woff') ||
        lower.endsWith('.woff2');
  }

  static String _findOpfPath(Map<String, ArchiveFile> files) {
    final container = files['META-INF/container.xml'];
    if (container != null) {
      try {
        final doc = XmlDocument.parse(_utf8(container));
        for (final rf in doc.findAllElements('rootfile', namespace: '*')) {
          final path = rf.getAttribute('full-path');
          if (path != null && files.containsKey(normalizePath(path))) {
            return normalizePath(path);
          }
        }
      } on XmlException {
        // Fällt unten auf die Suche nach einer OPF-Datei zurück.
      }
    }
    final any = files.keys.where((k) => k.toLowerCase().endsWith('.opf'));
    if (any.isEmpty) {
      throw const EpubException(EpubError.invalid, 'Keine OPF-Datei im EPUB');
    }
    return any.first;
  }

  static EpubBook _readOpf(
    XmlDocument opf,
    Map<String, ArchiveFile> files,
    String opfDir,
  ) {
    String? meta(String name) {
      final e = opf.findAllElements(name, namespace: '*').firstOrNull;
      final t = e?.innerText.trim();
      return t == null || t.isEmpty ? null : t;
    }

    final title = meta('title') ?? 'Ohne Titel';
    final author = meta('creator');
    final language = meta('language');

    // Manifest: id -> (Pfad, Medientyp, Eigenschaften)
    final items = <String, ({String href, String type, String props})>{};
    for (final item in opf.findAllElements('item', namespace: '*')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id == null || href == null) continue;
      items[id] = (
        href: resolveHref(opfDir, href),
        type: item.getAttribute('media-type') ?? '',
        props: item.getAttribute('properties') ?? '',
      );
    }

    // Spine: Reihenfolge der Kapitel.
    final spine = opf.findAllElements('spine', namespace: '*').firstOrNull;
    final hrefs = <String>[];
    if (spine != null) {
      for (final ref in spine.findElements('itemref', namespace: '*')) {
        final id = ref.getAttribute('idref');
        final item = id == null ? null : items[id];
        if (item == null) continue;
        if (!files.containsKey(item.href)) continue;
        if (!_isContentType(item.type, item.href)) continue;
        hrefs.add(item.href);
      }
    }
    if (hrefs.isEmpty) {
      throw const EpubException(EpubError.invalid, 'EPUB ohne Kapitel');
    }

    // Kapiteltitel: NAV (EPUB 3), ersatzweise NCX (EPUB 2).
    var titles = <String, String>{};
    final nav = items.values
        .where((i) => i.props.split(' ').contains('nav'))
        .firstOrNull;
    if (nav != null && files.containsKey(nav.href)) {
      titles = _titlesFromNav(_utf8(files[nav.href]!), _dirOf(nav.href));
    }
    if (titles.isEmpty) {
      final tocId = spine?.getAttribute('toc');
      var ncx = tocId == null ? null : items[tocId];
      ncx ??= items.values
          .where((i) => i.type == 'application/x-dtbncx+xml')
          .firstOrNull;
      if (ncx != null && files.containsKey(ncx.href)) {
        titles = _titlesFromNcx(_utf8(files[ncx.href]!), _dirOf(ncx.href));
      }
    }

    return EpubBook(
      title: title,
      author: author,
      language: language,
      chapters: [
        for (final (i, href) in hrefs.indexed)
          EpubChapter(index: i, href: href, title: titles[href]),
      ],
    );
  }

  static bool _isContentType(String type, String href) {
    if (type.contains('xhtml') || type.contains('html')) return true;
    if (type.isNotEmpty) return false;
    final lower = href.toLowerCase();
    return lower.endsWith('.xhtml') ||
        lower.endsWith('.html') ||
        lower.endsWith('.htm');
  }

  /// `nav[epub:type=toc]` → `a href` → Text; der erste Eintrag je Datei
  /// (ohne Fragment) gewinnt.
  static Map<String, String> _titlesFromNav(String xhtml, String dir) {
    final titles = <String, String>{};
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(xhtml);
    } on XmlException {
      return titles;
    }
    Iterable<XmlElement> navs = doc.findAllElements('nav', namespace: '*');
    final toc = navs.where((n) {
      final type = n.attributes
          .where((a) => a.name.local == 'type')
          .map((a) => a.value)
          .firstOrNull;
      return type == 'toc';
    });
    if (toc.isNotEmpty) navs = toc;
    for (final nav in navs) {
      for (final a in nav.findAllElements('a', namespace: '*')) {
        final href = a.getAttribute('href');
        if (href == null) continue;
        final path = resolveHref(dir, href.split('#').first);
        final text = _collapse(a.innerText);
        if (text.isEmpty) continue;
        titles.putIfAbsent(path, () => text);
      }
      if (titles.isNotEmpty) break;
    }
    return titles;
  }

  static Map<String, String> _titlesFromNcx(String xml, String dir) {
    final titles = <String, String>{};
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(xml);
    } on XmlException {
      return titles;
    }
    for (final point in doc.findAllElements('navPoint', namespace: '*')) {
      final label = point
          .findElements('navLabel', namespace: '*')
          .firstOrNull
          ?.findElements('text', namespace: '*')
          .firstOrNull
          ?.innerText;
      final src = point
          .findElements('content', namespace: '*')
          .firstOrNull
          ?.getAttribute('src');
      if (label == null || src == null) continue;
      final text = _collapse(label);
      if (text.isEmpty) continue;
      titles.putIfAbsent(resolveHref(dir, src.split('#').first), () => text);
    }
    return titles;
  }

  // ----- Pfade --------------------------------------------------------------

  /// Entfernt führende `/` und `./`, löst `..` auf.
  static String normalizePath(String path) {
    final parts = <String>[];
    for (final p in path.replaceAll('\\', '/').split('/')) {
      if (p.isEmpty || p == '.') continue;
      if (p == '..') {
        if (parts.isNotEmpty) parts.removeLast();
        continue;
      }
      parts.add(p);
    }
    return parts.join('/');
  }

  /// Löst [href] (prozentkodiert erlaubt, ohne Fragment) relativ zu [dir].
  static String resolveHref(String dir, String href) {
    var h = href.split('#').first.split('?').first;
    try {
      h = Uri.decodeComponent(h);
    } on ArgumentError {
      // Ungültige Kodierung: Pfad wie geschrieben verwenden.
    }
    if (h.startsWith('/')) return normalizePath(h);
    return normalizePath(dir.isEmpty ? h : '$dir/$h');
  }

  static String _dirOf(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i);
  }

  static String _utf8(ArchiveFile file) {
    final content = file.content;
    final bytes = content is Uint8List
        ? content
        : Uint8List.fromList(content as List<int>);
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
