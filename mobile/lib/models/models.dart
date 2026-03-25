// lib/models/models.dart

/// Extracts an 11-char YouTube video ID from a raw value that may be a full
/// URL (including Shorts), or already a bare ID.
String? parseYoutubeVideoId(String? raw) {
  if (raw == null) return null;
  raw = raw.trim();
  if (raw.isEmpty) return null;
  if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(raw)) return raw;
  final m = RegExp(r'(?:[?&]v=|youtu\.be/|embed/|shorts/)([a-zA-Z0-9_-]{11})')
      .firstMatch(raw);
  return m?.group(1);
}

class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  User({required this.id, required this.username, required this.email, required this.fullName, required this.role});
  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'], username: j['username'], email: j['email'],
    fullName: j['full_name'], role: j['role']);
  bool get isCoach => role == 'coach';
}

class DailyTracking {
  final int? id; final int userId; final String date;
  final double? weightKg; final int? stressLevel;
  final double? waterIntakeLiters; final int? steps;
  final double? sleepHours; final String? mood; final String? deviationNotes;
  DailyTracking({this.id, required this.userId, required this.date,
    this.weightKg, this.stressLevel, this.waterIntakeLiters,
    this.steps, this.sleepHours, this.mood, this.deviationNotes});
  factory DailyTracking.fromJson(Map<String, dynamic> j) => DailyTracking(
    id: j['id'], userId: j['user_id'], date: j['date'],
    weightKg: j['weight_kg'] != null ? double.tryParse(j['weight_kg'].toString()) : null,
    stressLevel: j['stress_level'],
    waterIntakeLiters: j['water_intake_liters'] != null ? double.tryParse(j['water_intake_liters'].toString()) : null,
    steps: j['steps'],
    sleepHours: j['sleep_hours'] != null ? double.tryParse(j['sleep_hours'].toString()) : null,
    mood: j['mood'], deviationNotes: j['deviation_notes']);
}

class Meal {
  final int id; final int userId; final String mealName;
  final double caloriesPer100g; final double proteinPer100g;
  final double carbsPer100g; final double fatPer100g;
  Meal({required this.id, required this.userId, required this.mealName,
    required this.caloriesPer100g, required this.proteinPer100g,
    required this.carbsPer100g, required this.fatPer100g});
  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
    id: j['id'], userId: j['user_id'], mealName: j['meal_name'],
    caloriesPer100g: double.tryParse(j['calories_per_100g'].toString()) ?? 0,
    proteinPer100g:  double.tryParse(j['protein_per_100g'].toString()) ?? 0,
    carbsPer100g:    double.tryParse(j['carbs_per_100g'].toString()) ?? 0,
    fatPer100g:      double.tryParse(j['fat_per_100g'].toString()) ?? 0);
}

class DietPlanMeal {
  final String mealSlot; final double calories;
  final double proteinG; final double carbsG; final double fatG;
  DietPlanMeal({required this.mealSlot, required this.calories,
    required this.proteinG, required this.carbsG, required this.fatG});
  factory DietPlanMeal.fromJson(Map<String, dynamic> j) => DietPlanMeal(
    mealSlot: j['meal_slot'],
    calories: double.tryParse(j['calories'].toString()) ?? 0,
    proteinG: double.tryParse(j['protein_g'].toString()) ?? 0,
    carbsG:   double.tryParse(j['carbs_g'].toString()) ?? 0,
    fatG:     double.tryParse(j['fat_g'].toString()) ?? 0);
}

class DietPlan {
  final int id; final String planName; final List<DietPlanMeal> meals;
  DietPlan({required this.id, required this.planName, required this.meals});
  factory DietPlan.fromJson(Map<String, dynamic> j) => DietPlan(
    id: j['id'], planName: j['plan_name'],
    meals: (j['meals'] as List? ?? []).map((m) => DietPlanMeal.fromJson(m)).toList());
  double get totalCalories => meals.fold(0, (s, m) => s + m.calories);
  double get totalProtein  => meals.fold(0, (s, m) => s + m.proteinG);
  double get totalCarbs    => meals.fold(0, (s, m) => s + m.carbsG);
  double get totalFat      => meals.fold(0, (s, m) => s + m.fatG);
}

class Exercise {
  final int id; final String exerciseName; final String muscleGroup;
  final String? description; final int defaultSets; final int defaultReps;
  final String? youtubeVideoId;
  Exercise({required this.id, required this.exerciseName, required this.muscleGroup,
    this.description, required this.defaultSets, required this.defaultReps,
    this.youtubeVideoId});
  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'], exerciseName: j['exercise_name'], muscleGroup: j['muscle_group'],
    description: j['description'], defaultSets: j['default_sets'] ?? 3,
    defaultReps: j['default_reps'] ?? 10,
    youtubeVideoId: parseYoutubeVideoId(j['youtube_video_id']));
}

class WorkoutDayExercise {
  final int exerciseId; final String exerciseName; final String muscleGroup;
  final int sets; final int reps; final String? notes;
  final String? youtubeVideoId;
  WorkoutDayExercise({required this.exerciseId, required this.exerciseName,
    required this.muscleGroup, required this.sets, required this.reps,
    this.notes, this.youtubeVideoId});
  factory WorkoutDayExercise.fromJson(Map<String, dynamic> j) => WorkoutDayExercise(
    exerciseId: j['exercise_id'] ?? j['id'],
    exerciseName: j['exercise_name'], muscleGroup: j['muscle_group'],
    sets: j['sets'] ?? 3, reps: j['reps'] ?? 10, notes: j['notes'],
    youtubeVideoId: parseYoutubeVideoId(j['youtube_video_id']));
}

class WorkoutDay {
  final int id; final int dayNumber; final String dayName;
  final List<WorkoutDayExercise> exercises;
  WorkoutDay({required this.id, required this.dayNumber,
    required this.dayName, required this.exercises});
  factory WorkoutDay.fromJson(Map<String, dynamic> j) => WorkoutDay(
    id: j['id'], dayNumber: j['day_number'], dayName: j['day_name'],
    exercises: (j['exercises'] as List? ?? [])
        .map((e) => WorkoutDayExercise.fromJson(e)).toList());
}

class WorkoutPlan {
  final int id; final String planName; final int totalDays;
  final List<WorkoutDay> days;
  // Keep exercises as flat list for backward compat
  List<WorkoutDayExercise> get exercises =>
      days.expand((d) => d.exercises).toList();
  WorkoutPlan({required this.id, required this.planName,
    required this.totalDays, required this.days});
  factory WorkoutPlan.fromJson(Map<String, dynamic> j) => WorkoutPlan(
    id: j['id'], planName: j['plan_name'],
    totalDays: j['total_days'] ?? 1,
    days: j['days'] != null
        ? (j['days'] as List).map((d) => WorkoutDay.fromJson(d)).toList()
        : j['exercises'] != null
            ? [WorkoutDay(id: 0, dayNumber: 1, dayName: 'Day 1',
                exercises: (j['exercises'] as List)
                    .map((e) => WorkoutDayExercise.fromJson(e)).toList())]
            : []);
}

class LifestyleItem {
  final int id; final String category; final String title;
  final String? targetValue; final String? unit; final String? notes;
  LifestyleItem({required this.id, required this.category, required this.title,
    this.targetValue, this.unit, this.notes});
  factory LifestyleItem.fromJson(Map<String, dynamic> j) => LifestyleItem(
    id: j['id'], category: j['category'], title: j['title'],
    targetValue: j['target_value'], unit: j['unit'], notes: j['notes']);
}

class LifestylePlan {
  final int id; final String planName; final List<LifestyleItem> items;
  LifestylePlan({required this.id, required this.planName, required this.items});
  factory LifestylePlan.fromJson(Map<String, dynamic> j) => LifestylePlan(
    id: j['id'], planName: j['plan_name'],
    items: (j['items'] as List? ?? []).map((i) => LifestyleItem.fromJson(i)).toList());
}

class Tip {
  final int id; final String content; final String coachName; final String createdAt;
  Tip({required this.id, required this.content, required this.coachName, required this.createdAt});
  factory Tip.fromJson(Map<String, dynamic> j) => Tip(
    id: j['id'], content: j['content'],
    coachName: j['coach_name'] ?? 'Coach', createdAt: j['created_at']);
}

class WorkoutSetLog {
  final int sessionId;
  final int exerciseId;
  final String exerciseName;
  final int setNumber;
  final int? repsDone;
  final double? weightKg; // null = bodyweight
  WorkoutSetLog({required this.sessionId, required this.exerciseId,
    required this.exerciseName, required this.setNumber,
    this.repsDone, this.weightKg});
  factory WorkoutSetLog.fromJson(Map<String, dynamic> j) => WorkoutSetLog(
    sessionId: j['session_id'], exerciseId: j['exercise_id'],
    exerciseName: j['exercise_name'], setNumber: j['set_number'],
    repsDone: j['reps_done'],
    weightKg: j['weight_kg'] != null ? double.tryParse(j['weight_kg'].toString()) : null);
}

class WorkoutSession {
  final int id;
  final String? dayName;
  final DateTime completedAt;
  final List<WorkoutSetLog> logs;
  WorkoutSession({required this.id, this.dayName, required this.completedAt, required this.logs});
  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
    id: j['id'], dayName: j['day_name'],
    completedAt: DateTime.parse(j['completed_at']),
    logs: (j['logs'] as List? ?? []).map((l) => WorkoutSetLog.fromJson(l)).toList());
}

// Health goals
const List<Map<String, String>> healthGoals = [
  {'key': 'lose_weight',       'label': 'Lose Weight'},
  {'key': 'build_muscle',      'label': 'Build Muscle'},
  {'key': 'stay_fit',          'label': 'Stay Fit'},
  {'key': 'reverse_diabetes',  'label': 'Reverse Diabetes'},
  {'key': 'healthy_lifestyle', 'label': 'Healthy Lifestyle'},
  {'key': 'improve_stamina',   'label': 'Improve Stamina'},
  {'key': 'stress_management', 'label': 'Stress Management'},
];

// Lifestyle categories
const List<Map<String, dynamic>> lifestyleCategories = [
  {'key': 'steps',       'label': 'Daily Steps',      'unit': 'steps/day',  'default': '8000'},
  {'key': 'water',       'label': 'Water Intake',     'unit': 'litres/day', 'default': '3'},
  {'key': 'sleep',       'label': 'Sleep Target',     'unit': 'hours',      'default': '8'},
  {'key': 'screen_time', 'label': 'Screen Time Limit','unit': 'hours/day',  'default': '2'},
  {'key': 'meditation',  'label': 'Meditation',       'unit': 'mins/day',   'default': '10'},
  {'key': 'sunlight',    'label': 'Sunlight Exposure','unit': 'mins/day',   'default': '20'},
  {'key': 'no_sugar',    'label': 'No Added Sugar',   'unit': null,         'default': null},
  {'key': 'no_alcohol',  'label': 'No Alcohol',       'unit': null,         'default': null},
  {'key': 'meal_timing', 'label': 'Meal Timing',      'unit': null,         'default': '7am / 1pm / 4pm / 8pm'},
  {'key': 'custom',      'label': 'Custom',           'unit': null,         'default': null},
];

// ── Food Log Models ───────────────────────────────────────────────────────────

class ServingSize {
  final String label;
  final double grams;
  const ServingSize({required this.label, required this.grams});
  Map<String, dynamic> toJson() => {'label': label, 'grams': grams};
}

class FoodItem {
  final String id;
  final String name;
  final String nameHi;
  final double caloriesPer100g;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final List<ServingSize> servings;
  final String source; // 'local', 'fatsecret', 'custom'

  const FoodItem({
    required this.id,
    required this.name,
    required this.nameHi,
    required this.caloriesPer100g,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.servings,
    this.source = 'local',
  });

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
    id: j['id']?.toString() ?? '',
    name: j['name'] ?? '',
    nameHi: j['name_hi'] ?? '',
    caloriesPer100g: double.tryParse(j['calories_per_100g'].toString()) ?? 0,
    proteinG:  double.tryParse(j['protein_g'].toString()) ?? 0,
    carbsG:    double.tryParse(j['carbs_g'].toString()) ?? 0,
    fatG:      double.tryParse(j['fat_g'].toString()) ?? 0,
    fiberG:    double.tryParse(j['fiber_g'].toString()) ?? 0,
    servings: (j['servings'] as List? ?? []).map((s) => ServingSize(
      label: s['label'] ?? '',
      grams: double.tryParse(s['grams'].toString()) ?? 100,
    )).toList(),
    source: j['source'] ?? 'fatsecret',
  );

  Map<String, double> nutrientsFor(double grams) {
    final r = grams / 100;
    return {
      'calories':  caloriesPer100g * r,
      'protein_g': proteinG * r,
      'carbs_g':   carbsG * r,
      'fat_g':     fatG * r,
      'fiber_g':   fiberG * r,
    };
  }

  // Default serving is first in list, or 100g
  ServingSize get defaultServing =>
      servings.isNotEmpty ? servings.first : const ServingSize(label: '100g', grams: 100);
}

class MealLogEntry {
  final int id;
  final String foodName;
  final String? foodNameHi;
  final String servingLabel;
  final double servingGrams;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final String mealSlot;
  final DateTime loggedAt;

  MealLogEntry({
    required this.id,
    required this.foodName,
    this.foodNameHi,
    required this.servingLabel,
    required this.servingGrams,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.mealSlot,
    required this.loggedAt,
  });

  factory MealLogEntry.fromJson(Map<String, dynamic> j) => MealLogEntry(
    id: j['id'],
    foodName: j['food_name'],
    foodNameHi: j['food_name_hi'],
    servingLabel: j['serving_label'] ?? '100g',
    servingGrams: double.tryParse(j['serving_grams'].toString()) ?? 100,
    calories: double.tryParse(j['calories'].toString()) ?? 0,
    proteinG: double.tryParse(j['protein_g'].toString()) ?? 0,
    carbsG:   double.tryParse(j['carbs_g'].toString()) ?? 0,
    fatG:     double.tryParse(j['fat_g'].toString()) ?? 0,
    fiberG:   double.tryParse(j['fiber_g'].toString()) ?? 0,
    mealSlot: j['meal_slot'] ?? 'other',
    loggedAt: DateTime.parse(j['created_at']),
  );
}
