// lib/screens/coach/assign_diet_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class AssignDietScreen extends StatefulWidget {
  final int clientId;
  const AssignDietScreen({super.key, required this.clientId});

  @override
  State<AssignDietScreen> createState() => _AssignDietScreenState();
}

class _AssignDietScreenState extends State<AssignDietScreen> {
  final _api      = ApiService();
  final _nameCtrl = TextEditingController(text: 'Nutrition Plan');
  bool _saving    = false;
  String? _error;

  // Per slot macros
  final Map<String, Map<String, TextEditingController>> _slots = {};

  @override
  void initState() {
    super.initState();
    for (final slot in AppConstants.mealSlots) {
      _slots[slot] = {
        'calories': TextEditingController(),
        'protein':  TextEditingController(),
        'carbs':    TextEditingController(),
        'fat':      TextEditingController(),
      };
    }
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final res = await _api.get('/diet/get?user_id=${widget.clientId}');
      if (res['diet_plan'] != null) {
        final plan = res['diet_plan'];
        _nameCtrl.text = plan['plan_name'] ?? 'Nutrition Plan';
        for (final meal in (plan['meals'] as List? ?? [])) {
          final slot = meal['meal_slot'];
          if (_slots.containsKey(slot)) {
            _slots[slot]!['calories']!.text = meal['calories'].toString();
            _slots[slot]!['protein']!.text  = meal['protein_g'].toString();
            _slots[slot]!['carbs']!.text    = meal['carbs_g'].toString();
            _slots[slot]!['fat']!.text      = meal['fat_g'].toString();
          }
        }
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final s in _slots.values) for (final c in s.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final meals = <Map<String, dynamic>>[];
      for (final slot in AppConstants.mealSlots) {
        final cals = double.tryParse(_slots[slot]!['calories']!.text);
        if (cals != null && cals > 0) {
          meals.add({
            'meal_slot': slot,
            'calories':  cals,
            'protein_g': double.tryParse(_slots[slot]!['protein']!.text) ?? 0,
            'carbs_g':   double.tryParse(_slots[slot]!['carbs']!.text)   ?? 0,
            'fat_g':     double.tryParse(_slots[slot]!['fat']!.text)     ?? 0,
          });
        }
      }

      if (meals.isEmpty) {
        setState(() { _error = 'Add at least one meal slot'; _saving = false; });
        return;
      }

      await _api.post('/diet/assign', {
        'participant_id': widget.clientId,
        'plan_name':      _nameCtrl.text.trim(),
        'meals':          meals,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Diet plan assigned!'), backgroundColor: Colors.green));
        context.go('/coach/client/${widget.clientId}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Diet Plan'),
        leading: BackButton(onPressed: () => context.go('/coach/client/${widget.clientId}')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ErrorMessage(message: _error!),

          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Plan Name',
              prefixIcon: Icon(Icons.restaurant_menu),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter macro targets for each meal slot. Leave empty to skip a slot.',
            style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary)),
          ),
          const SizedBox(height: 16),

          ...AppConstants.mealSlots.map((slot) => _slotCard(slot)),
          const SizedBox(height: 8),

          // Total
          _totalsCard(),
          const SizedBox(height: 20),

          LoadingButton(text: 'Assign Plan to Client', loading: _saving, onPressed: _save),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _slotCard(String slot) {
    final icons = {
      'breakfast': (Icons.wb_sunny_outlined, Colors.orange),
      'lunch':     (Icons.restaurant, Colors.blue),
      'snack':     (Icons.apple, Colors.green),
      'dinner':    (Icons.nights_stay_outlined, Colors.indigo),
    };
    final (icon, color) = icons[slot]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(slot[0].toUpperCase() + slot.substring(1),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _macroField(_slots[slot]!['calories']!, 'Calories', 'kcal', color)),
                const SizedBox(width: 8),
                Expanded(child: _macroField(_slots[slot]!['protein']!, 'Protein', 'g', Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _macroField(_slots[slot]!['carbs']!, 'Carbs', 'g', Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _macroField(_slots[slot]!['fat']!, 'Fat', 'g', Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroField(TextEditingController ctrl, String label, String suffix, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        suffixStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _totalsCard() {
    double totalCals = 0, totalP = 0, totalC = 0, totalF = 0;
    for (final slot in AppConstants.mealSlots) {
      totalCals += double.tryParse(_slots[slot]!['calories']!.text) ?? 0;
      totalP    += double.tryParse(_slots[slot]!['protein']!.text) ?? 0;
      totalC    += double.tryParse(_slots[slot]!['carbs']!.text) ?? 0;
      totalF    += double.tryParse(_slots[slot]!['fat']!.text) ?? 0;
    }
    if (totalCals == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(AppConstants.primaryColor).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(AppConstants.primaryColor).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Totals', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MacroChip(label: 'Calories', value: '${totalCals.toStringAsFixed(0)} kcal',
                  color: const Color(AppConstants.primaryColor)),
              MacroChip(label: 'Protein', value: '${totalP.toStringAsFixed(0)}g', color: Colors.blue),
              MacroChip(label: 'Carbs',   value: '${totalC.toStringAsFixed(0)}g', color: Colors.orange),
              MacroChip(label: 'Fat',     value: '${totalF.toStringAsFixed(0)}g', color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}
