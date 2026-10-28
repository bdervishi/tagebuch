/// EPUB-Parser des Sprach-Tagebuchs (D25).
///
/// Reines Dart ohne Flutter und ohne Netzwerkzugriff: [EpubDocument.open]
/// entpackt das ZIP im Speicher, liest `container.xml`, OPF und NAV oder NCX
/// und liefert je Kapitel beim ersten Zugriff eine Liste aus [EpubBlock]s
/// (Absatz, Überschrift, Zitat, Listenpunkt, Bild, Trennlinie) mit
/// Inline-Spans (fett, kursiv, Link-Text). Die Darstellung liegt in der App
/// (`features/reader`).
library;

export 'src/chapter_parser.dart' show ChapterParser, ResourceResolver;
export 'src/epub_document.dart';
export 'src/model.dart';
