import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import 'exercise_detail_page.dart';

class ExerciseHistoryPage extends StatefulWidget {
  final Exercise exercise;

  const ExerciseHistoryPage({super.key, required this.exercise});

  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> {
  final TrainingStorageService _storage = TrainingStorageService();

  bool _isLoading = true;
  List<ExerciseSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    final sessions = await _storage.getSessionsForExercise(widget.exercise.id);

    // Newest first
    sessions.sort((a, b) => b.date.compareTo(a.date));

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

  double _calculateTotalVolume(ExerciseSession session) {
    double total = 0;
    for (final set in session.sets) {
      total += set.weightKg * set.reps;
    }
    return total;
  }

  String _formatSets(ExerciseSession session) {
    if (session.sets.isEmpty) {
      return 'No sets';
    }

    return session.sets
        .map((s) => '${s.setIndex}: ${s.weightKg} kg x ${s.reps}')
        .join(' | ');
  }

  Future<void> _editSession(ExerciseSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseDetailPage(
          exercise: widget.exercise,
          initialSession: session,
        ),
      ),
    );

    await _loadSessions();
  }

  Future<bool> _confirmDeleteSessionDialog(ExerciseSession session) async {
    final strings = AppStrings.of(context);

    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete session'),
              content: Text(
                'Do you want to delete this session?\n\n'
                'Date: ${_formatDate(session.date)}\n'
                'Total volume: ${_calculateTotalVolume(session).toStringAsFixed(0)} kg',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(strings.delete),
                ),
              ],
            );
          },
        )) ==
        true;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Text(
          'No sessions recorded yet for this exercise.',
          style: TextStyle(fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final dateStr = _formatDate(session.date);
          final volumeStr = _calculateTotalVolume(session).toStringAsFixed(0);
          final setsStr = _formatSets(session);

          return Dismissible(
            key: ValueKey(session.id),
            direction: DismissDirection.horizontal,
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Swipe right = edit
                await _editSession(session);
                return false;
              }
              if (direction == DismissDirection.endToStart) {
                // Swipe left = delete (must confirm)
                return _confirmDeleteSessionDialog(session);
              }
              return false;
            },
            onDismissed: (direction) async {
              if (direction != DismissDirection.endToStart) return;
              await _storage.deleteSession(session.id);
              if (!mounted) return;
              await _loadSessions();
            },
            child: ListTile(
              title: Text('$dateStr \u2013 $volumeStr kg'),
              subtitle: Text(setsStr),
              onTap: () => _editSession(session),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.of(context).exerciseHistoryTitle(widget.exercise.name),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }
}
