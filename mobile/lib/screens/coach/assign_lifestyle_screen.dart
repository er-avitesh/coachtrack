// lib/screens/coach/assign_lifestyle_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class _CustomItem {
  String title;
  String value;
  String unit;
  _CustomItem({required this.title, this.value = '', this.unit = ''});
}

class AssignLifestyleScreen extends StatefulWidget {
  final int clientId;
  const AssignLifestyleScreen({super.key, required this.clientId});
  @override
  State<AssignLifestyleScreen> createState() => _AssignLifestyleScreenState();
}

class _AssignLifestyleScreenState extends State<AssignLifestyleScreen> {
  final _api      = ApiService();
  final _nameCtrl = TextEditingController(text: 'Lifestyle Plan');
  bool _saving    = false;
  String? _error;

  // Standard category selections: key → value controller
  final Map<String, TextEditingController> _selected = {};

  // Dynamic custom items
  final List<_CustomItem> _customItems = [];

  @override
  void initState() {
    super.initState();
    _loadExisting();
    // Pre-select common habits
    for (final cat in ['steps', 'water', 'sleep']) {
      final c = lifestyleCategories.firstWhere((c) => c['key'] == cat);
      _selected[cat] = TextEditingController(text: c['default']?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _selected.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final res = await _api.get('/lifestyle/get?user_id=${widget.clientId}');
      if (res['lifestyle_plan'] != null) {
        final plan = LifestylePlan.fromJson(res['lifestyle_plan']);
        _nameCtrl.text = plan.planName;
        setState(() {
          for (final c in _selected.values) { c.dispose(); }
          _selected.clear();
          _customItems.clear();
          for (final item in plan.items) {
            if (item.category == 'custom') {
              _customItems.add(_CustomItem(
                title: item.title,
                value: item.targetValue ?? '',
                unit:  item.unit ?? '',
              ));
            } else {
              _selected[item.category] =
                  TextEditingController(text: item.targetValue ?? '');
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_selected.isEmpty && _customItems.isEmpty) {
      setState(() => _error = 'Select at least one lifestyle item');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final items = <Map<String, dynamic>>[];

      // Standard items
      for (final entry in _selected.entries) {
        final cat = lifestyleCategories.firstWhere(
          (c) => c['key'] == entry.key,
          orElse: () => {'key': entry.key, 'label': entry.key, 'unit': null},
        );
        items.add({
          'category':     entry.key,
          'title':        cat['label'],
          'target_value': entry.value.text.isNotEmpty ? entry.value.text : null,
          'unit':         cat['unit'],
        });
      }

      // Custom items
      for (final custom in _customItems) {
        items.add({
          'category':     'custom',
          'title':        custom.title,
          'target_value': custom.value.isNotEmpty ? custom.value : null,
          'unit':         custom.unit.isNotEmpty  ? custom.unit  : null,
        });
      }

      await _api.post('/lifestyle/assign', {
        'participant_id': widget.clientId,
        'plan_name':      _nameCtrl.text.trim(),
        'items':          items,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lifestyle plan assigned!'),
            backgroundColor: Colors.green));
        context.go('/coach/client/${widget.clientId}');
      }
    } catch (e) { setState(() => _error = e.toString()); }
    setState(() => _saving = false);
  }

  void _showAddCustomDialog({_CustomItem? existing, int? index}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final valueCtrl = TextEditingController(text: existing?.value ?? '');
    final unitCtrl  = TextEditingController(text: existing?.unit  ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Custom Habit' : 'Edit Custom Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Habit name *',
                hintText: 'e.g. Morning walk, Cold shower',
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(
                controller: valueCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target value',
                  hintText: 'e.g. 30',
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'e.g. mins, times/week',
                ),
              )),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              setState(() {
                if (existing != null && index != null) {
                  _customItems[index] = _CustomItem(
                    title: title,
                    value: valueCtrl.text.trim(),
                    unit:  unitCtrl.text.trim(),
                  );
                } else {
                  _customItems.add(_CustomItem(
                    title: title,
                    value: valueCtrl.text.trim(),
                    unit:  unitCtrl.text.trim(),
                  ));
                }
              });
              Navigator.pop(context);
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    ).then((_) {
      titleCtrl.dispose();
      valueCtrl.dispose();
      unitCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Standard categories (exclude 'custom' — handled separately)
    final standardCats = lifestyleCategories.where((c) => c['key'] != 'custom').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lifestyle Plan'),
        leading: BackButton(onPressed: () => context.go('/coach/client/${widget.clientId}')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ErrorMessage(message: _error!),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Plan name'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select habits and set targets. Tap a habit to toggle, then edit its target.',
            style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary)),
          ),
          const SizedBox(height: 16),

          // ── Standard habit cards ──────────────────────────
          ...standardCats.map((cat) {
            final key        = cat['key'] as String;
            final label      = cat['label'] as String;
            final unit       = cat['unit'] as String?;
            final isSelected = _selected.containsKey(key);

            // Icon per category key
            const catIcons = <String, IconData>{
              'steps':       Icons.directions_walk,
              'water':       Icons.water_drop_outlined,
              'sleep':       Icons.bedtime_outlined,
              'screen_time': Icons.phone_android_outlined,
              'meditation':  Icons.self_improvement,
              'sunlight':    Icons.wb_sunny_outlined,
              'no_sugar':    Icons.no_food_outlined,
              'no_alcohol':  Icons.local_bar_outlined,
              'meal_timing': Icons.schedule,
            };
            final catIcon = catIcons[key] ?? Icons.check_circle_outline;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: isSelected
                  ? const Color(AppConstants.primaryColor).withValues(alpha: 0.04) : null,
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(key)?.dispose();
                        } else {
                          _selected[key] = TextEditingController(
                              text: cat['default']?.toString() ?? '');
                        }
                      });
                    },
                    borderRadius: isSelected
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Icon(catIcon,
                          color: isSelected
                              ? const Color(AppConstants.primaryColor)
                              : Colors.grey.shade500,
                          size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                            if (unit != null)
                              Text(unit, style: const TextStyle(
                                  fontSize: 11, color: Color(AppConstants.textSecondary))),
                          ],
                        )),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.add_circle_outline,
                          color: isSelected
                              ? const Color(AppConstants.primaryColor)
                              : Colors.grey.shade400,
                          size: 22,
                        ),
                      ]),
                    ),
                  ),
                  // ── Expanded value field when selected ──────
                  if (isSelected && unit != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: TextField(
                        controller: _selected[key],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Target',
                          suffixText: unit,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          // ── Custom habits section ─────────────────────────
          const Divider(height: 28),
          Row(children: [
            const Text('Custom Habits',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddCustomDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
            ),
          ]),
          const SizedBox(height: 6),

          if (_customItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                const Text('Tap "Add" to create a custom habit',
                  style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
              ]),
            )
          else
            ..._customItems.asMap().entries.map((e) {
              final i    = e.key;
              final item = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: const Color(AppConstants.primaryColor).withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                        if (item.value.isNotEmpty)
                          Text(
                            '${item.value}${item.unit.isNotEmpty ? " ${item.unit}" : ""}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(AppConstants.textSecondary))),
                      ],
                    )),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      onPressed: () => _showAddCustomDialog(existing: item, index: i),
                      color: const Color(AppConstants.primaryColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 17),
                      onPressed: () => setState(() => _customItems.removeAt(i)),
                      color: Colors.red.shade300,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                ),
              );
            }),

          const SizedBox(height: 16),
          LoadingButton(
            text: 'Assign Lifestyle Plan',
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
