import 'package:flutter/material.dart';

import '../models/training_models.dart';
import '../services/training_storage_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TrainingStorageService _storage = TrainingStorageService();

  bool _isLoading = true;
  List<ExerciseSession> _sessions = [];
  final Map<String, Exercise> _exerciseMap = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final exercises = await _storage.loadExercises();
    final sessions = await _storage.loadSessions();

    exercises.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    sessions.sort((a, b) => b.date.compareTo(a.date)); // newest first

    _exerciseMap
      ..clear()
      ..addEntries(exercises.map((e) => MapEntry(e.id, e)));

    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatSet(ExerciseSession session, int index) {
    final set = session.sets
        .where((s) => s.setIndex == index)
        .cast<ExerciseSet?>()
        .firstWhere(
          (s) => s != null,
          orElse: () => null,
        );

    if (set == null) {
      return '–';
    }

    return '${set.weightKg} kg x ${set.reps}';
  }

  void _showSessionDetails(ExerciseSession session) {
    final exercise = _exerciseMap[session.exerciseId];
    final name = exercise?.name ?? 'Unknown exercise';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${_formatDate(session.date)}'),
              const SizedBox(height: 8),
              for (final set in session.sets)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'Set ${set.setIndex}: ${set.weightKg} kg x ${set.reps} reps',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Text(
          'No sessions recorded yet.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final exercise = _exerciseMap[session.exerciseId];
          final exerciseName = exercise?.name ?? 'Unknown exercise';

          final dateStr = _formatDate(session.date);
          final s1 = _formatSet(session, 1);
          final s2 = _formatSet(session, 2);
          final s3 = _formatSet(session, 3);

          return ListTile(
            title: Text(exerciseName),
            subtitle: Text(
              'Date: $dateStr\n'
              'S1: $s1 | S2: $s2 | S3: $s3',
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () => _showSessionDetails(session),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }
}
