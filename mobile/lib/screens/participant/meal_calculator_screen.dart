// lib/screens/participant/meal_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class MealCalculatorScreen extends StatefulWidget {
  const MealCalculatorScreen({super.key});

  @override
  State<MealCalculatorScreen> createState() => _MealCalculatorScreenState();
}

class _MealCalculatorScreenState extends State<MealCalculatorScreen> {
  final _api            = ApiService();
  final _caloriesCtrl   = TextEditingController();

  List<Meal>  _meals         = [];
  DietPlan?   _dietPlan;
  Meal?       _selectedMeal;
  Map<String, dynamic>? _result;
  bool  _loading = true;
  bool  _calculating = false;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.get('/meals/list'),
        _api.get('/diet/get'),
      ]);
      setState(() {
        _meals    = (results[0]['meals'] as List).map((m) => Meal.fromJson(m)).toList();
        _dietPlan = results[1]['diet_plan'] != null
            ? DietPlan.fromJson(results[1]['diet_plan']) : null;
        _loading  = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _selectSlot(DietPlanMeal slot) {
    setState(() {
      _selectedSlot   = slot.mealSlot;
      _caloriesCtrl.text = slot.calories.toStringAsFixed(0);
      _result = null;
    });
  }

  Future<void> _calculate() async {
    if (_selectedMeal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meal first')),
      );
      return;
    }
    final target = double.tryParse(_caloriesCtrl.text);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid calorie target')),
      );
      return;
    }

    setState(() => _calculating = true);
    try {
      final res = await _api.post('/meals/calculate', {
        'meal_id':         _selectedMeal!.id,
        'target_calories': target,
      });
      setState(() => _result = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
    setState(() => _calculating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Calculator'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/meals'),
            icon: const Icon(Icons.add),
            label: const Text('Add Meal'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // How to use
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select your target calories, then pick a meal to see exactly how many grams to eat.',
                          style: TextStyle(fontSize: 13, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Step 1: Calorie Target (with quick-select from plan)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Step 1: Calorie Target',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _caloriesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Target Calories',
                            hintText: 'e.g. 400',
                            suffixText: 'kcal',
                          ),
                          onChanged: (_) => setState(() => _result = null),
                        ),
                        if (_dietPlan != null) ...[
                          const SizedBox(height: 14),
                          const Text('Or pick from your plan:',
                            style: TextStyle(fontSize: 13, color: Color(AppConstants.textSecondary))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: _dietPlan!.meals.map((m) {
                              final selected = _selectedSlot == m.mealSlot;
                              return GestureDetector(
                                onTap: () => _selectSlot(m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(AppConstants.primaryColor)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${m.mealSlot[0].toUpperCase()}${m.mealSlot.substring(1)} • ${m.calories.toStringAsFixed(0)} kcal',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: selected ? Colors.white : const Color(AppConstants.textPrimary),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Step 2: Select Meal
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Step 2: Select Your Meal',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 12),
                        if (_meals.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No meals yet. Add meals from My Meals.',
                                style: TextStyle(color: Color(AppConstants.textSecondary))),
                            ),
                          )
                        else
                          ..._meals.map((meal) {
                            final selected = _selectedMeal?.id == meal.id;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedMeal = meal;
                                _result = null;
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(AppConstants.primaryColor).withOpacity(0.08)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(AppConstants.primaryColor)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (selected)
                                      const Icon(Icons.check_circle,
                                          color: Color(AppConstants.primaryColor), size: 18)
                                    else
                                      const Icon(Icons.radio_button_unchecked,
                                          color: Colors.grey, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(meal.mealName,
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(
                                            '${meal.caloriesPer100g.toStringAsFixed(0)} kcal • '
                                            'P: ${meal.proteinPer100g.toStringAsFixed(0)}g • '
                                            'C: ${meal.carbsPer100g.toStringAsFixed(0)}g • '
                                            'F: ${meal.fatPer100g.toStringAsFixed(0)}g'
                                            ' (per 100g)',
                                            style: const TextStyle(
                                                fontSize: 12, color: Color(AppConstants.textSecondary)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                LoadingButton(
                  text: 'Calculate Quantity',
                  loading: _calculating,
                  onPressed: _calculate,
                ),

                // Result
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _resultCard(),
                ],
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _resultCard() {
    final n = _result!['nutrition'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(AppConstants.primaryColor).withOpacity(0.9),
            const Color(AppConstants.primaryColor),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(_result!['meal_name'],
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Recommended Serving',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${n['grams_needed']}g',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _resultMacro('Calories', '${n['calories']} kcal'),
              _resultMacro('Protein',  '${n['protein_g']}g'),
              _resultMacro('Carbs',    '${n['carbs_g']}g'),
              _resultMacro('Fat',      '${n['fat_g']}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultMacro(String label, String value) {
    return Column(
      children: [
        Text(value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
