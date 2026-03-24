// lib/screens/coach/client_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class ClientProfileScreen extends StatefulWidget {
  final int clientId;
  const ClientProfileScreen({super.key, required this.clientId});
  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _client;
  DietPlan?      _dietPlan;
  WorkoutPlan?   _workoutPlan;
  LifestylePlan? _lifestylePlan;
  List<Tip>      _tips      = [];
  List<Map<String, dynamic>> _tracking = [];
  bool _loading = true;
  DateTime? _programStartDate;
  DateTime? _programEndDate;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get('/coach/client/${widget.clientId}/summary'),
        _api.get('/diet/get?user_id=${widget.clientId}'),
        _api.get('/workout/get?user_id=${widget.clientId}'),
        _api.get('/tips/get?user_id=${widget.clientId}'),
        _api.get('/lifestyle/get?user_id=${widget.clientId}'),
      ]);
      setState(() {
        _client        = results[0]['client'];
        final sd = results[0]['client']?['program_start_date'];
        final ed = results[0]['client']?['program_end_date'];
        _programStartDate = sd != null ? DateTime.tryParse(sd) : null;
        _programEndDate   = ed != null ? DateTime.tryParse(ed) : null;
        _tracking      = List<Map<String,dynamic>>.from(results[0]['tracking'] ?? []);
        _dietPlan      = results[1]['diet_plan'] != null ? DietPlan.fromJson(results[1]['diet_plan']) : null;
        _workoutPlan   = results[2]['workout_plan'] != null ? WorkoutPlan.fromJson(results[2]['workout_plan']) : null;
        _tips          = (results[3]['tips'] as List? ?? []).map((t) => Tip.fromJson(t)).toList();
        _lifestylePlan = results[4]['lifestyle_plan'] != null ? LifestylePlan.fromJson(results[4]['lifestyle_plan']) : null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final c        = _client ?? {};
    final name     = c['full_name'] ?? 'Client';
    final initials = name.split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    // Find goal labels (health_goal is comma-separated)
    final rawGoal   = c['health_goal'] as String?;
    final goalKeys  = rawGoal?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];
    final goalLabels = goalKeys
        .map((k) => healthGoals.firstWhere((g) => g['key'] == k, orElse: () => {})['label'] as String?)
        .whereType<String>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: BackButton(onPressed: () => context.go('/coach')),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Profile header ────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(AppConstants.primaryColor).withValues(alpha: 0.1),
                    child: Text(initials, style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: Color(AppConstants.primaryColor))),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  Text('@${c['username'] ?? ''}',
                      style: const TextStyle(color: Color(AppConstants.textSecondary))),
                  const SizedBox(height: 10),

                  // Goal badges
                  if (goalLabels.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text('Goal: Not set yet',
                        style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                    )
                  else
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: goalLabels.map((label) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.primaryColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(AppConstants.primaryColor).withValues(alpha: 0.3)),
                        ),
                        child: Text(label,
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: Color(AppConstants.primaryColor))),
                      )).toList(),
                    ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _stat('Wt', '${c['current_weight_kg'] ?? '--'} kg', 'Current'),
                    _stat('Tgt', '${c['goal_weight_kg'] ?? '--'} kg', 'Goal'),
                    _stat('Act', _cap(c['activity_level']), 'Activity'),
                    _stat('Diet', _cap(c['diet_preference']), 'Diet'),
                  ]),
                  const SizedBox(height: 12),
                  _programPeriodRow(),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // ── Diet Plan card ────────────────────────────────
            _assignmentCard(
              icon: Icons.restaurant_menu,
              color: Colors.orange,
              title: 'Diet Plan',
              isAssigned: _dietPlan != null,
              assignLabel: 'Assign Diet Plan',
              modifyLabel: 'Modify Diet Plan',
              onTap: () => context.go('/coach/client/${widget.clientId}/diet'),
              child: _dietPlan != null ? _dietPlanBody(_dietPlan!) : null,
            ),
            const SizedBox(height: 10),

            // ── Workout Plan card ─────────────────────────────
            _assignmentCard(
              icon: Icons.fitness_center,
              color: Colors.green,
              title: 'Workout Plan',
              isAssigned: _workoutPlan != null,
              assignLabel: 'Assign Workout Plan',
              modifyLabel: 'Modify Workout Plan',
              onTap: () => context.go('/coach/client/${widget.clientId}/workout'),
              child: _workoutPlan != null ? _workoutPlanBody(_workoutPlan!) : null,
            ),
            const SizedBox(height: 10),

            // ── Lifestyle Plan card ───────────────────────────
            _assignmentCard(
              icon: Icons.self_improvement,
              color: Colors.teal,
              title: 'Lifestyle Plan',
              isAssigned: _lifestylePlan != null,
              assignLabel: 'Assign Lifestyle Plan',
              modifyLabel: 'Modify Lifestyle Plan',
              onTap: () => context.go('/coach/client/${widget.clientId}/lifestyle'),
              child: _lifestylePlan != null ? _lifestylePlanBody(_lifestylePlan!) : null,
            ),
            const SizedBox(height: 10),

            // ── Tips card ─────────────────────────────────────
            _assignmentCard(
              icon: Icons.lightbulb_outline,
              color: Colors.amber,
              title: 'Coach Tips',
              isAssigned: _tips.isNotEmpty,
              assignLabel: 'Add First Tip',
              modifyLabel: 'Add / View Tips (${_tips.length})',
              onTap: () => context.go('/coach/client/${widget.clientId}/tips'),
              child: _tips.isNotEmpty ? _tipsBody() : null,
            ),
            const SizedBox(height: 14),

            // ── Health notes ──────────────────────────────────
            const SectionHeader(title: 'Health Notes'),
            const SizedBox(height: 8),
            Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _row('Conditions', c['health_conditions']),
                _row('Injuries',   c['injuries']),
                _row('Allergies',  c['allergies']),
                _row('Medications',c['medications']),
              ]),
            )),
            const SizedBox(height: 14),

            // ── Onboarding: Eating Habits ─────────────────────
            const SectionHeader(title: 'Eating Habits'),
            const SizedBox(height: 8),
            Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _row('Meals / day',    c['meals_per_day']?.toString()),
                _row('Meal timings',   c['meal_timings']),
                _row('Breakfast',      c['typical_breakfast']),
                _row('Lunch',          c['typical_lunch']),
                _row('Snacks',         c['typical_snacks']),
                _row('Dinner',         c['typical_dinner']),
                _row('Tea / Coffee',   c['tea_coffee']),
                _row('Eats out',       c['eating_out_frequency']),
                _row('Eats out pref',  c['eating_out_preference']),
              ]),
            )),
            const SizedBox(height: 14),

            // ── Onboarding: Activity ──────────────────────────
            const SectionHeader(title: 'Activity'),
            const SizedBox(height: 8),
            Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _row('Currently workouts',
                    c['currently_workout'] == null ? null
                    : (c['currently_workout'] == true ? 'Yes' : 'No')),
                _row('Workout type',   c['workout_type']),
                _row('Activity level', _cap(c['activity_level'])),
              ]),
            )),
            const SizedBox(height: 14),

            // ── Onboarding: Lifestyle Baselines ───────────────
            const SectionHeader(title: 'Lifestyle Baselines'),
            const SizedBox(height: 8),
            Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _row('Typical sleep',  c['typical_sleep_hours'] != null
                    ? '${c['typical_sleep_hours']} hrs' : null),
                _row('Daily steps',    c['typical_daily_steps']?.toString()),
                _row('Stress level',   c['typical_stress_level']),
              ]),
            )),
            const SizedBox(height: 14),

            // ── Onboarding: Family ────────────────────────────
            const SectionHeader(title: 'Family'),
            const SizedBox(height: 8),
            Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _row('Family type',    _cap(c['family_type'])),
                _row('Family members', c['family_members_count']?.toString()),
              ]),
            )),
            const SizedBox(height: 14),

            // ── Recent tracking ───────────────────────────────
            SectionHeader(
              title: 'Recent Progress',
              action: Text('${_tracking.length} entries',
                style: const TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
            ),
            const SizedBox(height: 8),
            _tracking.isEmpty
                ? Card(child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade400, size: 18),
                      const SizedBox(width: 10),
                      const Text('No tracking data yet',
                        style: TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13)),
                    ]),
                  ))
                : Column(children: _tracking.take(7).map((t) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        Text(t['date'].toString().substring(0, 10),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const Spacer(),
                        if (t['weight_kg'] != null)    _chip('${t['weight_kg']}kg', Colors.purple),
                        if (t['steps'] != null) ...[    const SizedBox(width: 5), _chip('${t['steps']} steps', Colors.green)],
                        if (t['mood'] != null) ...[     const SizedBox(width: 5), _chip(t['mood'], Colors.orange)],
                        if (t['stress_level'] != null)...[const SizedBox(width: 5), _chip('stress ${t['stress_level']}', Colors.red)],
                      ]),
                    ),
                  )).toList()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Reusable assignment card ──────────────────────────
  Widget _assignmentCard({
    required IconData icon,
    required Color color,
    required String title,
    required bool isAssigned,
    required String assignLabel,
    required String modifyLabel,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row — title + assign/modify button on same row
        InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isAssigned ? color.withValues(alpha: 0.1) : const Color(AppConstants.primaryColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isAssigned ? Icons.edit_outlined : Icons.add,
                    size: 13,
                    color: isAssigned ? color : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAssigned ? modifyLabel : assignLabel,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: isAssigned ? color : Colors.white,
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        // Content if assigned
        if (child != null) ...[
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 14), child: child),
        ],
      ]),
    );
  }

  // ── Program period row (in profile header) ───────────
  Widget _programPeriodRow() {
    final start = _programStartDate;
    final end   = _programEndDate;
    final hasDate = start != null || end != null;
    final duration = (start != null && end != null)
        ? end.difference(start).inDays : null;

    return GestureDetector(
      onTap: _showProgramDateDialog,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.calendar_month_outlined, size: 14,
          color: hasDate ? const Color(AppConstants.primaryColor) : Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(
          hasDate
              ? '${start != null ? _fmtDate(start) : '?'} → ${end != null ? _fmtDate(end) : '?'}'
                '${duration != null ? ' · $duration d' : ''}'
              : 'No program dates set',
          style: TextStyle(
            fontSize: 12,
            color: hasDate ? const Color(AppConstants.primaryColor) : Colors.grey.shade400,
            fontWeight: hasDate ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.edit_outlined, size: 13, color: Colors.grey.shade400),
      ]),
    );
  }

  void _showProgramDateDialog() {
    DateTime? start = _programStartDate;
    DateTime? end   = _programEndDate;
    bool saving     = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Program Period'),
          content: PlanDateSection(
            startDate: start,
            endDate: end,
            onStartChanged: (d) => setS(() => start = d),
            onEndChanged:   (d) => setS(() => end   = d),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setS(() => saving = true);
                try {
                  await _api.patch(
                    '/coach/client/${widget.clientId}/program-dates',
                    {
                      'program_start_date': start?.toIso8601String().substring(0, 10),
                      'program_end_date':   end?.toIso8601String().substring(0, 10),
                    },
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {
                    _programStartDate = start;
                    _programEndDate   = end;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Program dates updated'),
                        backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                }
                if (ctx.mounted) setS(() => saving = false);
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun',
                           'Jul','Aug','Sep','Oct','Nov','Dec'];
  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  // ── Diet plan body ────────────────────────────────────
  Widget _dietPlanBody(DietPlan plan) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Total row
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Text('Daily total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const Spacer(),
          _macroTag('${plan.totalCalories.toStringAsFixed(0)} kcal', Colors.orange),
          const SizedBox(width: 6),
          _macroTag('P ${plan.totalProtein.toStringAsFixed(0)}g', Colors.blue),
          const SizedBox(width: 6),
          _macroTag('C ${plan.totalCarbs.toStringAsFixed(0)}g', Colors.deepOrange),
          const SizedBox(width: 6),
          _macroTag('F ${plan.totalFat.toStringAsFixed(0)}g', Colors.green),
        ]),
      ),
      const SizedBox(height: 10),
      // Per-meal table
      Table(
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(1.8),
          2: FlexColumnWidth(1.4),
          3: FlexColumnWidth(1.4),
          4: FlexColumnWidth(1.1),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
            children: ['Meal', 'Calories', 'Protein', 'Carbs', 'Fat']
                .map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                  child: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: Color(AppConstants.textSecondary))),
                )).toList(),
          ),
          // Each meal row
          ...plan.meals.map((m) => TableRow(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            children: [
              _cell(_capSlot(m.mealSlot), bold: true),
              _cell('${m.calories.toStringAsFixed(0)} kcal', color: Colors.orange.shade700),
              _cell('${m.proteinG.toStringAsFixed(0)}g', color: Colors.blue.shade700),
              _cell('${m.carbsG.toStringAsFixed(0)}g', color: Colors.deepOrange.shade700),
              _cell('${m.fatG.toStringAsFixed(0)}g', color: Colors.green.shade700),
            ],
          )),
        ],
      ),
    ]);
  }

  // ── Workout plan body ─────────────────────────────────
  Widget _workoutPlanBody(WorkoutPlan plan) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${plan.totalDays}-day rotation plan',
        style: const TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
      const SizedBox(height: 8),
      ...plan.days.map((day) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text('${day.dayNumber}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 8),
            Text(day.dayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            Text('${day.exercises.length} exercises',
              style: const TextStyle(fontSize: 11, color: Color(AppConstants.textSecondary))),
          ]),
          if (day.exercises.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 5, runSpacing: 4,
              children: day.exercises.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text('${e.exerciseName} ${e.sets}×${e.reps}',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
              )).toList(),
            ),
          ],
        ]),
      )),
    ]);
  }

  // ── Lifestyle plan body ───────────────────────────────
  Widget _lifestylePlanBody(LifestylePlan plan) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: plan.items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.teal.shade100),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 2),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              if (item.targetValue != null && item.targetValue!.isNotEmpty)
                Text('${item.targetValue} ${item.unit ?? ''}',
                  style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
            ]),
          ]),
        );
      }).toList(),
    );
  }

  // ── Tips body ─────────────────────────────────────────
  Widget _tipsBody() {
    return Column(children: _tips.take(2).map((t) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Colors.amber.shade400, width: 3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb, color: Colors.amber, size: 14),
        const SizedBox(width: 7),
        Expanded(child: Text(t.content,
          style: const TextStyle(fontSize: 12, height: 1.4),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    )).toList());
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _stat(String emoji, String value, String label) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(AppConstants.textSecondary))),
    ]);
  }

  Widget _macroTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _cell(String text, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(text, style: TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        color: color ?? const Color(AppConstants.textPrimary),
      )),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        Expanded(child: Text(value ?? '--',
          style: TextStyle(
            fontSize: 12,
            color: value != null
                ? const Color(AppConstants.textSecondary)
                : Colors.grey.shade400,
          ))),
      ]),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }

  String _cap(dynamic s) {
    if (s == null) return '--';
    return s.toString().replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String _capSlot(String s) => s[0].toUpperCase() + s.substring(1);
}
