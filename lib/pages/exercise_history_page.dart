import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import '../utils/formatting.dart';
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

    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  String _formatSets(ExerciseSession session) {
    if (session.sets.isEmpty) {
      return AppStrings.of(context).noSets;
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
              title: Text(strings.deleteSessionTitle),
              content: Text(
                strings.deleteSessionBody(
                  formatDate(session.date),
                  session.totalVolumeKg.toStringAsFixed(0),
                ),
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
      return Center(
        child: Text(
          AppStrings.of(context).noSessionsForExercise,
          style: const TextStyle(fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final dateStr = formatDate(session.date);
          final volumeStr = session.totalVolumeKg.toStringAsFixed(0);
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
              title: Text(
                AppStrings.of(context).sessionTitle(dateStr, volumeStr),
              ),
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
