// lib/screens/coach/client_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class ClientProfileScreen extends StatefulWidget {
  final int clientId;
  const ClientProfileScreen({super.key, required this.clientId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/coach/client/${widget.clientId}/summary');
      setState(() => _summary = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final client = _summary?['client'] ?? {};
    final tracking = List<Map<String, dynamic>>.from(_summary?['tracking'] ?? []);
    final photos   = List<Map<String, dynamic>>.from(_summary?['photos'] ?? []);
    final name = client['full_name'] ?? 'Client';
    final initials = name.split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: BackButton(onPressed: () => context.go('/coach')),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(AppConstants.primaryColor).withOpacity(0.1),
                      child: Text(initials,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                            color: Color(AppConstants.primaryColor))),
                    ),
                    const SizedBox(height: 10),
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('@${client['username'] ?? ''}',
                      style: const TextStyle(color: Color(AppConstants.textSecondary))),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoChip('⚖️', '${client['current_weight_kg'] ?? '--'} kg', 'Current'),
                        _infoChip('🎯', '${client['goal_weight_kg'] ?? '--'} kg', 'Goal'),
                        _infoChip('🏃', _capitalize(client['activity_level']), 'Activity'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(children: [
              Expanded(child: _actionBtn('Diet Plan', Icons.restaurant_menu,
                  Colors.orange, () => context.go('/coach/client/${widget.clientId}/diet'))),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('Workout', Icons.fitness_center,
                  Colors.green, () => context.go('/coach/client/${widget.clientId}/workout'))),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('Add Tip', Icons.lightbulb_outline,
                  Colors.amber, () => context.go('/coach/client/${widget.clientId}/tips'))),
            ]),
            const SizedBox(height: 14),

            // Profile details
            if (client['health_conditions'] != null ||
                client['injuries'] != null ||
                client['allergies'] != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Health Notes'),
                      const SizedBox(height: 10),
                      if (client['diet_preference'] != null)
                        _labelValue('Diet', _capitalize(client['diet_preference'])),
                      if (client['health_conditions'] != null)
                        _labelValue('Health', client['health_conditions']),
                      if (client['injuries'] != null)
                        _labelValue('Injuries', client['injuries']),
                      if (client['allergies'] != null)
                        _labelValue('Allergies', client['allergies']),
                      if (client['medications'] != null)
                        _labelValue('Medications', client['medications']),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // Body photos
            if (photos.isNotEmpty) ...[
              const SectionHeader(title: 'Body Photos'),
              const SizedBox(height: 10),
              Row(
                children: photos.map((p) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(p['s3_url'],
                            height: 110, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 110, color: Colors.grey.shade100,
                              child: const Icon(Icons.image_not_supported, color: Colors.grey))),
                        ),
                        const SizedBox(height: 4),
                        Text(_capitalize(p['photo_type']),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Recent tracking
            if (tracking.isNotEmpty) ...[
              SectionHeader(
                title: 'Recent Progress',
                action: Text('${tracking.length} entries',
                  style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13)),
              ),
              const SizedBox(height: 10),
              ...tracking.take(7).map((t) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(t['date'].toString().substring(0, 10),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      if (t['weight_kg'] != null) _trackChip('${t['weight_kg']}kg', Colors.purple),
                      if (t['steps'] != null) ...[
                        const SizedBox(width: 6),
                        _trackChip('${t['steps']} steps', Colors.green),
                      ],
                      if (t['mood'] != null) ...[
                        const SizedBox(width: 6),
                        _trackChip(t['mood'], Colors.orange),
                      ],
                    ],
                  ),
                ),
              )),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(AppConstants.textSecondary))),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: Text(value,
            style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13))),
        ],
      ),
    );
  }

  Widget _trackChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  String _capitalize(dynamic s) {
    if (s == null) return '--';
    return s.toString().replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
