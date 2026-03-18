// lib/screens/coach/assign_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class _SelEx {
  final Exercise exercise;
  int sets;
  int reps;
  _SelEx({required this.exercise, required this.sets, required this.reps});
}

class _Day {
  String name;
  // Use a Map keyed by exercise.id so each day has independent storage
  final Map<int, _SelEx> exerciseMap = {};
  _Day({required this.name});
  List<_SelEx> get exercises => exerciseMap.values.toList();
  bool has(int id) => exerciseMap.containsKey(id);
  void toggle(Exercise e) {
    if (has(e.id)) {
      exerciseMap.remove(e.id);
    } else {
      exerciseMap[e.id] = _SelEx(exercise: e, sets: e.defaultSets, reps: e.defaultReps);
    }
  }
}

class AssignWorkoutScreen extends StatefulWidget {
  final int clientId;
  const AssignWorkoutScreen({super.key, required this.clientId});
  @override
  State<AssignWorkoutScreen> createState() => _AssignWorkoutScreenState();
}

class _AssignWorkoutScreenState extends State<AssignWorkoutScreen> {
  final _api      = ApiService();
  final _nameCtrl = TextEditingController(text: 'Weekly Workout Plan');
  List<Exercise>  _library      = [];
  final List<_Day> _days        = [];
  int  _activeDayIdx            = 0;
  bool _loading                 = true;
  bool _saving                  = false;
  String  _searchQuery          = '';
  String? _filterMuscle;
  String? _error;
  List<Exercise> _filtered      = [];

  @override
  void initState() {
    super.initState();
    // Start with 3 common day templates
    _days.addAll([
      _Day(name: 'Day 1 — Chest & Triceps'),
      _Day(name: 'Day 2 — Back & Biceps'),
      _Day(name: 'Day 3 — Legs & Shoulders'),
    ]);
    _load();
  }

  String? _extractVideoId(String input) => parseYoutubeVideoId(input);

  Future<void> _saveVideoId(int exerciseId, String? videoId) async {
    try {
      await _api.patch('/workout/exercises/$exerciseId/video',
          {'youtube_video_id': videoId});
      setState(() {
        final idx = _library.indexWhere((e) => e.id == exerciseId);
        if (idx != -1) {
          final old = _library[idx];
          _library[idx] = Exercise(
            id: old.id, exerciseName: old.exerciseName,
            muscleGroup: old.muscleGroup, description: old.description,
            defaultSets: old.defaultSets, defaultReps: old.defaultReps,
            youtubeVideoId: videoId,
          );
          _updateFiltered();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showVideoPlayer(String exerciseName, String videoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoSheet(exerciseName: exerciseName, videoId: videoId),
    );
  }

  void _showVideoDialog(Exercise ex) {
    final ctrl = TextEditingController(text: ex.youtubeVideoId ?? '');
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(ex.youtubeVideoId == null ? 'Add Video Link' : 'Edit Video Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ex.exerciseName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'YouTube URL or Video ID',
                  hintText: 'e.g. youtube.com/watch?v=abc or just abc',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            if (ex.youtubeVideoId != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () { Navigator.pop(ctx); _saveVideoId(ex.id, null); },
                child: const Text('Remove'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final videoId = _extractVideoId(ctrl.text);
                if (videoId == null) {
                  setS(() => error = 'Invalid YouTube URL or ID');
                  return;
                }
                Navigator.pop(ctx);
                _saveVideoId(ex.id, videoId);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) => ctrl.dispose());
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/workout/exercises');
      setState(() {
        _library = (res['exercises'] as List).map((e) => Exercise.fromJson(e)).toList();
        _updateFiltered();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _updateFiltered() {
    _filtered = _library.where((e) {
      final matchName   = e.exerciseName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchMuscle = _filterMuscle == null || e.muscleGroup == _filterMuscle;
      return matchName && matchMuscle;
    }).toList();
  }

  List<String> get _muscleGroups =>
      _library.map((e) => e.muscleGroup).toSet().toList()..sort();

  _Day get _activeDay => _days[_activeDayIdx];

  void _addDay() => setState(() {
    _days.add(_Day(name: 'Day ${_days.length + 1}'));
    _activeDayIdx = _days.length - 1;
  });

  void _removeDay(int i) {
    if (_days.length <= 1) return;
    setState(() {
      _days.removeAt(i);
      if (_activeDayIdx >= _days.length) _activeDayIdx = _days.length - 1;
    });
  }

  void _renameDay(int i) {
    final ctrl = TextEditingController(text: _days[i].name);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Rename day'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. Chest & Triceps'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          if (ctrl.text.isNotEmpty) setState(() => _days[i].name = ctrl.text);
          Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _save() async {
    final hasAny = _days.any((d) => d.exercises.isNotEmpty);
    if (!hasAny) { setState(() => _error = 'Add at least one exercise to a day'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await _api.post('/workout/assign', {
        'participant_id': widget.clientId,
        'plan_name':      _nameCtrl.text.trim(),
        'days': _days.asMap().entries.map((e) => {
          'day_name': e.value.name,
          'exercises': e.value.exercises.asMap().entries.map((ex) => {
            'exercise_id': ex.value.exercise.id,
            'sets':        ex.value.sets,
            'reps':        ex.value.reps,
            'order_index': ex.key,
          }).toList(),
        }).toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Workout plan assigned!'), backgroundColor: Colors.green));
        context.go('/coach/client/${widget.clientId}');
      }
    } catch (e) { setState(() => _error = e.toString()); }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Workout Plan'),
        leading: BackButton(onPressed: () => context.go('/coach/client/${widget.clientId}')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // ── Top: plan name + day tabs ──────────────────
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_error != null) ErrorMessage(message: _error!),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Plan name',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Day tabs row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      ..._days.asMap().entries.map((e) {
                        final i      = e.key;
                        final day    = e.value;
                        final active = i == _activeDayIdx;
                        return GestureDetector(
                          onTap: () => setState(() => _activeDayIdx = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(AppConstants.primaryColor)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: active
                                    ? const Color(AppConstants.primaryColor)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(day.name,
                                style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500,
                                  color: active ? Colors.white : const Color(AppConstants.textPrimary),
                                )),
                              if (day.exercises.isNotEmpty) ...[
                                const SizedBox(width: 5),
                                Container(
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(child: Text('${day.exercises.length}',
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold,
                                      color: active ? Colors.white : Colors.green.shade700,
                                    ))),
                                ),
                              ],
                              const SizedBox(width: 4),
                              // Edit icon — opens rename dialog
                              GestureDetector(
                                onTap: () => _renameDay(i),
                                child: Icon(Icons.edit_outlined, size: 13,
                                  color: active ? Colors.white70 : Colors.grey.shade500),
                              ),
                              if (_days.length > 1) ...[
                                const SizedBox(width: 3),
                                GestureDetector(
                                  onTap: () => _removeDay(i),
                                  child: Icon(Icons.close, size: 13,
                                    color: active ? Colors.white60 : Colors.grey.shade400),
                                ),
                              ],
                            ]),
                          ),
                        );
                      }),
                      // Add day button
                      GestureDetector(
                        onTap: _addDay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add, size: 14, color: Colors.grey),
                            SizedBox(width: 3),
                            Text('Add day', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),

                  // Selected exercises for active day (scrollable chips)
                  if (_activeDay.exercises.isNotEmpty) ...[
                    Text('${_activeDay.name} — ${_activeDay.exercises.length} exercises selected',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(AppConstants.textPrimary))),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 28,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _activeDay.exercises.map((s) => GestureDetector(
                          onTap: () => setState(() => _activeDay.exerciseMap.remove(s.exercise.id)),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(s.exercise.exerciseName,
                                style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                              const SizedBox(width: 4),
                              Icon(Icons.close, size: 11, color: Colors.green.shade600),
                            ]),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else ...[
                    Text('Tap exercises below to add to ${_activeDay.name}',
                      style: const TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
                    const SizedBox(height: 8),
                  ],

                  // Search + muscle filter
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search exercises...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() { _searchQuery = v; _updateFiltered(); }),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _filterChip('All', _filterMuscle == null,
                          () => setState(() { _filterMuscle = null; _updateFiltered(); })),
                      ..._muscleGroups.map((m) => _filterChip(m, _filterMuscle == m,
                          () => setState(() { _filterMuscle = _filterMuscle == m ? null : m; _updateFiltered(); }))),
                    ]),
                  ),
                  const SizedBox(height: 4),
                ]),
              ),

              // ── Exercise list ──────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final ex  = _filtered[i];
                    final sel = _activeDay.has(ex.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      color: sel
                          ? const Color(AppConstants.primaryColor).withValues(alpha: 0.05) : null,
                      child: InkWell(
                        onTap: () => setState(() => _activeDay.toggle(ex)),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: sel ? const Color(AppConstants.primaryColor) : Colors.transparent,
                                border: Border.all(
                                  color: sel
                                      ? const Color(AppConstants.primaryColor)
                                      : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: sel
                                  ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex.exerciseName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(ex.muscleGroup,
                                      style: TextStyle(fontSize: 10, color: Colors.blue.shade700))),
                                  const SizedBox(width: 8),
                                  Text('${ex.defaultSets}×${ex.defaultReps}',
                                    style: const TextStyle(fontSize: 11,
                                        color: Color(AppConstants.textSecondary))),
                                ]),
                                if (ex.description != null) ...[
                                  const SizedBox(height: 2),
                                  Text(ex.description!,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11,
                                        color: Color(AppConstants.textSecondary),
                                        fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 6),
                                // ── Video controls ─────────────────────────
                                Row(children: [
                                  if (ex.youtubeVideoId != null) ...[
                                    _vidBtn('▶ Watch', Colors.red,
                                      () => _showVideoPlayer(ex.exerciseName, ex.youtubeVideoId!)),
                                    const SizedBox(width: 6),
                                    _vidBtn('Edit Link', Colors.grey,
                                      () => _showVideoDialog(ex)),
                                  ] else
                                    _vidBtn('+ Add Video', Colors.grey,
                                      () => _showVideoDialog(ex)),
                                ]),
                              ])),
                            // Sets/reps editor when selected
                            if (sel) ...[
                              const SizedBox(width: 8),
                              Column(children: [
                                _miniCounter('Sets',
                                  _activeDay.exerciseMap[ex.id]!.sets,
                                  (v) => setState(() => _activeDay.exerciseMap[ex.id]!.sets = v),
                                ),
                                const SizedBox(height: 4),
                                _miniCounter('Reps',
                                  _activeDay.exerciseMap[ex.id]!.reps,
                                  (v) => setState(() => _activeDay.exerciseMap[ex.id]!.reps = v),
                                ),
                              ]),
                            ],
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Summary of all days
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _days.map((d) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: d.exercises.isNotEmpty ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: d.exercises.isNotEmpty ? Colors.green.shade200 : Colors.grey.shade200),
              ),
              child: Text(
                '${d.name.split('—').last.trim()}: ${d.exercises.length} ex',
                style: TextStyle(
                  fontSize: 11,
                  color: d.exercises.isNotEmpty ? Colors.green.shade700 : Colors.grey,
                  fontWeight: FontWeight.w500,
                )),
            )).toList()),
          ),
          const SizedBox(height: 8),
          LoadingButton(
            text: 'Assign ${_days.length}-Day Plan',
            loading: _saving,
            onPressed: _save,
          ),
        ]),
      ),
    );
  }

  Widget _vidBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _miniCounter(String label, int value, ValueChanged<int> onChange) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label:', style: const TextStyle(fontSize: 10,
          color: Color(AppConstants.textSecondary))),
      const SizedBox(width: 2),
      GestureDetector(
        onTap: value > 1 ? () => onChange(value - 1) : null,
        child: Icon(Icons.remove_circle_outline, size: 16,
          color: value > 1 ? const Color(AppConstants.primaryColor) : Colors.grey.shade300),
      ),
      SizedBox(width: 20, child: Text('$value',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      GestureDetector(
        onTap: () => onChange(value + 1),
        child: const Icon(Icons.add_circle_outline, size: 16,
          color: Color(AppConstants.primaryColor)),
      ),
    ]);
  }
}
