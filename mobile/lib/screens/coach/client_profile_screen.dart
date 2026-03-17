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
  Map<String, dynamic>? _summary;
  DietPlan?    _dietPlan;
  WorkoutPlan? _workoutPlan;
  List<Tip>    _tips = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load all data in parallel
      final results = await Future.wait([
        _api.get('/coach/client/${widget.clientId}/summary'),
        _api.get('/diet/get?user_id=${widget.clientId}'),
        _api.get('/workout/get?user_id=${widget.clientId}'),
        _api.get('/tips/get?user_id=${widget.clientId}'),
      ]);

      setState(() {
        _summary     = results[0];
        _dietPlan    = results[1]['diet_plan'] != null
            ? DietPlan.fromJson(results[1]['diet_plan']) : null;
        _workoutPlan = results[2]['workout_plan'] != null
            ? WorkoutPlan.fromJson(results[2]['workout_plan']) : null;
        _tips        = (results[3]['tips'] as List? ?? [])
            .map((t) => Tip.fromJson(t)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final client  = _summary?['client'] ?? {};
    final tracking = List<Map<String, dynamic>>.from(_summary?['tracking'] ?? []);
    final photos   = List<Map<String, dynamic>>.from(_summary?['photos'] ?? []);
    final name     = client['full_name'] ?? 'Client';
    final initials = name.split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: BackButton(onPressed: () => context.go('/coach')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Header card ───────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(AppConstants.primaryColor).withOpacity(0.1),
                      child: Text(initials,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                            color: Color(AppConstants.primaryColor))),
                    ),
                    const SizedBox(height: 10),
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('@${client['username'] ?? ''}',
                      style: const TextStyle(color: Color(AppConstants.textSecondary))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoChip('⚖️', '${client['current_weight_kg'] ?? '--'} kg', 'Current'),
                        _infoChip('🎯', '${client['goal_weight_kg'] ?? '--'} kg', 'Goal'),
                        _infoChip('🏃', _capitalize(client['activity_level']), 'Activity'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Assignment status row ─────────────────────────
            Row(
              children: [
                _statusBadge(
                  label: 'Diet',
                  icon: Icons.restaurant_menu,
                  assigned: _dietPlan != null,
                  detail: _dietPlan != null
                      ? '${_dietPlan!.totalCalories.toStringAsFixed(0)} kcal/day'
                      : 'Not assigned',
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _statusBadge(
                  label: 'Workout',
                  icon: Icons.fitness_center,
                  assigned: _workoutPlan != null,
                  detail: _workoutPlan != null
                      ? '${_workoutPlan!.exercises.length} exercises'
                      : 'Not assigned',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _statusBadge(
                  label: 'Tips',
                  icon: Icons.lightbulb_outline,
                  assigned: _tips.isNotEmpty,
                  detail: _tips.isNotEmpty
                      ? '${_tips.length} tip${_tips.length != 1 ? 's' : ''}'
                      : 'None yet',
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Action Buttons ────────────────────────────────
            Row(children: [
              Expanded(child: _actionBtn(
                _dietPlan != null ? 'Edit Diet' : 'Assign Diet',
                Icons.restaurant_menu,
                Colors.orange,
                () => context.go('/coach/client/${widget.clientId}/diet'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn(
                _workoutPlan != null ? 'Edit Workout' : 'Assign Workout',
                Icons.fitness_center,
                Colors.green,
                () => context.go('/coach/client/${widget.clientId}/workout'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn(
                'Tips',
                Icons.lightbulb_outline,
                Colors.amber,
                () => context.go('/coach/client/${widget.clientId}/tips'),
              )),
            ]),
            const SizedBox(height: 14),

            // ── Diet Plan Summary ─────────────────────────────
            if (_dietPlan != null) ...[
              SectionHeader(
                title: 'Diet Plan',
                action: TextButton(
                  onPressed: () => context.go('/coach/client/${widget.clientId}/diet'),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Text(_dietPlan!.planName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const Spacer(),
                          Text('${_dietPlan!.totalCalories.toStringAsFixed(0)} kcal/day',
                            style: const TextStyle(
                                color: Color(AppConstants.primaryColor),
                                fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          MacroChip(label: 'Protein',
                              value: '${_dietPlan!.totalProtein.toStringAsFixed(0)}g',
                              color: Colors.blue),
                          MacroChip(label: 'Carbs',
                              value: '${_dietPlan!.totalCarbs.toStringAsFixed(0)}g',
                              color: Colors.orange),
                          MacroChip(label: 'Fat',
                              value: '${_dietPlan!.totalFat.toStringAsFixed(0)}g',
                              color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._dietPlan!.meals.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(
                              m.mealSlot[0].toUpperCase() + m.mealSlot.substring(1),
                              style: const TextStyle(fontSize: 13,
                                  color: Color(AppConstants.textSecondary)),
                            ),
                            const Spacer(),
                            Text('${m.calories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Text('P:${m.proteinG.toStringAsFixed(0)} '
                                'C:${m.carbsG.toStringAsFixed(0)} '
                                'F:${m.fatG.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(AppConstants.textSecondary))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Workout Plan Summary ──────────────────────────
            if (_workoutPlan != null) ...[
              SectionHeader(
                title: 'Workout Plan',
                action: TextButton(
                  onPressed: () => context.go('/coach/client/${widget.clientId}/workout'),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(_workoutPlan!.planName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const Spacer(),
                          Text('${_workoutPlan!.exercises.length} exercises',
                            style: const TextStyle(
                                color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._workoutPlan!.exercises.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(e.muscleGroup,
                                style: const TextStyle(fontSize: 10, color: Colors.green)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(e.exerciseName,
                                style: const TextStyle(fontSize: 13)),
                            ),
                            Text('${e.sets}×${e.reps}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(AppConstants.textSecondary))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Tips Summary ──────────────────────────────────
            if (_tips.isNotEmpty) ...[
              SectionHeader(
                title: 'Coach Tips',
                action: TextButton(
                  onPressed: () => context.go('/coach/client/${widget.clientId}/tips'),
                  child: const Text('Add more'),
                ),
              ),
              const SizedBox(height: 8),
              ..._tips.take(3).map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.content,
                        style: const TextStyle(fontSize: 13, height: 1.4))),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 14),
            ],

            // ── Health Notes ──────────────────────────────────
            if (client['health_conditions'] != null ||
                client['injuries'] != null ||
                client['allergies'] != null) ...[
              const SectionHeader(title: 'Health Notes'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      if (client['diet_preference'] != null)
                        _labelValue('Diet', _capitalize(client['diet_preference'])),
                      if (client['health_conditions'] != null)
                        _labelValue('Health', client['health_conditions']),
                      if (client['injuries'] != null)
                        _labelValue('Injuries', client['injuries']),
                      if (client['allergies'] != null)
                        _labelValue('Allergies', client['allergies']),
                      if (client['medications'] != null)
                        _labelValue('Medications', client['medications']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Body Photos ───────────────────────────────────
            if (photos.isNotEmpty) ...[
              const SectionHeader(title: 'Body Photos'),
              const SizedBox(height: 8),
              Row(
                children: photos.map((p) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(p['s3_url'],
                            height: 110, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 110, color: Colors.grey.shade100,
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey))),
                        ),
                        const SizedBox(height: 4),
                        Text(_capitalize(p['photo_type']),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // ── Recent Tracking ───────────────────────────────
            if (tracking.isNotEmpty) ...[
              SectionHeader(
                title: 'Recent Progress',
                action: Text('${tracking.length} entries',
                  style: const TextStyle(
                      color: Color(AppConstants.textSecondary), fontSize: 13)),
              ),
              const SizedBox(height: 8),
              ...tracking.take(7).map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(t['date'].toString().substring(0, 10),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      if (t['weight_kg'] != null)
                        _trackChip('${t['weight_kg']}kg', Colors.purple),
                      if (t['steps'] != null) ...[
                        const SizedBox(width: 6),
                        _trackChip('${t['steps']} steps', Colors.green),
                      ],
                      if (t['mood'] != null) ...[
                        const SizedBox(width: 6),
                        _trackChip(t['mood'], Colors.orange),
                      ],
                    ],
                  ),
                ),
              )),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade400),
                      const SizedBox(width: 10),
                      const Text('No tracking data yet — client hasn\'t logged',
                        style: TextStyle(
                            color: Color(AppConstants.textSecondary), fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge({
    required String label, required IconData icon, required bool assigned,
    required String detail, required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: assigned ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: assigned ? color.withOpacity(0.3) : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: assigned ? color : Colors.grey.shade400, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: assigned ? color : Colors.grey)),
            const SizedBox(height: 2),
            Text(detail, style: TextStyle(fontSize: 10,
                color: assigned ? color.withOpacity(0.8) : Colors.grey.shade400),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: assigned ? color.withOpacity(0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(assigned ? 'Assigned' : 'Pending',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                    color: assigned ? color : Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(AppConstants.textSecondary))),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: Text(value,
            style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13))),
        ],
      ),
    );
  }

  Widget _trackChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  String _capitalize(dynamic s) {
    if (s == null) return '--';
    return s.toString().replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}