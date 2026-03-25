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
  List<Map<String, dynamic>> _todayAppts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/coach/clients');
      setState(() => _clients = List<Map<String, dynamic>>.from(res['clients'] ?? []));
    } catch (_) {}
    try {
      final res = await _api.get('/appointments/today');
      setState(() => _todayAppts = List<Map<String, dynamic>>.from(res['appointments'] ?? []));
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddClientDialog(api: _api, onAdded: _load),
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
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Appointments',
            onPressed: () => context.go('/coach/appointments'),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
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
                        // Today's appointments
                        if (_todayAppts.isNotEmpty) ...[
                          const SectionHeader(title: "Today's Appointments"),
                          const SizedBox(height: 8),
                          ..._todayAppts.map(_todayApptCard),
                          const SizedBox(height: 20),
                        ],

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

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  String _apptTimeLabel(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  Widget _todayApptCard(Map<String, dynamic> a) {
    final timeStr = _apptTimeLabel(a['scheduled_at'] ?? '');
    final duration = a['duration_minutes'] ?? 30;
    final title = a['title'] ?? 'Connect';
    final clientName = a['other_name'] ?? 'Client';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/coach/appointments'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.video_call_outlined, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('$timeStr · ${duration}m · $clientName',
                      style: TextStyle(fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
                backgroundColor: const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

// ── Add Client Dialog ─────────────────────────────────────────────────────────

class _AddClientDialog extends StatefulWidget {
  final ApiService api;
  final VoidCallback onAdded;
  const _AddClientDialog({required this.api, required this.onAdded});

  @override
  State<_AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<_AddClientDialog> {
  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _filtered  = [];
  Map<String, dynamic>? _selected;
  bool _loading = true;
  bool _adding  = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await widget.api.get('/coach/clients/available');
      final list = List<Map<String, dynamic>>.from(res['clients'] ?? []);
      setState(() { _available = list; _filtered = list; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _available.where((c) =>
        (c['full_name'] as String).toLowerCase().contains(q) ||
        (c['username']  as String).toLowerCase().contains(q),
      ).toList();
    });
  }

  Future<void> _add() async {
    if (_selected == null) return;
    setState(() => _adding = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final res = await widget.api.post('/coach/clients/add',
          {'participant_username': _selected!['username']});
      nav.pop();
      widget.onAdded();
      messenger.showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Client added'),
            backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Client'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or username…',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No unassigned participants found',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final c = _filtered[i];
                          final sel = _selected?['id'] == c['id'];
                          return ListTile(
                            dense: true,
                            selected: sel,
                            selectedTileColor:
                                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
                              child: Text(
                                (c['full_name'] as String).split(' ').map((w) => w[0]).take(2).join().toUpperCase(),
                                style: const TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(AppConstants.primaryColor)),
                              ),
                            ),
                            title: Text(c['full_name'],
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text('@${c['username']}',
                                style: const TextStyle(fontSize: 11)),
                            trailing: sel ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : null,
                            onTap: () => setState(() => _selected = sel ? null : c),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selected == null || _adding) ? null : _add,
          child: _adding
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }
}
