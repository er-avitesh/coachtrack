// lib/screens/coach/assign_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class AssignWorkoutScreen extends StatefulWidget {
  final int clientId;
  const AssignWorkoutScreen({super.key, required this.clientId});

  @override
  State<AssignWorkoutScreen> createState() => _AssignWorkoutScreenState();
}

class _AssignWorkoutScreenState extends State<AssignWorkoutScreen> {
  final _api      = ApiService();
  final _nameCtrl = TextEditingController(text: 'Workout Plan');
  List<Exercise>  _library   = [];
  List<Exercise>  _filtered  = [];
  List<_Selected> _selected  = [];
  String _searchQuery = '';
  String? _filterMuscle;
  bool _loading = true;
  bool _saving  = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await _api.get('/workout/exercises');
      setState(() {
        _library  = (res['exercises'] as List).map((e) => Exercise.fromJson(e)).toList();
        _filtered = _library;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _filter(String query, String? muscle) {
    setState(() {
      _searchQuery   = query;
      _filterMuscle  = muscle;
      _filtered = _library.where((e) {
        final matchName   = e.exerciseName.toLowerCase().contains(query.toLowerCase());
        final matchMuscle = muscle == null || e.muscleGroup == muscle;
        return matchName && matchMuscle;
      }).toList();
    });
  }

  List<String> get _muscleGroups {
    final groups = _library.map((e) => e.muscleGroup).toSet().toList()..sort();
    return groups;
  }

  bool _isSelected(Exercise e) => _selected.any((s) => s.exercise.id == e.id);

  void _toggleExercise(Exercise e) {
    setState(() {
      if (_isSelected(e)) {
        _selected.removeWhere((s) => s.exercise.id == e.id);
      } else {
        _selected.add(_Selected(exercise: e, sets: e.defaultSets, reps: e.defaultReps));
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      setState(() => _error = 'Select at least one exercise');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _api.post('/workout/assign', {
        'participant_id': widget.clientId,
        'plan_name':      _nameCtrl.text.trim(),
        'exercises': _selected.asMap().entries.map((e) => {
          'exercise_id': e.value.exercise.id,
          'sets':        e.value.sets,
          'reps':        e.value.reps,
          'order_index': e.key,
        }).toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Workout assigned!'), backgroundColor: Colors.green));
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
        title: const Text('Assign Workout'),
        leading: BackButton(onPressed: () => context.go('/coach/client/${widget.clientId}')),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: () => _showSelectedSheet(),
              child: Text('Review (${_selected.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      if (_error != null) ErrorMessage(message: _error!),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search exercises...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _filter('', _filterMuscle),
                                ) : null,
                        ),
                        onChanged: (v) => _filter(v, _filterMuscle),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('All', _filterMuscle == null,
                                () => _filter(_searchQuery, null)),
                            ..._muscleGroups.map((m) =>
                              _filterChip(m, _filterMuscle == m,
                                  () => _filter(_searchQuery, _filterMuscle == m ? null : m))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final e = _filtered[i];
                      final selected = _isSelected(e);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: selected
                            ? const Color(AppConstants.primaryColor).withOpacity(0.05) : null,
                        child: InkWell(
                          onTap: () => _toggleExercise(e),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selected,
                                  onChanged: (_) => _toggleExercise(e),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.exerciseName,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(e.muscleGroup,
                                              style: const TextStyle(
                                                  fontSize: 11, color: Colors.blue)),
                                          ),
                                          const SizedBox(width: 6),
                                          Text('${e.defaultSets}×${e.defaultReps}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(AppConstants.textSecondary))),
                                        ],
                                      ),
                                      if (e.description != null) ...[
                                        const SizedBox(height: 2),
                                        Text(e.description!,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(AppConstants.textSecondary),
                                              fontStyle: FontStyle.italic)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _selected.isEmpty ? null : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: LoadingButton(
          text: 'Assign ${_selected.length} Exercise${_selected.length != 1 ? 's' : ''}',
          loading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }

  void _showSelectedSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selected Exercises',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Plan Name'),
              ),
              const SizedBox(height: 12),
              ...List.generate(_selected.length, (i) {
                final s = _selected[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.exercise.exerciseName),
                  subtitle: Row(
                    children: [
                      _setRepsWidget('Sets', s.sets, (v) {
                        setSheetState(() => _selected[i].sets = v);
                        setState(() {});
                      }),
                      const SizedBox(width: 12),
                      _setRepsWidget('Reps', s.reps, (v) {
                        setSheetState(() => _selected[i].reps = v);
                        setState(() {});
                      }),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setSheetState(() => _selected.removeAt(i));
                      setState(() {});
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setRepsWidget(String label, int value, ValueChanged<int> onChange) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 12)),
        IconButton(
          iconSize: 16, padding: EdgeInsets.zero,
          icon: const Icon(Icons.remove),
          onPressed: value > 1 ? () => onChange(value - 1) : null,
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          iconSize: 16, padding: EdgeInsets.zero,
          icon: const Icon(Icons.add),
          onPressed: () => onChange(value + 1),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Selected {
  Exercise exercise;
  int sets;
  int reps;
  _Selected({required this.exercise, required this.sets, required this.reps});
}
