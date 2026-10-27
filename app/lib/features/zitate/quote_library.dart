import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Ein Zitat des gebündelten Schatzes (`assets/quotes/quotes.json`) oder ein
/// eigenes der Nutzerin. Beide Sprachen liegen vor; [text] wählt nach der
/// Sprache der Oberfläche.
@immutable
class Quote {
  const Quote({
    required this.id,
    required this.author,
    required this.de,
    required this.en,
    this.years = '',
    this.source = '',
    this.themes = const [],
    this.own = false,
  });

  factory Quote.fromJson(Map<String, Object?> json) => Quote(
    id: json['id'] as String,
    author: json['author'] as String,
    years: (json['years'] as String?) ?? '',
    de: json['de'] as String,
    en: (json['en'] as String?) ?? json['de'] as String,
    source: (json['source'] as String?) ?? '',
    themes: [
      for (final t in (json['themes'] as List?) ?? const []) t as String,
    ],
    own: (json['own'] as bool?) ?? false,
  );

  final String id;
  final String author;
  final String years;
  final String de;
  final String en;
  final String source;
  final List<String> themes;

  /// Von der Nutzerin selbst eingetragen (liegt verschlüsselt in den
  /// Einstellungen, nicht in der Datei).
  final bool own;

  /// Text in der Sprache [languageCode] (`de` oder `en`).
  String text(String languageCode) => languageCode == 'en' ? en : de;

  Map<String, Object?> toJson() => {
    'id': id,
    'author': author,
    if (years.isNotEmpty) 'years': years,
    'de': de,
    'en': en,
    if (source.isNotEmpty) 'source': source,
    'themes': themes,
    if (own) 'own': true,
  };

  @override
  bool operator ==(Object other) => other is Quote && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Thema mit Anzeigename in beiden Sprachen.
@immutable
class QuoteTheme {
  const QuoteTheme({required this.key, required this.de, required this.en});

  final String key;
  final String de;
  final String en;

  String name(String languageCode) => languageCode == 'en' ? en : de;
}

/// Zitatenschatz: lädt die gebündelte Datei, wählt das Zitat des Tages
/// deterministisch (gleiches Datum, gleiches Zitat, auch offline und nach
/// Neustart) und kennt zwei Plätze je Tag: morgens ([slotMorning]) und abends
/// ([slotEvening]). Eigene Zitate der Nutzerin ([withOwn]) nehmen an der
/// Auswahl teil; Themenfilter wirken nur auf den gebündelten Teil, eigene
/// Zitate bleiben immer im Topf.
@immutable
class QuoteLibrary {
  const QuoteLibrary({required this.quotes, required this.themes});

  static const String assetPath = 'assets/quotes/quotes.json';
  static const int slotMorning = 0;
  static const int slotEvening = 1;

  /// Liest die gebündelte Datei.
  static Future<QuoteLibrary> load() async =>
      QuoteLibrary.fromJson(await rootBundle.loadString(assetPath));

  factory QuoteLibrary.fromJson(String source) {
    final data = jsonDecode(source) as Map<String, Object?>;
    return QuoteLibrary(
      quotes: [
        for (final q in data['quotes'] as List)
          Quote.fromJson(q as Map<String, Object?>),
      ],
      themes: [
        for (final t in (data['themes'] as List?) ?? const [])
          QuoteTheme(
            key: (t as Map)['key'] as String,
            de: t['de'] as String,
            en: t['en'] as String,
          ),
      ],
    );
  }

  final List<Quote> quotes;
  final List<QuoteTheme> themes;

  /// Dieselbe Bibliothek plus eigene Zitate.
  QuoteLibrary withOwn(List<Quote> own) =>
      QuoteLibrary(quotes: [...quotes, ...own], themes: themes);

  Quote? byId(String id) => quotes.where((q) => q.id == id).firstOrNull;

  /// Auswahltopf: bei leerem [selectedThemes] alle, sonst die passenden
  /// gebündelten plus alle eigenen. Fällt nichts passt, wieder alle.
  List<Quote> pool(Set<String> selectedThemes) {
    if (selectedThemes.isEmpty) return quotes;
    final own = [
      for (final q in quotes)
        if (q.own) q,
    ];
    final matching = [
      for (final q in quotes)
        if (!q.own && q.themes.any(selectedThemes.contains)) q,
    ];
    if (matching.isEmpty) return quotes;
    return [...matching, ...own];
  }

  /// Zitat für [day] und [slot]; `null` nur bei leerem Schatz. Morgen- und
  /// Abendzitat eines Tages sind verschieden, sobald es mehr als eines gibt.
  Quote? forDay(
    DateTime day, {
    Set<String> selectedThemes = const {},
    int slot = slotMorning,
  }) {
    final candidates = pool(selectedThemes);
    if (candidates.isEmpty) return null;
    final n = candidates.length;
    final dayNumber = day.year * 10000 + day.month * 100 + day.day;
    final base = _mix(dayNumber) % n;
    if (slot == slotMorning || n == 1) return candidates[base];
    final offset = 1 + _mix(dayNumber ^ 0x5bd1e995) % (n - 1);
    return candidates[(base + offset) % n];
  }

  /// Kleine Streuung (xorshift-artig), damit aufeinanderfolgende Tage nicht
  /// benachbarte Zitate liefern.
  static int _mix(int x) {
    var v = x & 0xffffffff;
    v ^= v << 13 & 0xffffffff;
    v ^= v >> 17;
    v ^= v << 5 & 0xffffffff;
    v = (v * 2654435761) & 0xffffffff;
    return v;
  }
}
