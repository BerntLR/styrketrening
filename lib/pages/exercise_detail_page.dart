import 'package:flutter/material.dart';

import '../models/training_models.dart';
import '../services/training_storage_service.dart';

class ExerciseDetailPage extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  final TrainingStorageService _storage = TrainingStorageService();

  ExerciseSession? _lastSession;
  bool _isLoading = true;

  final List<TextEditingController> _weightControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _repsControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _loadLastSession();
  }

  @override
  void dispose() {
    for (final c in _weightControllers) {
      c.dispose();
    }
    for (final c in _repsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLastSession() async {
    setState(() {
      _isLoading = true;
    });

    final last =
        await _storage.getLastSessionForExercise(widget.exercise.id);

    setState(() {
      _lastSession = last;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Widget _buildLastSessionCard() {
    if (_lastSession == null) {
      return const Card(
        margin: EdgeInsets.all(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'No previous session for this exercise yet.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    final last = _lastSession!;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last session: ${_formatDate(last.date)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final set in last.sets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Set ${set.setIndex}: ${set.weightKg} kg x ${set.reps} reps',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSession() async {
    final List<ExerciseSet> sets = [];

    for (int i = 0; i < 3; i++) {
      final weightStr = _weightControllers[i].text.trim();
      final repsStr = _repsControllers[i].text.trim();

      final weight = double.tryParse(weightStr) ?? 0;
      final reps = int.tryParse(repsStr) ?? 0;

      sets.add(
        ExerciseSet(
          setIndex: i + 1,
          weightKg: weight,
          reps: reps,
        ),
      );
    }

    final session = ExerciseSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: widget.exercise.id,
      date: DateTime.now(),
      sets: sets,
    );

    await _storage.addSession(session);

    setState(() {
      _lastSession = session;
    });

    for (final c in _weightControllers) {
      c.clear();
    }
    for (final c in _repsControllers) {
      c.clear();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session saved'),
      ),
    );
  }

  Widget _buildNewSessionCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New session (3 sets)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text('Set ${i + 1}:'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _weightControllers[i],
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'kg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _repsControllers[i],
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'reps',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSession,
                icon: const Icon(Icons.save),
                label: const Text('Save session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        _buildLastSessionCard(),
        _buildNewSessionCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }
}
