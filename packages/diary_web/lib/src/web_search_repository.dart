import 'dart:async';
import 'dart:math' as math;

import 'package:diary_core/diary_core.dart';

import 'codecs.dart';
import 'encrypted_record_store.dart';
import 'text_normalization.dart';
import 'web_repositories.dart';

/// Volltextsuche im Speicher (docs/10-pwa.md Abschnitt 4): Beim ersten
/// Suchen werden alle Transkripte entschlüsselt geladen und gefaltet
/// (`ß → ss`, Kleinschreibung, Diakritika entfernt); Suchbegriffe durchlaufen
/// dieselbe Faltung, Teilworttreffer zählen, alle Begriffe müssen vorkommen.
/// Jede Änderung im Store macht den Index ungültig; er wird beim nächsten
/// Suchen neu aufgebaut.
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
          entry: e,
          recording: r,
          transcript: t,
          folded: foldWithMap(t.text),
          foldedSegments: [for (final s in t.segments) foldForMatch(s.text)],
        ),
      );
    }
    docs.sort((a, b) {
      final byDay = b.entry.day.compareTo(a.entry.day);
      if (byDay != 0) return byDay;
      return b.recording.startedAt.compareTo(a.recording.startedAt);
    });
    _documents = docs;
    _dirty = false;
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
      final entry = doc.entry;
      if (journalId != null && entry.journalId != journalId) continue;
      if (from != null && entry.day.isBefore(from)) continue;
      if (to != null && entry.day.isAfter(to)) continue;
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
          entryId: entry.id,
          day: entry.day,
          recordingId: doc.recording.id,
          snippet: _snippet(doc, firstMatch, terms),
          jumpTo: _jumpTo(doc, terms),
        ),
      );
    }
    return hits;
  }

  /// Ausschnitt des Originaltexts rund um den ersten Treffer.
  static String _snippet(_Document doc, int foldedIndex, List<String> terms) {
    final original = doc.transcript.text;
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
      if (terms.any(seg.contains)) return doc.transcript.segments[i].start;
    }
    return null;
  }
}

final class _Document {
  const _Document({
    required this.entry,
    required this.recording,
    required this.transcript,
    required this.folded,
    required this.foldedSegments,
  });

  final DiaryEntry entry;
  final Recording recording;
  final Transcript transcript;
  final FoldedText folded;
  final List<String> foldedSegments;
}
