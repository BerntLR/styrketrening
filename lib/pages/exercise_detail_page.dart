import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/training_models.dart';
import '../services/training_storage_service.dart';
import '../utils/formatting.dart';
import 'exercise_history_page.dart';

class ExerciseDetailPage extends StatefulWidget {
  final Exercise exercise;

  /// If this is provided, the page will open in "edit existing session" mode.
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

  ExerciseSession? _lastSession; // last recorded session for this exercise
  ExerciseSession? _editingSession; // non-null when editing an existing one
  bool _isLoading = true;

  bool get _isEditing => _editingSession != null;

  // controllers for 3 sets
  final List<TextEditingController> _weightControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _repsControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  // Pause settings and optional timer
  bool _useTimer = true;
  int _pauseMinutes = 1;
  final TextEditingController _pauseController = TextEditingController(
    text: '1',
  );

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _isTimerRunning = false;

  int _currentSet = 1; // 1..3

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadData() async {
    // Editing an existing session: prefill from it.
    // New session: keep the inputs empty (the last session is shown above).
    final initial = widget.initialSession;
    if (initial != null) {
      _editingSession = initial;
      for (int i = 0; i < 3 && i < initial.sets.length; i++) {
        _weightControllers[i].text = initial.sets[i].weightKg.toString();
        _repsControllers[i].text = initial.sets[i].reps.toString();
      }
    }

    final last = await _storage.getLastSessionForExercise(widget.exercise.id);
    if (!mounted) return;

    setState(() {
      _lastSession = last;
      _isLoading = false;
    });
  }

  Widget _buildLastSessionCard() {
    final strings = AppStrings.of(context);

    if (_lastSession == null) {
      return Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            strings.noPreviousSessionForExercise,
            style: const TextStyle(fontSize: 14),
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
              strings.lastSessionLabel(formatDate(last.date)),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              strings.totalVolumeLabel(last.totalVolumeKg.toStringAsFixed(0)),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            for (final set in last.sets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  strings.setLine(
                    set.setIndex,
                    set.weightKg.toString(),
                    set.reps,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingBanner() {
    if (!_isEditing || _editingSession == null) {
      return const SizedBox.shrink();
    }

    final dateStr = formatDate(_editingSession!.date);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      color: Colors.amber.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          AppStrings.of(context).editingBanner(dateStr),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  /// Card for session settings (rest time and timer on/off)
  Widget _buildSessionSettingsCard() {
    final strings = AppStrings.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.sessionSettings,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.restTimeMinutes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _pauseController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: strings.minutes),
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
              title: Text(
                strings.useRestTimer,
                style: const TextStyle(fontSize: 14),
              ),
              value: _useTimer,
              onChanged: (v) {
                setState(() {
                  _useTimer = v;
                  if (!v) {
                    // reset timer if we turn it off
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

  /// Start countdown with given number of seconds
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

  /// Save (new or edited) session manually.
  /// This is called from the explicit "Save session" button only.
  Future<void> _saveSession() async {
    final strings = AppStrings.of(context);
    final List<ExerciseSet> sets = [];

    for (int i = 0; i < 3; i++) {
      final weightStr = _weightControllers[i].text.trim();
      final repsStr = _repsControllers[i].text.trim();

      final weight = double.tryParse(weightStr) ?? 0;
      final reps = int.tryParse(repsStr) ?? 0;

      sets.add(ExerciseSet(setIndex: i + 1, weightKg: weight, reps: reps));
    }

    if (_isEditing && _editingSession != null) {
      // Update existing session (keep original id and date)
      final updated = ExerciseSession(
        id: _editingSession!.id,
        exerciseId: _editingSession!.exerciseId,
        date: _editingSession!.date,
        sets: sets,
      );
      await _storage.updateSession(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.sessionUpdated)));
      Navigator.of(context).pop(true);
    } else {
      // Create new session
      final session = ExerciseSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: widget.exercise.id,
        date: DateTime.now(),
        sets: sets,
      );

      await _storage.addSession(session);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.sessionSaved)));

      Navigator.of(context).pop(true);
    }
  }

  Future<void> _discardSessionWithConfirm() async {
    // If nothing is filled in, leave without asking.
    final hasAnyInput =
        _weightControllers.any((c) => c.text.trim().isNotEmpty) ||
        _repsControllers.any((c) => c.text.trim().isNotEmpty);

    final shouldAsk = hasAnyInput || _isEditing;

    if (!shouldAsk) {
      _timer?.cancel();
      _isTimerRunning = false;
      if (!mounted) return;
      Navigator.of(context).pop(false);
      return;
    }

    final strings = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.discardSessionTitle),
          content: Text(strings.discardSessionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.discard),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    _timer?.cancel();
    _isTimerRunning = false;
    _remainingSeconds = 0;
    _currentSet = 1;

    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  Widget _buildSetRow(int index) {
    final strings = AppStrings.of(context);
    final isCurrent = _useTimer && (_currentSet == index);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.blue.withValues(alpha: 0.1) : Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? Colors.blue : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(strings.setLabel(index))),
          Expanded(
            child: TextField(
              controller: _weightControllers[index - 1],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: strings.kg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _repsControllers[index - 1],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              decoration: InputDecoration(labelText: strings.repsLabel),
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

    final strings = AppStrings.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              strings.restTimerTitle(_pauseMinutes),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _isTimerRunning
                  ? strings.timerRemainingSeconds(_remainingSeconds)
                  : (_currentSet <= 3
                        ? strings.timerReadyForSet(_currentSet)
                        : strings.timerAllSetsDone),
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

                      // Just handle rest between sets; saving is manual now.
                      if (_currentSet < 3) {
                        if (totalSeconds > 0) {
                          _startTimer(totalSeconds);
                        }
                        setState(() {
                          _currentSet++;
                        });
                      } else {
                        // All sets done; optional rest but no auto-save
                        if (totalSeconds > 0) {
                          _startTimer(totalSeconds);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.allSetsCompletedRememberSave),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.timer),
              label: Text(strings.startRest),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveSession,
              icon: const Icon(Icons.check),
              label: Text(
                _isEditing ? strings.saveChanges : strings.saveSession,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _discardSessionWithConfirm,
            icon: const Icon(Icons.close),
            label: Text(strings.discard),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: AppStrings.of(context).fullHistory,
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
          _buildEditingBanner(),
          _buildLastSessionCard(),
          _buildSessionSettingsCard(),
          for (int i = 1; i <= 3; i++) _buildSetRow(i),
          _buildTimerCard(),
          _buildActionButtons(),
        ],
      ),
    );
  }
}
