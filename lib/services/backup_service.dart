import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/training_models.dart';
import 'training_storage_service.dart';

class BackupService {
  final TrainingStorageService _storage = TrainingStorageService();

  static const Duration backupReminderInterval = Duration(days: 30);

  Future<bool> shouldShowBackupReminder() async {
    final last = await _storage.getLastBackupDate();
    if (last == null) return true;

    final now = DateTime.now();
    final diff = now.difference(last);
    return diff >= backupReminderInterval;
  }

  Future<Directory> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/backups');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> exportBackup(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(0, 0, 1, 1);

    final exercises = await _storage.loadExercises();
    final sessions = await _storage.loadSessions();

    final nowUtc = DateTime.now().toUtc();
    final Map<String, dynamic> root = {
      'version': 1,
      'exportedAt': nowUtc.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(root);

    final suggestedFileName =
        'KaroStrengthTraining_backup_${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}_${nowUtc.hour.toString().padLeft(2, '0')}-${nowUtc.minute.toString().padLeft(2, '0')}.json';

    final dir = await _backupDir();
    final outFile = File('${dir.path}/$suggestedFileName');
    await outFile.writeAsBytes(utf8.encode(jsonString));

    await Share.shareXFiles(
      [XFile(outFile.path)],
      text: 'Exported training data backup.',
      sharePositionOrigin: origin,
    );

    await _storage.setLastBackupDate(DateTime.now());
  }

  Future<bool> importBackup() async {
    final dir = await _backupDir();
    final entries = await dir.list(followLinks: false).toList();

    final files = entries.whereType<File>().where((f) {
      final name = f.path.toLowerCase();
      return name.endsWith('.json');
    }).toList();

    if (files.isEmpty) return false;

    files.sort((a, b) {
      final am = a.statSync().modified;
      final bm = b.statSync().modified;
      return bm.compareTo(am);
    });

    final latest = files.first;
    final fileBytes = await latest.readAsBytes();
    final jsonString = utf8.decode(fileBytes);

    late Map<String, dynamic> root;
    try {
      root = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }

    final exercisesJson = root['exercises'] as List<dynamic>? ?? <dynamic>[];
    final sessionsJson = root['sessions'] as List<dynamic>? ?? <dynamic>[];

    final exercises = exercisesJson
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
    final sessions = sessionsJson
        .map((s) => ExerciseSession.fromJson(s as Map<String, dynamic>))
        .toList();

    await _storage.saveExercises(exercises);
    await _storage.saveSessions(sessions);

    return true;
  }
}
