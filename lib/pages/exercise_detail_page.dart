import 'dart:async';
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

  // --- Timer state ---
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _isTimerRunning = false;

  // --- Which set are we on (1, 2, 3) ---
  int _currentSet = 1;

  @override
  void initState() {
    super.initState();
    _loadLastSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  // -------------------------------------------
  // TIMER LOGIC
  // -------------------------------------------
  void _startTimer() {
    if (_isTimerRunning) return;

    setState(() {
      _isTimerRunning = true;
      _remainingSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          _isTimerRunning = false;
        });
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  // -------------------------------------------
  // SAVE SESSION AFTER 3 SETS
  // -------------------------------------------
  Future<void> _saveAfterThirdSet() async {
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

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercise completed and saved')),
    );

    Navigator.of(context).pop(); // back to overview
  }

  // -------------------------------------------
  // BUILD SET ROW
  // -------------------------------------------
  Widget _buildSetRow(int index) {
    final isCurrent = _currentSet == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.blue.withOpacity(0.1) : Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? Colors.blue : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text('Set $index')),
          Expanded(
            child: TextField(
              controller: _weightControllers[index - 1],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'kg'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _repsControllers[index - 1],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(labelText: 'reps'),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------
  // BUILD TIMER CARD
  // -------------------------------------------
  Widget _buildTimerCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Rest timer (1 minute)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _isTimerRunning
                  ? '$_remainingSeconds sec'
                  : 'Ready for next set',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isTimerRunning
                  ? null
                  : () {
                      // SET COMPLETED → START PAUSE → MOVE TO NEXT SET
                      if (_currentSet < 3) {
                        _startTimer();
                        setState(() {
                          _currentSet++;
                        });
                      } else {
                        // THIRD SET → COMPLETE EXERCISE
                        _startTimer();
                        Future.delayed(const Duration(seconds: 60), () {
                          _saveAfterThirdSet();
                        });
                      }
                    },
              icon: const Icon(Icons.timer),
              label: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------
  // BUILD BODY
  // -------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildLastSessionCard(),
          for (int i = 1; i <= 3; i++) _buildSetRow(i),
          _buildTimerCard(),
        ],
      ),
    );
  }
}
