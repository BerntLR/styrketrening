import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/training_models.dart';
import 'training_storage_service.dart';

/// The data read from a backup file.
class BackupData {
  const BackupData(this.exercises, this.sessions);
  final List<Exercise> exercises;
  final List<ExerciseSession> sessions;
}

/// Export/import of all exercises and sessions as one JSON file.
class BackupService {
  static const String appId = 'karos_strength';
  static const int schemaVersion = 2;

  final TrainingStorageService _storage = TrainingStorageService();

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// karos_strength_backup_YYYY-MM-DD_HH-mm.json (local time).
  static String fileName(DateTime t) =>
      '${appId}_backup_${t.year}-${_two(t.month)}-${_two(t.day)}'
      '_${_two(t.hour)}-${_two(t.minute)}.json';

  static String encode(
    List<Exercise> exercises,
    List<ExerciseSession> sessions, {
    required DateTime now,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'app': appId,
      'schemaVersion': schemaVersion,
      'exportedAt': now.toUtc().toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });
  }

  /// Reads a backup. Also accepts files from older versions of the app
  /// (no "app" field). Throws [FormatException] when the file is not valid.
  static BackupData decode(String text) {
    try {
      final root = jsonDecode(text);
      if (root is! Map<String, dynamic>) {
        throw const FormatException('not an object');
      }
      final app = root['app'];
      if (app != null && app != appId) {
        throw const FormatException('backup from another app');
      }
      final ex = root['exercises'];
      final se = root['sessions'];
      if (ex is! List || se is! List) {
        throw const FormatException('missing exercises or sessions');
      }
      return BackupData(
        ex.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList(),
        se
            .map((s) => ExerciseSession.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('invalid backup: $e');
    }
  }

  /// Saves via the system "save file" dialog, or the share sheet when that
  /// is not available. Returns true when a file was saved or shared.
  Future<bool> exportBackup({
    required Rect shareOrigin,
    String? dialogTitle,
  }) async {
    final now = DateTime.now();
    final name = fileName(now);
    final bytes = utf8.encode(
      encode(
        await _storage.loadExercises(),
        await _storage.loadSessions(),
        now: now,
      ),
    );

    String? path;
    try {
      path = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: name,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
    } catch (_) {
      path = null;
    }

    var ok = false;
    if (path != null) {
      final f = File(path);
      if (!await f.exists() || await f.length() == 0) {
        await f.writeAsBytes(bytes, flush: true);
      }
      ok = true;
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      final res = await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/json'),
      ], sharePositionOrigin: shareOrigin);
      ok = res.status == ShareResultStatus.success;
    }

    if (ok) await _storage.setLastBackupDate(now);
    return ok;
  }

  /// Lets the user pick a backup file. Returns null when cancelled.
  /// Throws [FormatException] when the file is not a valid backup.
  Future<BackupData?> pickBackup() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return null;
    final f = res.files.first;
    final String text;
    try {
      text = f.bytes != null
          ? utf8.decode(f.bytes!)
          : await File(f.path!).readAsString();
    } catch (e) {
      throw FormatException('could not read file: $e');
    }
    return decode(text);
  }

  /// Replaces all data with [data]. Only called after the whole file has
  /// been read and checked, so a bad file never changes anything.
  Future<void> restore(BackupData data) async {
    await _storage.saveExercises(data.exercises);
    await _storage.saveSessions(data.sessions);
  }
}
