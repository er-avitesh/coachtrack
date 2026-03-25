// lib/screens/participant/workout_history_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});
  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final _api = ApiService();
  List<WorkoutSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/workout/history');
      setState(() {
        _sessions = (res['sessions'] as List? ?? [])
            .map((s) => WorkoutSession.fromJson(s))
            .toList();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[dt.weekday % 7]}, ${months[dt.month]} ${dt.day}';
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  // Group set logs by exercise within a session
  Map<String, List<WorkoutSetLog>> _groupByExercise(List<WorkoutSetLog> logs) {
    final map = <String, List<WorkoutSetLog>>{};
    for (final log in logs) {
      (map[log.exerciseName] ??= []).add(log);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _sessions.isEmpty ? _emptyState() : _sessionList(),
            ),
    );
  }

  Widget _sessionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (_, i) => _sessionCard(_sessions[i]),
    );
  }

  Widget _sessionCard(WorkoutSession session) {
    final byExercise = _groupByExercise(session.logs);
    final dateLabel = _formatDate(session.completedAt.toLocal());
    final timeLabel = _timeLabel(session.completedAt.toLocal());
    final totalSets = session.logs.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center, color: Colors.green, size: 20),
        ),
        title: Text(
          session.dayName ?? 'Workout',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          '$dateLabel · $timeLabel · $totalSets sets',
          style: TextStyle(fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        children: byExercise.entries.map((entry) {
          final exName = entry.key;
          final logs = entry.value..sort((a, b) => a.setNumber.compareTo(b.setNumber));
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: logs.map((log) {
                  final weightLabel = log.weightKg == null
                      ? 'BW'
                      : '${log.weightKg! % 1 == 0 ? log.weightKg!.toInt() : log.weightKg}kg';
                  final repsLabel = log.repsDone != null ? '×${log.repsDone}' : '';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Set ${log.setNumber}  $weightLabel$repsLabel',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, size: 64,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        const Text('No workout history yet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text('Complete a workout to see it here',
          style: TextStyle(fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
      ]),
    );
  }
}
