import 'package:flutter_test/flutter_test.dart';
import 'package:karo_strength_training/models/training_models.dart';
import 'package:karo_strength_training/services/backup_service.dart';
import 'package:karo_strength_training/utils/formatting.dart';

void main() {
  group('weight input', () {
    test('accepts comma and point', () {
      expect(parseWeight('62,5'), 62.5);
      expect(parseWeight('62.5'), 62.5);
      expect(parseWeight(' 80 '), 80);
    });
    test('rejects text', () {
      expect(parseWeight('abc'), isNull);
      expect(parseWeight(''), isNull);
      expect(parseWeight('-5'), isNull);
    });
    test('reps are whole numbers', () {
      expect(parseReps('8'), 8);
      expect(parseReps('8,5'), isNull);
    });
    test('formats without trailing zero', () {
      expect(formatWeight(60), '60');
      expect(formatWeight(62.5), '62.5');
      expect(formatWeight(1.25), '1.25');
    });
  });

  group('backup', () {
    final ex = [Exercise(id: '1', name: 'Benkpress')];
    final se = [
      ExerciseSession(
        id: 'a',
        exerciseId: '1',
        date: DateTime(2026, 11, 18, 18),
        sets: [ExerciseSet(setIndex: 1, weightKg: 62.5, reps: 8)],
      ),
    ];

    test('round trip keeps everything', () {
      final text = BackupService.encode(ex, se, now: DateTime(2026, 11, 19));
      expect(text, contains('"app": "karos_strength"'));
      expect(text, contains('"schemaVersion": 2'));
      final data = BackupService.decode(text);
      expect(data.exercises.single.name, 'Benkpress');
      expect(data.sessions.single.sets.single.weightKg, 62.5);
    });

    test('reads files from the old version (no app field)', () {
      const old =
          '{"version":1,"exportedAt":"2026-01-01T00:00:00Z","exercises":[{"id":"1","name":"Knebøy"}],"sessions":[]}';
      expect(BackupService.decode(old).exercises.single.name, 'Knebøy');
    });

    test('rejects bad files', () {
      expect(() => BackupService.decode('not json'), throwsFormatException);
      expect(
        () => BackupService.decode(
          '{"app":"karos_packing","exercises":[],"sessions":[]}',
        ),
        throwsFormatException,
      );
      expect(
        () => BackupService.decode('{"exercises":[{"id":1}],"sessions":[]}'),
        throwsFormatException,
      );
    });

    test('file name follows the standard', () {
      expect(
        BackupService.fileName(DateTime(2026, 11, 19, 8, 5)),
        'karos_strength_backup_2026-11-19_08-05.json',
      );
    });
  });
}
