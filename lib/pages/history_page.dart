import 'package:flutter/material.dart';

import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import '../services/backup_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TrainingStorageService _storage = TrainingStorageService();
  final BackupService _backupService = BackupService();

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

    exercises.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
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

  Future<void> _editSession(ExerciseSession session) async {
    final TextEditingController w1 = TextEditingController();
    final TextEditingController w2 = TextEditingController();
    final TextEditingController w3 = TextEditingController();
    final TextEditingController r1 = TextEditingController();
    final TextEditingController r2 = TextEditingController();
    final TextEditingController r3 = TextEditingController();

    ExerciseSet? getSet(int idx) {
      return session.sets
          .where((s) => s.setIndex == idx)
          .cast<ExerciseSet?>()
          .firstWhere(
            (s) => s != null,
            orElse: () => null,
          );
    }

    final s1 = getSet(1);
    final s2 = getSet(2);
    final s3 = getSet(3);

    w1.text = s1?.weightKg.toString() ?? '';
    w2.text = s2?.weightKg.toString() ?? '';
    w3.text = s3?.weightKg.toString() ?? '';
    r1.text = s1?.reps.toString() ?? '';
    r2.text = s2?.reps.toString() ?? '';
    r3.text = s3?.reps.toString() ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 60, child: Text('Set 1')),
                    Expanded(
                      child: TextField(
                        controller: w1,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'kg'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: r1,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        decoration: const InputDecoration(labelText: 'reps'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 60, child: Text('Set 2')),
                    Expanded(
                      child: TextField(
                        controller: w2,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'kg'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: r2,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        decoration: const InputDecoration(labelText: 'reps'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 60, child: Text('Set 3')),
                    Expanded(
                      child: TextField(
                        controller: w3,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'kg'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: r3,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        decoration: const InputDecoration(labelText: 'reps'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    ExerciseSet updatedSet(int index, TextEditingController wc,
        TextEditingController rc) {
      final weight = double.tryParse(wc.text.trim()) ?? 0;
      final reps = int.tryParse(rc.text.trim()) ?? 0;
      return ExerciseSet(
        setIndex: index,
        weightKg: weight,
        reps: reps,
      );
    }

    final updatedSession = ExerciseSession(
      id: session.id,
      exerciseId: session.exerciseId,
      date: session.date,
      sets: [
        updatedSet(1, w1, r1),
        updatedSet(2, w2, r2),
        updatedSet(3, w3, r3),
      ],
    );

    await _storage.updateSession(updatedSession);
    await _loadHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session updated')),
    );
  }

  Future<void> _deleteSession(ExerciseSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete session'),
          content: Text(
            'Delete this session for "${_exerciseMap[session.exerciseId]?.name ?? 'Unknown'}" '
            'on ${_formatDate(session.date)}?',
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

    await _storage.deleteSession(session.id);
    await _loadHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session deleted')),
    );
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
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSession(session);
              },
              child: const Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editSession(session);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating backup...')),
    );

    final path = await _backupService.createBackupFile();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backup saved:\n$path'),
        duration: const Duration(seconds: 5),
      ),
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
        actions: [
          IconButton(
            tooltip: 'Backup',
            icon: const Icon(Icons.backup),
            onPressed: _runBackup,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
