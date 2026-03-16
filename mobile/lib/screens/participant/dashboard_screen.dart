// lib/screens/participant/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  DailyTracking? _today;
  DietPlan? _dietPlan;
  List<Tip> _tips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.get('/tracking/today'),
        _api.get('/diet/get'),
        _api.get('/tips/get'),
      ]);

      setState(() {
        _today = results[0]['tracking'] != null
            ? DailyTracking.fromJson(results[0]['tracking']) : null;
        _dietPlan = results[1]['diet_plan'] != null
            ? DietPlan.fromJson(results[1]['diet_plan']) : null;
        _tips = (results[2]['tips'] as List? ?? []).map((t) => Tip.fromJson(t)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${user.fullName.split(' ').first} 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Track your progress today',
              style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Today's Stats
                  const SectionHeader(title: "Today's Stats"),
                  const SizedBox(height: 12),
                  _today != null ? _todayStats() : _noTrackingCard(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  _quickActions(context),
                  const SizedBox(height: 24),

                  // Diet Plan Summary
                  if (_dietPlan != null) ...[
                    SectionHeader(
                      title: "Today's Macros",
                      action: TextButton(
                        onPressed: () => context.go('/meals/calculator'),
                        child: const Text('Calculator'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _dietSummary(),
                    const SizedBox(height: 24),
                  ],

                  // Coach Tips
                  if (_tips.isNotEmpty) ...[
                    const SectionHeader(title: 'Coach Tips'),
                    const SizedBox(height: 12),
                    ..._tips.take(3).map(_tipCard),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _todayStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatCard(
          label: 'Weight', icon: Icons.monitor_weight_outlined,
          value: _today?.weightKg?.toStringAsFixed(1) ?? '--',
          unit: 'kg', iconColor: Colors.purple,
        ),
        StatCard(
          label: 'Steps', icon: Icons.directions_walk,
          value: _today?.steps?.toString() ?? '--',
          iconColor: Colors.green,
        ),
        StatCard(
          label: 'Water', icon: Icons.water_drop_outlined,
          value: _today?.waterIntakeLiters?.toStringAsFixed(1) ?? '--',
          unit: 'L', iconColor: Colors.blue,
        ),
        StatCard(
          label: 'Sleep', icon: Icons.bedtime_outlined,
          value: _today?.sleepHours?.toStringAsFixed(1) ?? '--',
          unit: 'hrs', iconColor: Colors.indigo,
        ),
      ],
    );
  }

  Widget _noTrackingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_note, color: Colors.orange.shade700),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("No data yet today",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text("Log your daily metrics to track progress",
                    style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    final actions = [
      ('Log Today', Icons.add_circle_outline,  Colors.blue,   '/tracking'),
      ('My Meals',  Icons.restaurant_menu,      Colors.orange, '/meals'),
      ('Workout',   Icons.fitness_center,        Colors.green,  '/workout'),
      ('Progress',  Icons.show_chart,            Colors.purple, '/progress'),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      children: actions.map((a) {
        final (label, icon, color, route) = a;
        return GestureDetector(
          onTap: () => context.go(route),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _dietSummary() {
    final plan = _dietPlan!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Targets',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text('${plan.totalCalories.toStringAsFixed(0)} kcal total',
                  style: const TextStyle(
                    color: Color(AppConstants.primaryColor), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MacroChip(label: 'Protein', value: '${plan.totalProtein.toStringAsFixed(0)}g', color: Colors.blue),
                MacroChip(label: 'Carbs',   value: '${plan.totalCarbs.toStringAsFixed(0)}g',   color: Colors.orange),
                MacroChip(label: 'Fat',     value: '${plan.totalFat.toStringAsFixed(0)}g',     color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(Tip tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text('From ${tip.coachName}',
                  style: const TextStyle(fontSize: 12, color: Color(AppConstants.textSecondary))),
              ],
            ),
            const SizedBox(height: 6),
            Text(tip.content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        const routes = ['/dashboard', '/tracking', '/meals', '/workout'];
        context.go(routes[i]);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.edit_note), label: 'Track'),
        NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Meals'),
        NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Workout'),
      ],
    );
  }
}
