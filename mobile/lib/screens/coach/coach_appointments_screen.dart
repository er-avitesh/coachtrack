import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants.dart';

class CoachAppointmentsScreen extends StatefulWidget {
  const CoachAppointmentsScreen({super.key});
  @override
  State<CoachAppointmentsScreen> createState() => _CoachAppointmentsScreenState();
}

class _CoachAppointmentsScreenState extends State<CoachAppointmentsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _clients = [];
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
      final res = await _api.get('/appointments');
      setState(() => _appointments = List<Map<String, dynamic>>.from(res['appointments'] ?? []));
    } catch (_) {}
    setState(() => _loading = false);
  }

  // ── Setup weekly series dialog ─────────────────────────────────────────
  void _showSetupSeriesDialog({Map<String, dynamic>? existing, required Map<String, dynamic> client}) {
    String selectedTitle = existing?['title'] ?? 'Weekly Connect';
    int selectedDay  = existing?['day_of_week'] ?? 1; // Monday
    TimeOfDay selectedTime = existing != null
        ? _parseTime(existing['time_of_day'])
        : const TimeOfDay(hour: 10, minute: 0);
    int duration = existing?['duration_minutes'] ?? 30;
    bool saving = false;

    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing != null ? 'Reschedule Series' : 'Set Weekly Connect'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Client: ${client['full_name']}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedTitle,
                decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                items: const [
                  DropdownMenuItem(value: 'Weekly Connect', child: Text('Weekly Connect')),
                  DropdownMenuItem(value: 'Ad-hoc Call',    child: Text('Ad-hoc Call')),
                ],
                onChanged: (v) => setS(() => selectedTitle = v!),
              ),
              const SizedBox(height: 14),
              const Align(alignment: Alignment.centerLeft,
                child: Text('Day of week', style: TextStyle(fontSize: 12, color: Colors.grey))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) => ChoiceChip(
                  label: Text(days[i]),
                  selected: selectedDay == i,
                  onSelected: (_) => setS(() => selectedDay = i),
                )),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text('Time: ${selectedTime.format(ctx)}'),
                trailing: const Icon(Icons.edit, size: 16),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setS(() => selectedTime = t);
                },
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Duration: '),
                DropdownButton<int>(
                  value: duration,
                  items: [15, 30, 45, 60].map((v) => DropdownMenuItem(
                    value: v, child: Text('$v min'))).toList(),
                  onChanged: (v) => setS(() => duration = v!),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setS(() => saving = true);
                try {
                  final timeStr = '${selectedTime.hour.toString().padLeft(2,'0')}:${selectedTime.minute.toString().padLeft(2,'0')}';
                  if (existing != null) {
                    await _api.patch('/appointments/series/${existing['series_id']}', {
                      'title': selectedTitle,
                      'day_of_week': selectedDay,
                      'time_of_day': timeStr,
                      'duration_minutes': duration,
                    });
                  } else {
                    await _api.post('/appointments/series', {
                      'client_id': client['id'],
                      'title': selectedTitle,
                      'day_of_week': selectedDay,
                      'time_of_day': timeStr,
                      'duration_minutes': duration,
                    });
                  }
                  Navigator.pop(ctx);
                  _load();
                  _showSnack(existing != null ? 'Series rescheduled' : 'Weekly connect set up', Colors.green);
                } catch (e) {
                  _showSnack(e.toString(), Colors.red);
                }
                setS(() => saving = false);
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(existing != null ? 'Reschedule' : 'Set Up'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Adhoc call dialog ──────────────────────────────────────────────────
  void _showAdhocDialog() {
    if (_clients.isEmpty) {
      _showSnack('No clients yet', Colors.orange);
      return;
    }
    int? selectedClientId = _clients.first['id'];
    String selectedTitle = 'Ad-hoc Call';
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay(hour: selectedDate.hour, minute: 0);
    int duration = 30;
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Schedule Ad-hoc Call'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                value: selectedClientId,
                decoration: const InputDecoration(labelText: 'Client', prefixIcon: Icon(Icons.person)),
                items: _clients.map((c) => DropdownMenuItem(
                  value: c['id'] as int,
                  child: Text(c['full_name']),
                )).toList(),
                onChanged: (v) => setS(() => selectedClientId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTitle,
                decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                items: const [
                  DropdownMenuItem(value: 'Ad-hoc Call',    child: Text('Ad-hoc Call')),
                  DropdownMenuItem(value: 'Weekly Connect', child: Text('Weekly Connect')),
                ],
                onChanged: (v) => setS(() => selectedTitle = v!),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('EEE, MMM d').format(selectedDate)),
                trailing: const Icon(Icons.edit, size: 16),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setS(() => selectedDate = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text('Time: ${selectedTime.format(ctx)}'),
                trailing: const Icon(Icons.edit, size: 16),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setS(() => selectedTime = t);
                },
              ),
              Row(children: [
                const Text('Duration: '),
                DropdownButton<int>(
                  value: duration,
                  items: [15, 30, 45, 60].map((v) => DropdownMenuItem(
                    value: v, child: Text('$v min'))).toList(),
                  onChanged: (v) => setS(() => duration = v!),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes)),
                maxLines: 2,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setS(() => saving = true);
                try {
                  final dt = DateTime(selectedDate.year, selectedDate.month,
                      selectedDate.day, selectedTime.hour, selectedTime.minute);
                  await _api.post('/appointments/adhoc', {
                    'client_id': selectedClientId,
                    'title': selectedTitle,
                    'scheduled_at': dt.toIso8601String(),
                    'duration_minutes': duration,
                    if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text,
                  });
                  Navigator.pop(ctx);
                  _load();
                  _showSnack('Ad-hoc call scheduled', Colors.green);
                } catch (e) {
                  _showSnack(e.toString(), Colors.red);
                }
                setS(() => saving = false);
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reschedule single appointment ─────────────────────────────────────
  void _showRescheduleDialog(Map<String, dynamic> appt) {
    final original = DateTime.parse(appt['scheduled_at']);
    DateTime selectedDate = original;
    TimeOfDay selectedTime = TimeOfDay(hour: original.hour, minute: original.minute);
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Reschedule Appointment'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(appt['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('with ${appt['other_name']}',
              style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('EEE, MMM d').format(selectedDate)),
              trailing: const Icon(Icons.edit, size: 16),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setS(() => selectedDate = d);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text('Time: ${selectedTime.format(ctx)}'),
              trailing: const Icon(Icons.edit, size: 16),
              onTap: () async {
                final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                if (t != null) setS(() => selectedTime = t);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                setS(() => saving = true);
                try {
                  final dt = DateTime(selectedDate.year, selectedDate.month,
                      selectedDate.day, selectedTime.hour, selectedTime.minute);
                  await _api.patch('/appointments/${appt['id']}', {
                    'scheduled_at': dt.toIso8601String(),
                  });
                  Navigator.pop(ctx);
                  _load();
                  _showSnack('Appointment rescheduled', Colors.green);
                } catch (e) {
                  _showSnack(e.toString(), Colors.red);
                }
                setS(() => saving = false);
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Reschedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text('Cancel "${appt['title']}" with ${appt['other_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel it', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.delete('/appointments/${appt['id']}');
        _load();
        _showSnack('Appointment cancelled', Colors.orange);
      } catch (e) {
        _showSnack(e.toString(), Colors.red);
      }
    }
  }

  // ── Client picker for weekly series ───────────────────────────────────
  void _showClientPickerForSeries() {
    if (_clients.isEmpty) {
      _showSnack('No clients yet', Colors.orange);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select client for weekly connect',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ..._clients.map((c) => ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
              child: Text(
                (c['full_name'] as String).split(' ').take(2).map((w) => w[0]).join().toUpperCase(),
                style: const TextStyle(color: Color(AppConstants.primaryColor), fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(c['full_name']),
            subtitle: Text('@${c['username']}'),
            onTap: () {
              Navigator.pop(context);
              _showSetupSeriesDialog(client: c);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color));
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // ── Group appointments by date ─────────────────────────────────────────
  Map<String, List<Map<String, dynamic>>> _grouped() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final a in _appointments) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime.parse(a['scheduled_at']).toLocal());
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();
    final dates = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call_outlined),
            tooltip: 'Ad-hoc call',
            onPressed: _showAdhocDialog,
          ),
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: 'Set weekly connect',
            onPressed: _showClientPickerForSeries,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dates.length,
                    itemBuilder: (_, i) {
                      final date = DateTime.parse(dates[i]);
                      final items = grouped[dates[i]]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dateHeader(date),
                          ...items.map((a) => _appointmentCard(a)),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _dateHeader(DateTime date) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isToday
                ? const Color(AppConstants.primaryColor)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isToday ? 'Today' : DateFormat('EEE, MMM d').format(date),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isToday ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> a) {
    final dt = DateTime.parse(a['scheduled_at']).toLocal();
    final isRecurring = a['type'] == 'recurring';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isRecurring
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Icon(isRecurring ? Icons.repeat : Icons.video_call,
                size: 18,
                color: isRecurring ? Colors.blue : Colors.purple),
              const SizedBox(height: 2),
              Text(DateFormat('HH:mm').format(dt),
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: isRecurring ? Colors.blue : Colors.purple,
                )),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('with ${a['other_name']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${a['duration_minutes']} min',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'reschedule') _showRescheduleDialog(a);
              if (v == 'cancel') _cancelAppointment(a);
              if (v == 'reschedule_series' && a['series_id'] != null) {
                final client = _clients.firstWhere(
                  (c) => c['id'] == a['client_id'], orElse: () => {});
                if (client.isNotEmpty) {
                  _showSetupSeriesDialog(
                    existing: {...a, 'series_id': a['series_id']},
                    client: client,
                  );
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'reschedule',
                child: ListTile(leading: Icon(Icons.edit_calendar), title: Text('Reschedule this'))),
              if (isRecurring)
                const PopupMenuItem(value: 'reschedule_series',
                  child: ListTile(leading: Icon(Icons.repeat_one), title: Text('Reschedule series'))),
              const PopupMenuItem(value: 'cancel',
                child: ListTile(leading: Icon(Icons.cancel_outlined, color: Colors.red),
                  title: Text('Cancel', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      const Text('No upcoming appointments',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      const Text('Tap the icons above to set up a\nweekly connect or ad-hoc call',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey)),
    ]),
  );
}
