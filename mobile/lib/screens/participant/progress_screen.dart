// lib/screens/participant/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _api = ApiService();
  List<DailyTracking> _data = [];
  bool _loading = true;
  int _days = 30;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/tracking/get?days=$_days');
      setState(() {
        _data = (res['tracking'] as List)
            .map((t) => DailyTracking.fromJson(t))
            .toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<FlSpot> _weightSpots() {
    final filtered = _data.where((d) => d.weightKg != null).toList();
    return List.generate(filtered.length, (i) =>
      FlSpot(i.toDouble(), filtered[i].weightKg!));
  }

  List<FlSpot> _stepsSpots() {
    final filtered = _data.where((d) => d.steps != null).toList();
    return List.generate(filtered.length, (i) =>
      FlSpot(i.toDouble(), filtered[i].steps!.toDouble()));
  }

  List<FlSpot> _sleepSpots() {
    final filtered = _data.where((d) => d.sleepHours != null).toList();
    return List.generate(filtered.length, (i) =>
      FlSpot(i.toDouble(), filtered[i].sleepHours!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          DropdownButton<int>(
            value: _days,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 7,  child: Text('7 days')),
              DropdownMenuItem(value: 14, child: Text('14 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
              DropdownMenuItem(value: 60, child: Text('60 days')),
            ],
            onChanged: (v) { setState(() => _days = v!); _load(); },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? const EmptyState(
                  icon: Icons.show_chart,
                  message: 'No tracking data yet',
                  subtitle: 'Start logging your daily metrics to see progress charts',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary stats
                    _summaryRow(),
                    const SizedBox(height: 20),

                    // Weight chart
                    if (_weightSpots().length > 1) ...[
                      _chartCard(
                        title: 'Weight Progress',
                        subtitle: 'kg over time',
                        icon: Icons.monitor_weight_outlined,
                        color: Colors.purple,
                        spots: _weightSpots(),
                        unit: 'kg',
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Steps chart
                    if (_stepsSpots().length > 1) ...[
                      _chartCard(
                        title: 'Daily Steps',
                        subtitle: 'steps over time',
                        icon: Icons.directions_walk,
                        color: Colors.green,
                        spots: _stepsSpots(),
                        unit: 'steps',
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Sleep chart
                    if (_sleepSpots().length > 1) ...[
                      _chartCard(
                        title: 'Sleep Hours',
                        subtitle: 'hours over time',
                        icon: Icons.bedtime_outlined,
                        color: Colors.indigo,
                        spots: _sleepSpots(),
                        unit: 'hrs',
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Mood log
                    _moodLog(),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }

  Widget _summaryRow() {
    final weights = _data.where((d) => d.weightKg != null).map((d) => d.weightKg!).toList();
    final avgSteps = _data.where((d) => d.steps != null).isEmpty ? 0
        : (_data.where((d) => d.steps != null).map((d) => d.steps!).reduce((a, b) => a + b) /
           _data.where((d) => d.steps != null).length).round();
    final avgSleep = _data.where((d) => d.sleepHours != null).isEmpty ? 0.0
        : _data.where((d) => d.sleepHours != null).map((d) => d.sleepHours!).reduce((a, b) => a + b) /
          _data.where((d) => d.sleepHours != null).length;

    return Row(
      children: [
        Expanded(child: StatCard(
          label: 'Entries', value: '${_data.length}', icon: Icons.calendar_today,
          iconColor: Colors.blue,
        )),
        const SizedBox(width: 10),
        Expanded(child: StatCard(
          label: 'Latest Weight',
          value: weights.isNotEmpty ? weights.last.toStringAsFixed(1) : '--',
          unit: 'kg', icon: Icons.monitor_weight_outlined, iconColor: Colors.purple,
        )),
        const SizedBox(width: 10),
        Expanded(child: StatCard(
          label: 'Avg Sleep',
          value: avgSleep > 0 ? avgSleep.toStringAsFixed(1) : '--',
          unit: 'hrs', icon: Icons.bedtime_outlined, iconColor: Colors.indigo,
        )),
      ],
    );
  }

  Widget _chartCard({
    required String title, required String subtitle, required IconData icon,
    required Color color, required List<FlSpot> spots, required String unit,
  }) {
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(
                        fontSize: 11, color: Color(AppConstants.textSecondary))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: minY - padding,
                  maxY: maxY + padding,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(unit == 'steps' ? 0 : 1),
                          style: const TextStyle(fontSize: 10, color: Color(AppConstants.textSecondary)),
                        ),
                      ),
                    ),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: spots.length <= 14,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4, color: color, strokeWidth: 1.5, strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moodLog() {
    final moodData = _data.where((d) => d.mood != null).toList().reversed.take(10).toList();
    if (moodData.isEmpty) return const SizedBox();

    final moodIcons = {
      'Great': ('😄', Colors.green),
      'Good':  ('🙂', Colors.lightGreen),
      'Okay':  ('😐', Colors.orange),
      'Tired': ('😴', Colors.grey),
      'Stressed': ('😰', Colors.red),
      'Bad':   ('😞', Colors.red),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mood, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Recent Mood Log',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: moodData.map((d) {
                final (emoji, color) = moodIcons[d.mood] ?? ('😐', Colors.grey);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(d.date.substring(5), // MM-DD
                        style: TextStyle(fontSize: 11, color: color)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
