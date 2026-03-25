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
  double? _heightM;
  bool _loading = true;
  int _days = 30;

  static const _durations = [(7, '7d'), (14, '14d'), (30, '30d'), (60, '60d')];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get('/tracking/get?days=$_days'),
        _api.get('/profile/get'),
      ]);
      final tracking = (results[0]['tracking'] as List)
          .map((t) => DailyTracking.fromJson(t))
          .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      final profile = results[1]['profile'];
      setState(() {
        _data = tracking;
        if (profile != null && profile['height_cm'] != null) {
          final h = double.tryParse(profile['height_cm'].toString());
          _heightM = h != null ? h / 100 : null;
        }
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  // ── Spot builders ──────────────────────────────────────────────────────────

  List<FlSpot> _weightSpots() {
    final f = _data.where((d) => d.weightKg != null).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), f[i].weightKg!));
  }

  List<FlSpot> _sleepSpots() {
    final f = _data.where((d) => d.sleepHours != null).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), f[i].sleepHours!));
  }

  List<FlSpot> _waterSpots() {
    final f = _data.where((d) => d.waterIntakeLiters != null).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), f[i].waterIntakeLiters!));
  }

  List<FlSpot> _stressSpots() {
    final f = _data.where((d) => d.stressLevel != null).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), f[i].stressLevel!.toDouble()));
  }

  List<FlSpot> _bmiSpots() {
    if (_heightM == null || _heightM! <= 0) return [];
    final f = _data.where((d) => d.weightKg != null).toList();
    return List.generate(f.length, (i) {
      final bmi = f[i].weightKg! / (_heightM! * _heightM!);
      return FlSpot(i.toDouble(), double.parse(bmi.toStringAsFixed(1)));
    });
  }

  List<FlSpot> _moodSpots() {
    const map = {'Great': 5.0, 'Good': 4.0, 'Okay': 3.0, 'Tired': 2.0, 'Stressed': 1.0, 'Bad': 1.0};
    final f = _data.where((d) => d.mood != null && map.containsKey(d.mood)).toList();
    return List.generate(f.length, (i) => FlSpot(i.toDouble(), map[f[i].mood]!));
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
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
                    _durationSelector(),
                    const SizedBox(height: 16),
                    _summaryRow(),
                    const SizedBox(height: 20),

                    if (_weightSpots().isNotEmpty) ...[
                      _lineChart(
                        title: 'Weight', subtitle: 'kg over time',
                        icon: Icons.monitor_weight_outlined, color: Colors.purple,
                        spots: _weightSpots(), unit: 'kg',
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_heightM == null) ...[
                      _bmiMissingCard(),
                      const SizedBox(height: 14),
                    ] else if (_bmiSpots().length > 1) ...[
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

                    if (_moodSpots().isNotEmpty) ...[
                      _moodChart(),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 8),
                  ],
                ),
    );
  }

  // ── Duration selector ──────────────────────────────────────────────────────

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

  // ── WHO helpers ────────────────────────────────────────────────────────────

  static const _bmiCategories = [
    (0.0,  18.5, 'Underweight', Colors.blue,       Icons.arrow_downward),
    (18.5, 25.0, 'Normal',      Colors.green,      Icons.thumb_up),
    (25.0, 30.0, 'Overweight',  Colors.orange,     Icons.arrow_upward),
    (30.0, 99.0, 'Obese',       Colors.red,        Icons.warning_amber),
  ];

  (String, Color, IconData) _bmiCategory(double bmi) {
    for (final (lo, hi, label, color, icon) in _bmiCategories) {
      if (bmi >= lo && bmi < hi) return (label, color, icon);
    }
    return ('Obese', Colors.red, Icons.warning_amber);
  }

  (String, Color) _weightStatus(double weight) {
    if (_heightM == null || _heightM! <= 0) return ('--', Colors.grey);
    final minW = 18.5 * _heightM! * _heightM!;
    final maxW = 24.9 * _heightM! * _heightM!;
    if (weight < minW) return ('Low',     Colors.blue);
    if (weight > maxW) return ('High',    Colors.orange);
    return ('Healthy', Colors.green);
  }

  // ── Summary row ────────────────────────────────────────────────────────────

  Widget _summaryRow() {
    final weights  = _data.where((d) => d.weightKg != null).map((d) => d.weightKg!).toList();
    final sleeps   = _data.where((d) => d.sleepHours != null).map((d) => d.sleepHours!).toList();
    final stepList = _data.where((d) => d.steps != null).map((d) => d.steps!).toList();

    final avgSleep = sleeps.isEmpty ? 0.0 : sleeps.reduce((a, b) => a + b) / sleeps.length;
    final avgSteps = stepList.isEmpty ? 0  : (stepList.reduce((a, b) => a + b) / stepList.length).round();

    final latestWeight = weights.isNotEmpty ? weights.last : null;
    final bmi = (latestWeight != null && _heightM != null && _heightM! > 0)
        ? latestWeight / (_heightM! * _heightM!) : null;

    final (weightStatus, weightColor) = latestWeight != null
        ? _weightStatus(latestWeight)
        : ('--', Colors.grey);
    final (bmiLabel, bmiColor, bmiIcon) = bmi != null
        ? _bmiCategory(bmi)
        : ('--', Colors.grey, Icons.help_outline);

    return Column(
      children: [
        // Row 1: weight + BMI with WHO badges
        Row(
          children: [
            Expanded(child: _whoCard(
              icon: Icons.monitor_weight_outlined, color: Colors.purple,
              label: 'Latest Weight',
              value: latestWeight != null ? '${latestWeight.toStringAsFixed(1)} kg' : '--',
              badge: weightStatus, badgeColor: weightColor,
              badgeIcon: weightStatus == 'Healthy' ? Icons.thumb_up : Icons.info_outline,
            )),
            const SizedBox(width: 10),
            Expanded(child: _whoCard(
              icon: Icons.accessibility_new, color: Colors.deepOrange,
              label: 'Latest BMI',
              value: bmi != null ? bmi.toStringAsFixed(1) : '--',
              badge: bmiLabel, badgeColor: bmiColor, badgeIcon: bmiIcon,
            )),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: sleep + steps
        Row(
          children: [
            Expanded(child: StatCard(
              label: 'Avg Sleep', value: avgSleep > 0 ? avgSleep.toStringAsFixed(1) : '--',
              unit: 'hrs', icon: Icons.bedtime_outlined, iconColor: Colors.indigo,
            )),
            const SizedBox(width: 10),
            Expanded(child: StatCard(
              label: 'Avg Steps', value: avgSteps > 0 ? '$avgSteps' : '--',
              icon: Icons.directions_walk, iconColor: Colors.green,
            )),
          ],
        ),
      ],
    );
  }

  Widget _whoCard({
    required IconData icon, required Color color,
    required String label, required String value,
    required String badge, required Color badgeColor, required IconData badgeIcon,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                    overflow: TextOverflow.ellipsis),
                  Text(label,
                    style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 11, color: badgeColor),
                  const SizedBox(width: 3),
                  Text(badge,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chart header ───────────────────────────────────────────────────────────

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
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(AppConstants.textSecondary))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Text('$count pts', style: const TextStyle(fontSize: 10, color: Color(AppConstants.textSecondary))),
        ),
      ],
    );
  }

  // ── Line chart card ────────────────────────────────────────────────────────

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
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 38,
                    getTitlesWidget: (v, _) => Text(
                      unit == '/10' ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 9, color: Color(AppConstants.textSecondary)),
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
                      y: val,
                      color: rColor.withValues(alpha: 0.5),
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => label,
                        style: TextStyle(fontSize: 9, color: rColor, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
                lineBarsData: [LineChartBarData(
                  spots: spots,
                  isCurved: spots.length > 1,
                  color: color,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: spots.length <= 14,
                    getDotPainter: (sp, pct, bar, idx) => FlDotCirclePainter(
                      radius: 3.5, color: color, strokeWidth: 1.5, strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
                )],
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bar chart card (steps) ─────────────────────────────────────────────────

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
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 38,
                    getTitlesWidget: (v, _) => Text(
                      '${(v / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 9, color: Color(AppConstants.textSecondary)),
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

  // ── BMI missing card ───────────────────────────────────────────────────────

  Widget _bmiMissingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.accessibility_new, color: Colors.deepOrange, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BMI', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('Height needed to calculate BMI',
                    style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/profile'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Add height →', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mood chart ─────────────────────────────────────────────────────────────

  Widget _moodChart() {
    final moodLabels = {5.0: 'Great', 4.0: 'Good', 3.0: 'Okay', 2.0: 'Tired', 1.0: 'Low'};
    final spots = _moodSpots();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chartHeader(Icons.mood, Colors.amber, 'Mood', 'mood score over time', spots.length),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(LineChartData(
                minY: 0.5, maxY: 5.5,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false, horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 46, interval: 1,
                    getTitlesWidget: (v, _) {
                      final label = moodLabels[v];
                      if (label == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(label, style: const TextStyle(
                            fontSize: 9, color: Color(AppConstants.textSecondary))),
                      );
                    },
                  )),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.amber,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) {
                      final c = spot.y >= 4 ? Colors.green
                          : spot.y == 3 ? Colors.orange : Colors.red;
                      return FlDotCirclePainter(
                          radius: 4, color: c, strokeWidth: 1.5, strokeColor: Colors.white);
                    },
                  ),
                  belowBarData: BarAreaData(show: true, color: Colors.amber.withValues(alpha: 0.07)),
                )],
              )),
            ),
          ],
        ),
      ),
    );
  }
}
