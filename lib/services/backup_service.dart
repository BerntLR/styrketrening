import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/training_models.dart';
import 'training_storage_service.dart';

class BackupService {
  final TrainingStorageService _storage = TrainingStorageService();

  /// Hvor ofte vi vil minne brukeren om backup.
  /// 30 dager ~ ca. 1 gang i måneden.
  static const Duration backupReminderInterval = Duration(days: 30);

  /// Sjekker om det er på tide med en backup-paminnelse.
  ///
  /// - Returnerer true hvis:
  ///   - vi aldri har tatt backup (ingen dato lagret), eller
  ///   - det har gaatt minst [backupReminderInterval] siden sist backup.
  /// - Returnerer false ellers.
  Future<bool> shouldShowBackupReminder() async {
    final last = await _storage.getLastBackupDate();
    if (last == null) {
      // Aldri tatt backup -> vis paminnelse
      return true;
    }

    final now = DateTime.now();
    final diff = now.difference(last);

    return diff >= backupReminderInterval;
  }

  /// Eksporterer alle ovelser og sessions som en JSON-fil.
  ///
  /// Format (root-objekt):
  /// {
  ///   "version": 1,
  ///   "exportedAt": "2025-01-01T12:34:56.000Z",
  ///   "exercises": [ ... ],
  ///   "sessions":  [ ... ]
  /// }
  Future<void> exportBackup() async {
    // 1. Hent data
    final exercises = await _storage.loadExercises();
    final sessions = await _storage.loadSessions();

    // 2. Bygg JSON-struktur
    final nowUtc = DateTime.now().toUtc();
    final Map<String, dynamic> root = {
      'version': 1,
      'exportedAt': nowUtc.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(root);

    // 3. Lag midlertidig fil
    final suggestedFileName =
        'styrketrening_backup_${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}_${nowUtc.hour.toString().padLeft(2, '0')}-${nowUtc.minute.toString().padLeft(2, '0')}.json';

    final tmpDirPath = (await getTemporaryDirectory()).path;
    final outFile = File('$tmpDirPath/$suggestedFileName');
    await outFile.writeAsBytes(utf8.encode(jsonString));

    // 4. Del filen (bruker velger hvor den havner)
    await Share.shareXFiles(
      [XFile(outFile.path)],
      subject: 'Styrketrening backup',
      text: 'Here is the exported training data JSON.',
    );

    // 5. Marker at vi na har tatt backup (bruk lokal tid til paminnelseslogikk)
    await _storage.setLastBackupDate(DateTime.now());
  }

  /// Importerer en tidligere eksportert JSON-fil.
  ///
  /// Returnerer true hvis importen gikk bra, false hvis brukeren avbrot
  /// eller noe var feil.
  Future<bool> importBackup() async {
    // 1. La brukeren velge fil
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return false; // avbrutt
    }

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) {
      return false;
    }

    final jsonString = utf8.decode(fileBytes);

    // 2. Parse JSON
    late Map<String, dynamic> root;
    try {
      root = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }

    // 3. Les arrays
    final exercisesJson = root['exercises'] as List<dynamic>? ?? <dynamic>[];
    final sessionsJson = root['sessions'] as List<dynamic>? ?? <dynamic>[];

    final exercises = exercisesJson
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
    final sessions = sessionsJson
        .map((s) => ExerciseSession.fromJson(s as Map<String, dynamic>))
        .toList();

    // 4. Lagre inn i appens storage (overskriver alt eksisterende)
    await _storage.saveExercises(exercises);
    await _storage.saveSessions(sessions);

    return true;
  }
}

