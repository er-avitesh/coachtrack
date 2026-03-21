// lib/screens/participant/my_meals_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class MyMealsScreen extends StatefulWidget {
  const MyMealsScreen({super.key});
  @override
  State<MyMealsScreen> createState() => _MyMealsScreenState();
}

class _MyMealsScreenState extends State<MyMealsScreen> {
  final _api = ApiService();
  List<Meal> _meals  = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/meals/list');
      setState(() => _meals = (res['meals'] as List).map((m) => Meal.fromJson(m)).toList());
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    try {
      await _api.delete('/meals/$id');
      setState(() => _meals.removeWhere((m) => m.id == id));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showAddDialog() {
    final nameCtrl     = TextEditingController();
    final calCtrl      = TextEditingController();
    final proteinCtrl  = TextEditingController();
    final carbsCtrl    = TextEditingController();
    final fatCtrl      = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AlertDialog(
          title: const Text('Add Custom Meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter values per 100g',
                  style: TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Meal Name *', hintText: 'e.g. Paneer Poha'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _sheetField(calCtrl,     'Calories *',  'kcal')),
                  const SizedBox(width: 10),
                  Expanded(child: _sheetField(proteinCtrl, 'Protein',     'g')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _sheetField(carbsCtrl, 'Carbs', 'g')),
                  const SizedBox(width: 10),
                  Expanded(child: _sheetField(fatCtrl,   'Fat',   'g')),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            LoadingButton(
              text: 'Save Meal',
              loading: saving,
              onPressed: () async {
                if (nameCtrl.text.isEmpty || calCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and calories are required')));
                  return;
                }
                setSheetState(() => saving = true);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _api.post('/meals/create', {
                    'meal_name':          nameCtrl.text.trim(),
                    'calories_per_100g':  double.tryParse(calCtrl.text) ?? 0,
                    'protein_per_100g':   double.tryParse(proteinCtrl.text) ?? 0,
                    'carbs_per_100g':     double.tryParse(carbsCtrl.text) ?? 0,
                    'fat_per_100g':       double.tryParse(fatCtrl.text) ?? 0,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                }
                setSheetState(() => saving = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meals'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Meal Calculator',
            onPressed: () => context.go('/meals/calculator'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _meals.isEmpty
              ? const EmptyState(
                  icon: Icons.restaurant_menu,
                  message: 'No meals added yet',
                  subtitle: 'Tap + to add your first custom meal\nwith nutritional info per 100g',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _meals.length,
                  itemBuilder: (_, i) {
                    final m = _meals[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.restaurant,
                              color: Color(AppConstants.primaryColor), size: 22),
                        ),
                        title: Text(m.mealName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${m.caloriesPer100g.toStringAsFixed(0)} kcal  •  '
                            'P: ${m.proteinPer100g.toStringAsFixed(0)}g  •  '
                            'C: ${m.carbsPer100g.toStringAsFixed(0)}g  •  '
                            'F: ${m.fatPer100g.toStringAsFixed(0)}g  (per 100g)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(m),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmDelete(Meal m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Meal?'),
        content: Text('Remove "${m.mealName}" from your library?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); _delete(m.id); },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, String suffix) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}
