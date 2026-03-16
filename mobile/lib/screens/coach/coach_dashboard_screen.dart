// lib/screens/coach/coach_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});
  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/coach/clients');
      setState(() => _clients = List<Map<String, dynamic>>.from(res['clients']));
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showAddClientDialog() {
    final ctrl = TextEditingController();
    bool adding = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Client'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the participant\'s username to add them as your client.',
                style: TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g. john_doe',
                  prefixIcon: Icon(Icons.person_search),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: adding ? null : () async {
                if (ctrl.text.isEmpty) return;
                setDialogState(() => adding = true);
                try {
                  final res = await _api.post('/coach/clients/add',
                      {'participant_username': ctrl.text.trim()});
                  Navigator.pop(ctx);
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'Client added'),
                        backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())));
                }
                setDialogState(() => adding = false);
              },
              child: adding
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coach ${user.fullName.split(' ').first}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Client Dashboard',
              style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            context.read<AuthProvider>().logout();
            context.go('/login');
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _clients.isEmpty
                  ? const EmptyState(
                      icon: Icons.groups_outlined,
                      message: 'No clients yet',
                      subtitle: 'Tap "Add Client" to onboard\nyour first participant',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Stats row
                        Row(
                          children: [
                            Expanded(child: _statCard('${_clients.length}', 'Total Clients',
                                Icons.groups, Colors.blue)),
                            const SizedBox(width: 10),
                            Expanded(child: _statCard(
                              '${_clients.where((c) => c['last_tracked'] != null).length}',
                              'Tracking Active', Icons.check_circle_outline, Colors.green,
                            )),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SectionHeader(
                          title: 'Your Clients',
                          action: Text('${_clients.length} total',
                            style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13)),
                        ),
                        const SizedBox(height: 12),

                        ..._clients.map((c) => _clientCard(c)),
                      ],
                    ),
            ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(
                  fontSize: 11, color: Color(AppConstants.textSecondary))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clientCard(Map<String, dynamic> c) {
    final hasTracked = c['last_tracked'] != null;
    final initials = (c['full_name'] as String).split(' ')
        .take(2).map((w) => w[0]).join().toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/coach/client/${c['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(AppConstants.primaryColor).withOpacity(0.12),
                child: Text(initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor),
                  )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['full_name'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('@${c['username']}',
                      style: const TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
                    if (c['current_weight_kg'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _miniChip('${c['current_weight_kg']}kg', Colors.purple),
                          if (c['goal_weight_kg'] != null) ...[
                            const SizedBox(width: 6),
                            _miniChip('→ ${c['goal_weight_kg']}kg', Colors.green),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasTracked ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasTracked ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: hasTracked ? Colors.green.shade700 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
