import 'package:diary_core/diary_core.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_keys/diary_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/app_lock.dart';
import 'package:tagebuch_app/features/aufnahme/recording_screen.dart';
import 'package:tagebuch_app/features/einstellungen/settings_screen.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';
import 'package:tagebuch_app/features/onboarding/onboarding_screen.dart';
import 'package:tagebuch_app/features/schutz/lock_gate.dart';
import 'package:tagebuch_app/features/schutz/lock_screen.dart';
import 'package:tagebuch_app/features/schutz/pin_flow_screen.dart';
import 'package:tagebuch_app/features/schutz/pin_pad.dart';
import 'package:tagebuch_app/services/platform_features.dart';

import 'test_app.dart';

/// App-Sperre mit PIN (D23): Vergabe, Sperrbildschirm, Fehlversuche,
/// Hintergrundzeit, Schnellaktion, "PIN vergessen".
void main() {
  /// Hinterlegt einen gesetzten PIN in den Einstellungen (wie nach dem
  /// Einschalten), damit der nächste Start gesperrt beginnt.
  Future<void> seedLock(
    TestServices s,
    String pin, {
    LockAfter? lockAfter,
  }) async {
    final hash = await PinHash.create(
      pin,
      kdf: const Argon2idKdf(),
      random: SecureRandomSource(),
      params: Argon2Params.testing,
    );
    await s.settings.set(AppLockKeys.enabled, 'true');
    await s.settings.set(AppLockKeys.hash, hexEncode(hash.hash));
    await s.settings.set(AppLockKeys.salt, hexEncode(hash.salt));
    await s.settings.set(AppLockKeys.kdf, hash.encodedParams);
    if (lockAfter != null) {
      await s.settings.set(AppLockKeys.lockAfter, lockAfter.setting);
    }
  }

  /// Tippt [pin] auf dem Ziffernfeld und bestätigt. Ohne [settle] werden nur
  /// einige Frames gepumpt (wenn danach die Aufnahme mit ihren Timern läuft,
  /// würde `pumpAndSettle` sie bis zum Ende durchlaufen).
  Future<void> enterPin(
    WidgetTester tester,
    String pin, {
    bool settle = true,
  }) async {
    for (final c in pin.split('')) {
      await tester.tap(find.byKey(pinDigitKey(int.parse(c))));
      await tester.pump();
    }
    if (pin.length < PinRules.maxLength) {
      await tester.tap(find.byKey(pinSubmitKey));
    }
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Echte Abfolge der Zustände wie das Framework sie meldet (Flutter prüft
  /// die Übergänge): in den Hintergrund und wieder zurück.
  Future<void> toBackground(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
  }

  Future<void> toForeground(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Einstellungen'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollSettingsTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Einschalten öffnet die PIN-Vergabe und speichert nur den Hash', (
    tester,
  ) async {
    final services = TestServices();
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsNothing);

    await openSettings(tester);
    await scrollSettingsTo(tester, find.byKey(appLockSwitchKey));
    expect(
      tester.widget<SwitchListTile>(find.byKey(appLockSwitchKey)).value,
      isFalse,
    );
    await tester.tap(find.byKey(appLockSwitchKey));
    await pumpTransition(tester);
    expect(find.byType(PinFlowScreen), findsOneWidget);
    expect(find.text('Neuen PIN wählen (4 bis 8 Ziffern)'), findsOneWidget);

    // Zu kurz: Bestätigen ist nicht bedienbar, nichts passiert.
    await enterPin(tester, '123');
    expect(find.text('Neuen PIN wählen (4 bis 8 Ziffern)'), findsOneWidget);
    await tester.tap(find.byKey(pinBackspaceKey));
    await tester.tap(find.byKey(pinBackspaceKey));
    await tester.tap(find.byKey(pinBackspaceKey));
    await tester.pump();

    await enterPin(tester, '123456');
    expect(find.text('PIN wiederholen'), findsOneWidget);
    // Falsche Wiederholung: von vorn.
    await enterPin(tester, '654321');
    expect(
      find.text('Die Eingaben stimmen nicht überein. Noch einmal von vorn.'),
      findsOneWidget,
    );
    expect(find.text('Neuen PIN wählen (4 bis 8 Ziffern)'), findsOneWidget);

    await enterPin(tester, '123456');
    await enterPin(tester, '123456');
    await pumpTransition(tester);
    await tester.pumpAndSettle();
    expect(find.byType(PinFlowScreen), findsNothing);
    expect(
      tester.widget<SwitchListTile>(find.byKey(appLockSwitchKey)).value,
      isTrue,
    );
    expect(find.byType(LockScreen), findsNothing, reason: 'bleibt entsperrt');

    final all = await services.settings.all();
    expect(all[AppLockKeys.enabled], 'true');
    expect(all[AppLockKeys.hash], hasLength(64));
    expect(all[AppLockKeys.salt], hasLength(32));
    expect(all[AppLockKeys.kdf], '64,1,1');
    expect(
      all.values.any((v) => v.contains('123456')),
      isFalse,
      reason: 'der PIN selbst wird nie gespeichert',
    );
    // Die Sperre wandert nicht ins Backup.
    final snapshot = await services.services.transfer().snapshot();
    expect(snapshot.settings.keys.where(AppLockKeys.isLockKey), isEmpty);
  });

  testWidgets('Neustart zeigt den Sperrbildschirm und verbirgt Inhalte', (
    tester,
  ) async {
    final services = TestServices(
      seed: [
        testEntry(id: 'a', day: dayOfToday(), transcript: 'Kaffee im Park'),
      ],
    );
    await seedLock(services, '2468');
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('PIN eingeben'), findsOneWidget);
    expect(find.text('Kaffee im Park'), findsNothing);
    expect(find.byKey(recordButtonKey), findsNothing);
    // Die Hauptansicht ist aufgebaut, aber unerreichbar (Offstage).
    expect(find.byType(TodayScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);

    await enterPin(tester, '1111');
    expect(find.text('Falscher PIN. 1 Fehlversuch'), findsOneWidget);
    expect(await services.settings.get(AppLockKeys.failures), '1');
    expect(find.byType(LockScreen), findsOneWidget);

    await enterPin(tester, '2468');
    expect(find.byType(LockScreen), findsNothing);
    expect(find.byKey(recordButtonKey), findsOneWidget);
    expect(await services.settings.get(AppLockKeys.failures), '0');
  });

  testWidgets('Fünf Fehlversuche sperren das Feld für 30 Sekunden', (
    tester,
  ) async {
    final clock = FixedClock(DateTime(2026, 10, 27, 21));
    final services = TestServices(clock: clock);
    await seedLock(services, '2468');
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await enterPin(tester, '0000');
    }
    expect(find.text('Zu viele Versuche. Warte 30 Sekunden.'), findsOneWidget);
    expect(await services.settings.get(AppLockKeys.failures), '5');
    expect(await services.settings.get(AppLockKeys.lockedUntil), isNotEmpty);

    // Während der Wartezeit prüft nichts, auch der richtige PIN nicht.
    await enterPin(tester, '2468');
    expect(find.byType(LockScreen), findsOneWidget);
    expect(await services.settings.get(AppLockKeys.failures), '5');

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Zu viele Versuche. Warte 30 Sekunden.'), findsNothing);

    // Sechster Fehler: 60 Sekunden.
    await enterPin(tester, '0000');
    expect(find.text('Zu viele Versuche. Warte 60 Sekunden.'), findsOneWidget);
    clock.advance(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();

    await enterPin(tester, '2468');
    expect(find.byType(LockScreen), findsNothing);
    expect(await services.settings.get(AppLockKeys.lockedUntil), '');
  });

  testWidgets('PIN ändern verlangt den alten und zweimal den neuen', (
    tester,
  ) async {
    final services = TestServices();
    await seedLock(services, '1234');
    final oldHash = await services.settings.get(AppLockKeys.hash);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    await enterPin(tester, '1234');

    await openSettings(tester);
    await scrollSettingsTo(tester, find.byKey(appLockChangePinKey));
    await tester.tap(find.byKey(appLockChangePinKey));
    await pumpTransition(tester);
    expect(find.text('Aktuellen PIN eingeben'), findsOneWidget);
    await enterPin(tester, '9999');
    expect(find.text('Falscher PIN. 1 Fehlversuch'), findsOneWidget);
    await enterPin(tester, '1234');
    expect(find.text('Neuen PIN wählen (4 bis 8 Ziffern)'), findsOneWidget);
    await enterPin(tester, '98765');
    await enterPin(tester, '98765');
    await pumpTransition(tester);
    await tester.pumpAndSettle();
    expect(find.byType(PinFlowScreen), findsNothing);

    final stored = PinHash.decode(
      hashHex: await services.settings.get(AppLockKeys.hash),
      saltHex: await services.settings.get(AppLockKeys.salt),
      params: await services.settings.get(AppLockKeys.kdf),
    );
    expect(await services.settings.get(AppLockKeys.hash), isNot(oldHash));
    expect(await stored!.verify('98765', kdf: const Argon2idKdf()), isTrue);
    expect(await stored.verify('1234', kdf: const Argon2idKdf()), isFalse);
    expect(await services.settings.get(AppLockKeys.enabled), 'true');
  });

  testWidgets('Ausschalten verlangt den PIN und "Sperren nach" ist wählbar', (
    tester,
  ) async {
    final services = TestServices();
    await seedLock(services, '1234');
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    await enterPin(tester, '1234');

    await openSettings(tester);
    await scrollSettingsTo(tester, find.byKey(appLockAfterKey));
    expect(find.text('1 Minute'), findsOneWidget);
    await tester.tap(find.byKey(appLockAfterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 Minuten'));
    await tester.pumpAndSettle();
    expect(find.text('5 Minuten'), findsOneWidget);
    expect(await services.settings.get(AppLockKeys.lockAfter), '300');

    await scrollSettingsTo(tester, find.byKey(appLockSwitchKey));
    await tester.tap(find.byKey(appLockSwitchKey));
    await pumpTransition(tester);
    expect(
      find.text('PIN eingeben, um die Sperre auszuschalten'),
      findsOneWidget,
    );
    await enterPin(tester, '0000');
    expect(find.byType(PinFlowScreen), findsOneWidget);
    expect(await services.settings.get(AppLockKeys.enabled), 'true');

    await enterPin(tester, '1234');
    await pumpTransition(tester);
    await tester.pumpAndSettle();
    expect(find.byType(PinFlowScreen), findsNothing);
    expect(
      tester.widget<SwitchListTile>(find.byKey(appLockSwitchKey)).value,
      isFalse,
    );
    expect(await services.settings.get(AppLockKeys.enabled), 'false');
    expect(await services.settings.get(AppLockKeys.hash), '');
  });

  testWidgets('Hintergrund: Schleier sofort, Sperre nach der Sperrzeit', (
    tester,
  ) async {
    final clock = FixedClock(DateTime(2026, 10, 27, 21));
    final services = TestServices(clock: clock);
    await seedLock(services, '1234');
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    await enterPin(tester, '1234');
    expect(find.byKey(recordButtonKey), findsOneWidget);

    // Kurze Pause: Schleier sofort beim Fokusverlust, aber keine Sperre.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byKey(privacyVeilKey), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(find.byType(LockScreen), findsNothing);
    clock.advance(const Duration(seconds: 30));
    await toForeground(tester);
    expect(find.byKey(privacyVeilKey), findsNothing);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.byKey(recordButtonKey), findsOneWidget);

    // Länger als eine Minute: gesperrt.
    await toBackground(tester);
    clock.advance(const Duration(seconds: 61));
    await toForeground(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.byKey(recordButtonKey), findsNothing);

    await enterPin(tester, '1234');
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('Fokusverlust allein startet die Sperrzeit nicht', (
    tester,
  ) async {
    final clock = FixedClock(DateTime(2026, 10, 27, 21));
    final services = TestServices(clock: clock);
    await seedLock(services, '1234', lockAfter: LockAfter.immediately);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    await enterPin(tester, '1234');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byKey(privacyVeilKey), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(privacyVeilKey), findsNothing);
    expect(find.byType(LockScreen), findsNothing);

    // "Sofort": verborgen und zurück sperrt ohne Wartezeit.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await toForeground(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LockScreen), findsOneWidget);
  });

  testWidgets('Schnellaktion wartet bis nach dem Entsperren', (tester) async {
    final features = FakePlatformFeatures()..startAction = StartAction.record;
    final services = TestServices(features: features);
    await seedLock(services, '1234');
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.byType(RecordingScreen, skipOffstage: false), findsNothing);
    expect(features.startAction, isNull, reason: 'abgeholt, aber gemerkt');

    await enterPin(tester, '1234', settle: false);
    await pumpTransition(tester);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.byType(RecordingScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(stopButtonKey));
    await pumpTransition(tester);
    await tester.pumpAndSettle();
    expect(find.byType(RecordingScreen), findsNothing);
  });

  testWidgets(
    '"PIN vergessen" setzt die App nach dem Tippen des Wortes zurück',
    (tester) async {
      final services = TestServices();
      await seedLock(services, '1234');
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(lockForgotKey));
      await tester.pump();
      await tester.tap(find.byKey(lockForgotKey));
      await tester.pumpAndSettle();
      expect(find.text('PIN vergessen'), findsOneWidget);
      expect(find.textContaining('Backup mit Passphrase'), findsOneWidget);
      expect(find.byType(PinPad), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byKey(lockResetButtonKey)).enabled,
        isFalse,
      );

      await tester.enterText(find.byKey(lockResetFieldKey), 'löschen');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byKey(lockResetButtonKey)).enabled,
        isFalse,
        reason: 'nur das genaue Wort',
      );

      // Zurück zur Eingabe und wieder hin: das Feld bleibt.
      await tester.ensureVisible(find.byKey(lockResetBackKey));
      await tester.pump();
      await tester.tap(find.byKey(lockResetBackKey));
      await tester.pumpAndSettle();
      expect(find.byType(PinPad), findsOneWidget);
      await tester.ensureVisible(find.byKey(lockForgotKey));
      await tester.pump();
      await tester.tap(find.byKey(lockForgotKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(lockResetFieldKey), 'LÖSCHEN');
      await tester.pump();
      await tester.ensureVisible(find.byKey(lockResetButtonKey));
      await tester.pump();
      await tester.tap(find.byKey(lockResetButtonKey));
      await tester.pumpAndSettle();

      expect(services.resetCalls, 1);
      expect(find.byType(LockScreen), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(await services.settings.get(AppLockKeys.hash), isNull);
    },
  );
}

/// Heutiger Kalendertag (Mitternacht).
DateTime dayOfToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
