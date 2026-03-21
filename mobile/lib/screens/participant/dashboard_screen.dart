// lib/screens/participant/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
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

  DailyTracking?       _today;
  DietPlan?            _dietPlan;
  WorkoutPlan?         _workoutPlan;
  LifestylePlan?       _lifestylePlan;
  Map<String, dynamic>? _profileData;
  List<Tip>            _tips            = [];
  int?                 _nextDayIndex;   // suggested next workout day
  bool                 _workoutDoneToday = false;
  bool                 _loading         = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.get('/tracking/today'),
        _api.get('/diet/get'),
        _api.get('/tips/get'),
        _api.get('/lifestyle/get'),
        _api.get('/workout/get'),
        _api.get('/profile/get'),
      ]);

      WorkoutPlan? plan;
      if (results[4]['workout_plan'] != null) {
        plan = WorkoutPlan.fromJson(results[4]['workout_plan']);
      }

      int? nextDay;
      if (plan != null) {
        nextDay = await _resolveNextDay(plan);
      }

      setState(() {
        _today = results[0]['tracking'] != null
            ? DailyTracking.fromJson(results[0]['tracking']) : null;
        _dietPlan = results[1]['diet_plan'] != null
            ? DietPlan.fromJson(results[1]['diet_plan']) : null;
        _tips = (results[2]['tips'] as List? ?? []).map((t) => Tip.fromJson(t)).toList();
        _lifestylePlan = results[3]['lifestyle_plan'] != null
            ? LifestylePlan.fromJson(results[3]['lifestyle_plan']) : null;
        _workoutPlan  = plan;
        _nextDayIndex = nextDay;
        _profileData  = results[5]['profile'] as Map<String, dynamic>?;
        _loading      = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  /// Reads SharedPreferences to find the most recently completed workout day,
  /// returns the index of the *next* one (wraps around).
  /// Also sets [_workoutDoneToday] if any day was completed today.
  Future<int?> _resolveNextDay(WorkoutPlan plan) async {
    if (plan.days.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    DateTime? latest;
    int latestIdx = -1;
    bool doneToday = false;
    for (int i = 0; i < plan.days.length; i++) {
      final str = prefs.getString('workout_${plan.id}_day${i}_lastdone');
      if (str != null) {
        final d = DateTime.tryParse(str);
        if (d != null) {
          if (d.year == today.year && d.month == today.month && d.day == today.day) {
            doneToday = true;
          }
          if (latest == null || d.isAfter(latest)) {
            latest = d;
            latestIdx = i;
          }
        }
      }
    }
    _workoutDoneToday = doneToday;
    if (latestIdx == -1) return 0;
    return (latestIdx + 1) % plan.days.length;
  }

  // ── Profile completeness ──────────────────────────────────────────────────

  /// Returns a list of (label, icon) for every missing onboarding field group.
  List<({String label, IconData icon})> _profileActionItems() {
    final p = _profileData;
    // No profile at all
    if (p == null) {
      return [
        (label: 'Fill in your basic details', icon: Icons.person_outline),
        (label: 'Set your health goal', icon: Icons.track_changes),
        (label: 'Add your diet preference', icon: Icons.restaurant_menu),
        (label: 'Describe your eating habits', icon: Icons.dining),
        (label: 'Add activity & workout info', icon: Icons.fitness_center),
        (label: 'Add lifestyle baselines', icon: Icons.bedtime_outlined),
      ];
    }

    final missing = <({String label, IconData icon})>[];

    // Basic info
    if (p['height_cm'] == null || p['current_weight_kg'] == null ||
        p['goal_weight_kg'] == null || p['dob'] == null || p['gender'] == null) {
      missing.add((label: 'Complete basic details (height, weight, DOB)', icon: Icons.person_outline));
    }

    // Health goal
    if (p['health_goal'] == null) {
      missing.add((label: 'Set your health goal', icon: Icons.track_changes));
    }

    // Diet preference
    if (p['diet_preference'] == null) {
      missing.add((label: 'Add your diet preference', icon: Icons.restaurant_menu));
    }

    // Eating habits
    if (p['meals_per_day'] == null || p['typical_breakfast'] == null) {
      missing.add((label: 'Describe your typical meals', icon: Icons.dining));
    }

    // Eating out
    if (p['eating_out_frequency'] == null) {
      missing.add((label: 'Add eating out habits', icon: Icons.local_dining));
    }

    // Activity
    if (p['currently_workout'] == null) {
      missing.add((label: 'Add activity & workout info', icon: Icons.fitness_center));
    }

    // Lifestyle baselines
    if (p['typical_sleep_hours'] == null || p['typical_daily_steps'] == null ||
        p['typical_stress_level'] == null) {
      missing.add((label: 'Add lifestyle baselines (sleep, steps, stress)', icon: Icons.bedtime_outlined));
    }

    return missing;
  }

  Widget _profileActionItemsCard(BuildContext context) {
    final items = _profileActionItems();
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Help your coach personalise your plan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final item = e.value;
              return Column(
                children: [
                  InkWell(
                    onTap: () => context.go('/profile'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 18,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.label,
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Icon(Icons.chevron_right, size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 46),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user        = context.read<AuthProvider>().user!;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${user.fullName.split(' ').first}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Track your progress today',
              style: TextStyle(fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: themeProvider.isDark ? 'Light mode' : 'Dark mode',
            onPressed: themeProvider.toggle,
          ),
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
                  // Profile Action Items
                  if (_profileActionItems().isNotEmpty) ...[
                    const SectionHeader(title: 'Complete Your Profile'),
                    const SizedBox(height: 12),
                    _profileActionItemsCard(context),
                    const SizedBox(height: 24),
                  ],

                  // Today's Goals — moved to top for quick daily check-off
                  if (_workoutPlan != null || _lifestylePlan != null) ...[
                    SectionHeader(
                      title: "Today's Goals",
                      action: TextButton(
                        onPressed: () => context.go('/tracking'),
                        child: const Text('Log Today'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _todayGoals(context),
                    const SizedBox(height: 24),
                  ],

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

                  // Diet Plan – per meal
                  if (_dietPlan != null) ...[
                    SectionHeader(
                      title: "Today's Meals",
                      action: TextButton(
                        onPressed: () => context.go('/meals/calculator'),
                        child: const Text('Calculator'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _dietPerMeal(),
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

  // ── Today's stats grid ────────────────────────────────────────────────────

  Widget _todayStats() {
    return GridView.custom(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 72,
      ),
      childrenDelegate: SliverChildListDelegate([
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
      ]),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("No data yet today",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text("Log your daily metrics to track progress",
                    style: TextStyle(fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _quickActions(BuildContext context) {
    final actions = [
      ('Log Today', Icons.add_circle_outline,  Colors.blue,   '/tracking'),
      ('My Meals',  Icons.restaurant_menu,      Colors.orange, '/meals'),
      ('Workout',   Icons.fitness_center,        Colors.green,  '/workout'),
      ('Progress',  Icons.show_chart,            Colors.purple, '/progress'),
    ];

    return GridView.custom(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisExtent: 90,
      ),
      childrenDelegate: SliverChildListDelegate(actions.map((a) {
        final (label, icon, color, route) = a;
        return GestureDetector(
          onTap: () => context.go(route),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
      }).toList()),
    );
  }

  // ── Today's Goals — compact checkbox cards ────────────────────────────────

  Widget _todayGoals(BuildContext context) {
    final items = <({
      IconData icon,
      Color color,
      String title,
      String target,
      bool done,
      String route,
    })>[];

    // Workout
    if (_workoutPlan != null && _nextDayIndex != null) {
      final day = _workoutPlan!.days[_nextDayIndex!];
      items.add((
        icon: Icons.fitness_center,
        color: Colors.green,
        title: day.dayName,
        target: '${day.exercises.length} exercises',
        done: _workoutDoneToday,
        route: '/workout',
      ));
    }

    // Lifestyle plan items
    if (_lifestylePlan != null) {
      for (final item in _lifestylePlan!.items) {
        final targetStr = item.targetValue != null
            ? '${item.targetValue}${item.unit != null ? ' ${item.unit}' : ''}'
            : '';

        // Auto-check based on today's logged data vs target
        bool done = false;
        final target = double.tryParse(item.targetValue ?? '');
        if (item.category == 'steps' && target != null) {
          done = (_today?.steps ?? 0) >= target;
        } else if (item.category == 'water' && target != null) {
          done = (_today?.waterIntakeLiters ?? 0) >= target;
        } else if (item.category == 'sleep' && target != null) {
          done = (_today?.sleepHours ?? 0) >= target;
        } else if (_today != null) {
          // For non-numeric goals, mark done if user has logged today at all
          done = item.category == 'meditation' || item.category == 'sunlight'
              ? false // can't auto-check these
              : false;
        }

        IconData icon = Icons.check_circle_outline;
        Color color = Colors.teal;
        if (item.category == 'steps')       { icon = Icons.directions_walk;      color = Colors.green; }
        else if (item.category == 'water')  { icon = Icons.water_drop_outlined;  color = Colors.blue; }
        else if (item.category == 'sleep')  { icon = Icons.bedtime_outlined;     color = Colors.indigo; }
        else if (item.category == 'meditation') { icon = Icons.self_improvement; color = Colors.purple; }
        else if (item.category == 'screen_time') { icon = Icons.phone_android_outlined; color = Colors.orange; }
        else if (item.category == 'sunlight') { icon = Icons.wb_sunny_outlined;  color = Colors.amber; }

        items.add((
          icon: icon,
          color: color,
          title: item.title,
          target: targetStr,
          done: done,
          route: '/tracking',
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => context.go(item.route),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  // Checkbox circle
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: item.done
                          ? item.color.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.done ? Icons.check_rounded : item.icon,
                      size: 17,
                      color: item.done ? item.color : item.color.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13,
                            decoration: item.done ? TextDecoration.lineThrough : null,
                            color: item.done
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)
                                : null,
                          )),
                        if (item.target.isNotEmpty)
                          Text(item.target,
                            style: TextStyle(fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  Icon(
                    item.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: item.done ? item.color : Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Diet per meal ─────────────────────────────────────────────────────────

  Widget _dietPerMeal() {
    final plan = _dietPlan!;
    const slotIcons = {
      'breakfast': (Icons.wb_sunny_outlined,    Colors.orange),
      'lunch':     (Icons.restaurant,            Colors.blue),
      'snack':     (Icons.apple,                 Colors.green),
      'dinner':    (Icons.nights_stay_outlined,  Colors.indigo),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Meal Targets',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text('${plan.totalCalories.toStringAsFixed(0)} kcal total',
                  style: const TextStyle(
                    color: Color(AppConstants.primaryColor), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 14),
            ...plan.meals.asMap().entries.map((entry) {
              final i    = entry.key;
              final meal = entry.value;
              final slot = meal.mealSlot;
              final (icon, color) = slotIcons[slot] ?? (Icons.restaurant, Colors.grey);
              final title = slot[0].toUpperCase() + slot.substring(1);
              final isLast = i == plan.meals.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('${meal.calories.toStringAsFixed(0)} kcal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'P: ${meal.proteinG.toStringAsFixed(0)}g  ·  C: ${meal.carbsG.toStringAsFixed(0)}g  ·  F: ${meal.fatG.toStringAsFixed(0)}g',
                              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Tips ──────────────────────────────────────────────────────────────────

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
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
            const SizedBox(height: 6),
            Text(tip.content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

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
