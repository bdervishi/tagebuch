import 'dart:async';
import 'dart:math' as math;

import 'package:diary_core/diary_core.dart';

import 'codecs.dart';
import 'encrypted_record_store.dart';
import 'text_normalization.dart';
import 'web_repositories.dart';

/// Volltextsuche im Speicher (docs/10-pwa.md Abschnitt 4): Beim ersten
/// Suchen werden alle Transkripte, geschriebenen Texte (D17, ohne interne
/// Notizen) und Passagen samt Gedanken (D21) entschlüsselt geladen und
/// gefaltet (`ß → ss`, Kleinschreibung, Diakritika entfernt); Suchbegriffe
/// durchlaufen dieselbe Faltung, Teilworttreffer zählen, alle Begriffe müssen
/// vorkommen. Treffer in Transkripten tragen ein Sprungziel, Treffer in
/// Notizen keines; Treffer in Passagen tragen das Buch (`bookId`) und keinen
/// Eintrag. Jede Änderung im Store macht den Index ungültig; er wird beim
/// nächsten Suchen neu aufgebaut.
class WebSearchRepository implements SearchRepository {
  WebSearchRepository(this._store) {
    _subscription = _store.changes.listen((_) => _dirty = true);
  }

  /// Zeichen vor und nach dem ersten Treffer im Ausschnitt.
  static const int snippetContext = 60;

  final EncryptedRecordStore _store;
  StreamSubscription<String>? _subscription;
  List<_Document> _documents = const [];
  bool _dirty = true;

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Baut den Index neu auf (sonst geschieht das beim nächsten Suchen).
  Future<void> rebuild() async {
    final entries = {
      for (final m in await _store.getAll(Collections.entries))
        m['id'] as String: Codecs.decodeEntry(m),
    };
    final recordings = {
      for (final m in await _store.getAll(Collections.recordings))
        m['id'] as String: Codecs.decodeRecording(m),
    };
    final docs = <_Document>[];
    for (final m in await _store.getAll(Collections.transcripts)) {
      final t = Codecs.decodeTranscript(m);
      if (!t.isPrimary) continue;
      final r = recordings[t.recordingId];
      if (r == null) continue;
      final e = entries[r.entryId];
      if (e == null) continue;
      docs.add(
        _Document(
          journalId: e.journalId,
          day: e.day,
          entryId: e.id,
          text: t.text,
          at: r.startedAt,
          recordingId: r.id,
          segments: t.segments,
          folded: foldWithMap(t.text),
          foldedSegments: [for (final s in t.segments) foldForMatch(s.text)],
        ),
      );
    }
    for (final m in await _store.getAll(Collections.notes)) {
      final n = Codecs.decodeNote(m);
      if (n.isInternal || n.text.trim().isEmpty) continue;
      final e = entries[n.entryId];
      if (e == null) continue;
      docs.add(
        _Document(
          journalId: e.journalId,
          day: e.day,
          entryId: e.id,
          text: n.text,
          at: n.createdAt,
          folded: foldWithMap(n.text),
        ),
      );
    }
    final books = {
      for (final m in await _store.getAll(Collections.books))
        m['id'] as String: Codecs.decodeBook(m),
    };
    for (final m in await _store.getAll(Collections.passages)) {
      final p = Codecs.decodePassage(m);
      final b = books[p.bookId];
      if (b == null) continue;
      final text = passageSearchText(p);
      docs.add(
        _Document(
          journalId: b.journalId,
          day: p.day,
          bookId: b.id,
          text: text,
          at: p.createdAt,
          folded: foldWithMap(text),
        ),
      );
    }
    docs.sort((a, b) {
      final byDay = b.day.compareTo(a.day);
      if (byDay != 0) return byDay;
      return b.at.compareTo(a.at);
    });
    _documents = docs;
    _dirty = false;
  }

  /// Text einer Passage für die Suche: die Stelle und, getrennt durch einen
  /// Zeilenumbruch, der eigene Gedanke.
  static String passageSearchText(Passage p) {
    final thought = p.thought?.trim();
    return thought == null || thought.isEmpty ? p.text : '${p.text}\n$thought';
  }

  @override
  Future<List<SearchHit>> search(
    String query, {
    String? journalId,
    LocalDay? from,
    LocalDay? to,
  }) async {
    final terms = foldForMatch(query)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return const [];
    if (_dirty) await rebuild();
    final hits = <SearchHit>[];
    for (final doc in _documents) {
      if (journalId != null && doc.journalId != journalId) continue;
      if (from != null && doc.day.isBefore(from)) continue;
      if (to != null && doc.day.isAfter(to)) continue;
      final text = doc.folded.folded;
      var firstMatch = -1;
      var allFound = true;
      for (final term in terms) {
        final idx = text.indexOf(term);
        if (idx < 0) {
          allFound = false;
          break;
        }
        if (firstMatch < 0 || idx < firstMatch) firstMatch = idx;
      }
      if (!allFound) continue;
      hits.add(
        SearchHit(
          entryId: doc.entryId ?? '',
          day: doc.day,
          recordingId: doc.recordingId,
          snippet: _snippet(doc, firstMatch, terms),
          jumpTo: _jumpTo(doc, terms),
          bookId: doc.bookId,
        ),
      );
    }
    return hits;
  }

  /// Ausschnitt des Originaltexts rund um den ersten Treffer.
  static String _snippet(_Document doc, int foldedIndex, List<String> terms) {
    final original = doc.text;
    final start = doc.folded.toOriginal(foldedIndex);
    final end = doc.folded.toOriginal(foldedIndex + terms.first.length);
    final from = math.max(0, start - snippetContext);
    final to = math.min(original.length, end + snippetContext);
    final buffer = StringBuffer();
    if (from > 0) buffer.write('…');
    buffer.write(original.substring(from, to).trim());
    if (to < original.length) buffer.write('…');
    return buffer.toString();
  }

  /// Start des ersten Segments, dessen Text einen Begriff enthält.
  static Duration? _jumpTo(_Document doc, List<String> terms) {
    for (var i = 0; i < doc.foldedSegments.length; i++) {
      final seg = doc.foldedSegments[i];
      if (terms.any(seg.contains)) return doc.segments[i].start;
    }
    return null;
  }
}

/// Ein durchsuchbarer Text: Transkript (mit Eintrag, Aufnahme und Segmenten),
/// Notiz (mit Eintrag, ohne beides) oder Passage (mit Buch statt Eintrag).
final class _Document {
  const _Document({
    required this.journalId,
    required this.day,
    required this.text,
    required this.at,
    required this.folded,
    this.entryId,
    this.bookId,
    this.recordingId,
    this.segments = const [],
    this.foldedSegments = const [],
  });

  final String journalId;
  final LocalDay day;
  final String? entryId;
  final String? bookId;
  final String text;
  final DateTime at;
  final String? recordingId;
  final List<TranscriptSegment> segments;
  final FoldedText folded;
  final List<String> foldedSegments;
}
