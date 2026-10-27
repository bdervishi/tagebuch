import 'dart:convert';

import 'package:diary_core/diary_core.dart';
import 'package:test/test.dart';

void main() {
  test('EntryNote: JSON-Round-Trip, Wortzahl, interne Schlüssel', () {
    final n = EntryNote(
      id: 'n1',
      entryId: 'e1',
      createdAt: DateTime(2026, 10, 27, 21, 5),
      updatedAt: DateTime(2026, 10, 27, 21, 7),
      text: 'Drei Dinge:  Kaffee, Sonne, Anruf.',
      promptKey: ReviewPrompts.good,
    );
    final back = ModelJson.decodeNote(
      jsonDecode(jsonEncode(ModelJson.encodeNote(n))) as Map<String, Object?>,
    );
    expect(back.id, 'n1');
    expect(back.entryId, 'e1');
    expect(back.text, n.text);
    expect(back.promptKey, 'good');
    expect(back.source, NoteSource.typed);
    expect(back.createdAt, n.createdAt);
    expect(back.updatedAt, n.updatedAt);
    expect(back.wordCount, 5);
    expect(back.isInternal, isFalse);

    // Ältere Datensätze ohne `source`.
    final legacy = ModelJson.decodeNote({
      'id': 'n2',
      'entryId': 'e1',
      'createdAt': '2026-10-27T19:00:00.000Z',
      'updatedAt': '2026-10-27T19:00:00.000Z',
      'text': '',
    });
    expect(legacy.source, NoteSource.typed);
    expect(legacy.promptKey, isNull);
    expect(legacy.wordCount, 0);

    expect(ReviewPrompts.isInternal(ReviewPrompts.promptsAt), isTrue);
    expect(ReviewPrompts.isInternal(ReviewPrompts.nextDone), isTrue);
    expect(ReviewPrompts.isInternal(null), isFalse);
    expect(ReviewPrompts.review, ['free', 'good', 'lesson', 'next']);
    // Kurznotizen (D22) sind kein Impuls und nicht intern: sichtbar,
    // durchsuchbar, exportiert.
    expect(ReviewPrompts.quick, 'quick');
    expect(ReviewPrompts.isInternal(ReviewPrompts.quick), isFalse);
    expect(ReviewPrompts.review, isNot(contains(ReviewPrompts.quick)));
  });

  test('PromptMarks: JSON-Round-Trip', () {
    final marks = PromptMarks(
      recordingId: 'r1',
      marks: const [
        PromptMark(promptKey: 'free', at: Duration.zero),
        PromptMark(promptKey: 'good', at: Duration(seconds: 45)),
      ],
    );
    final back = PromptMarks.fromJson(
      jsonDecode(jsonEncode(marks.toJson())) as Map<String, Object?>,
    );
    expect(back.recordingId, 'r1');
    expect(back.marks.map((m) => m.promptKey), ['free', 'good']);
    expect(back.marks.last.at, const Duration(seconds: 45));
  });

  test('MoodScale: nur 1 bis 5, Eintrag kann die Stimmung wieder lösen', () {
    expect(MoodScale.parse('3'), 3);
    expect(MoodScale.parse('0'), isNull);
    expect(MoodScale.parse('6'), isNull);
    expect(MoodScale.parse('gut'), isNull);
    expect(MoodScale.parse(null), isNull);
    expect(MoodScale.encode(5), '5');
    expect(() => MoodScale.encode(7), throwsArgumentError);

    final e = DiaryEntry(
      id: 'e',
      journalId: 'j',
      day: const LocalDay(2026, 10, 27),
      createdAt: DateTime(2026, 10, 27),
      updatedAt: DateTime(2026, 10, 27),
    );
    final withMood = e.copyWith(mood: '4');
    expect(withMood.mood, '4');
    expect(withMood.copyWith(title: 'x').mood, '4');
    expect(withMood.copyWith(clearMood: true).mood, isNull);
  });
}
