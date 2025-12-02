import 'dart:async';
import 'package:flutter/material.dart';

import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import 'exercise_history_page.dart';

class ExerciseDetailPage extends StatefulWidget {
  final Exercise exercise;
  final ExerciseSession? initialSession;

  const ExerciseDetailPage({
    super.key,
    required this.exercise,
    this.initialSession,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  final TrainingStorageService _storage = TrainingStorageService();

  ExerciseSession? _lastSession;
  ExerciseSession? _editingSession;
  bool get _isEditing => _editingSession != null;

  bool _isLoading = true;

  final List<TextEditingController> _weightControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _repsControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  // Pause-innstillinger og valgfri timer
  bool _useTimer = true;
  int _pauseMinutes = 1;
  final TextEditingController _pauseController =
      TextEditingController(text: '1');

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _isTimerRunning = false;

  int _currentSet = 1;

  @override
  void initState() {
    super.initState();

    // Hvis vi kommer inn for å redigere en økt fra HistoryPage
    if (widget.initialSession != null) {
      _editingSession = widget.initialSession;
      _prefillFromSession(widget.initialSession!);
    }

    _loadData();
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
    _pauseController.dispose();
    super.dispose();
  }

  void _prefillFromSession(ExerciseSession session) {
    for (int i = 0; i < 3; i++) {
      final setIndex = i + 1;
      final set = session.sets
          .where((s) => s.setIndex == setIndex)
          .cast<ExerciseSet?>()
          .firstWhere((s) => s != null, orElse: () => null);

      if (set != null) {
        _weightControllers[i].text = set.weightKg.toString();
        _repsControllers[i].text = set.reps.toString();
      } else {
        _weightControllers[i].text = '';
        _repsControllers[i].text = '';
      }
    }
  }

  Future<void> _loadData() async {
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

  bool _isReadyToIncrease(ExerciseSession? session) {
    if (session == null) return false;
    if (session.sets.length < 3) return false;
    return session.sets.every((s) => s.reps >= 12);
  }

  double _calculateTotalVolume(ExerciseSession session) {
    double total = 0;
    for (final set in session.sets) {
      total += set.weightKg * set.reps;
    }
    return total;
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
            Text(
              'Total volume: ${_calculateTotalVolume(last).toStringAsFixed(0)} kg',
              style: const TextStyle(fontSize: 14),
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

  Widget _buildProgressionHint() {
    if (!_isReadyToIncrease(_lastSession)) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.green.withOpacity(0.2),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Last time you hit 12 reps on all 3 sets.\n'
          'You can increase the weight for this exercise.',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  /// Kort for økt-innstillinger (pause og timer av/på)
  Widget _buildSessionSettingsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit session' : 'New session',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (_isEditing)
              Text(
                'Original date: ${_formatDate(_editingSession!.date)}',
                style: const TextStyle(fontSize: 13),
              ),
            if (_isEditing) const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rest time (minutes)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _pauseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value.trim()) ?? 0;
                      final sanitized = parsed < 0 ? 0 : parsed;
                      setState(() {
                        _pauseMinutes = sanitized;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Use rest timer',
                style: TextStyle(fontSize: 14),
              ),
              value: _useTimer,
              onChanged: (v) {
                setState(() {
                  _useTimer = v;
                  if (!v) {
                    // Nullstill timer hvis vi slår den av
                    _timer?.cancel();
                    _isTimerRunning = false;
                    _remainingSeconds = 0;
                    _currentSet = 1;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Start nedtelling med gitt antall sekunder
  void _startTimer(int seconds) {
    if (_isTimerRunning) return;
    if (seconds <= 0) {
      setState(() {
        _isTimerRunning = false;
        _remainingSeconds = 0;
      });
      return;
    }

    setState(() {
      _isTimerRunning = true;
      _remainingSeconds = seconds;
    });

    _timer?.cancel();
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

  /// Felles lagrefunksjon: nå KUN manuell (både ny og redigert økt)
  Future<void> _saveSession() async {
    // Stopp eventuell timer, vi er ferdige med økten
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = 0;
    });

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

    ExerciseSession session;
    if (_isEditing) {
      // Behold id og dato, oppdater sett
      final base = _editingSession!;
      session = ExerciseSession(
        id: base.id,
        exerciseId: base.exerciseId,
        date: base.date,
        sets: sets,
      );
      await _storage.updateSession(session);
    } else {
      session = ExerciseSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: widget.exercise.id,
        date: DateTime.now(),
        sets: sets,
      );
      await _storage.addSession(session);
    }

    setState(() {
      _lastSession = session;
      _editingSession = session;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Session updated' : 'Exercise completed and saved',
        ),
      ),
    );

    Navigator.of(context).pop(); // back to previous page
  }

  Widget _buildSetRow(int index) {
    final isCurrent = _useTimer && (_currentSet == index);

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

  Widget _buildTimerCard() {
    if (!_useTimer) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Rest timer (${_pauseMinutes} min)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      final totalSeconds = _pauseMinutes <= 0
                          ? 0
                          : _pauseMinutes * 60;

                      if (totalSeconds > 0) {
                        _startTimer(totalSeconds);
                      }

                      setState(() {
                        if (_currentSet < 3) {
                          _currentSet++;
                        } else {
                          // Alle sett er i praksis ferdige,
                          // bare gi en påminnelse om manuell lagring.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'All sets done. Remember to save the session.',
                              ),
                            ),
                          );
                        }
                      });
                    },
              icon: const Icon(Icons.timer),
              label: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  /// Lagre / avbryt-knapper – alltid tilgjengelig,
  /// uansett om timeren er på eller ikke.
  Widget _buildSaveButtons() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Avbryt økten uten å lagre
                Navigator.of(context).pop();
              },
              child: const Text('Discard'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveSession,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Update session' : 'Save session'),
            ),
          ),
        ],
      ),
    );
  }

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
        actions: [
          IconButton(
            tooltip: 'Full history',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ExerciseHistoryPage(exercise: widget.exercise),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildLastSessionCard(),
          _buildProgressionHint(),
          _buildSessionSettingsCard(),
          for (int i = 1; i <= 3; i++) _buildSetRow(i),
          _buildTimerCard(),
          _buildSaveButtons(),
        ],
      ),
    );
  }
}

