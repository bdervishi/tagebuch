import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/app/app.dart';
import 'package:tagebuch_app/data/diary_entry.dart';
import 'package:tagebuch_app/data/entries_notifier.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/l10n/app_localizations.dart';

/// Baut die ganze App mit festgelegter Sprache und Vorbelegung.
Widget buildTestApp({
  Locale locale = const Locale('de'),
  bool onboardingDone = true,
  List<DiaryEntry> entries = const [],
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        () => SettingsNotifier(
          initial: AppSettings(onboardingDone: onboardingDone),
        ),
      ),
      entriesProvider.overrideWith(() => EntriesNotifier(initial: entries)),
    ],
    child: TagebuchApp(locale: locale),
  );
}

/// Bettet einen einzelnen Bildschirm in eine lokalisierte MaterialApp ein.
Widget buildTestScreen(
  Widget screen, {
  Locale locale = const Locale('de'),
  List<DiaryEntry> entries = const [],
}) {
  return ProviderScope(
    overrides: [
      entriesProvider.overrideWith(() => EntriesNotifier(initial: entries)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  );
}

/// Pumpt eine Routenanimation zu Ende, ohne auf laufende Timer zu warten
/// (die Aufnahme hat periodische Timer, `pumpAndSettle` würde nicht enden).
Future<void> pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

DiaryEntry testEntry({
  required String id,
  required DateTime day,
  String transcript = 'Transkription folgt',
  Duration duration = const Duration(seconds: 90),
}) {
  return DiaryEntry(
    id: id,
    day: day,
    recordedAt: day.add(const Duration(hours: 21)),
    duration: duration,
    transcript: transcript,
    language: 'de-DE',
  );
}
