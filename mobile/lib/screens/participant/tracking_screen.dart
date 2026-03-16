// lib/screens/participant/tracking_screen.dart
import 'package:flutter/material.dart';
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

  int    _stress   = 5;
  String _mood     = 'Good';
  bool   _loading  = false;
  bool   _saving   = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadToday();
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
          _stress = t.stressLevel ?? 5;
          _mood   = t.mood ?? 'Good';
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
          const SnackBar(content: Text('✅ Progress saved!'), backgroundColor: Colors.green),
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
      appBar: AppBar(
        title: const Text('Daily Tracking'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
      ),
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

                  // Activity
                  _sectionCard('Activity & Hydration', Icons.directions_walk, Colors.green, [
                    _numField(_stepsCtrl, 'Steps',           'e.g. 8000', isInt: true),
                    _numField(_waterCtrl, 'Water (liters)',  'e.g. 2.5'),
                  ]),
                  const SizedBox(height: 14),

                  // Stress Level
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology_outlined, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              const Text('Stress Level',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _stressColor(_stress).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('$_stress / 10',
                                  style: TextStyle(
                                    color: _stressColor(_stress),
                                    fontWeight: FontWeight.bold,
                                  )),
                              ),
                            ],
                          ),
                          Slider(
                            value: _stress.toDouble(),
                            min: 1, max: 10, divisions: 9,
                            onChanged: (v) => setState(() => _stress = v.round()),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Relaxed', style: TextStyle(fontSize: 11, color: Colors.green)),
                              Text('Very Stressed', style: TextStyle(fontSize: 11, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mood
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mood, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              const Text('Mood',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: AppConstants.moods.map((m) {
                              final selected = _mood == m;
                              return ChoiceChip(
                                label: Text(m),
                                selected: selected,
                                onSelected: (_) => setState(() => _mood = m),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notes, color: Colors.blueGrey, size: 20),
                              const SizedBox(width: 8),
                              const Text('Deviation Notes',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Any deviations from plan? Ate out, missed workout...',
                              border: OutlineInputBorder(),
                            ),
                          ),
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

  Widget _sectionCard(String title, IconData icon, Color color, List<Widget> fields) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _numField(
    TextEditingController ctrl, String label, String hint,
    {bool isInt = false}
  ) {
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
