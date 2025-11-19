import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/training_models.dart';
import 'training_storage_service.dart';

/// Håndterer eksport og import av alle øvelser og treningsøkter.
///
/// Format (version 1):
/// {
///   "version": 1,
///   "exportedAt": "2025-11-19T08:31:00.000Z",
///   "exercises": [ ... ],
///   "sessions": [ ... ]
/// }
class BackupService {
  final TrainingStorageService _storage;

  BackupService({TrainingStorageService? storage})
      : _storage = storage ?? TrainingStorageService();

  /// Bygger et JSON-kart med hele databasen (øvelser + økter).
  Future<Map<String, dynamic>> _buildBackupMap() async {
    final exercises = await _storage.loadExercises();
    final sessions = await _storage.loadSessions();

    return <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  /// Eksporterer alle øvelser og økter til en JSON-fil og åpner delingsvindu.
  Future<void> exportBackup() async {
    // 1. Bygg komplett JSON
    final backupMap = await _buildBackupMap();
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupMap);

    // 2. Lag midlertidig fil
    final dir = await getTemporaryDirectory();
    final timestamp =
        DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final filename = 'styrketrening_backup_$timestamp.json';
    final filePath = '${dir.path}/$filename';

    final file = File(filePath);
    await file.writeAsString(jsonString);

    // 3. Del filen via systemets delingsmeny
    final xFile = XFile(
      file.path,
      mimeType: 'application/json',
      name: filename,
    );

    await Share.shareXFiles(
      [xFile],
      subject: 'Styrketrening backup',
      text: 'Backup av øvelser og treningsøkter fra app styrketrening.',
    );
  }

  /// Importerer en backup-fil valgt via filvelger.
  ///
  /// Returnerer:
  /// - true  => import gjennomført og lagret
  /// - false => bruker avbrøt (ingen endring gjort)
  ///
  /// Eksisterende øvelser og økter blir erstattet.
  Future<bool> importBackup() async {
    // 1. La brukeren velge JSON-fil
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      // Bruker avbrøt
      return false;
    }

    final path = result.files.single.path;
    if (path == null) {
      throw Exception('Kunne ikke lese valgt fil (mangler path).');
    }

    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Valgt fil finnes ikke lenger.');
    }

    // 2. Les og parse JSON
    final content = await file.readAsString();
    final dynamic decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Ugyldig backup-fil: forventet JSON-objekt.');
    }

    final map = decoded;

    // 3. Versjonssjekk
    final dynamic versionRaw = map['version'];
    final int version;
    if (versionRaw == null) {
      version = 1; // eldste format
    } else if (versionRaw is int) {
      version = versionRaw;
    } else {
      throw Exception('Ugyldig backup-fil: "version" må være et tall.');
    }

    if (version != 1) {
      throw Exception(
        'Backup-versjon $version støttes ikke av denne app-versjonen.',
      );
    }

    // 4. Les øvelser
    final dynamic exercisesRaw = map['exercises'];
    if (exercisesRaw is! List) {
      throw Exception('Ugyldig backup-fil: "exercises" må være en liste.');
    }

    final exercises = exercisesRaw.map<Exercise>((e) {
      if (e is! Map<String, dynamic>) {
        throw Exception(
          'Ugyldig element i "exercises" – forventet JSON-objekt.',
        );
      }
      return Exercise.fromJson(e);
    }).toList();

    // 5. Les økter
    final dynamic sessionsRaw = map['sessions'];
    if (sessionsRaw is! List) {
      throw Exception('Ugyldig backup-fil: "sessions" må være en liste.');
    }

    final sessions = sessionsRaw.map<ExerciseSession>((s) {
      if (s is! Map<String, dynamic>) {
        throw Exception(
          'Ugyldig element i "sessions" – forventet JSON-objekt.',
        );
      }
      return ExerciseSession.fromJson(s);
    }).toList();

    // 6. Lagre – erstatt alt eksisterende innhold
    await _storage.saveExercises(exercises);
    await _storage.saveSessions(sessions);

    return true;
  }
}

