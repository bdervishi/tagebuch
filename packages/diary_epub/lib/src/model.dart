import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Ein Stück Text innerhalb eines Blocks mit seiner Auszeichnung (D25). Links
/// werden nur als Text wiedergegeben; die App öffnet nichts (D14).
@immutable
class EpubSpan {
  const EpubSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.link = false,
  });

  final String text;
  final bool bold;
  final bool italic;

  /// Text eines `<a href>`; nur zur Kennzeichnung, kein Ziel.
  final bool link;

  bool get isPlain => !bold && !italic && !link;

  EpubSpan copyWith({String? text}) =>
      EpubSpan(text ?? this.text, bold: bold, italic: italic, link: link);

  @override
  bool operator ==(Object other) =>
      other is EpubSpan &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.link == link;

  @override
  int get hashCode => Object.hash(text, bold, italic, link);

  @override
  String toString() =>
      'EpubSpan("$text"${bold ? ' bold' : ''}${italic ? ' italic' : ''}'
      '${link ? ' link' : ''})';
}

/// Ein Block eines Kapitels. Der Reader zeigt Blöcke untereinander; Anker
/// von Passagen zeigen auf den Blockindex und Zeichen-Offsets im [text].
sealed class EpubBlock {
  const EpubBlock();

  /// Reiner Text des Blocks (Spans aneinander), für Anker und Suche; bei
  /// Bildern der Alternativtext, bei Trennlinien leer.
  String get text;
}

/// Block mit Inline-Spans (Absatz, Überschrift, Zitat, Listenpunkt).
sealed class EpubTextBlock extends EpubBlock {
  const EpubTextBlock(this.spans);

  final List<EpubSpan> spans;

  @override
  String get text => spans.map((s) => s.text).join();
}

class Paragraph extends EpubTextBlock {
  const Paragraph(super.spans);

  @override
  String toString() => 'Paragraph("$text")';
}

class Heading extends EpubTextBlock {
  const Heading(this.level, super.spans)
    : assert(level >= 1 && level <= 3, 'Ebene 1 bis 3');

  /// 1 bis 3; h4 bis h6 werden auf 3 abgebildet.
  final int level;

  @override
  String toString() => 'Heading($level, "$text")';
}

class Quote extends EpubTextBlock {
  const Quote(super.spans);

  @override
  String toString() => 'Quote("$text")';
}

class ListItem extends EpubTextBlock {
  const ListItem(super.spans, {this.ordinal});

  /// Nummer in einer geordneten Liste, `null` bei Aufzählungspunkten.
  final int? ordinal;

  @override
  String toString() => 'ListItem(${ordinal ?? '•'}, "$text")';
}

/// Bild aus dem EPUB; die Bytes stammen aus dem ZIP und wurden nie auf das
/// Dateisystem geschrieben.
class ImageBlock extends EpubBlock {
  const ImageBlock({required this.bytes, this.mimeType, this.alt});

  final Uint8List bytes;
  final String? mimeType;
  final String? alt;

  @override
  String get text => alt ?? '';

  @override
  String toString() => 'ImageBlock(${bytes.length} B, alt "$alt")';
}

class Divider extends EpubBlock {
  const Divider();

  @override
  String get text => '';

  @override
  String toString() => 'Divider';
}

/// Ein Kapitel in Spine-Reihenfolge: Titel aus NAV oder NCX (sonst `null`,
/// die App zeigt dann "Kapitel n") und der Pfad der Inhaltsdatei im ZIP.
@immutable
class EpubChapter {
  const EpubChapter({required this.index, required this.href, this.title});

  final int index;
  final String href;
  final String? title;

  @override
  String toString() => 'EpubChapter($index, "$href", "$title")';
}

/// Metadaten eines EPUB (OPF `dc:title`, `dc:creator`, `dc:language`).
@immutable
class EpubBook {
  const EpubBook({
    required this.title,
    required this.chapters,
    this.author,
    this.language,
  });

  final String title;
  final String? author;
  final String? language;

  /// Kapitel in Leserichtung (Spine).
  final List<EpubChapter> chapters;
}

/// Woran das Öffnen gescheitert ist.
enum EpubError {
  /// Kein ZIP, kein `container.xml`, kein OPF, keine Kapitel.
  invalid,

  /// `META-INF/encryption.xml` verschlüsselt Inhaltsdateien (DRM). Die App
  /// umgeht nichts (D25 Punkt 5).
  encrypted,

  /// Größer als die erlaubte Dateigröße.
  tooLarge,
}

class EpubException implements Exception {
  const EpubException(this.error, this.message);

  final EpubError error;
  final String message;

  @override
  String toString() => 'EpubException(${error.name}): $message';
}
