// lib/screens/participant/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api     = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Basic Details
  final _heightCtrl      = TextEditingController();
  final _currWtCtrl      = TextEditingController();
  final _goalWtCtrl      = TextEditingController();
  DateTime? _dob;
  String?   _gender;

  // Goal — multi-select
  final List<String> _healthGoals = [];

  // Unit toggles (display only; DB always stores cm / kg)
  bool _heightInInches = false;
  bool _weightInLbs    = false;

  // Eating pattern
  final _mealsPerDayCtrl  = TextEditingController();
  final _mealTimingsCtrl  = TextEditingController();

  // What you usually eat
  final _breakfastCtrl   = TextEditingController();
  final _lunchCtrl       = TextEditingController();
  final _snacksCtrl      = TextEditingController();
  final _dinnerCtrl      = TextEditingController();
  final _teaCoffeeCtrl   = TextEditingController();

  // Eating out
  final _eatingOutFreqCtrl = TextEditingController();
  final _eatingOutPrefCtrl = TextEditingController();

  // Activity
  bool?   _currentlyWorkout;
  String? _activityLevel;
  final _workoutTypeCtrl = TextEditingController();

  // Lifestyle baselines
  final _sleepCtrl        = TextEditingController();
  final _stepsCtrl        = TextEditingController();
  String? _stressLevel;   // Low / Medium / High

  // Health
  final _healthCtrl  = TextEditingController();
  final _injuryCtrl  = TextEditingController();
  final _medCtrl     = TextEditingController();

  // Diet
  String? _dietPref;
  final _allergyCtrl = TextEditingController();

  // Family
  String? _familyType;
  int     _familyCount = 1;

  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await _api.get('/profile/get');
      if (res['profile'] != null) {
        final p = res['profile'];
        _heightCtrl.text       = p['height_cm']?.toString() ?? '';
        _currWtCtrl.text       = p['current_weight_kg']?.toString() ?? '';
        _goalWtCtrl.text       = p['goal_weight_kg']?.toString() ?? '';
        _mealsPerDayCtrl.text  = p['meals_per_day']?.toString() ?? '';
        _mealTimingsCtrl.text  = p['meal_timings'] ?? '';
        _breakfastCtrl.text    = p['typical_breakfast'] ?? '';
        _lunchCtrl.text        = p['typical_lunch'] ?? '';
        _snacksCtrl.text       = p['typical_snacks'] ?? '';
        _dinnerCtrl.text       = p['typical_dinner'] ?? '';
        _teaCoffeeCtrl.text    = p['tea_coffee'] ?? '';
        _eatingOutFreqCtrl.text = p['eating_out_frequency'] ?? '';
        _eatingOutPrefCtrl.text = p['eating_out_preference'] ?? '';
        _workoutTypeCtrl.text  = p['workout_type'] ?? '';
        _sleepCtrl.text        = p['typical_sleep_hours']?.toString() ?? '';
        _stepsCtrl.text        = p['typical_daily_steps']?.toString() ?? '';
        _healthCtrl.text       = p['health_conditions'] ?? '';
        _injuryCtrl.text       = p['injuries'] ?? '';
        _medCtrl.text          = p['medications'] ?? '';
        _allergyCtrl.text      = p['allergies'] ?? '';
        setState(() {
          _gender          = p['gender'];
          _activityLevel   = p['activity_level'];
          final rawGoal = p['health_goal'] as String?;
          if (rawGoal != null && rawGoal.isNotEmpty) {
            _healthGoals.clear();
            _healthGoals.addAll(rawGoal.split(',').map((s) => s.trim()));
          }
          _currentlyWorkout = p['currently_workout'];
          _stressLevel     = p['typical_stress_level'];
          _dietPref        = p['diet_preference'];
          _familyType      = p['family_type'];
          _familyCount     = p['family_members_count'] ?? 1;
          if (p['dob'] != null) _dob = DateTime.tryParse(p['dob']);
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.post('/profile/create', {
        'dob':                    _dob?.toIso8601String().split('T').first,
        'gender':                 _gender,
        'height_cm': _heightInInches
            ? (double.tryParse(_heightCtrl.text) ?? 0) * 2.54
            : double.tryParse(_heightCtrl.text),
        'current_weight_kg': _weightInLbs
            ? (double.tryParse(_currWtCtrl.text) ?? 0) / 2.20462
            : double.tryParse(_currWtCtrl.text),
        'goal_weight_kg': _weightInLbs
            ? (double.tryParse(_goalWtCtrl.text) ?? 0) / 2.20462
            : double.tryParse(_goalWtCtrl.text),
        'health_goal':            _healthGoals.isEmpty ? null : _healthGoals.join(','),
        'activity_level':         _activityLevel,
        'meals_per_day':          int.tryParse(_mealsPerDayCtrl.text),
        'meal_timings':           _mealTimingsCtrl.text.isNotEmpty ? _mealTimingsCtrl.text : null,
        'typical_breakfast':      _breakfastCtrl.text.isNotEmpty ? _breakfastCtrl.text : null,
        'typical_lunch':          _lunchCtrl.text.isNotEmpty ? _lunchCtrl.text : null,
        'typical_snacks':         _snacksCtrl.text.isNotEmpty ? _snacksCtrl.text : null,
        'typical_dinner':         _dinnerCtrl.text.isNotEmpty ? _dinnerCtrl.text : null,
        'tea_coffee':             _teaCoffeeCtrl.text.isNotEmpty ? _teaCoffeeCtrl.text : null,
        'eating_out_frequency':   _eatingOutFreqCtrl.text.isNotEmpty ? _eatingOutFreqCtrl.text : null,
        'eating_out_preference':  _eatingOutPrefCtrl.text.isNotEmpty ? _eatingOutPrefCtrl.text : null,
        'currently_workout':      _currentlyWorkout,
        'workout_type':           _workoutTypeCtrl.text.isNotEmpty ? _workoutTypeCtrl.text : null,
        'typical_sleep_hours':    double.tryParse(_sleepCtrl.text),
        'typical_daily_steps':    int.tryParse(_stepsCtrl.text),
        'typical_stress_level':   _stressLevel,
        'health_conditions':      _healthCtrl.text.isNotEmpty ? _healthCtrl.text : null,
        'medications':            _medCtrl.text.isNotEmpty ? _medCtrl.text : null,
        'injuries':               _injuryCtrl.text.isNotEmpty ? _injuryCtrl.text : null,
        'diet_preference':        _dietPref,
        'allergies':              _allergyCtrl.text.isNotEmpty ? _allergyCtrl.text : null,
        'family_type':            _familyType,
        'family_members_count':   _familyCount,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved!'), backgroundColor: Colors.green));
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton(
            onPressed: () { context.read<AuthProvider>().logout(); context.go('/login'); },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _userCard(user),
                  const SizedBox(height: 16),
                  _section('Basic Details', Icons.person_outline, Colors.blue, [
                    _datePicker(),
                    _gap(),
                    _dropdown('Gender', _gender, ['male', 'female', 'other'],
                        (v) => setState(() => _gender = v)),
                    _gap(),
                    _unitField(
                      ctrl: _heightCtrl,
                      label: _heightInInches ? 'Height (in)' : 'Height (cm)',
                      hint: _heightInInches ? 'e.g. 67.0' : 'e.g. 170',
                      unit1: 'cm', unit2: 'in',
                      useUnit2: _heightInInches,
                      onToggle: () {
                        final v = double.tryParse(_heightCtrl.text);
                        setState(() {
                          if (!_heightInInches && v != null) {
                            _heightCtrl.text = (v / 2.54).toStringAsFixed(1);
                          } else if (_heightInInches && v != null) {
                            _heightCtrl.text = (v * 2.54).toStringAsFixed(1);
                          }
                          _heightInInches = !_heightInInches;
                        });
                      },
                    ),
                    _gap(),
                    _unitField(
                      ctrl: _currWtCtrl,
                      label: _weightInLbs ? 'Current Weight (lbs)' : 'Current Weight (kg)',
                      hint: _weightInLbs ? 'e.g. 160' : 'e.g. 72.5',
                      unit1: 'kg', unit2: 'lbs',
                      useUnit2: _weightInLbs,
                      onToggle: () {
                        final v = double.tryParse(_currWtCtrl.text);
                        final gv = double.tryParse(_goalWtCtrl.text);
                        setState(() {
                          if (!_weightInLbs) {
                            if (v != null) _currWtCtrl.text = (v * 2.20462).toStringAsFixed(1);
                            if (gv != null) _goalWtCtrl.text = (gv * 2.20462).toStringAsFixed(1);
                          } else {
                            if (v != null) _currWtCtrl.text = (v / 2.20462).toStringAsFixed(1);
                            if (gv != null) _goalWtCtrl.text = (gv / 2.20462).toStringAsFixed(1);
                          }
                          _weightInLbs = !_weightInLbs;
                        });
                      },
                    ),
                  ]),
                  const SizedBox(height: 14),

                  _section('Your Goal', Icons.flag_outlined, Colors.deepOrange, [
                    _label('Main Goals (select all that apply)'),
                    const SizedBox(height: 10),
                    _multiChipGroup(
                      options: const {
                        'lose_weight':       'Fat Loss',
                        'build_muscle':      'Muscle Gain',
                        'stay_fit':          'General Fitness',
                        'reverse_diabetes':  'Reverse Diabetes',
                        'healthy_lifestyle': 'Healthy Lifestyle',
                        'improve_stamina':   'Improve Stamina',
                        'stress_management': 'Stress Management',
                      },
                      selected: _healthGoals,
                      onToggle: (key) => setState(() {
                        _healthGoals.contains(key)
                            ? _healthGoals.remove(key)
                            : _healthGoals.add(key);
                      }),
                      color: Colors.deepOrange,
                    ),
                    _gap(),
                    _numField(_goalWtCtrl,
                        _weightInLbs ? 'Target Weight (lbs)' : 'Target Weight (kg)',
                        _weightInLbs ? 'e.g. 143' : 'e.g. 65'),
                  ]),
                  const SizedBox(height: 14),

                  _section('Daily Eating Pattern', Icons.schedule, Colors.teal, [
                    _numField(_mealsPerDayCtrl, 'How many meals per day?', 'e.g. 3', isInt: true),
                    _gap(),
                    _textField(_mealTimingsCtrl, 'Typical meal timings',
                        'e.g. 8am / 1pm / 4pm / 8pm'),
                  ]),
                  const SizedBox(height: 14),

                  _section('What You Usually Eat', Icons.restaurant_outlined, Colors.orange, [
                    _textField(_breakfastCtrl, 'Breakfast', 'e.g. Poha, milk'),
                    _gap(),
                    _textField(_lunchCtrl, 'Lunch', 'e.g. Rice, dal, sabzi'),
                    _gap(),
                    _textField(_snacksCtrl, 'Snacks', 'e.g. Fruits, biscuits'),
                    _gap(),
                    _textField(_dinnerCtrl, 'Dinner', 'e.g. Roti, sabzi'),
                    _gap(),
                    _textField(_teaCoffeeCtrl, 'Tea / Coffee', 'e.g. 2 cups of tea with sugar'),
                  ]),
                  const SizedBox(height: 14),

                  _section('Eating Out', Icons.storefront_outlined, Colors.brown, [
                    _textField(_eatingOutFreqCtrl, 'How often do you eat outside?',
                        'e.g. 2-3 times a week'),
                    _gap(),
                    _textField(_eatingOutPrefCtrl, 'What do you usually order?',
                        'e.g. Biryani, pizza, Chinese'),
                  ]),
                  const SizedBox(height: 14),

                  _section('Activity Level', Icons.fitness_center, Colors.green, [
                    _label('Do you currently workout?'),
                    const SizedBox(height: 8),
                    _yesNoToggle(
                      value: _currentlyWorkout,
                      onChanged: (v) => setState(() => _currentlyWorkout = v),
                    ),
                    if (_currentlyWorkout == true) ...[
                      _gap(),
                      _textField(_workoutTypeCtrl, 'What type of workout?',
                          'e.g. Gym, running, yoga, home workout'),
                    ],
                    _gap(),
                    _dropdown('Overall Activity Level', _activityLevel,
                        ['sedentary', 'moderate', 'active'],
                        (v) => setState(() => _activityLevel = v)),
                  ]),
                  const SizedBox(height: 14),

                  _section('Lifestyle', Icons.self_improvement, Colors.indigo, [
                    _numField(_sleepCtrl, 'Sleep hours per day', 'e.g. 7'),
                    _gap(),
                    _numField(_stepsCtrl, 'Daily steps (if known)', 'e.g. 6000', isInt: true),
                    _gap(),
                    _label('Stress level'),
                    const SizedBox(height: 8),
                    _chipGroup(['Low', 'Medium', 'High'], _stressLevel,
                        (v) => setState(() => _stressLevel = v),
                        colors: {'Low': Colors.green, 'Medium': Colors.orange, 'High': Colors.red}),
                  ]),
                  const SizedBox(height: 14),

                  _section('Health', Icons.health_and_safety_outlined, Colors.red, [
                    _textField(_healthCtrl, 'Any medical conditions?',
                        'e.g. Diabetes, hypertension, thyroid — or type "None"'),
                    _gap(),
                    _textField(_injuryCtrl, 'Any injuries?',
                        'e.g. Lower back pain, knee issue — or type "None"'),
                    _gap(),
                    _textField(_medCtrl, 'Any medications?',
                        'e.g. Metformin, thyroid pills — or type "None"'),
                  ]),
                  const SizedBox(height: 14),

                  _section('Diet Preference', Icons.set_meal_outlined, Colors.purple, [
                    _dropdown('Diet Type', _dietPref,
                        ['vegetarian', 'eggetarian', 'non_vegetarian', 'vegan'],
                        (v) => setState(() => _dietPref = v),
                        display: {
                          'vegetarian': 'Vegetarian',
                          'eggetarian': 'Eggetarian',
                          'non_vegetarian': 'Non-Vegetarian',
                          'vegan': 'Vegan',
                        }),
                    _gap(),
                    _textField(_allergyCtrl, 'Food allergies or restrictions',
                        'e.g. Lactose intolerant, no gluten — or type "None"'),
                  ]),
                  const SizedBox(height: 14),

                  _section('Family', Icons.people_outline, Colors.cyan, [
                    _dropdown('Family Type', _familyType, ['single', 'joint'],
                        (v) => setState(() => _familyType = v)),
                    _gap(),
                    Row(
                      children: [
                        const Expanded(child: Text('Family Members')),
                        IconButton(
                          onPressed: () => setState(() { if (_familyCount > 1) _familyCount--; }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_familyCount',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => setState(() => _familyCount++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 24),

                  LoadingButton(text: 'Save Profile', loading: _saving, onPressed: _save),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'v${AppConstants.version}',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── Section builder ────────────────────────────────────────────────────────

  Widget _section(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  // ── Field helpers ──────────────────────────────────────────────────────────

  Widget _gap() => const SizedBox(height: 12);

  Widget _label(String text) => Text(text,
      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)));

  Widget _numField(TextEditingController ctrl, String label, String hint, {bool isInt = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged, {Map<String, String>? display}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) {
        final text = display?[i] ?? i.replaceAll('_', ' ').split(' ')
            .map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
        return DropdownMenuItem(value: i, child: Text(text));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _yesNoToggle({required bool? value, required ValueChanged<bool> onChanged}) {
    return Row(children: [
      _toggleChip('Yes', value == true, Colors.green, () => onChanged(true)),
      const SizedBox(width: 10),
      _toggleChip('No', value == false, Colors.red, () => onChanged(false)),
    ]);
  }

  Widget _toggleChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          )),
      ),
    );
  }

  Widget _chipGroup(List<String> options, String? selected,
      ValueChanged<String> onChanged, {Map<String, Color>? colors}) {
    return Wrap(
      spacing: 8,
      children: options.map((o) {
        final isSelected = selected == o;
        final color = colors?[o] ?? const Color(AppConstants.primaryColor);
        return GestureDetector(
          onTap: () => onChanged(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
              border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(o,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              )),
          ),
        );
      }).toList(),
    );
  }

  // Height/weight field with cm↔in or kg↔lbs toggle
  Widget _unitField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required String unit1,
    required String unit2,
    required bool useUnit2,
    required VoidCallback onToggle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(unit1, style: TextStyle(
                fontSize: 13, fontWeight: useUnit2 ? FontWeight.normal : FontWeight.bold,
                color: useUnit2 ? Colors.grey : const Color(AppConstants.primaryColor),
              )),
              Text('  /  ', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              Text(unit2, style: TextStyle(
                fontSize: 13, fontWeight: useUnit2 ? FontWeight.bold : FontWeight.normal,
                color: useUnit2 ? const Color(AppConstants.primaryColor) : Colors.grey,
              )),
            ]),
          ),
        ),
      ],
    );
  }

  // Multi-select chip group (goals)
  Widget _multiChipGroup({
    required Map<String, String> options,
    required List<String> selected,
    required ValueChanged<String> onToggle,
    Color color = const Color(AppConstants.primaryColor),
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final isSel = selected.contains(e.key);
        return GestureDetector(
          onTap: () => onToggle(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSel ? color.withValues(alpha: 0.12) : Colors.transparent,
              border: Border.all(color: isSel ? color : Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isSel) ...[
                Icon(Icons.check, size: 13, color: color),
                const SizedBox(width: 4),
              ],
              Text(e.value, style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13,
                color: isSel ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _datePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Date of Birth'),
      subtitle: Text(_dob == null ? 'Not set' : '${_dob!.day}/${_dob!.month}/${_dob!.year}'),
      trailing: const Icon(Icons.calendar_today, size: 18),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime(1990),
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _dob = picked);
      },
    );
  }

  Widget _userCard(dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(AppConstants.primaryColor).withValues(alpha: 0.1),
              child: Text(user.fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor))),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('@${user.username}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                Text(user.email,
                  style: TextStyle(fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
