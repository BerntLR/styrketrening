import 'package:flutter/material.dart';

import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import '../services/backup_service.dart';
import 'exercise_detail_page.dart';
import 'history_page.dart';

enum _MenuAction {
  exportData,
  importData,
}

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({super.key});

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final TrainingStorageService _storage = TrainingStorageService();
  final BackupService _backup = BackupService();

  List<Exercise> _exercises = [];
  final Map<String, ExerciseSession?> _lastSessions = {};
  bool _isLoading = true;

  bool _autoBackupChecked = false;

  @override
  void initState() {
    super.initState();
    _loadExercises().then((_) => _checkAutoBackup());
  }

  // ============================
  // BACKUP / IMPORT MENY
  // ============================

  Future<void> _handleMenuAction(_MenuAction action) async {
    switch (action) {
      case _MenuAction.exportData:
        await _backup.exportBackup();
        break;

      case _MenuAction.importData:
        final ok = await _backup.importBackup();
        if (ok) {
          await _loadExercises();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data importert")),
          );
        }
        break;
    }
  }

  // ============================
  // LASTER ØVELSER OG SESSIONS
  // ============================

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    final exercises = await _storage.loadExercises();
    final Map<String, ExerciseSession?> lastMap = {};

    for (final ex in exercises) {
      lastMap[ex.id] = await _storage.getLastSessionForExercise(ex.id);
    }

    setState(() {
      _exercises = exercises;
      _lastSessions
        ..clear()
        ..addAll(lastMap);
      _isLoading = false;
    });
  }

  // ============================
  // AUTO BACKUP (ukentlig)
  // ============================

  Future<void> _checkAutoBackup() async {
    if (_autoBackupChecked) return;
    _autoBackupChecked = true;

    // Ingen vits i å mase om backup hvis du ikke har noen økter ennå
    final allSessions = await _storage.loadSessions();
    if (allSessions.isEmpty) {
      return;
    }

    final lastBackup = await _storage.getLastBackupDate();
    final now = DateTime.now();

    // Hvis vi har en backup, bare mas hvis det er 7+ dager siden
    if (lastBackup != null) {
      final diffDays = now.difference(lastBackup).inDays;
      if (diffDays < 7) {
        return;
      }
    }

    if (!mounted) return;

    final daysSince =
        lastBackup == null ? null : now.difference(lastBackup).inDays;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final message = lastBackup == null
            ? 'You have training data but no backup yet.\n\nDo you want to export a backup now?'
            : 'It has been $daysSince days since your last backup.\n\nDo you want to export a backup now?';

        return AlertDialog(
          title: const Text('Backup reminder'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Backup now'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _backup.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exported')),
      );
    }
  }

  // ============================
  // FORMATTERING / LOGIKK
  // ============================

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatSet(int index, ExerciseSession session) {
    final set = session.sets
        .where((s) => s.setIndex == index)
        .cast<ExerciseSet?>()
        .firstWhere((s) => s != null, orElse: () => null);

    if (set == null) return '–';

    return '${set.weightKg} kg x ${set.reps}';
  }

  bool _isReadyToIncrease(ExerciseSession? session) {
    if (session == null) return false;
    if (session.sets.length < 3) return false;
    return session.sets.every((s) => s.reps >= 12);
  }

  Widget _buildSubtitle(Exercise exercise) {
    final last = _lastSessions[exercise.id];
    if (last == null) {
      return const Text('No sessions yet.');
    }

    final dateStr = _formatDate(last.date);

    // Days since last session (dato til dato, ikke timer)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.date.year, last.date.month, last.date.day);
    final daysSince = today.difference(lastDay).inDays;

    final s1 = _formatSet(1, last);
    final s2 = _formatSet(2, last);
    final s3 = _formatSet(3, last);
    final ready = _isReadyToIncrease(last);

    final extraLine = ready ? '\nReady to increase weight' : '';

    return Text(
      'Last: $dateStr ($daysSince days ago)\n'
      'S1: $s1 | S2: $s2 | S3: $s3$extraLine',
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No exercises yet.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showExerciseDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New exercise'),
            )
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
          final last = _lastSessions[exercise.id];
          final ready = _isReadyToIncrease(last);

          return ListTile(
            leading: ready
                ? const Icon(Icons.trending_up, color: Colors.greenAccent)
                : const Icon(Icons.fitness_center),
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

    if (confirm != true) return;

    await _storage.deleteExercise(exercise.id);
    await _loadExercises();
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop(name);
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    if (isEditing) {
      final updated = Exercise(id: exercise!.id, name: result);
      await _storage.updateExercise(updated);
    } else {
      await _storage.addExercise(result);
    }

    await _loadExercises();
  }

  void _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HistoryPage(),
      ),
    );
    await _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('styrketrening'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MenuAction.exportData,
                child: Text('Eksporter data'),
              ),
              PopupMenuItem(
                value: _MenuAction.importData,
                child: Text('Importer data'),
              ),
            ],
          ),
        ],
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

