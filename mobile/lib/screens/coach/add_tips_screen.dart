// lib/screens/coach/add_tips_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class AddTipsScreen extends StatefulWidget {
  final int clientId;
  const AddTipsScreen({super.key, required this.clientId});

  @override
  State<AddTipsScreen> createState() => _AddTipsScreenState();
}

class _AddTipsScreenState extends State<AddTipsScreen> {
  final _api     = ApiService();
  final _tipCtrl = TextEditingController();
  List<Tip> _tips = [];
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/tips/get?user_id=${widget.clientId}');
      setState(() => _tips = (res['tips'] as List).map((t) => Tip.fromJson(t)).toList());
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _addTip() async {
    if (_tipCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _api.post('/tips/add', {
        'participant_id': widget.clientId,
        'content':        _tipCtrl.text.trim(),
      });
      _tipCtrl.clear();
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Tips'),
        leading: BackButton(onPressed: () => context.go('/coach/client/${widget.clientId}')),
      ),
      body: Column(
        children: [
          // Add tip input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add a note or tip for your client',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 10),
                TextField(
                  controller: _tipCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Great progress this week! Try adding 500 more steps daily. Focus on drinking water in the morning...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                LoadingButton(text: 'Post Tip', loading: _saving, onPressed: _addTip),
              ],
            ),
          ),

          // Existing tips
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tips.isEmpty
                    ? const EmptyState(
                        icon: Icons.lightbulb_outline,
                        message: 'No tips yet',
                        subtitle: 'Add your first tip for this client',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tips.length,
                        itemBuilder: (_, i) {
                          final t = _tips[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDate(t.createdAt),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(AppConstants.textSecondary)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(t.content,
                                    style: const TextStyle(fontSize: 14, height: 1.5)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }
}
