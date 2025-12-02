import 'package:flutter/material.dart';

import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import 'exercise_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TrainingStorageService _storage = TrainingStorageService();

  bool _isLoading = true;
  List<_ExerciseHistory> _items = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Hent alle øvelser
    final exercises = await _storage.loadExercises();

    // 2. For hver øvelse: hent alle økter
    final List<_ExerciseHistory> result = [];
    for (final exercise in exercises) {
      final sessions =
          await _storage.getSessionsForExercise(exercise.id);

      if (sessions.isEmpty) {
        continue; // hopp over øvelser uten økter
      }

      // sorter øktene nyeste først
      sessions.sort((a, b) => b.date.compareTo(a.date));

      result.add(
        _ExerciseHistory(
          exercise: exercise,
          sessions: sessions,
        ),
      );
    }

    // 3. Sorter øvelsene slik at den med nyeste økt totalt kommer øverst
    result.sort(
      (a, b) => b.sessions.first.date.compareTo(a.sessions.first.date),
    );

    setState(() {
      _items = result;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double _calculateTotalVolume(ExerciseSession session) {
    double total = 0;
    for (final set in session.sets) {
      total += set.weightKg * set.reps;
    }
    return total;
  }

  Widget _buildExerciseCard(_ExerciseHistory item) {
    final exercise = item.exercise;
    final sessions = item.sessions;

    // Vis kun de 3 siste øktene for å unngå gigantisk liste
    final visibleSessions = sessions.length <= 3
        ? sessions
        : sessions.sublist(0, 3);

    final latest = sessions.first;
    final totalCount = sessions.length;
    final visibleCount = visibleSessions.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tittel: navn på øvelse + dato for siste økt
            Text(
              '${exercise.name} – last: ${_formatDate(latest.date)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Showing $visibleCount of $totalCount sessions',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            // Liste over (maks) 3 nyeste økter
            for (final session in visibleSessions)
              InkWell(
                onTap: () async {
                  // Åpne detaljside for å redigere akkurat denne økten
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailPage(
                        exercise: exercise,
                        initialSession: session,
                      ),
                    ),
                  );
                  await _loadHistory();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatDate(session.date)} – '
                        '${_calculateTotalVolume(session).toStringAsFixed(0)} kg total',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      for (final set in session.sets)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            'Set ${set.setIndex}: '
                            '${set.weightKg} kg x ${set.reps} reps',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training history'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No sessions recorded yet.',
                    style: TextStyle(fontSize: 14),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildExerciseCard(_items[index]);
                    },
                  ),
                ),
    );
  }
}

/// Hjelpeklasse for å samle øvelse + alle øktene dens
class _ExerciseHistory {
  final Exercise exercise;
  final List<ExerciseSession> sessions;

  _ExerciseHistory({
    required this.exercise,
    required this.sessions,
  });
}

