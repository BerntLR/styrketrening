import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_models.dart';

class TrainingStorageService {
  TrainingStorageService._internal();

  static final TrainingStorageService _instance =
      TrainingStorageService._internal();

  factory TrainingStorageService() => _instance;

  static const String _exercisesKey = 'exercises';
  static const String _sessionsKey = 'sessions';

  Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  // -----------------------------
  // Exercises
  // -----------------------------

  Future<List<Exercise>> loadExercises() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_exercisesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExercises(List<Exercise> exercises) async {
    final prefs = await _prefs;
    final jsonString =
        jsonEncode(exercises.map((e) => e.toJson()).toList());
    await prefs.setString(_exercisesKey, jsonString);
  }

  Future<Exercise> addExercise(String name) async {
    final exercises = await loadExercises();
    final newExercise = Exercise.create(name);
    exercises.add(newExercise);
    await saveExercises(exercises);
    return newExercise;
  }

  Future<void> updateExercise(Exercise updated) async {
    final exercises = await loadExercises();
    final index = exercises.indexWhere((e) => e.id == updated.id);
    if (index == -1) {
      return;
    }
    exercises[index] = updated;
    await saveExercises(exercises);
  }

  Future<void> deleteExercise(String id) async {
    final exercises = await loadExercises();
    exercises.removeWhere((e) => e.id == id);
    await saveExercises(exercises);

    // Also remove sessions for this exercise
    final sessions = await loadSessions();
    final filtered =
        sessions.where((s) => s.exerciseId != id).toList();
    await saveSessions(filtered);
  }

  // -----------------------------
  // Sessions
  // -----------------------------

  Future<List<ExerciseSession>> loadSessions() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_sessionsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => ExerciseSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSessions(List<ExerciseSession> sessions) async {
    final prefs = await _prefs;
    final jsonString =
        jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, jsonString);
  }

  Future<ExerciseSession> addSession(ExerciseSession session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    await saveSessions(sessions);
    return session;
  }

  Future<void> updateSession(ExerciseSession updated) async {
    final sessions = await loadSessions();
    final index = sessions.indexWhere((s) => s.id == updated.id);
    if (index == -1) {
      return;
    }
    sessions[index] = updated;
    await saveSessions(sessions);
  }

  Future<void> deleteSession(String sessionId) async {
    final sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await saveSessions(sessions);
  }

  Future<List<ExerciseSession>> getSessionsForExercise(
      String exerciseId) async {
    final sessions = await loadSessions();
    return sessions.where((s) => s.exerciseId == exerciseId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<ExerciseSession?> getLastSessionForExercise(
      String exerciseId) async {
    final sessions = await getSessionsForExercise(exerciseId);
    if (sessions.isEmpty) {
      return null;
    }
    return sessions.last;
  }
}
