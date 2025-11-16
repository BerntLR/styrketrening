import 'package:flutter/material.dart';

import '../models/training_models.dart';
import '../services/training_storage_service.dart';

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({super.key});

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final TrainingStorageService _storage = TrainingStorageService();
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    final exercises = await _storage.loadExercises();

    setState(() {
      _exercises = exercises;
      _isLoading = false;
    });
  }

  Future<void> _showExerciseDialog({Exercise? exercise}) async {
    final isEditing = exercise != null;
    final controller = TextEditingController(text: exercise?.name ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit exercise' : 'New exercise'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Exercise name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(name);
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    if (isEditing) {
      final updated = Exercise(id: exercise!.id, name: result);
      await _storage.updateExercise(updated);
    } else {
      await _storage.addExercise(result);
    }

    await _loadExercises();
  }

  Future<void> _confirmDeleteExercise(Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete exercise'),
          content: Text(
            'Are you sure you want to delete "${exercise.name}"?\n\n'
            'All sessions for this exercise will also be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _storage.deleteExercise(exercise.id);
    await _loadExercises();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No exercises yet.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showExerciseDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add first exercise'),
            ),
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

          return ListTile(
            title: Text(exercise.name),
            subtitle: const Text(
              'Last session and sets will be shown here later',
            ),
            onTap: () {
              // Her kommer vi senere til å åpne detaljsiden for øvelsen
              // (med forrige økt, nye sett osv.)
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showExerciseDialog(exercise: exercise),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteExercise(exercise),
                ),
              ],
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
        title: const Text('styrketrening'),
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExerciseDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New exercise'),
      ),
    );
  }
}

