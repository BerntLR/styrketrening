import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import '../utils/formatting.dart';
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

    return '${set.weightKg} kg x ${set.reps}';
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

  Future<bool> _confirmDeleteExerciseDialog(Exercise exercise) async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) {
            final strings2 = AppStrings.of(context);
            return AlertDialog(
              title: Text(strings2.deleteExerciseTitle),
              content: Text(strings2.deleteExerciseConfirm(exercise.name)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings2.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(strings2.delete),
                ),
              ],
            );
          },
        )) ==
        true;
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

  void _openInfo() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const InfoPage()));
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
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];

          return Dismissible(
            key: ValueKey(exercise.id),
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
                await _showExerciseDialog(exercise: exercise);
                return false;
              }

              if (direction == DismissDirection.endToStart) {
                // Swipe left = delete (must confirm)
                return _confirmDeleteExerciseDialog(exercise);
              }

              return false;
            },
            onDismissed: (direction) async {
              if (direction != DismissDirection.endToStart) return;
              await _storage.deleteExercise(exercise.id);
              if (!mounted) return;
              await _loadExercises();
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
