// lib/screens/participant/workout_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _api = ApiService();
  WorkoutPlan? _plan;
  bool _loading = true;
  int _activeDayIndex = 0;

  // completedSets: dayIndex -> exerciseIndex -> sets done count
  final Map<int, Map<int, int>> _completedSets = {};
  // setWeights: dayIndex -> exerciseIndex -> setNumber(1-based) -> weight_kg (null=bodyweight)
  final Map<int, Map<int, Map<int, double?>>> _setWeights = {};
  // last done date per day
  final Map<int, DateTime?> _lastDoneDate = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/workout/get');
      if (res['workout_plan'] != null) {
        _plan = WorkoutPlan.fromJson(res['workout_plan']);
        await _loadPersisted();
      }
      setState(() {});
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _key(String suffix, int dayIndex) =>
      'workout_${_plan!.id}_day${dayIndex}_$suffix';

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    for (int d = 0; d < _plan!.days.length; d++) {
      // completed counts
      final raw = prefs.getString(_key('sets', d));
      if (raw != null) {
        final parts = raw.split(',');
        final map = <int, int>{};
        for (int i = 0; i < parts.length; i++) { map[i] = int.tryParse(parts[i]) ?? 0; }
        _completedSets[d] = map;
      }
      // weights: stored as "exIdx:setNum:weight|..." where weight is empty for bodyweight
      final wRaw = prefs.getString(_key('weights', d));
      if (wRaw != null && wRaw.isNotEmpty) {
        final exMap = <int, Map<int, double?>>{};
        for (final entry in wRaw.split('|')) {
          final parts = entry.split(':');
          if (parts.length == 3) {
            final exIdx = int.tryParse(parts[0]);
            final setNum = int.tryParse(parts[1]);
            if (exIdx != null && setNum != null) {
              exMap.putIfAbsent(exIdx, () => {})[setNum] =
                  parts[2].isEmpty ? null : double.tryParse(parts[2]);
            }
          }
        }
        _setWeights[d] = exMap;
      }
      // last done
      final dateStr = prefs.getString(_key('lastdone', d));
      if (dateStr != null) _lastDoneDate[d] = DateTime.tryParse(dateStr);
    }
  }

  Future<void> _persist(int dayIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final day = _plan!.days[dayIndex];
    final map = _completedSets[dayIndex] ?? {};

    // Save set counts
    final encoded = List.generate(day.exercises.length, (i) => '${map[i] ?? 0}').join(',');
    await prefs.setString(_key('sets', dayIndex), encoded);

    // Save weights
    final weightParts = <String>[];
    final wMap = _setWeights[dayIndex] ?? {};
    for (final exEntry in wMap.entries) {
      for (final setEntry in exEntry.value.entries) {
        weightParts.add('${exEntry.key}:${setEntry.key}:${setEntry.value ?? ''}');
      }
    }
    await prefs.setString(_key('weights', dayIndex), weightParts.join('|'));

    // Check fully done
    final allDone = day.exercises.asMap().entries.every(
        (e) => (map[e.key] ?? 0) >= e.value.sets);
    if (allDone) {
      final now = DateTime.now();
      _lastDoneDate[dayIndex] = now;
      await prefs.setString(_key('lastdone', dayIndex), now.toIso8601String());
      setState(() {});
      await _saveSession(dayIndex);
    }
  }

  Future<void> _saveSession(int dayIndex) async {
    final day = _plan!.days[dayIndex];
    final wMap = _setWeights[dayIndex] ?? {};
    final setLogs = <Map<String, dynamic>>[];

    for (int i = 0; i < day.exercises.length; i++) {
      final ex = day.exercises[i];
      final done = _completedSets[dayIndex]?[i] ?? 0;
      for (int s = 1; s <= done; s++) {
        setLogs.add({
          'exercise_id':   ex.exerciseId,
          'exercise_name': ex.exerciseName,
          'set_number':    s,
          'reps_done':     ex.reps,
          'weight_kg':     wMap[i]?[s], // null = bodyweight
        });
      }
    }

    try {
      await _api.post('/workout/sessions', {
        'workout_plan_id': _plan!.id,
        'workout_day_id':  day.id,
        'day_name':        day.dayName,
        'set_logs':        setLogs,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout saved!'), backgroundColor: Colors.green));
      }
    } catch (_) {
      // Silently fail — data already persisted locally
    }
  }

  // ── Weight input dialog ──────────────────────────────────────────────────

  Future<void> _onSetTap(int dayIndex, int exIdx, int setNum, bool alreadyDone) async {
    if (alreadyDone) {
      // Long-press handles undo; single tap on done set does nothing
      return;
    }
    final weight = await _showWeightDialog(setNum);
    if (weight == null) return; // cancelled

    setState(() {
      _completedSets[dayIndex] ??= {};
      _completedSets[dayIndex]![exIdx] = setNum; // mark sets 1..setNum done
      _setWeights[dayIndex] ??= {};
      _setWeights[dayIndex]![exIdx] ??= {};
      _setWeights[dayIndex]![exIdx]![setNum] = weight == -1 ? null : weight;
    });
    await _persist(dayIndex);
  }

  void _onSetLongPress(int dayIndex, int exIdx, int setNum) {
    setState(() {
      _completedSets[dayIndex] ??= {};
      final current = _completedSets[dayIndex]![exIdx] ?? 0;
      if (current >= setNum) {
        _completedSets[dayIndex]![exIdx] = setNum - 1;
        // Clear weights for sets >= setNum
        _setWeights[dayIndex]?[exIdx]?.remove(setNum);
      }
    });
    _persist(dayIndex);
  }

  /// Returns the weight in kg, -1 for bodyweight, or null if cancelled.
  Future<double?> _showWeightDialog(int setNum) async {
    final ctrl = TextEditingController();
    return showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set $setNum — Weight used?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'e.g. 20, 45.5',
                suffixText: 'kg',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.accessibility_new, size: 16),
              label: const Text('Use Bodyweight instead'),
              onPressed: () => Navigator.pop(ctx, -1.0),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, v ?? -1.0);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showVideoPlayer(String exerciseName, String videoId) {
    showDialog(context: context,
      builder: (_) => VideoSheet(exerciseName: exerciseName, videoId: videoId));
  }

  Widget _lastDoneBadge(DateTime date, bool activeTab) {
    final days = DateTime.now().difference(date).inDays;
    final label = days == 0 ? 'today' : days == 1 ? '1d ago' : '${days}d ago';
    return Text(label, style: TextStyle(
      fontSize: 9, fontWeight: FontWeight.w600,
      color: activeTab ? Colors.white70 : Colors.green.shade700));
  }

  Color _muscleColor(String muscle) {
    const map = {
      'Chest': Colors.red, 'Back': Colors.blue, 'Legs': Colors.green,
      'Shoulders': Colors.orange, 'Biceps': Colors.purple, 'Triceps': Colors.indigo,
      'Core': Colors.teal, 'Cardio': Colors.pink, 'Full Body': Colors.brown,
      'Hamstrings': Colors.deepOrange, 'Calves': Colors.cyan,
    };
    return map[muscle] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => context.push('/workout/history'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? const EmptyState(
                  icon: Icons.fitness_center,
                  message: 'No workout plan assigned',
                  subtitle: 'Your coach will assign a workout plan for you',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 14),
                      _buildDayTabs(),
                      const SizedBox(height: 12),
                      ..._buildExerciseCards(),
                      const SizedBox(height: 16),
                      _buildCompletionBanner(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final activeDay = _plan!.days[_activeDayIndex];
    final total = activeDay.exercises.length;
    final doneCount = _completedSets[_activeDayIndex]?.entries
        .where((e) => e.value >= activeDay.exercises[e.key].sets).length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.fitness_center, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(_plan!.planName,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text('${_plan!.days.length}-day plan  •  ${activeDay.exercises.length} exercises today',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: total == 0 ? 0 : doneCount / total,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation(Colors.white),
        ),
        const SizedBox(height: 4),
        Text('$doneCount / $total done',
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildDayTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _plan!.days.asMap().entries.map((entry) {
          final i   = entry.key;
          final day = entry.value;
          final active = i == _activeDayIndex;
          return GestureDetector(
            onTap: () => setState(() => _activeDayIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? Colors.green : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? Colors.green : Colors.grey.shade200),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(day.dayName, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : const Color(AppConstants.textPrimary))),
                if (_lastDoneDate[i] != null) ...[
                  const SizedBox(width: 4),
                  _lastDoneBadge(_lastDoneDate[i]!, active),
                ],
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildExerciseCards() {
    final activeDay = _plan!.days[_activeDayIndex];
    return activeDay.exercises.asMap().entries.map((entry) {
      final i  = entry.key;
      final ex = entry.value;
      final done = _completedSets[_activeDayIndex]?[i] ?? 0;
      final isComplete = done >= ex.sets;

      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top row
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _muscleColor(ex.muscleGroup).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ex.muscleGroup, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: _muscleColor(ex.muscleGroup))),
              ),
              const Spacer(),
              if (ex.youtubeVideoId != null) ...[
                GestureDetector(
                  onTap: () => _showVideoPlayer(ex.exerciseName, ex.youtubeVideoId!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_circle_outline, color: Colors.red, size: 15),
                      SizedBox(width: 4),
                      Text('Watch', style: TextStyle(color: Colors.red,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (isComplete)
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
            ]),
            const SizedBox(height: 8),
            Text(ex.exerciseName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${ex.sets} sets × ${ex.reps} reps',
              style: const TextStyle(color: Color(AppConstants.textSecondary))),
            if (ex.notes != null) ...[
              const SizedBox(height: 4),
              Text(ex.notes!, style: const TextStyle(
                fontSize: 12, color: Color(AppConstants.textSecondary),
                fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            // Set tracker with weight display
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Sets:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              Wrap(
                spacing: 6,
                children: List.generate(ex.sets, (s) {
                  final setNum = s + 1; // 1-based
                  final complete = s < done;
                  final w = _setWeights[_activeDayIndex]?[i]?[setNum];
                  final weightLabel = complete
                      ? (w == null ? 'BW' : '${w % 1 == 0 ? w.toInt() : w}kg')
                      : null;

                  return GestureDetector(
                    onTap: () => _onSetTap(_activeDayIndex, i, setNum, complete),
                    onLongPress: () => _onSetLongPress(_activeDayIndex, i, setNum),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: complete ? Colors.green : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: complete ? Colors.green : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: complete
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : Text('$setNum', style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        if (weightLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(weightLabel, style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            color: Colors.green.shade700)),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Tap to log · Long-press to undo',
              style: TextStyle(fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35))),
          ]),
        ),
      );
    }).toList();
  }

  Widget _buildCompletionBanner() {
    final activeDay = _plan!.days[_activeDayIndex];
    final total = activeDay.exercises.length;
    if (total == 0) return const SizedBox.shrink();
    final done = _completedSets[_activeDayIndex]?.entries
        .where((e) => e.value >= activeDay.exercises[e.key].sets).length ?? 0;
    if (done < total) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.emoji_events, color: Colors.green, size: 28),
        SizedBox(width: 10),
        Text('Day complete! Great job!',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
      ]),
    );
  }
}
