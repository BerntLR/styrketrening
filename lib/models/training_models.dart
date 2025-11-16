class Exercise {
  final String id;
  String name;

  Exercise({
    required this.id,
    required this.name,
  });

  /// Convenience factory to create a new Exercise with a generated id.
  factory Exercise.create(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return Exercise(id: id, name: name);
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ExerciseSet {
  final int setIndex; // 1, 2, 3
  final double weightKg;
  final int reps;

  ExerciseSet({
    required this.setIndex,
    required this.weightKg,
    required this.reps,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      setIndex: json['setIndex'] as int,
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: json['reps'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setIndex': setIndex,
      'weightKg': weightKg,
      'reps': reps,
    };
  }
}

class ExerciseSession {
  final String id;
  final String exerciseId;
  final DateTime date;
  final List<ExerciseSet> sets;

  ExerciseSession({
    required this.id,
    required this.exerciseId,
    required this.date,
    required this.sets,
  });

  /// Convenience factory for a new session with 3 empty sets.
  factory ExerciseSession.createEmpty({
    required String exerciseId,
    DateTime? date,
  }) {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final sessionDate = date ?? DateTime.now();
    return ExerciseSession(
      id: sessionId,
      exerciseId: exerciseId,
      date: sessionDate,
      sets: [
        ExerciseSet(setIndex: 1, weightKg: 0, reps: 0),
        ExerciseSet(setIndex: 2, weightKg: 0, reps: 0),
        ExerciseSet(setIndex: 3, weightKg: 0, reps: 0),
      ],
    );
  }

  factory ExerciseSession.fromJson(Map<String, dynamic> json) {
    final setsJson = json['sets'] as List<dynamic>;
    return ExerciseSession(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      date: DateTime.parse(json['date'] as String),
      sets: setsJson
          .map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'date': date.toIso8601String(),
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }
}
