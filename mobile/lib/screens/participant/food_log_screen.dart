// lib/screens/participant/food_log_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../data/indian_meals_db.dart';
import '../../core/constants.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});
  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final _api         = ApiService();
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();

  List<FoodItem>      _localResults = [];
  List<FoodItem>      _apiResults   = [];
  List<MealLogEntry>  _todayLog     = [];

  bool _searchingApi  = false;
  bool _loadingLog    = false;
  bool _showResults   = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTodayLog();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Search logic ─────────────────────────────────────────────────────────

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();

    // Instant local search
    if (q.length >= 2) {
      setState(() {
        _localResults = searchLocalFoods(q, limit: 10);
        _showResults  = true;
      });
    } else {
      setState(() {
        _localResults = [];
        _apiResults   = [];
        _showResults  = q.isNotEmpty;
      });
    }

    // Debounced backend/FatSecret search
    _debounce?.cancel();
    if (q.length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 500), () => _searchApi(q));
    }
  }

  Future<void> _searchApi(String q) async {
    if (!mounted) return;
    setState(() => _searchingApi = true);
    try {
      final res = await _api.get('/food/search?q=${Uri.encodeQueryComponent(q)}');
      if (!mounted) return;
      final list = (res['foods'] as List? ?? []).map((f) => FoodItem.fromJson(f)).toList();
      // Filter out items already in local results
      final localIds = _localResults.map((f) => f.id).toSet();
      setState(() => _apiResults = list.where((f) => !localIds.contains(f.id)).toList());
    } catch (_) {}
    if (mounted) setState(() => _searchingApi = false);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _localResults = [];
      _apiResults   = [];
      _showResults  = false;
    });
    _searchFocus.unfocus();
  }

  // ── Today's log ───────────────────────────────────────────────────────────

  Future<void> _loadTodayLog() async {
    setState(() => _loadingLog = true);
    try {
      final res = await _api.get('/food/log');
      if (!mounted) return;
      setState(() =>
        _todayLog = (res['logs'] as List? ?? [])
            .map((e) => MealLogEntry.fromJson(e))
            .toList()
      );
    } catch (_) {}
    if (mounted) setState(() => _loadingLog = false);
  }

  Future<void> _deleteLogEntry(int id) async {
    try {
      await _api.delete('/food/log/$id');
      setState(() => _todayLog.removeWhere((e) => e.id == id));
    } catch (_) {}
  }

  // ── Add to log ────────────────────────────────────────────────────────────

  Future<void> _addToLog(FoodItem food, ServingSize serving) async {
    final n = food.nutrientsFor(serving.grams);
    try {
      final res = await _api.post('/food/log', {
        'food_id':       food.id,
        'food_name':     food.name,
        'food_name_hi':  food.nameHi,
        'serving_label': serving.label,
        'serving_grams': serving.grams,
        'calories':      n['calories']!.round(),
        'protein_g':     double.parse(n['protein_g']!.toStringAsFixed(1)),
        'carbs_g':       double.parse(n['carbs_g']!.toStringAsFixed(1)),
        'fat_g':         double.parse(n['fat_g']!.toStringAsFixed(1)),
        'fiber_g':       double.parse(n['fiber_g']!.toStringAsFixed(1)),
      });
      if (res['success'] == true) {
        await _loadTodayLog();
        if (mounted) {
          _clearSearch();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${food.name} added to today\'s log'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add meal. Please try again.')),
        );
      }
    }
  }

  // ── Custom food dialog ────────────────────────────────────────────────────

  void _showAddCustomFood() {
    final nameCtrl    = TextEditingController(text: _searchCtrl.text.trim());
    final nameHiCtrl  = TextEditingController();
    final calCtrl     = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl   = TextEditingController();
    final fatCtrl     = TextEditingController();
    final fiberCtrl   = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Add Custom Food',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Values per 100g',
                  style: TextStyle(fontSize: 13,
                    color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.55))),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Food Name (English) *',
                    hintText: 'e.g. Pav Bhaji',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameHiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hindi Name (optional)',
                    hintText: 'e.g. पाव भाजी',
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _numField(calCtrl,     'Calories * (kcal)')),
                  const SizedBox(width: 10),
                  Expanded(child: _numField(proteinCtrl, 'Protein (g)')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _numField(carbsCtrl,  'Carbs (g)')),
                  const SizedBox(width: 10),
                  Expanded(child: _numField(fatCtrl,    'Fat (g)')),
                ]),
                const SizedBox(height: 10),
                _numField(fiberCtrl, 'Fiber (g) — optional'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final cal  = double.tryParse(calCtrl.text.trim());
                      if (name.isEmpty || cal == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name and calories are required')));
                        return;
                      }
                      final custom = FoodItem(
                        id:               'custom_${name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
                        name:             name,
                        nameHi:           nameHiCtrl.text.trim(),
                        caloriesPer100g:  cal,
                        proteinG:         double.tryParse(proteinCtrl.text.trim()) ?? 0,
                        carbsG:           double.tryParse(carbsCtrl.text.trim())   ?? 0,
                        fatG:             double.tryParse(fatCtrl.text.trim())     ?? 0,
                        fiberG:           double.tryParse(fiberCtrl.text.trim())   ?? 0,
                        servings: const [
                          ServingSize(label: '100g',                  grams: 100),
                          ServingSize(label: '1 serving (150g)',       grams: 150),
                          ServingSize(label: '1 bowl / 1 कटोरा (200g)', grams: 200),
                        ],
                        source: 'custom',
                      );
                      Navigator.pop(ctx);
                      _showFoodDetail(custom);
                    },
                    child: const Text('Next: Choose Serving'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  // ── Food detail bottom sheet ──────────────────────────────────────────────

  void _showFoodDetail(FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FoodDetailSheet(
        food: food,
        onAdd: (serving) {
          Navigator.pop(ctx);
          _addToLog(food, serving);
        },
      ),
    );
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  Map<String, double> get _totals {
    if (_todayLog.isEmpty) return {'cal': 0, 'p': 0, 'c': 0, 'f': 0, 'fb': 0};
    return {
      'cal': _todayLog.fold(0, (s, e) => s + e.calories),
      'p':   _todayLog.fold(0, (s, e) => s + e.proteinG),
      'c':   _todayLog.fold(0, (s, e) => s + e.carbsG),
      'f':   _todayLog.fold(0, (s, e) => s + e.fatG),
      'fb':  _todayLog.fold(0, (s, e) => s + e.fiberG),
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
      ),
      body: Column(
        children: [
          _searchBar(),
          Expanded(
            child: _showResults ? _searchResults() : _logBody(),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:  _searchCtrl,
              focusNode:   _searchFocus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search foods… (e.g. dal, roti, chicken)',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search results ────────────────────────────────────────────────────────

  Widget _searchResults() {
    final all = [..._localResults, ..._apiResults];

    return Column(
      children: [
        if (_searchingApi)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              if (all.isEmpty && !_searchingApi) ...[
                const SizedBox(height: 40),
                Icon(Icons.search_off, size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Center(
                  child: Text('No results for "${_searchCtrl.text}"',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                ),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _showAddCustomFood,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Custom Food'),
                  ),
                ),
              ],

              if (_localResults.isNotEmpty) ...[
                _sectionLabel('From Indian Foods Database'),
                ..._localResults.map(_foodTile),
              ],

              if (_apiResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionLabel('From Online Database'),
                ..._apiResults.map(_foodTile),
              ],

              if (all.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _showAddCustomFood,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Custom Food'),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
      child: Text(text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.5,
        )),
    );
  }

  Widget _foodTile(FoodItem food) {
    final isLocal = food.source == 'local';
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => _showFoodDetail(food),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_outlined,
                  color: Color(AppConstants.primaryColor), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (food.nameHi.isNotEmpty)
                      Text(food.nameHi,
                        style: TextStyle(fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${food.caloriesPer100g.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('per 100g',
                    style: TextStyle(fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                  if (!isLocal)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Online',
                        style: TextStyle(fontSize: 9, color: Colors.blue)),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ── Log body (shown when not searching) ───────────────────────────────────

  Widget _logBody() {
    return RefreshIndicator(
      onRefresh: _loadTodayLog,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _calorieSummary(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s Log',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _searchFocus.requestFocus(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Food'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingLog)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else if (_todayLog.isEmpty)
            _emptyLog()
          else
            ..._todayLog.map(_logEntryTile),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _calorieSummary() {
    final t = _totals;
    final cal = t['cal']!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_fire_department_outlined,
                    color: Color(AppConstants.primaryColor), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${cal.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('consumed today',
                      style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
                  ],
                ),
              ],
            ),
            if (cal > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _macroChip('Protein', t['p']!, 'g', Colors.blue),
                  _macroChip('Carbs',   t['c']!, 'g', Colors.orange),
                  _macroChip('Fat',     t['f']!, 'g', Colors.red),
                  _macroChip('Fiber',   t['fb']!, 'g', Colors.green),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text('${value.toStringAsFixed(1)}$unit',
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        Text(label,
          style: const TextStyle(fontSize: 11, color: Color(AppConstants.textSecondary))),
      ],
    );
  }

  Widget _emptyLog() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.restaurant_outlined, size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            const Text('No meals logged today',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Search for a food above to add it',
              style: TextStyle(fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
          ],
        ),
      ),
    );
  }

  Widget _logEntryTile(MealLogEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant, color: Colors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.foodName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(entry.servingLabel,
                    style: TextStyle(fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 3),
                  Text(
                    'P: ${entry.proteinG.toStringAsFixed(1)}g  '
                    'C: ${entry.carbsG.toStringAsFixed(1)}g  '
                    'F: ${entry.fatG.toStringAsFixed(1)}g',
                    style: TextStyle(fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDelete(entry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(MealLogEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove meal?'),
        content: Text('Remove "${entry.foodName}" from today\'s log?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); _deleteLogEntry(entry.id); },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Food detail bottom sheet ──────────────────────────────────────────────────

class _FoodDetailSheet extends StatefulWidget {
  final FoodItem food;
  final void Function(ServingSize) onAdd;
  const _FoodDetailSheet({required this.food, required this.onAdd});

  @override
  State<_FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<_FoodDetailSheet> {
  int _servingIdx = 0;
  bool _adding    = false;

  ServingSize get _serving =>
      widget.food.servings.isNotEmpty
          ? widget.food.servings[_servingIdx]
          : const ServingSize(label: '100g', grams: 100);

  Map<String, double> get _nutrients => widget.food.nutrientsFor(_serving.grams);

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final n    = _nutrients;
    final cal  = n['calories']!;
    const primary = Color(AppConstants.primaryColor);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Food name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (food.nameHi.isNotEmpty)
                        Text(food.nameHi,
                          style: TextStyle(fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Text('${food.caloriesPer100g.toStringAsFixed(0)} kcal per 100g',
                        style: TextStyle(fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Serving size selector
            const Text('Serving Size',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<int>(
                value: _servingIdx,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: food.servings.asMap().entries.map((e) =>
                  DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value.label, style: const TextStyle(fontSize: 14)),
                  )
                ).toList(),
                onChanged: (i) => setState(() => _servingIdx = i!),
              ),
            ),
            const SizedBox(height: 20),

            // Calorie banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary.withValues(alpha: 0.85), primary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(cal.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    )),
                  const Text('calories',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Macro row
            Row(
              children: [
                _macroCard('Protein',  n['protein_g']!, 'g', Colors.blue),
                const SizedBox(width: 8),
                _macroCard('Carbs',    n['carbs_g']!,   'g', Colors.orange),
                const SizedBox(width: 8),
                _macroCard('Fat',      n['fat_g']!,     'g', Colors.red),
                const SizedBox(width: 8),
                _macroCard('Fiber',    n['fiber_g']!,   'g', Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            // Add button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _adding ? null : () {
                  setState(() => _adding = true);
                  widget.onAdd(_serving);
                },
                icon: _adding
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_circle_outline),
                label: Text(_adding ? 'Adding…' : 'Add to Today\'s Log',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroCard(String label, double value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('${value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Text(label,
              style: TextStyle(fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }
}
