import 'dart:convert';
import 'dart:typed_data';

import 'package:diary_container/diary_container.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:meta/meta.dart';

import '../model/entry.dart';
import '../model/goal.dart';
import '../model/json_codecs.dart';
import '../model/local_day.dart';
import '../model/note.dart';
import '../model/recording.dart';
import '../model/reminder_settings.dart';
import '../model/transcript.dart';
import '../ports/clock.dart';
import '../ports/files.dart';
import '../ports/repositories.dart';
import '../ports/services.dart';

/// Abschnitt eines Exports oder Imports für die Fortschrittsanzeige.
enum TransferPhase {
  /// Einträge, Aufnahmen, Transkripte und Audio werden gesammelt.
  collecting,

  /// Schlüsselableitung (Argon2id dauert spürbar).
  derivingKey,

  /// Nutzdaten werden verschlüsselt geschrieben.
  encrypting,

  /// Nutzdaten werden entschlüsselt und geprüft.
  decrypting,

  /// Einträge und Audiodateien werden angelegt.
  importing,
}

@immutable
class TransferProgress {
  const TransferProgress(this.phase, {this.done = 0, this.total = 0});
  final TransferPhase phase;
  final int done;
  final int total;

  /// 0 bis 1 oder `null`, wenn die Gesamtmenge unbekannt ist.
  double? get fraction => total <= 0 ? null : (done / total).clamp(0.0, 1.0);
}

typedef TransferProgressCallback = void Function(TransferProgress progress);

/// Ergebnis eines Exports für ein anderes Gerät.
@immutable
class TransferExport {
  const TransferExport({required this.bytes, required this.verificationCode});
  final Uint8List bytes;

  /// Sechsstelliger Code aus dem QR-Code des Empfängers; beide Geräte zeigen
  /// ihn, damit kein untergeschobener Code unbemerkt bleibt (docs/06 8).
  final String verificationCode;
}

/// Sitzung des neuen Geräts: Schlüsselpaar und Sitzungs-ID hinter dem
/// QR-Code. Wird bis zum Import gespeichert (verschlüsselt über das
/// `SettingsRepository`), weil die Datei erst später eintrifft.
@immutable
class ReceiveSession {
  const ReceiveSession({
    required this.sessionId,
    required this.keyPair,
    required this.createdAt,
    this.platform = 0,
  });

  final Uint8List sessionId;
  final X25519KeyPair keyPair;
  final DateTime createdAt;
  final int platform;

  QrPayload get qrPayload => QrPayload(
    platform: platform,
    sessionId: sessionId,
    publicKey: keyPair.publicKey,
  );

  String get verificationCode => qrPayload.verificationCode();

  Map<String, Object?> toJson() => {
    'sessionId': base64Encode(sessionId),
    'privateKey': base64Encode(keyPair.privateKey),
    'publicKey': base64Encode(keyPair.publicKey),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'platform': platform,
  };

  static ReceiveSession fromJson(Map<String, Object?> j) => ReceiveSession(
    sessionId: base64Decode(j['sessionId'] as String),
    keyPair: X25519KeyPair(
      privateKey: base64Decode(j['privateKey'] as String),
      publicKey: base64Decode(j['publicKey'] as String),
    ),
    createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
    platform: j['platform'] as int? ?? 0,
  );
}

/// Inhalt eines Tagebuchs, wie er in `db.ndjson` steht. Dateischlüssel
/// werden nicht exportiert (das Audio liegt im Container als Rohbytes und
/// wird beim Import neu gewrappt).
@immutable
class TransferSnapshot {
  const TransferSnapshot({
    required this.entries,
    required this.recordings,
    required this.transcripts,
    this.notes = const [],
    this.goals = const [],
    this.milestones = const [],
    this.reminder,
    this.settings = const {},
  });

  /// Schemaversion des NDJSON-Exports (Manifest `schemaVersion`). Die
  /// Zeilentypen `note` (D17) sowie `goal` und `milestone` (D19) kamen ohne
  /// Versionssprung hinzu: Leser überspringen unbekannte Typen, und eine
  /// Datei ohne Notizen oder Ziele bleibt gültig.
  static const int schemaVersion = 1;

  final List<DiaryEntry> entries;
  final List<Recording> recordings;
  final List<Transcript> transcripts;

  /// Geschriebene Texte (D17); fehlt in Dateien älterer Versionen.
  final List<EntryNote> notes;

  /// Ziele und Etappen (D19); fehlen in Dateien älterer Versionen.
  final List<Goal> goals;
  final List<Milestone> milestones;
  final ReminderSettings? reminder;
  final Map<String, String> settings;

  String? get firstDay => entries.isEmpty
      ? null
      : entries.map((e) => e.day).reduce((a, b) => a.isBefore(b) ? a : b).iso;
  String? get lastDay => entries.isEmpty
      ? null
      : entries.map((e) => e.day).reduce((a, b) => a.isAfter(b) ? a : b).iso;

  /// Eine JSON-Zeile je Datensatz mit Feld `type`.
  String encodeNdjson() {
    final lines = <String>[];
    void line(String type, Map<String, Object?> m) =>
        lines.add(jsonEncode({'type': type, ...m}));
    for (final e in entries) {
      line('entry', ModelJson.encodeEntry(e));
    }
    for (final r in recordings) {
      line(
        'recording',
        ModelJson.encodeRecording(r.copyWith(fileKeyWrapped: Uint8List(0))),
      );
    }
    for (final t in transcripts) {
      line('transcript', ModelJson.encodeTranscript(t));
    }
    for (final n in notes) {
      line('note', ModelJson.encodeNote(n));
    }
    for (final g in goals) {
      line('goal', ModelJson.encodeGoal(g));
    }
    for (final m in milestones) {
      line('milestone', ModelJson.encodeMilestone(m));
    }
    if (reminder != null) {
      line('reminder', ModelJson.encodeReminderSettings(reminder!));
    }
    for (final s in settings.entries) {
      line('setting', {'key': s.key, 'value': s.value});
    }
    return lines.map((l) => '$l\n').join();
  }

  /// Unbekannte Typen werden übersprungen (Vorwärtskompatibilität).
  static TransferSnapshot decodeNdjson(String text) {
    final entries = <DiaryEntry>[];
    final recordings = <Recording>[];
    final transcripts = <Transcript>[];
    final notes = <EntryNote>[];
    final goals = <Goal>[];
    final milestones = <Milestone>[];
    ReminderSettings? reminder;
    final settings = <String, String>{};
    for (final raw in LineSplitter.split(text)) {
      if (raw.trim().isEmpty) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Zeile in db.ndjson ist kein Objekt');
      }
      final m = Map<String, Object?>.from(decoded);
      switch (m['type']) {
        case 'entry':
          entries.add(ModelJson.decodeEntry(m));
        case 'recording':
          recordings.add(ModelJson.decodeRecording(m));
        case 'transcript':
          transcripts.add(ModelJson.decodeTranscript(m));
        case 'note':
          notes.add(ModelJson.decodeNote(m));
        case 'goal':
          goals.add(ModelJson.decodeGoal(m));
        case 'milestone':
          milestones.add(ModelJson.decodeMilestone(m));
        case 'reminder':
          reminder = ModelJson.decodeReminderSettings(m);
        case 'setting':
          settings[m['key'] as String] = m['value'] as String;
        default:
          continue;
      }
    }
    return TransferSnapshot(
      entries: entries,
      recordings: recordings,
      transcripts: transcripts,
      notes: notes,
      goals: goals,
      milestones: milestones,
      reminder: reminder,
      settings: settings,
    );
  }
}

/// Ein geöffneter Container: Manifest zur Zusammenfassung vor dem Import und
/// die entschlüsselten Nutzdaten.
class OpenedContainer {
  const OpenedContainer({
    required this.header,
    required this.payload,
    required this.snapshot,
  });
  final ContainerHeader header;
  final ContainerPayload payload;
  final TransferSnapshot snapshot;

  ContainerManifest get manifest => payload.manifest;
}

@immutable
class ImportResult {
  const ImportResult({
    required this.entriesCreated,
    required this.entriesMerged,
    required this.recordingsImported,
    required this.recordingsSkipped,
    this.notesImported = 0,
    this.notesSkipped = 0,
    this.goalsImported = 0,
    this.goalsSkipped = 0,
    this.milestonesImported = 0,
    this.milestonesSkipped = 0,
  });
  final int entriesCreated;

  /// Einträge, deren Tag es hier schon gab: Aufnahmen wurden angehängt.
  final int entriesMerged;
  final int recordingsImported;

  /// Aufnahmen, deren Kennung hier schon vorhanden war.
  final int recordingsSkipped;

  /// Geschriebene Texte (D17), übernommen bzw. wegen vorhandener Kennung
  /// übersprungen.
  final int notesImported;
  final int notesSkipped;

  /// Ziele und Etappen (D19), übernommen bzw. übersprungen (Kennung schon
  /// vorhanden oder Ziel der Etappe unbekannt).
  final int goalsImported;
  final int goalsSkipped;
  final int milestonesImported;
  final int milestonesSkipped;
}

/// Backup und Gerätewechsel (M8, D6, D16): packt alle Einträge in den
/// Container aus `diary_container` und liest ihn auf dem Zielgerät wieder
/// ein. Zwei Schlüsselwege: Passphrase (Argon2id) für das Backup, X25519 mit
/// dem QR-Code des Empfängers für den Gerätewechsel.
///
/// Import führt zusammen: Ein Tag, den es hier schon gibt, behält seinen
/// Eintrag; die Aufnahmen aus dem Container werden angehängt. Aufnahmen mit
/// bereits vorhandener Kennung werden übersprungen; nichts wird überschrieben.
class TransferUseCase {
  TransferUseCase({
    required this.journalId,
    required this.entries,
    required this.recordings,
    required this.transcripts,
    required this.settings,
    required this.audioSource,
    required this.audioSink,
    required this.ids,
    required this.clock,
    this.notes,
    this.goals,
    this.appVersion = '0.0.0',
    this.argon2Params = Argon2Params.standard,
    this.keys = const ContainerKeys(),
    ContainerStreamCipherFactory? cipherFactory,
    RandomSource? random,
  }) : cipherFactory = cipherFactory ?? ChunkAeadStreamCipherFactory(),
       _random = random ?? SecureRandomSource();

  /// Dateiendung des Containers.
  static const String fileExtension = 'tgbx';

  /// Mindestlänge der Backup-Passphrase (docs/06 6.1 nennt zwölf als Ziel;
  /// acht ist die Untergrenze der Oberfläche).
  static const int minPassphraseLength = 8;

  final String journalId;
  final EntryRepository entries;
  final RecordingRepository recordings;
  final TranscriptRepository transcripts;

  /// Geschriebene Texte (D17); `null`, wenn die Plattform keine hat.
  final NoteRepository? notes;

  /// Ziele und Etappen (D19); `null`, wenn die Plattform keine hat.
  final GoalRepository? goals;
  final SettingsRepository settings;
  final AudioFileSource audioSource;
  final AudioFileSink audioSink;
  final IdGenerator ids;
  final Clock clock;
  final String appVersion;
  final Argon2Params argon2Params;
  final ContainerKeys keys;
  final ContainerStreamCipherFactory cipherFactory;
  final RandomSource _random;

  /// Dateiname `tagebuch-backup-JJJJ-MM-TT.tgbx` für [day].
  static String backupFileName(LocalDay day) =>
      'tagebuch-backup-${day.iso}.$fileExtension';

  /// Dateiname `tagebuch-transfer-JJJJ-MM-TT.tgbx` für den Gerätewechsel.
  static String transferFileName(LocalDay day) =>
      'tagebuch-transfer-${day.iso}.$fileExtension';

  // ----- Export -----------------------------------------------------------

  /// Backup mit Passphrase.
  Future<Uint8List> exportWithPassphrase(
    String passphrase, {
    TransferProgressCallback? onProgress,
  }) async {
    if (passphrase.length < minPassphraseLength) {
      throw ArgumentError('Passphrase zu kurz');
    }
    final builder = await _collect(onProgress);
    onProgress?.call(const TransferProgress(TransferPhase.derivingKey));
    final salt = _random.bytes(argon2Params.saltLength);
    final sessionId = _random.bytes(16);
    final key = await keys.fromPassphrase(
      passphrase: passphrase,
      salt: salt,
      params: argon2Params,
    );
    try {
      final check = await keys.keyCheck(key, sessionId);
      return await _write(
        builder,
        key,
        (sh) => ContainerHeader(
          keyKind: ContainerKeyKind.passphraseArgon2id,
          cipher: ContainerCipher.chunkAeadXchacha20,
          sessionId: sessionId,
          salt: salt,
          argon2Params: argon2Params,
          keyCheck: check,
          streamHeader: sh,
        ),
        onProgress,
      );
    } finally {
      zeroize(key);
    }
  }

  /// Gerätewechsel: Export für den Empfänger aus dem gescannten QR-Code.
  Future<TransferExport> exportForRecipient(
    QrPayload recipient, {
    TransferProgressCallback? onProgress,
  }) async {
    final builder = await _collect(onProgress);
    onProgress?.call(const TransferProgress(TransferPhase.derivingKey));
    final sender = await keys.forRecipient(
      recipientPublicKey: recipient.publicKey,
      sessionId: recipient.sessionId,
    );
    try {
      final check = await keys.keyCheck(sender.key, recipient.sessionId);
      final bytes = await _write(
        builder,
        sender.key,
        (sh) => ContainerHeader(
          keyKind: ContainerKeyKind.recipientX25519,
          cipher: ContainerCipher.chunkAeadXchacha20,
          sessionId: recipient.sessionId,
          ephemeralPublicKey: sender.ephemeralPublicKey,
          keyCheck: check,
          streamHeader: sh,
        ),
        onProgress,
      );
      return TransferExport(
        bytes: bytes,
        verificationCode: recipient.verificationCode(),
      );
    } finally {
      zeroize(sender.key);
    }
  }

  /// Neues Gerät: Sitzung mit Schlüsselpaar für den QR-Code anlegen.
  Future<ReceiveSession> createReceiveSession({int platform = 0}) async =>
      ReceiveSession(
        sessionId: _random.bytes(16),
        keyPair: await keys.x25519.newKeyPair(),
        createdAt: clock.now(),
        platform: platform,
      );

  Future<TransferSnapshot> snapshot() async {
    final allEntries = await entries.listAll(journalId);
    final allRecordings = <Recording>[];
    final allTranscripts = <Transcript>[];
    final allNotes = <EntryNote>[];
    final noteRepo = notes;
    for (final e in allEntries) {
      for (final r in await recordings.listForEntry(e.id)) {
        allRecordings.add(r);
        allTranscripts.addAll(await transcripts.listForRecording(r.id));
      }
      if (noteRepo != null) allNotes.addAll(await noteRepo.listForEntry(e.id));
    }
    final goalRepo = goals;
    final allGoals = goalRepo == null
        ? const <Goal>[]
        : await goalRepo.listAllGoals(journalId);
    final allMilestones = <Milestone>[];
    if (goalRepo != null) {
      for (final g in allGoals) {
        allMilestones.addAll(await goalRepo.listMilestones(g.id));
      }
    }
    return TransferSnapshot(
      entries: allEntries,
      recordings: allRecordings,
      transcripts: allTranscripts,
      notes: allNotes,
      goals: allGoals,
      milestones: allMilestones,
      reminder: await settings.reminder(),
      settings: await settings.all(),
    );
  }

  Future<ContainerPayloadBuilder> _collect(
    TransferProgressCallback? onProgress,
  ) async {
    onProgress?.call(const TransferProgress(TransferPhase.collecting));
    final snap = await snapshot();
    final builder = ContainerPayloadBuilder(
      createdAt: clock.now(),
      appVersion: appVersion,
      schemaVersion: TransferSnapshot.schemaVersion,
      entryCount: snap.entries.length,
      recordingCount: snap.recordings.length,
      noteCount: snap.notes.length,
      goalCount: snap.goals.length,
      milestoneCount: snap.milestones.length,
      firstDay: snap.firstDay,
      lastDay: snap.lastDay,
    );
    await builder.add(
      ContainerPayload.databaseName,
      Uint8List.fromList(utf8.encode(snap.encodeNdjson())),
    );
    var done = 0;
    for (final r in snap.recordings) {
      done++;
      if (r.state == RecordingState.audioDeleted) continue;
      final audio = await audioSource.read(r);
      if (audio == null) continue;
      await builder.add('${ContainerPayload.audioPrefix}${r.fileName}', audio);
      onProgress?.call(
        TransferProgress(
          TransferPhase.collecting,
          done: done,
          total: snap.recordings.length,
        ),
      );
    }
    return builder;
  }

  Future<Uint8List> _write(
    ContainerPayloadBuilder builder,
    Uint8List key,
    ContainerHeader Function(Uint8List streamHeader) header,
    TransferProgressCallback? onProgress,
  ) async {
    onProgress?.call(const TransferProgress(TransferPhase.encrypting));
    final out = BytesBuilder(copy: false);
    final writer = await ContainerWriter.start(
      cipherFactory: cipherFactory,
      key: key,
      header: header,
      sink: out.add,
    );
    await builder.writeTo(
      writer,
      onProgress: (done, total) => onProgress?.call(
        TransferProgress(TransferPhase.encrypting, done: done, total: total),
      ),
    );
    return out.toBytes();
  }

  // ----- Import -----------------------------------------------------------

  /// Liest nur den Kopf (Schlüsselart), ohne Schlüssel.
  ContainerHeader inspect(Uint8List bytes) => ContainerReader(bytes).header;

  /// Backup öffnen: Argon2id-Parameter und Salt aus dem Kopf.
  Future<OpenedContainer> openWithPassphrase(
    Uint8List bytes,
    String passphrase, {
    TransferProgressCallback? onProgress,
  }) async {
    final reader = ContainerReader(bytes);
    final h = reader.header;
    if (h.keyKind != ContainerKeyKind.passphraseArgon2id) {
      throw const ContainerException(
        ContainerError.wrongKey,
        'Diese Datei ist ein Gerätewechsel-Container, kein Backup',
      );
    }
    onProgress?.call(const TransferProgress(TransferPhase.derivingKey));
    final key = await keys.fromPassphrase(
      passphrase: passphrase,
      salt: h.salt!,
      params: h.argon2Params!,
    );
    try {
      return await _open(reader, key, onProgress);
    } finally {
      zeroize(key);
    }
  }

  /// Gerätewechsel: Datei mit der eigenen Sitzung öffnen.
  Future<OpenedContainer> openAsRecipient(
    Uint8List bytes,
    ReceiveSession session, {
    TransferProgressCallback? onProgress,
  }) async {
    final reader = ContainerReader(bytes);
    final h = reader.header;
    if (h.keyKind != ContainerKeyKind.recipientX25519) {
      throw const ContainerException(
        ContainerError.wrongKey,
        'Diese Datei ist ein Backup mit Passphrase',
      );
    }
    if (!constantTimeEquals(h.sessionId, session.sessionId)) {
      throw const ContainerException(
        ContainerError.wrongSession,
        'Diese Datei wurde für einen anderen Code erstellt',
      );
    }
    onProgress?.call(const TransferProgress(TransferPhase.derivingKey));
    final key = await keys.asRecipient(
      recipientPrivateKey: session.keyPair.privateKey,
      ephemeralPublicKey: h.ephemeralPublicKey!,
      sessionId: h.sessionId,
    );
    try {
      return await _open(reader, key, onProgress);
    } finally {
      zeroize(key);
    }
  }

  Future<OpenedContainer> _open(
    ContainerReader reader,
    Uint8List key,
    TransferProgressCallback? onProgress,
  ) async {
    onProgress?.call(const TransferProgress(TransferPhase.decrypting));
    final clear = await reader.decrypt(
      key,
      cipherFactory,
      keys: keys,
      onProgress: (done, total) => onProgress?.call(
        TransferProgress(TransferPhase.decrypting, done: done, total: total),
      ),
    );
    final payload = await ContainerPayload.parse(clear);
    if (payload.manifest.schemaVersion > TransferSnapshot.schemaVersion) {
      throw ContainerException(
        ContainerError.unsupported,
        'Datenbank-Schema ${payload.manifest.schemaVersion} ist neuer als '
        'diese App (${TransferSnapshot.schemaVersion})',
      );
    }
    final db = payload.file(ContainerPayload.databaseName);
    if (db == null) {
      throw const ContainerException(
        ContainerError.manifestMismatch,
        'db.ndjson fehlt im Container',
      );
    }
    final TransferSnapshot snapshot;
    try {
      snapshot = TransferSnapshot.decodeNdjson(utf8.decode(db));
    } on FormatException catch (e) {
      throw ContainerException(ContainerError.manifestMismatch, e.message);
    } on TypeError catch (e) {
      throw ContainerException(ContainerError.manifestMismatch, '$e');
    }
    return OpenedContainer(
      header: reader.header,
      payload: payload,
      snapshot: snapshot,
    );
  }

  /// Übernimmt den geöffneten Container in die Repositories.
  Future<ImportResult> import(
    OpenedContainer opened, {
    TransferProgressCallback? onProgress,
  }) async {
    final snap = opened.snapshot;
    final localEntries = await entries.listAll(journalId);
    final freshDevice = localEntries.isEmpty;
    final existingRecordingIds = {
      for (final r in await recordings.listAll()) r.id,
    };
    final byEntry = <String, List<Recording>>{};
    for (final r in snap.recordings) {
      byEntry.putIfAbsent(r.entryId, () => []).add(r);
    }
    final byRecording = <String, List<Transcript>>{};
    for (final t in snap.transcripts) {
      byRecording.putIfAbsent(t.recordingId, () => []).add(t);
    }
    final notesByEntry = <String, List<EntryNote>>{};
    for (final n in snap.notes) {
      notesByEntry.putIfAbsent(n.entryId, () => []).add(n);
    }
    final noteRepo = notes;

    var created = 0;
    var merged = 0;
    var imported = 0;
    var skipped = 0;
    var notesImported = 0;
    var notesSkipped = 0;
    var done = 0;
    final total = snap.recordings.length;
    onProgress?.call(TransferProgress(TransferPhase.importing, total: total));

    for (final e in snap.entries) {
      final existing = await entries.findByDay(journalId, e.day);
      final String targetId;
      if (existing != null) {
        targetId = existing.id;
        merged++;
      } else {
        final fresh = await entries.getOrCreate(journalId, e.day, e.createdAt);
        if (e.title != null || e.mood != null || e.pinned) {
          await entries.update(
            fresh.copyWith(
              title: e.title,
              mood: e.mood,
              pinned: e.pinned,
              updatedAt: e.updatedAt,
            ),
          );
        }
        targetId = fresh.id;
        created++;
      }
      for (final r in byEntry[e.id] ?? const <Recording>[]) {
        done++;
        if (existingRecordingIds.contains(r.id)) {
          skipped++;
          continue;
        }
        final audio = opened.payload.file(
          '${ContainerPayload.audioPrefix}${r.fileName}',
        );
        Recording target;
        if (audio != null && r.state != RecordingState.audioDeleted) {
          final stored = await audioSink.write(r.fileName, audio);
          target = Recording(
            id: r.id,
            entryId: targetId,
            startedAt: r.startedAt,
            duration: r.duration,
            codec: r.codec,
            container: r.container,
            sampleRate: r.sampleRate,
            bitrate: r.bitrate,
            fileName: r.fileName,
            fileKeyWrapped: stored.fileKeyWrapped,
            sizeBytes: stored.sizeBytes,
            state: r.state,
            waveform: r.waveform,
          );
        } else {
          target = Recording(
            id: r.id,
            entryId: targetId,
            startedAt: r.startedAt,
            duration: r.duration,
            codec: r.codec,
            container: r.container,
            sampleRate: r.sampleRate,
            bitrate: r.bitrate,
            fileName: r.fileName,
            fileKeyWrapped: Uint8List(0),
            sizeBytes: 0,
            state: RecordingState.audioDeleted,
            waveform: r.waveform,
          );
        }
        await recordings.insert(target);
        existingRecordingIds.add(r.id);
        for (final t in byRecording[r.id] ?? const <Transcript>[]) {
          await transcripts.insert(t);
        }
        imported++;
        onProgress?.call(
          TransferProgress(TransferPhase.importing, done: done, total: total),
        );
      }
      // Notizen (D17) hängen am Zieleintrag; vorhandene Kennungen bleiben.
      final incoming = notesByEntry[e.id] ?? const <EntryNote>[];
      if (noteRepo != null && incoming.isNotEmpty) {
        final present = {
          for (final n in await noteRepo.listForEntry(targetId)) n.id,
        };
        for (final n in incoming) {
          if (present.contains(n.id)) {
            notesSkipped++;
            continue;
          }
          await noteRepo.insert(n.copyWith(entryId: targetId));
          notesImported++;
        }
      }
    }

    // Ziele und Etappen (D19): Kennungen bleiben, vorhandene werden
    // übersprungen; die Drei-Grenze gilt nur beim Anlegen, nicht hier.
    var goalsImported = 0;
    var goalsSkipped = 0;
    var milestonesImported = 0;
    var milestonesSkipped = 0;
    final goalRepo = goals;
    if (goalRepo != null && snap.goals.isNotEmpty) {
      final knownGoals = <String>{};
      for (final g in snap.goals) {
        if (await goalRepo.goalById(g.id) != null) {
          knownGoals.add(g.id);
          goalsSkipped++;
          continue;
        }
        await goalRepo.insertGoal(
          Goal(
            id: g.id,
            journalId: journalId,
            title: g.title,
            why: g.why,
            createdAt: g.createdAt,
            updatedAt: g.updatedAt,
            completedAt: g.completedAt,
            archivedAt: g.archivedAt,
            sortIndex: g.sortIndex,
          ),
        );
        knownGoals.add(g.id);
        goalsImported++;
      }
      for (final m in snap.milestones) {
        if (!knownGoals.contains(m.goalId) ||
            await goalRepo.milestoneById(m.id) != null) {
          milestonesSkipped++;
          continue;
        }
        await goalRepo.insertMilestone(m);
        milestonesImported++;
      }
    }

    // Einstellungen: nur ergänzen, nie überschreiben; die Erinnerung nur auf
    // einem Gerät ohne eigene Einträge.
    for (final s in snap.settings.entries) {
      if (await settings.get(s.key) == null) {
        await settings.set(s.key, s.value);
      }
    }
    if (freshDevice && snap.reminder != null) {
      await settings.saveReminder(snap.reminder!);
    }
    return ImportResult(
      entriesCreated: created,
      entriesMerged: merged,
      recordingsImported: imported,
      recordingsSkipped: skipped,
      notesImported: notesImported,
      notesSkipped: notesSkipped,
      goalsImported: goalsImported,
      goalsSkipped: goalsSkipped,
      milestonesImported: milestonesImported,
      milestonesSkipped: milestonesSkipped,
    );
  }
}
