// lib/screens/participant/tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _api        = ApiService();
  final _formKey    = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _waterCtrl  = TextEditingController();
  final _stepsCtrl  = TextEditingController();
  final _sleepCtrl  = TextEditingController();
  final _notesCtrl  = TextEditingController();

  int    _stress        = 5;
  String _mood          = 'Good';
  bool   _hadDeviation  = false;
  bool   _loading       = false;
  bool   _saving        = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waterCtrl.dispose();
    _stepsCtrl.dispose();
    _sleepCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/tracking/today');
      if (res['tracking'] != null) {
        final t = DailyTracking.fromJson(res['tracking']);
        _weightCtrl.text = t.weightKg?.toString() ?? '';
        _waterCtrl.text  = t.waterIntakeLiters?.toString() ?? '';
        _stepsCtrl.text  = t.steps?.toString() ?? '';
        _sleepCtrl.text  = t.sleepHours?.toString() ?? '';
        _notesCtrl.text  = t.deviationNotes ?? '';
        setState(() {
          _stress       = t.stressLevel ?? 5;
          _mood         = t.mood ?? 'Good';
          _hadDeviation = t.deviationNotes != null && t.deviationNotes!.isNotEmpty;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await _api.post('/tracking/add', {
        'weight_kg':           double.tryParse(_weightCtrl.text),
        'water_intake_liters': double.tryParse(_waterCtrl.text),
        'steps':               int.tryParse(_stepsCtrl.text),
        'sleep_hours':         double.tryParse(_sleepCtrl.text),
        'stress_level':        _stress,
        'mood':                _mood,
        'deviation_notes':     _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress saved!'), backgroundColor: Colors.green),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Tracking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ErrorMessage(message: _error!),

                  // Body Metrics
                  _sectionCard('Body Metrics', Icons.monitor_weight_outlined, Colors.purple, [
                    _numField(_weightCtrl, 'Weight (kg)',   'e.g. 72.5'),
                    _numField(_sleepCtrl,  'Sleep (hours)', 'e.g. 7.5'),
                  ]),
                  const SizedBox(height: 14),

                  // Activity & Hydration
                  _sectionCard('Activity & Hydration', Icons.directions_walk, Colors.green, [
                    _stepsField(),
                    _numField(_waterCtrl, 'Water (liters)', 'e.g. 2.5'),
                  ]),
                  const SizedBox(height: 14),

                  // Mood & Wellbeing (combined card)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.favorite_outline, color: Colors.pink, size: 20),
                            const SizedBox(width: 8),
                            const Text('Mood & Wellbeing',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ]),
                          const SizedBox(height: 14),

                          // Mood chips
                          Text('How are you feeling?',
                            style: TextStyle(fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: AppConstants.moods.map((m) {
                              final sel = _mood == m;
                              return ChoiceChip(
                                label: Text(m),
                                selected: sel,
                                onSelected: (_) => setState(() => _mood = m),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 14),

                          // Stress slider
                          Row(children: [
                            Text('Stress Level',
                              style: TextStyle(fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _stressColor(_stress).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$_stress / 10',
                                style: TextStyle(
                                  color: _stressColor(_stress),
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ]),
                          Slider(
                            value: _stress.toDouble(),
                            min: 1, max: 10, divisions: 9,
                            activeColor: _stressColor(_stress),
                            onChanged: (v) => setState(() => _stress = v.round()),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Relaxed',
                                style: TextStyle(fontSize: 11, color: Colors.green)),
                              Text('Very Stressed',
                                style: TextStyle(fontSize: 11, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Deviation
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.notes, color: Colors.blueGrey, size: 20),
                            const SizedBox(width: 8),
                            const Text('Any Deviation Today?',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ]),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('No deviation'),
                                selected: !_hadDeviation,
                                onSelected: (_) => setState(() {
                                  _hadDeviation = false;
                                  _notesCtrl.clear();
                                }),
                              ),
                              ChoiceChip(
                                label: const Text('Had deviation'),
                                selected: _hadDeviation,
                                onSelected: (_) => setState(() => _hadDeviation = true),
                              ),
                            ],
                          ),
                          if (_hadDeviation) ...[
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _notesCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Ate out, missed workout...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  LoadingButton(text: 'Save Today\'s Progress', loading: _saving, onPressed: _save),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Color _stressColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }

  // Steps field with digits-only enforced
  Widget _stepsField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _stepsCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Steps',
          hintText: 'e.g. 8000',
        ),
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Color color, List<Widget> fields) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ]),
            const SizedBox(height: 14),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
