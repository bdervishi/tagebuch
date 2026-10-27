import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/features/daten/backup_screen.dart';
import 'package:tagebuch_app/features/daten/restore_screen.dart';
import 'package:tagebuch_app/features/daten/transfer_screen.dart';
import 'package:tagebuch_app/features/einstellungen/settings_screen.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';
import 'package:tagebuch_app/widgets/backup_reminder_card.dart';

import 'test_app.dart';

void main() {
  final seeds = [
    testEntry(id: 'a', day: DateTime(2026, 10, 24), transcript: 'Erster Tag'),
    testEntry(id: 'b', day: DateTime(2026, 10, 25), transcript: 'Zweiter Tag'),
    testEntry(id: 'c', day: DateTime(2026, 10, 26), transcript: 'Dritter Tag'),
  ];

  /// Bildschirm mit eigenen Diensten einbetten. Der eindeutige Schlüssel
  /// erzwingt einen neuen Baum (neue ProviderScope, frischer Zustand), wenn
  /// ein Test zwischen zwei "Geräten" wechselt.
  Widget screen(Widget child, TestServices services) => KeyedSubtree(
    key: UniqueKey(),
    child: buildTestScreen(child, services: services),
  );

  testWidgets('Backup: Passphrase prüfen, Datei erzeugen, Zeitpunkt merken; '
      'Wiederherstellen zeigt Zusammenfassung und übernimmt', (tester) async {
    final features = FakePlatformFeatures(isWeb: true);
    final old = TestServices(seed: seeds, features: features);
    // Audio nur für eine Aufnahme, damit beide Wege (mit/ohne) vorkommen.
    old.audioFiles.files['rec-a.tgbc'] = Uint8ListOf(2000, 3);

    await tester.pumpWidget(screen(const BackupScreen(), old));
    await tester.pumpAndSettle();

    // Zu kurz
    await tester.enterText(find.byKey(backupPassphraseKey), 'kurz');
    await tester.enterText(find.byKey(backupPassphraseRepeatKey), 'kurz');
    await tester.tap(find.byKey(backupStartKey));
    await tester.pumpAndSettle();
    expect(find.text('Mindestens 8 Zeichen.'), findsOneWidget);
    expect(features.savedFiles, isEmpty);

    // Ungleich
    await tester.enterText(find.byKey(backupPassphraseKey), 'korrektes pferd');
    await tester.enterText(
      find.byKey(backupPassphraseRepeatKey),
      'korrektes pfer',
    );
    await tester.tap(find.byKey(backupStartKey));
    await tester.pumpAndSettle();
    expect(find.text('Die Passphrasen stimmen nicht überein.'), findsOneWidget);
    expect(features.savedFiles, isEmpty);

    // Gültig
    await tester.enterText(
      find.byKey(backupPassphraseRepeatKey),
      'korrektes pferd',
    );
    await tester.tap(find.byKey(backupStartKey));
    await tester.pumpAndSettle();
    expect(features.savedFiles, hasLength(1));
    final (fileName, bytes) = features.savedFiles.single;
    expect(
      fileName,
      matches(RegExp(r'^tagebuch-backup-\d{4}-\d{2}-\d{2}\.tgbx$')),
    );
    expect(bytes.sublist(0, 4), 'TGBX'.codeUnits);
    expect(find.textContaining('Backup erstellt:'), findsOneWidget);
    expect(await old.settings.get(AppSettings.keyLastBackupAt), isNotNull);

    // Wiederherstellen auf einem leeren Gerät
    final fresh = TestServices(features: FakePlatformFeatures(isWeb: true));
    final freshFeatures = fresh.services.features as FakePlatformFeatures;
    await tester.pumpWidget(screen(const RestoreScreen(), fresh));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Datei gewählt.'), findsOneWidget);

    freshFeatures.fileToPick = bytes;
    await tester.tap(find.byKey(restoreChooseFileKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Datei gewählt'), findsOneWidget);

    // Falsche Passphrase
    await tester.enterText(find.byKey(restorePassphraseKey), 'falsch falsch');
    await tester.tap(find.byKey(restoreOpenKey));
    await tester.pumpAndSettle();
    expect(find.text('Passphrase falsch.'), findsOneWidget);
    expect(find.byKey(restoreConfirmKey), findsNothing);

    // Richtige Passphrase: Zusammenfassung vor dem Import
    await tester.enterText(find.byKey(restorePassphraseKey), 'korrektes pferd');
    await tester.tap(find.byKey(restoreOpenKey));
    await tester.pumpAndSettle();
    expect(find.text('Inhalt der Datei'), findsOneWidget);
    expect(find.textContaining('3 Einträge, 3 Aufnahmen'), findsOneWidget);
    expect(find.textContaining('Zeitraum: '), findsOneWidget);
    expect(fresh.entries.items, isEmpty);

    await tester.tap(find.byKey(restoreConfirmKey));
    await tester.pumpAndSettle();
    expect(find.text('Übernommen'), findsOneWidget);
    expect(
      find.text(
        '3 neue Tage, 0 ergänzte Tage, 3 Aufnahmen übernommen, 0 waren schon da.',
      ),
      findsOneWidget,
    );
    expect(fresh.entries.items, hasLength(3));
    expect(fresh.recordings.items, hasLength(3));
    final withAudio = fresh.recordings.items.singleWhere(
      (r) => r.id == 'rec-a',
    );
    expect(withAudio.state, RecordingState.complete);
    expect(fresh.audioFiles.files['rec-a.tgbc'], Uint8ListOf(2000, 3));
    final withoutAudio = fresh.recordings.items.singleWhere(
      (r) => r.id == 'rec-b',
    );
    expect(withoutAudio.state, RecordingState.audioDeleted);
    expect(
      fresh.transcripts.items.map((t) => t.text),
      containsAll(['Erster Tag', 'Dritter Tag']),
    );
  });

  testWidgets('Gerätewechsel: Code vom neuen Gerät, Datei vom alten, Import', (
    tester,
  ) async {
    final newDevice = TestServices(features: FakePlatformFeatures(isWeb: true));
    final newFeatures = newDevice.services.features as FakePlatformFeatures;
    final oldDevice = TestServices(
      seed: seeds.sublist(0, 2),
      features: FakePlatformFeatures(isWeb: true),
    );
    final oldFeatures = oldDevice.services.features as FakePlatformFeatures;

    // Neues Gerät zeigt Code und Prüfcode.
    await tester.pumpWidget(screen(const TransferScreen(), newDevice));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(transferRoleNewKey));
    await tester.pumpAndSettle();
    final codeWidget = tester.widget<SelectableText>(
      find.byKey(transferTextCodeKey),
    );
    final code = codeWidget.data!;
    expect(code, startsWith('tgb1:'));
    final expectedCode = QrPayload.decode(code).verificationCode();
    expect(find.text('Prüfcode $expectedCode'), findsOneWidget);
    expect(
      await newDevice.settings.get(AppSettings.keyTransferSession),
      isNotNull,
    );

    // Altes Gerät: Code eintippen, Prüfcode vergleichen, Datei erzeugen.
    await tester.pumpWidget(screen(const TransferScreen(), oldDevice));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(transferRoleOldKey));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Die Kamera kann hier keine Codes lesen'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(transferCodeFieldKey), 'tgb1:kaputt');
    await tester.pumpAndSettle();
    expect(find.text('Das ist kein Code dieser App.'), findsOneWidget);
    await tester.enterText(find.byKey(transferCodeFieldKey), code);
    await tester.pumpAndSettle();
    expect(find.text('Code gelesen'), findsOneWidget);
    expect(find.text('Prüfcode $expectedCode'), findsOneWidget);
    await tester.tap(find.byKey(transferCreateFileKey));
    await tester.pumpAndSettle();
    expect(oldFeatures.savedFiles, hasLength(1));
    expect(oldFeatures.savedFiles.single.$1, startsWith('tagebuch-transfer-'));
    expect(find.textContaining('Datei erzeugt:'), findsOneWidget);
    // Die Einträge bleiben auf dem alten Gerät.
    expect(oldDevice.entries.items, hasLength(2));

    // Neues Gerät: Datei wählen, Zusammenfassung, übernehmen.
    await tester.pumpWidget(screen(const TransferScreen(), newDevice));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(transferRoleNewKey));
    await tester.pumpAndSettle();
    // Dieselbe Sitzung wie zuvor (gespeichert), also derselbe Prüfcode.
    expect(find.text('Prüfcode $expectedCode'), findsOneWidget);
    newFeatures.fileToPick = oldFeatures.savedFiles.single.$2;
    await tester.dragUntilVisible(
      find.byKey(transferReceiveFileKey),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(transferReceiveFileKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 Einträge, 2 Aufnahmen'), findsOneWidget);
    await tester.tap(find.byKey(transferConfirmKey));
    await tester.pumpAndSettle();
    expect(find.text('Übernommen'), findsOneWidget);
    expect(newDevice.entries.items, hasLength(2));
    expect(
      newDevice.transcripts.items.map((t) => t.text),
      containsAll(['Erster Tag', 'Zweiter Tag']),
    );
    // Sitzung verbraucht.
    expect(await newDevice.settings.get(AppSettings.keyTransferSession), '');

    // Eine Datei für einen anderen Code wird abgewiesen.
    await tester.pumpWidget(screen(const TransferScreen(), newDevice));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(transferRoleNewKey));
    await tester.pumpAndSettle();
    expect(find.text('Prüfcode $expectedCode'), findsNothing);
    await tester.dragUntilVisible(
      find.byKey(transferReceiveFileKey),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(transferReceiveFileKey));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.textContaining('für einen anderen Code erstellt'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(
      find.textContaining('für einen anderen Code erstellt'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Backup-Erinnerung ab dem dritten Eintrag, "Später" stellt zurück',
    (tester) async {
      final few = TestServices(
        seed: seeds.sublist(0, 2),
        features: FakePlatformFeatures(isWeb: true),
      );
      await tester.pumpWidget(screen(const TodayScreen(), few));
      await tester.pumpAndSettle();
      expect(find.byKey(backupReminderCardKey), findsNothing);

      final many = TestServices(
        seed: seeds,
        features: FakePlatformFeatures(isWeb: true),
      );
      await tester.pumpWidget(screen(const TodayScreen(), many));
      await tester.pumpAndSettle();
      expect(find.byKey(backupReminderCardKey), findsOneWidget);
      expect(find.textContaining('Du hast schon 3 Einträge.'), findsOneWidget);

      // Die Karte steht unter "Deine Wege" (D19); erst sichtbar machen.
      await tester.ensureVisible(find.byKey(backupReminderLaterKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(backupReminderLaterKey));
      await tester.pumpAndSettle();
      expect(find.byKey(backupReminderCardKey), findsNothing);
      expect(
        await many.settings.get(AppSettings.keyBackupRemindAfter),
        isNotNull,
      );

      // Frisches Backup: keine Karte. Altes Backup: Karte mit Hinweis.
      final recent = TestServices(seed: seeds);
      await recent.settings.set(
        AppSettings.keyLastBackupAt,
        DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      );
      await tester.pumpWidget(screen(const TodayScreen(), recent));
      await tester.pumpAndSettle();
      expect(find.byKey(backupReminderCardKey), findsNothing);

      final stale = TestServices(seed: seeds);
      await stale.settings.set(
        AppSettings.keyLastBackupAt,
        DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
      );
      await tester.pumpWidget(screen(const TodayScreen(), stale));
      await tester.pumpAndSettle();
      expect(
        find.text('Dein letztes Backup ist älter als eine Woche.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Einstellungen: Daten-Einträge sind aktiv und führen zu den Bildschirmen',
    (tester) async {
      final services = TestServices();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Einstellungen'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(backupCreateKey), 200);
      await tester.pumpAndSettle();
      expect(find.text('Noch nicht verfügbar'), findsNothing);
      expect(find.text('Noch kein Backup erstellt'), findsOneWidget);

      await tester.tap(find.byKey(backupCreateKey));
      await tester.pumpAndSettle();
      expect(find.byType(BackupScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byKey(deviceTransferKey), 200);
      await tester.tap(find.byKey(deviceTransferKey));
      await tester.pumpAndSettle();
      expect(find.byType(TransferScreen), findsOneWidget);
      expect(find.text('Dieses Gerät ist das neue'), findsOneWidget);
    },
  );
}
