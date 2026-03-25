// lib/screens/coach/client_progress_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class ClientProgressScreen extends StatefulWidget {
  final int clientId;
  const ClientProgressScreen({super.key, required this.clientId});

  @override
  State<ClientProgressScreen> createState() => _ClientProgressScreenState();
}

class _ClientProgressScreenState extends State<ClientProgressScreen> {
  final _api = ApiService();
  List<DailyTracking> _data = [];
  double? _heightM;
  bool _loading = true;
  int _days = 30;

  static const _durations = [(7, '7d'), (14, '14d'), (30, '30d')];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/tracking/get?days=$_days&user_id=${widget.clientId}');
      final tracking = (res['tracking'] as List? ?? [])
          .map((t) => DailyTracking.fromJson(t))
          .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      setState(() => _data = tracking);
    } catch (_) {}
    setState(() => _loading = false);
  }

  // ── Spot / group builders ─────────────────────────────────────────────────

  List<FlSpot> _weightSpots() {
    final f = _data.where((d) => d.weightKg != null).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), f[i].weightKg!));
  }

  List<FlSpot> _bmiSpots() {
    if (_heightM == null || _heightM! <= 0) return [];
    final f = _data.where((d) => d.weightKg != null).toList();
    return List.generate(f.length, (i) {
      final bmi = f[i].weightKg! / (_heightM! * _heightM!);
      return FlSpot(i.toDouble(), double.parse(bmi.toStringAsFixed(1)));
    });
  }

  List<FlSpot> _sleepSpots() {
    final f = _data.where((d) => d.sleepHours != null).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), f[i].sleepHours!));
  }

  List<FlSpot> _stressSpots() {
    final f = _data.where((d) => d.stressLevel != null).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), f[i].stressLevel!.toDouble()));
  }

  List<FlSpot> _waterSpots() {
    final f = _data.where((d) => d.waterIntakeLiters != null).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), f[i].waterIntakeLiters!));
  }

  List<BarChartGroupData> _stepsGroups() {
    final f = _data.where((d) => d.steps != null).toList();
    final barW = f.length > 20 ? 6.0 : 12.0;
    return List.generate(f.length, (i) => BarChartGroupData(
      x: i,
      barRods: [BarChartRodData(
        toY: f[i].steps!.toDouble(),
        color: Colors.green,
        width: barW,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      )],
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Report'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? const EmptyState(
                  icon: Icons.show_chart,
                  message: 'No tracking data yet',
                  subtitle: 'Client has not logged any daily metrics',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _durationSelector(),
                    const SizedBox(height: 20),

                    if (_weightSpots().isNotEmpty) ...[
                      _lineChart(
                        title: 'Weight', subtitle: 'kg over time',
                        icon: Icons.monitor_weight_outlined, color: Colors.purple,
                        spots: _weightSpots(), unit: 'kg',
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_bmiSpots().isNotEmpty) ...[
                      _lineChart(
                        title: 'BMI', subtitle: 'body mass index',
                        icon: Icons.accessibility_new, color: Colors.deepOrange,
                        spots: _bmiSpots(), unit: '',
                        refLines: const [
                          (18.5, 'Underweight', Colors.blue),
                          (25.0, 'Overweight',  Colors.orange),
                          (30.0, 'Obese',       Colors.red),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_stepsGroups().isNotEmpty) ...[
                      _barChart(
                        title: 'Daily Steps', subtitle: 'steps per day',
                        icon: Icons.directions_walk, color: Colors.green,
                        groups: _stepsGroups(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_sleepSpots().isNotEmpty) ...[
                      _lineChart(
                        title: 'Sleep', subtitle: 'hours per night',
                        icon: Icons.bedtime_outlined, color: Colors.indigo,
                        spots: _sleepSpots(), unit: 'hrs',
                        refLines: const [(8.0, '8h goal', Colors.indigo)],
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_waterSpots().isNotEmpty) ...[
                      _lineChart(
                        title: 'Water Intake', subtitle: 'liters per day',
                        icon: Icons.water_drop_outlined, color: Colors.blue,
                        spots: _waterSpots(), unit: 'L',
                        refLines: const [(2.0, '2L goal', Colors.blue)],
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_stressSpots().isNotEmpty) ...[
                      _lineChart(
                        title: 'Stress Level', subtitle: '1 = relaxed  ·  10 = stressed',
                        icon: Icons.psychology_outlined, color: Colors.orange,
                        spots: _stressSpots(), unit: '/10',
                      ),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
    );
  }

  // ── Duration selector ─────────────────────────────────────────────────────

  Widget _durationSelector() {
    return Row(
      children: _durations.map((d) {
        final (days, label) = d;
        final selected = _days == days;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) { setState(() => _days = days); _load(); },
          ),
        );
      }).toList(),
    );
  }

  // ── Chart header ──────────────────────────────────────────────────────────

  Widget _chartHeader(IconData icon, Color color, String title, String subtitle, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Color(AppConstants.textSecondary))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text('$count pts',
            style: const TextStyle(fontSize: 10, color: Color(AppConstants.textSecondary))),
        ),
      ],
    );
  }

  // ── Line chart ────────────────────────────────────────────────────────────

  Widget _lineChart({
    required String title, required String subtitle,
    required IconData icon, required Color color,
    required List<FlSpot> spots, required String unit,
    List<(double, String, Color)>? refLines,
  }) {
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad  = ((maxY - minY) * 0.15).clamp(0.5, double.infinity);
    double adjMin = minY - pad;
    double adjMax = maxY + pad;
    if (refLines != null) {
      for (final (v, _, _) in refLines) {
        if (v < adjMin) adjMin = v - 0.5;
        if (v > adjMax) adjMax = v + 0.5;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chartHeader(icon, color, title, subtitle, spots.length),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(LineChartData(
                minY: adjMin, maxY: adjMax,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 38,
                    getTitlesWidget: (v, _) => Text(
                      unit == '/10' ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 9, color: Color(AppConstants.textSecondary)),
                    ),
                  )),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                extraLinesData: refLines == null ? null : ExtraLinesData(
                  horizontalLines: refLines.map((r) {
                    final (val, label, rColor) = r;
                    return HorizontalLine(
                      y: val, color: rColor.withValues(alpha: 0.5),
                      strokeWidth: 1.2, dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true, alignment: Alignment.topRight,
                        labelResolver: (_) => label,
                        style: TextStyle(
                            fontSize: 9, color: rColor, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
                lineBarsData: [LineChartBarData(
                  spots: spots,
                  isCurved: spots.length > 1,
                  color: color, barWidth: 2.5,
                  dotData: FlDotData(
                    show: spots.length <= 14,
                    getDotPainter: (sp, pct, bar, idx) => FlDotCirclePainter(
                      radius: 3.5, color: color,
                      strokeWidth: 1.5, strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                      show: true, color: color.withValues(alpha: 0.08)),
                )],
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bar chart ─────────────────────────────────────────────────────────────

  Widget _barChart({
    required String title, required String subtitle,
    required IconData icon, required Color color,
    required List<BarChartGroupData> groups,
  }) {
    final maxVal = groups
        .map((g) => g.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chartHeader(icon, color, title, subtitle, groups.length),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(BarChartData(
                maxY: maxVal * 1.2,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 38,
                    getTitlesWidget: (v, _) => Text(
                      '${(v / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(
                          fontSize: 9, color: Color(AppConstants.textSecondary)),
                    ),
                  )),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: groups,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toStringAsFixed(0)} steps',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
