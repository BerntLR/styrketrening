import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import '../utils/formatting.dart';
import '../widgets/swipe_tile.dart';
import '../widgets/watermark.dart';
import 'exercise_detail_page.dart';
import 'info_page.dart';

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({super.key});

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final TrainingStorageService _storage = TrainingStorageService();

  List<Exercise> _exercises = [];
  final Map<String, ExerciseSession?> _lastSessions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);

    final exercises = await _storage.loadExercises();
    final lastSessions = <String, ExerciseSession?>{};
    for (final e in exercises) {
      lastSessions[e.id] = await _storage.getLastSessionForExercise(e.id);
    }

    if (!mounted) return;
    setState(() {
      _exercises = exercises;
      _lastSessions
        ..clear()
        ..addAll(lastSessions);
      _isLoading = false;
    });
  }

  String _formatSet(int index, ExerciseSession session) {
    final set = session.sets.where((s) => s.setIndex == index).firstOrNull;

    if (set == null) return '–';

    return '${formatWeight(set.weightKg)} kg x ${set.reps}';
  }

  Widget _buildSubtitle(Exercise exercise) {
    final last = _lastSessions[exercise.id];
    final strings = AppStrings.of(context);

    if (last == null) {
      return Text(strings.noSessionsYet);
    }

    final line1 = strings.lastLine(formatDate(last.date), daysSince(last.date));
    final line2 = strings.setsLine(
      _formatSet(1, last),
      _formatSet(2, last),
      _formatSet(3, last),
    );

    return Text('$line1\n$line2', style: const TextStyle(fontSize: 13));
  }

  Future<bool> _confirmDeleteExerciseDialog(Exercise exercise) {
    final strings = AppStrings.of(context);
    return confirmDelete(
      context,
      title: strings.deleteExerciseTitle,
      message: strings.deleteExerciseConfirm(exercise.name),
      cancel: strings.cancel,
      confirm: strings.delete,
    );
  }

  Future<void> _showExerciseDialog({Exercise? exercise}) async {
    final isEditing = exercise != null;
    final controller = TextEditingController(text: exercise?.name ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final strings2 = AppStrings.of(context);
        return AlertDialog(
          title: Text(
            isEditing ? strings2.editExerciseTitle : strings2.newExerciseTitle,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: strings2.exerciseNameLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings2.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop(name);
              },
              child: Text(isEditing ? strings2.save : strings2.add),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    if (isEditing) {
      final updated = Exercise(id: exercise.id, name: result);
      await _storage.updateExercise(updated);
    } else {
      await _storage.addExercise(result);
    }

    await _loadExercises();
  }

  Future<void> _openInfo() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const InfoPage()));
    // An import on the Info page may have replaced all data.
    if (mounted) await _loadExercises();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final strings = AppStrings.of(context);

    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.noExercisesYet, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExercises,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];

          return SwipeTile(
            id: exercise.id,
            onEdit: () => _showExerciseDialog(exercise: exercise),
            onDelete: () async {
              if (!await _confirmDeleteExerciseDialog(exercise)) return false;
              await _storage.deleteExercise(exercise.id);
              if (mounted) await _loadExercises();
              return true;
            },
            child: ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(exercise.name),
              subtitle: _buildSubtitle(exercise),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ExerciseDetailPage(exercise: exercise),
                  ),
                );
                await _loadExercises();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: strings.info,
            icon: const Icon(Icons.info_outline),
            onPressed: _openInfo,
          ),
        ],
      ),
      body: Stack(children: [const Watermark(), _buildBody()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExerciseDialog(),
        icon: const Icon(Icons.add),
        label: Text(strings.newExercise),
      ),
    );
  }
}
