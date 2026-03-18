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
  final _api        = ApiService();
  final _formKey    = GlobalKey<FormState>();
  final _heightCtrl = TextEditingController();
  final _currWtCtrl = TextEditingController();
  final _goalWtCtrl = TextEditingController();
  final _healthCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _injuryCtrl = TextEditingController();
  final _medCtrl    = TextEditingController();

  String? _gender;
  String? _activity;
  String? _dietPref;
  String? _familyType;
  String? _healthGoal;
  DateTime? _dob;
  int _familyCount = 1;
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await _api.get('/profile/get');
      if (res['profile'] != null) {
        final p = res['profile'];
        _heightCtrl.text  = p['height_cm']?.toString() ?? '';
        _currWtCtrl.text  = p['current_weight_kg']?.toString() ?? '';
        _goalWtCtrl.text  = p['goal_weight_kg']?.toString() ?? '';
        _healthCtrl.text  = p['health_conditions'] ?? '';
        _allergyCtrl.text = p['allergies'] ?? '';
        _injuryCtrl.text  = p['injuries'] ?? '';
        _medCtrl.text     = p['medications'] ?? '';
        setState(() {
          _gender      = p['gender'];
          _activity    = p['activity_level'];
          _dietPref    = p['diet_preference'];
          _familyType  = p['family_type'];
          _healthGoal  = p['health_goal'];
          _familyCount = p['family_members_count'] ?? 1;
          if (p['dob'] != null) _dob = DateTime.tryParse(p['dob']);
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() { _saving = true; });
    try {
      await _api.post('/profile/create', {
        'dob':                  _dob?.toIso8601String().split('T').first,
        'gender':               _gender,
        'height_cm':            double.tryParse(_heightCtrl.text),
        'current_weight_kg':    double.tryParse(_currWtCtrl.text),
        'goal_weight_kg':       double.tryParse(_goalWtCtrl.text),
        'activity_level':       _activity,
        'health_goal':          _healthGoal,
        'health_conditions':    _healthCtrl.text.isNotEmpty ? _healthCtrl.text : null,
        'medications':          _medCtrl.text.isNotEmpty ? _medCtrl.text : null,
        'injuries':             _injuryCtrl.text.isNotEmpty ? _injuryCtrl.text : null,
        'family_type':          _familyType,
        'family_members_count': _familyCount,
        'diet_preference':      _dietPref,
        'allergies':            _allergyCtrl.text.isNotEmpty ? _allergyCtrl.text : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                  // User card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(AppConstants.primaryColor).withOpacity(0.1),
                            child: Text(user.fullName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                                  color: Color(AppConstants.primaryColor))),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName, style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('@${user.username}',
                                style: const TextStyle(color: Color(AppConstants.textSecondary))),
                              Text(user.email,
                                style: const TextStyle(fontSize: 12,
                                    color: Color(AppConstants.textSecondary))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Basic info
                  _section('Basic Information', [
                    // DOB
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date of Birth'),
                      subtitle: Text(_dob == null ? 'Not set'
                          : '${_dob!.day}/${_dob!.month}/${_dob!.year}'),
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
                    ),
                    _dropdown('Gender', _gender, ['male', 'female', 'other'],
                        (v) => setState(() => _gender = v)),
                    const SizedBox(height: 10),
                    _numField(_heightCtrl, 'Height (cm)', 'e.g. 170'),
                    const SizedBox(height: 10),
                    _numField(_currWtCtrl, 'Current Weight (kg)', 'e.g. 72.5'),
                    const SizedBox(height: 10),
                    _numField(_goalWtCtrl, 'Goal Weight (kg)', 'e.g. 65'),
                    const SizedBox(height: 10),
                    _dropdown('Activity Level', _activity,
                        ['sedentary', 'moderate', 'active'],
                        (v) => setState(() => _activity = v)),
                  ]),
                  const SizedBox(height: 14),

                  // Diet
                  _section('Diet & Nutrition', [
                    _dropdown('Diet Preference', _dietPref,
                        ['vegetarian', 'non_vegetarian', 'vegan'],
                        (v) => setState(() => _dietPref = v)),
                    const SizedBox(height: 10),
                    _textField(_allergyCtrl, 'Allergies', 'e.g. Peanuts, Gluten'),
                  ]),
                  const SizedBox(height: 14),

                  // Health
                  _section('Health Information', [
                    _textField(_healthCtrl, 'Health Conditions', 'e.g. Diabetes, Hypertension'),
                    const SizedBox(height: 10),
                    _textField(_medCtrl, 'Medications', 'e.g. Metformin'),
                    const SizedBox(height: 10),
                    _textField(_injuryCtrl, 'Injuries', 'e.g. Lower back pain'),
                  ]),
                  const SizedBox(height: 14),

                  // Family
                  _section('Family', [
                    _dropdown('Family Type', _familyType, ['single', 'joint'],
                        (v) => setState(() => _familyType = v)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(child: Text('Family Members')),
                        IconButton(
                          onPressed: () => setState(() {
                            if (_familyCount > 1) _familyCount--;
                          }),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label, String hint) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, String hint) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(
        value: i,
        child: Text(i.replaceAll('_', ' ').split(' ').map((w) =>
          w[0].toUpperCase() + w.substring(1)).join(' ')),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
