import 'dart:convert';

import 'package:meta/meta.dart';

/// Woher ein geschriebener Text stammt.
enum NoteSource {
  /// Vom Nutzer getippt (Schreiben statt sprechen, D17).
  typed,

  /// Aus der Bearbeitung eines Transkripts hervorgegangen (vorgesehen für
  /// die Transkript-Korrektur, docs/03 Abschnitt 6; noch nicht genutzt).
  transcriptEdit,
}

/// Schlüssel der Impulse des geführten Abendrückblicks (D17) und der
/// internen Notizen, die der Ablauf daran hängt. Die Reihenfolge von
/// [review] ist die Reihenfolge beim Sprechen und Schreiben.
abstract final class ReviewPrompts {
  /// "Was ist heute passiert, was beschäftigt dich?"
  static const String free = 'free';

  /// "Was ist heute gut gelaufen, wofür bist du dankbar?"
  static const String good = 'good';

  /// "Was hast du gelernt, was würdest du morgen anders machen?"
  static const String lesson = 'lesson';

  /// "Der eine Schritt für morgen."
  static const String next = 'next';

  /// Die vier Impulse in Reihenfolge.
  static const List<String> review = [free, good, lesson, next];

  /// Interne Notiz an einem Eintrag: Zeitmarken der Impulswechsel während
  /// einer Aufnahme als JSON ([PromptMarks]). Wird nicht als Text gezeigt.
  static const String promptsAt = 'prompts_at';

  /// Interne Notiz am heutigen Eintrag: der gestrige Schritt wurde als
  /// erledigt markiert. Text `1` oder, wenn daraus eine Etappe eines Ziels
  /// wurde, das JSON von [StepDoneMark] (D19). Kein Streak, kein Zähler.
  static const String nextDone = 'next_done';

  /// Wahr für Notizen, die der Ablauf anlegt und die nicht als Text in der
  /// Eintragsliste erscheinen.
  static bool isInternal(String? promptKey) =>
      promptKey == promptsAt || promptKey == nextDone;
}

/// Ein geschriebener Eintragstext (D17): nicht an eine Aufnahme gebunden,
/// mit optionalem Impuls-Schlüssel aus [ReviewPrompts].
@immutable
class EntryNote {
  const EntryNote({
    required this.id,
    required this.entryId,
    required this.createdAt,
    required this.updatedAt,
    required this.text,
    this.promptKey,
    this.source = NoteSource.typed,
    this.goalId,
  });

  final String id;
  final String entryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String text;

  /// Impuls, auf den der Text antwortet, oder `null` für freien Text.
  final String? promptKey;
  final NoteSource source;

  /// Ziel (D19), dem der Schritt für morgen zugeordnet ist; nur beim Impuls
  /// [ReviewPrompts.next] belegt, sonst `null`. Fehlt in älteren Datensätzen.
  final String? goalId;

  bool get isInternal => ReviewPrompts.isInternal(promptKey);

  int get wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  /// [clearGoalId] löst die Zuordnung zu einem Ziel.
  EntryNote copyWith({
    String? text,
    DateTime? updatedAt,
    String? entryId,
    String? goalId,
    bool clearGoalId = false,
  }) => EntryNote(
    id: id,
    entryId: entryId ?? this.entryId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    text: text ?? this.text,
    promptKey: promptKey,
    source: source,
    goalId: clearGoalId ? null : (goalId ?? this.goalId),
  );
}

/// Inhalt der Notiz [ReviewPrompts.nextDone] (D19): ob aus dem erledigten
/// Schritt eine Etappe eines Ziels wurde. Ohne Etappe steht in der Notiz
/// weiterhin `1`; mit Etappe das JSON `{"milestoneId":"…"}`, damit das
/// Zurücknehmen des Häkchens die Etappe wieder entfernen kann. Unlesbarer
/// Text gilt als "erledigt, ohne Etappe".
@immutable
class StepDoneMark {
  const StepDoneMark({this.milestoneId});

  /// Text der Notiz ohne Etappe (D17).
  static const String plain = '1';

  final String? milestoneId;

  String encode() =>
      milestoneId == null ? plain : jsonEncode({'milestoneId': milestoneId});

  static StepDoneMark parse(String text) {
    final t = text.trim();
    if (!t.startsWith('{')) return const StepDoneMark();
    try {
      final m = jsonDecode(t);
      if (m is Map && m['milestoneId'] is String) {
        return StepDoneMark(milestoneId: m['milestoneId'] as String);
      }
    } on FormatException {
      // Älterer oder fremder Text: erledigt ohne Etappe.
    }
    return const StepDoneMark();
  }
}

/// Zeitmarke eines Impulswechsels während einer Aufnahme.
@immutable
class PromptMark {
  const PromptMark({required this.promptKey, required this.at});
  final String promptKey;

  /// Position in der Aufnahme (gezählte Aufnahmezeit ohne Pausen).
  final Duration at;
}

/// Inhalt der Notiz [ReviewPrompts.promptsAt]: welche Impulse während der
/// Aufnahme wann eingeblendet waren. Gewählt statt zusätzlicher
/// Segmentgrenzen im Transkript, weil die Segmente der Engine gehören und die
/// Marken auch ohne Transkript Sinn haben (D17).
@immutable
class PromptMarks {
  const PromptMarks({required this.recordingId, required this.marks});

  final String recordingId;
  final List<PromptMark> marks;

  Map<String, Object?> toJson() => {
    'recordingId': recordingId,
    'marks': [
      for (final m in marks)
        {'prompt': m.promptKey, 'atMs': m.at.inMilliseconds},
    ],
  };

  static PromptMarks fromJson(Map<String, Object?> m) => PromptMarks(
    recordingId: m['recordingId'] as String,
    marks: [
      for (final raw in (m['marks'] as List? ?? const []))
        PromptMark(
          promptKey: (raw as Map)['prompt'] as String,
          at: Duration(milliseconds: raw['atMs'] as int),
        ),
    ],
  );
}

/// Stimmung als Selbsteinschätzung in fünf Stufen (D8: nie abgeleitet).
/// Gespeichert in `DiaryEntry.mood` als Ziffer `1` bis `5`.
abstract final class MoodScale {
  static const int min = 1;
  static const int max = 5;

  static int? parse(String? mood) {
    if (mood == null) return null;
    final v = int.tryParse(mood);
    return v == null || v < min || v > max ? null : v;
  }

  static String encode(int value) {
    if (value < min || value > max) {
      throw ArgumentError.value(value, 'value', 'Stimmung 1 bis 5');
    }
    return '$value';
  }
}
