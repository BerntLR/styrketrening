import 'package:flutter_test/flutter_test.dart';
import 'package:karo_strength_training/models/training_models.dart';
import 'package:karo_strength_training/services/training_storage_service.dart';
import 'package:karo_strength_training/utils/formatting.dart';
import 'package:shared_preferences/shared_preferences.dart';

ExerciseSession _session(String id, DateTime date, double kg) {
  return ExerciseSession(
    id: id,
    exerciseId: 'squat',
    date: date,
    sets: [
      ExerciseSet(setIndex: 1, weightKg: kg, reps: 10),
      ExerciseSet(setIndex: 2, weightKg: kg, reps: 8),
    ],
  );
}

void main() {
  group('models', () {
    test('session survives a JSON round trip', () {
      final original = _session('1', DateTime(2026, 1, 2, 18, 30), 42.5);
      final copy = ExerciseSession.fromJson(original.toJson());

      expect(copy.id, original.id);
      expect(copy.exerciseId, original.exerciseId);
      expect(copy.date, original.date);
      expect(copy.sets.length, 2);
      expect(copy.sets.first.weightKg, 42.5);
      expect(copy.sets.last.reps, 8);
    });

    test('integer weights in JSON are read as doubles', () {
      final set = ExerciseSet.fromJson({
        'setIndex': 1,
        'weightKg': 40,
        'reps': 12,
      });
      expect(set.weightKg, 40.0);
    });

    test('total volume is weight x reps over all sets', () {
      final session = _session('1', DateTime(2026), 50);
      expect(session.totalVolumeKg, 50 * 10 + 50 * 8);
    });
  });

  group('formatting', () {
    test('formatDate pads month and day', () {
      expect(formatDate(DateTime(2026, 3, 7)), '2026-03-07');
    });

    test('daysSince counts calendar days', () {
      final now = DateTime.now();
      expect(daysSince(now), 0);
      expect(daysSince(now.subtract(const Duration(days: 3))), 3);
    });
  });

  group('storage', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('deleting an exercise also deletes its sessions', () async {
      final storage = TrainingStorageService();
      final exercise = await storage.addExercise('Squat');
      await storage.addSession(
        ExerciseSession(
          id: 's1',
          exerciseId: exercise.id,
          date: DateTime(2026, 1, 1),
          sets: const [],
        ),
      );

      await storage.deleteExercise(exercise.id);

      expect(await storage.loadExercises(), isEmpty);
      expect(await storage.loadSessions(), isEmpty);
    });

    test('last session is the newest by date', () async {
      final storage = TrainingStorageService();
      await storage.addSession(_session('new', DateTime(2026, 5, 1), 60));
      await storage.addSession(_session('old', DateTime(2026, 1, 1), 50));

      final last = await storage.getLastSessionForExercise('squat');
      expect(last?.id, 'new');
    });
  });
}
