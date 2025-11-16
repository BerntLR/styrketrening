import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/training_models.dart';
import 'training_storage_service.dart';

class BackupService {
  final TrainingStorageService _storage = TrainingStorageService();

  Future<String> createBackupFile() async {
    final List<Exercise> exercises = await _storage.loadExercises();
    final List<ExerciseSession> sessions = await _storage.loadSessions();

    final Map<String, dynamic> data = {
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };

    final jsonString = jsonEncode(data);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now();
    final ts =
        '${timestamp.year.toString().padLeft(4, '0')}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.day.toString().padLeft(2, '0')}_'
        '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}'
        '${timestamp.second.toString().padLeft(2, '0')}';

    final fileName = 'styrketrening_backup_$ts.json';
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(jsonString);

    return file.path;
  }
}
