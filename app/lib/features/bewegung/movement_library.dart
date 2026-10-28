import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Eine Bewegungspause (D24): Uhrzeit und die Wochentage, an denen sie
/// gilt (`DateTime.weekday`, 1 = Montag … 7 = Sonntag). Liegt als Teil der
/// JSON-Liste `movementBreaks` verschlüsselt in den Einstellungen.
@immutable
class MovementBreak {
  const MovementBreak({
    required this.hour,
    required this.minute,
    this.weekdays = workdays,
  });

  factory MovementBreak.fromJson(Map<String, Object?> json) => MovementBreak(
    hour: (json['hour'] as num).toInt(),
    minute: (json['minute'] as num?)?.toInt() ?? 0,
    weekdays: {
      for (final d in (json['weekdays'] as List?) ?? const [1, 2, 3, 4, 5])
        if ((d as num).toInt() case final w when w >= 1 && w <= 7) w,
    },
  );

  /// Montag bis Freitag.
  static const Set<int> workdays = {1, 2, 3, 4, 5};

  /// Höchstens drei Pausen (D24 Punkt 1).
  static const int maxCount = 3;

  /// Standard: 10:00 und 15:00, Montag bis Freitag.
  static const List<MovementBreak> defaults = [
    MovementBreak(hour: 10, minute: 0),
    MovementBreak(hour: 15, minute: 0),
  ];

  final int hour;
  final int minute;
  final Set<int> weekdays;

  /// Minuten seit Mitternacht (zum Sortieren und Vergleichen).
  int get minutesOfDay => hour * 60 + minute;

  /// Ob die Pause an [day] gilt.
  bool appliesOn(DateTime day) => weekdays.contains(day.weekday);

  /// Zeitpunkt der Pause an [day].
  DateTime at(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  MovementBreak copyWith({int? hour, int? minute, Set<int>? weekdays}) =>
      MovementBreak(
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        weekdays: weekdays ?? this.weekdays,
      );

  Map<String, Object?> toJson() => {
    'hour': hour,
    'minute': minute,
    'weekdays': weekdays.toList()..sort(),
  };

  static List<MovementBreak> decodeList(String? json) {
    if (json == null || json.isEmpty) return defaults;
    try {
      return [
        for (final b in jsonDecode(json) as List)
          MovementBreak.fromJson(b as Map<String, Object?>),
      ];
    } on Object {
      return defaults;
    }
  }

  static String encodeList(List<MovementBreak> breaks) =>
      jsonEncode([for (final b in breaks) b.toJson()]);

  @override
  bool operator ==(Object other) =>
      other is MovementBreak &&
      other.hour == hour &&
      other.minute == minute &&
      setEquals(other.weekdays, weekdays);

  @override
  int get hashCode =>
      Object.hash(hour, minute, Object.hashAllUnordered(weekdays));
}

/// Kategorie einer Übung mit Anzeigename in beiden Sprachen.
@immutable
class ExerciseCategory {
  const ExerciseCategory({
    required this.key,
    required this.de,
    required this.en,
  });

  /// Schlüssel aus der Datei; eigene Übungen ohne Kategorie bekommen [other].
  static const String other = 'other';

  final String key;
  final String de;
  final String en;

  String name(String languageCode) => languageCode == 'en' ? en : de;
}

/// Eine Übung aus der gebündelten Liste (`assets/movement/exercises.json`)
/// oder eine eigene der Nutzerin. Beide Sprachen liegen vor; [title] und
/// [how] wählen nach der Sprache der Oberfläche.
@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.category,
    required this.minutes,
    required this.de,
    required this.en,
    this.howDe = '',
    this.howEn = '',
    this.own = false,
  });

  factory Exercise.fromJson(Map<String, Object?> json) => Exercise(
    id: json['id'] as String,
    category: (json['category'] as String?) ?? ExerciseCategory.other,
    minutes: ((json['minutes'] as num?) ?? 0).toDouble(),
    de: json['de'] as String,
    en: (json['en'] as String?) ?? json['de'] as String,
    howDe: (json['howDe'] as String?) ?? '',
    howEn: (json['howEn'] as String?) ?? '',
    own: (json['own'] as bool?) ?? false,
  );

  final String id;
  final String category;

  /// Dauer in Minuten; unter einer Minute als Bruch (0,5 = 30 Sekunden),
  /// 0 = keine Angabe.
  final double minutes;
  final String de;
  final String en;
  final String howDe;
  final String howEn;

  /// Von der Nutzerin selbst eingetragen (liegt verschlüsselt in den
  /// Einstellungen, nicht in der Datei).
  final bool own;

  String title(String languageCode) => languageCode == 'en' ? en : de;
  String how(String languageCode) => languageCode == 'en' ? howEn : howDe;

  /// Dauer als Sekunden (für die Anzeige unter einer Minute).
  int get seconds => (minutes * 60).round();

  Map<String, Object?> toJson() => {
    'id': id,
    'category': category,
    'minutes': minutes,
    'de': de,
    'en': en,
    if (howDe.isNotEmpty) 'howDe': howDe,
    if (howEn.isNotEmpty) 'howEn': howEn,
    if (own) 'own': true,
  };

  static List<Exercise> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      return [
        for (final e in jsonDecode(json) as List)
          Exercise.fromJson(e as Map<String, Object?>),
      ];
    } on Object {
      return const [];
    }
  }

  static String encodeList(List<Exercise> exercises) =>
      jsonEncode([for (final e in exercises) e.toJson()]);

  @override
  bool operator ==(Object other) => other is Exercise && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Übungsliste (D24): lädt die gebündelte Datei, kennt die Kategorien und
/// den Hinweis zu Schmerzen und wählt je Pause drei Vorschläge
/// deterministisch aus Datum und Pausenindex (gleicher Tag, gleiche
/// Vorschläge, offline und nach Neustart; wie das Zitat des Tages, D20).
/// Eigene Übungen ([withOwn]) nehmen an der Auswahl teil.
@immutable
class MovementLibrary {
  const MovementLibrary({
    required this.exercises,
    required this.categories,
    this.noticeDe = '',
    this.noticeEn = '',
  });

  static const String assetPath = 'assets/movement/exercises.json';

  /// Wie viele Übungen die Karte vorschlägt.
  static const int suggestionCount = 3;

  /// Liest die gebündelte Datei.
  static Future<MovementLibrary> load() async =>
      MovementLibrary.fromJson(await rootBundle.loadString(assetPath));

  factory MovementLibrary.fromJson(String source) {
    final data = jsonDecode(source) as Map<String, Object?>;
    final notice = (data['notice'] as Map?) ?? const {};
    return MovementLibrary(
      exercises: [
        for (final e in data['exercises'] as List)
          Exercise.fromJson(e as Map<String, Object?>),
      ],
      categories: [
        for (final c in (data['categories'] as List?) ?? const [])
          ExerciseCategory(
            key: (c as Map)['key'] as String,
            de: c['de'] as String,
            en: c['en'] as String,
          ),
      ],
      noticeDe: (notice['de'] as String?) ?? '',
      noticeEn: (notice['en'] as String?) ?? '',
    );
  }

  final List<Exercise> exercises;
  final List<ExerciseCategory> categories;
  final String noticeDe;
  final String noticeEn;

  /// Hinweis zu Schmerzen in der Sprache der Oberfläche (leer, wenn die
  /// Datei keinen trägt; die Oberfläche hat ihren eigenen Text).
  String notice(String languageCode) =>
      languageCode == 'en' ? noticeEn : noticeDe;

  /// Dieselbe Liste plus eigene Übungen.
  MovementLibrary withOwn(List<Exercise> own) => MovementLibrary(
    exercises: [...exercises, ...own],
    categories: categories,
    noticeDe: noticeDe,
    noticeEn: noticeEn,
  );

  Exercise? byId(String id) => exercises.where((e) => e.id == id).firstOrNull;

  /// Übungen einer Kategorie; eigene Übungen ohne bekannte Kategorie stehen
  /// unter [ExerciseCategory.other].
  List<Exercise> inCategory(String key) {
    final known = {for (final c in categories) c.key};
    return [
      for (final e in exercises)
        if (e.category == key ||
            (key == ExerciseCategory.other && !known.contains(e.category)))
          e,
    ];
  }

  /// Bis zu [count] verschiedene Vorschläge für [day] und [breakIndex].
  List<Exercise> suggestionsFor(
    DateTime day,
    int breakIndex, {
    int count = suggestionCount,
  }) {
    if (exercises.isEmpty) return const [];
    final n = exercises.length;
    final want = count < n ? count : n;
    final dayNumber = day.year * 10000 + day.month * 100 + day.day;
    var h = _mix(dayNumber * 7 + breakIndex + 1);
    final picked = <int>[];
    while (picked.length < want) {
      final idx = h % n;
      if (!picked.contains(idx)) picked.add(idx);
      h = _mix(h ^ (picked.length * 0x9e3779b9));
    }
    return [for (final i in picked) exercises[i]];
  }

  /// Kleine Streuung (xorshift-artig), damit aufeinanderfolgende Tage nicht
  /// benachbarte Übungen liefern.
  static int _mix(int x) {
    var v = x & 0xffffffff;
    v ^= v << 13 & 0xffffffff;
    v ^= v >> 17;
    v ^= v << 5 & 0xffffffff;
    v = (v * 2654435761) & 0xffffffff;
    return v;
  }
}

/// Zeitplan der Pausen (D24): welche Pause gerade fällig ist und wann die
/// nächste kommt. Reine Rechnung ohne Zustand, testbar mit festen Zeiten.
abstract final class MovementSchedule {
  /// Index der fälligen Pause zu [now]: die letzte Pause des Tages, deren
  /// Zeit erreicht ist und die an diesem Wochentag gilt; `null`, wenn noch
  /// keine fällig ist oder heute keine gilt. Die Karte bleibt bis zur
  /// nächsten Pause oder zum Tagesende.
  static int? dueIndex(List<MovementBreak> breaks, DateTime now) {
    int? due;
    var best = -1;
    for (final (i, b) in breaks.indexed) {
      if (!b.appliesOn(now)) continue;
      final m = b.minutesOfDay;
      if (m <= now.hour * 60 + now.minute && m > best) {
        best = m;
        due = i;
      }
    }
    return due;
  }

  /// Nächste Pause ab [now] (ausschließlich der laufenden Minute) innerhalb
  /// der nächsten sieben Tage, oder `null`, wenn keine Pause einen Wochentag
  /// hat.
  static DateTime? nextAfter(List<MovementBreak> breaks, DateTime now) {
    DateTime? best;
    for (var d = 0; d < 8; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      for (final b in breaks) {
        if (!b.appliesOn(day)) continue;
        final at = b.at(day);
        if (!at.isAfter(now)) continue;
        if (best == null || at.isBefore(best)) best = at;
      }
      if (best != null) return best;
    }
    return null;
  }
}
