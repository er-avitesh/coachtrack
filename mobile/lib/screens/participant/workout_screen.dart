// lib/screens/participant/workout_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  // Track completed sets per exercise: dayIndex -> exerciseIndex -> setsCompleted
  final Map<int, Map<int, int>> _completedSets = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/workout/get');
      setState(() {
        _plan = res['workout_plan'] != null
            ? WorkoutPlan.fromJson(res['workout_plan']) : null;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showVideoPlayer(String exerciseName, String videoId) {
    showDialog(
      context: context,
      builder: (_) => VideoSheet(exerciseName: exerciseName, videoId: videoId),
    );
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
        leading: BackButton(onPressed: () => context.go('/dashboard')),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(_plan!.planName,
            style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('${_plan!.days.length}-day plan  •  ${activeDay.exercises.length} exercises today',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: total == 0 ? 0 : (_completedSets[_activeDayIndex]?.entries
                .where((e) => e.value >= activeDay.exercises[e.key].sets).length ?? 0) / total,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${_completedSets[_activeDayIndex]?.entries.where((e) => e.value >= activeDay.exercises[e.key].sets).length ?? 0} / $total done',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
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
                border: Border.all(
                  color: active ? Colors.green : Colors.grey.shade200),
              ),
              child: Text(day.dayName,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : const Color(AppConstants.textPrimary))),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: muscle tag + video button + done check
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _muscleColor(ex.muscleGroup).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(ex.muscleGroup,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: _muscleColor(ex.muscleGroup))),
                ),
                const Spacer(),
                // ▶ Watch button — only shown when video is available
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
                Text(ex.notes!,
                  style: const TextStyle(fontSize: 12,
                      color: Color(AppConstants.textSecondary),
                      fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 12),
              // Set tracker
              Row(children: [
                const Text('Sets done:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                ...List.generate(ex.sets, (s) {
                  final complete = s < done;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _completedSets[_activeDayIndex] ??= {};
                      _completedSets[_activeDayIndex]![i] = complete ? s : s + 1;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: complete ? Colors.green : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: complete ? Colors.green : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: complete
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text('${s + 1}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }),
              ]),
            ],
          ),
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: Colors.green, size: 28),
          SizedBox(width: 10),
          Text("Day complete! Great job! 💪",
            style: TextStyle(fontWeight: FontWeight.bold,
                color: Colors.green, fontSize: 15)),
        ],
      ),
    );
  }
}

