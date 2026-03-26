// lib/screens/coach/client_goal_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class ClientGoalTrackingScreen extends StatefulWidget {
  final int clientId;
  const ClientGoalTrackingScreen({super.key, required this.clientId});

  @override
  State<ClientGoalTrackingScreen> createState() => _ClientGoalTrackingScreenState();
}

class _ClientGoalTrackingScreenState extends State<ClientGoalTrackingScreen> {
  final _api = ApiService();
  String _clientName = '';
  List<Map<String, dynamic>> _tracking = [];
  Map<String, dynamic>? _lifestylePlan;
  List<String> _workoutDates = [];
  bool _loading = true;

  // Last 14 days (today = index 0)
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(14, (i) {
      final d = today.subtract(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/coach/client/${widget.clientId}/goal-tracking');
      setState(() {
        _clientName    = res['client_name'] ?? '';
        _tracking      = List<Map<String, dynamic>>.from(res['tracking'] ?? []);
        _lifestylePlan = res['lifestyle_plan'] as Map<String, dynamic>?;
        _workoutDates  = List<String>.from(res['workout_dates'] ?? []);
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  // Find tracking row for a specific date
  Map<String, dynamic>? _trackingFor(DateTime day) {
    final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    for (final t in _tracking) {
      final raw = (t['date'] as String).substring(0, 10);
      if (raw == dateStr) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_clientName.isEmpty ? 'Goal Tracking' : _clientName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Last 14 days', style: TextStyle(fontSize: 11)),
          ],
        ),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final items = _lifestylePlan == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            (_lifestylePlan!['items'] as List? ?? []).where((i) => i != null));

    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.flag_outlined,
        message: 'No lifestyle goals assigned',
        subtitle: 'Assign a lifestyle plan to track goal completion',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _dateHeaderRow(),
        const SizedBox(height: 8),
        _workoutRow(),
        _deviationRow(),
        if (items.isNotEmpty) const Divider(height: 16),
        ...items.map((item) => _goalRow(item)),
        const SizedBox(height: 20),
        _trackingSection(),
      ],
    );
  }

  // Top row: day labels (Mon 23, Tue 24, …)
  Widget _dateHeaderRow() {
    return Row(
      children: [
        const SizedBox(width: 130), // label column width
        Expanded(
          child: Row(
            children: _days.reversed.map((day) {
              final isToday = day == _days.first;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _weekday(day),
                      style: TextStyle(
                        fontSize: 9,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : const Color(AppConstants.textSecondary),
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : const Color(AppConstants.textSecondary),
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // One row per goal
  Widget _goalRow(Map<String, dynamic> item) {
    final category  = item['category'] as String? ?? '';
    final title     = item['title']    as String? ?? category;
    final target    = item['target_value'] as String?;
    final unit      = item['unit']     as String? ?? '';
    final isNumeric = ['steps', 'water', 'sleep'].contains(category);
    final (icon, color) = _goalMeta(category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Goal label
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      if (target != null)
                        Text('Target: $target$unit',
                            style: const TextStyle(
                                fontSize: 10, color: Color(AppConstants.textSecondary))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Day dots
          Expanded(
            child: Row(
              children: _days.reversed.map((day) {
                final t = _trackingFor(day);
                final status = isNumeric
                    ? _numericStatus(category, target, t)
                    : _noData; // yes/no goals not tracked server-side
                return Expanded(child: Center(child: _dot(status, isNumeric)));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workoutRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                const Text('Workout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: _days.reversed.map((day) {
                final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final done = _workoutDates.contains(dateStr);
                return Expanded(child: Center(child: _dot(done ? 1 : 0, true)));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 16),
                const SizedBox(width: 6),
                const Text('Deviation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: _days.reversed.map((day) {
                final t = _trackingFor(day);
                if (t == null) return Expanded(child: Center(child: _dot(0, true)));
                final hadDev = (t['deviation_notes'] as String?)?.trim().isNotEmpty == true;
                return Expanded(
                  child: Center(
                    child: hadDev
                        ? Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(color: Colors.orange.shade400, shape: BoxShape.circle),
                            child: const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.white),
                          )
                        : _dot(1, true), // logged, no deviation = green
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 0 = no data, 1 = done, -1 = missed
  static const _noData = 0;

  // PostgreSQL DECIMAL/NUMERIC columns come back as strings — handle both
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int _numericStatus(String category, String? target, Map<String, dynamic>? t) {
    if (t == null || target == null) return _noData;
    final tgt = double.tryParse(target);
    if (tgt == null) return _noData;
    double? actual;
    if (category == 'steps') actual = _toDouble(t['steps']);
    if (category == 'water') actual = _toDouble(t['water_intake_liters']);
    if (category == 'sleep') actual = _toDouble(t['sleep_hours']);
    if (actual == null) return _noData;
    return actual >= tgt ? 1 : -1;
  }

  Widget _dot(int status, bool isNumeric) {
    if (status == 0 && !isNumeric) {
      // Yes/no goals: show dash (not tracked server-side)
      return const Text('–',
          style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary)),
          textAlign: TextAlign.center);
    }
    final color = status == 1
        ? Colors.green
        : status == -1
            ? Colors.red.shade300
            : Colors.grey.shade200;
    final icon  = status == 1 ? Icons.check : status == -1 ? Icons.close : null;
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, size: 11, color: Colors.white)
          : null,
    );
  }

  // ── Daily tracking summary table ─────────────────────────────────────────

  Widget _trackingSection() {
    if (_tracking.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text('Daily Logged Metrics',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        ..._tracking.take(14).map((t) => _trackingRow(t)),
      ],
    );
  }

  Widget _trackingRow(Map<String, dynamic> t) {
    final date      = (t['date'] as String).substring(0, 10);
    final steps     = _toDouble(t['steps']);
    final water     = _toDouble(t['water_intake_liters']);
    final sleep     = _toDouble(t['sleep_hours']);
    final stress    = t['stress_level'];
    final deviation = t['deviation_notes'] as String?;
    final hadDev    = deviation != null && deviation.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(date,
                  style: const TextStyle(fontSize: 11, color: Color(AppConstants.textSecondary))),
              if (hadDev) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade300, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 10, color: Colors.orange.shade700),
                      const SizedBox(width: 3),
                      Text('Deviation', style: TextStyle(fontSize: 9, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _metricChip(Icons.directions_walk,
                  steps != null ? steps.toInt().toString() : '–', Colors.green),
              _metricChip(Icons.water_drop_outlined,
                  water != null ? '${water.toStringAsFixed(1)}L' : '–', Colors.blue),
              _metricChip(Icons.bedtime_outlined,
                  sleep != null ? '${sleep.toStringAsFixed(1)}h' : '–', Colors.indigo),
              _metricChip(Icons.psychology_outlined,
                  stress != null ? '$stress/10' : '–', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  (IconData, Color) _goalMeta(String category) => switch (category) {
    'steps'       => (Icons.directions_walk,    Colors.green),
    'water'       => (Icons.water_drop_outlined, Colors.blue),
    'sleep'       => (Icons.bedtime_outlined,    Colors.indigo),
    'meditation'  => (Icons.self_improvement,    Colors.purple),
    'screen_time' => (Icons.phone_android,       Colors.red),
    'sunlight'    => (Icons.wb_sunny_outlined,   Colors.amber),
    'no_sugar'    => (Icons.no_food,             Colors.brown),
    'no_alcohol'  => (Icons.no_drinks,           Colors.deepOrange),
    'meal_timing' => (Icons.schedule,            Colors.teal),
    _             => (Icons.flag_outlined,       Colors.grey),
  };

  String _weekday(DateTime d) =>
      const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7];
}
