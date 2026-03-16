// lib/models/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;

  User({required this.id, required this.username, required this.email,
        required this.fullName, required this.role});

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'], username: j['username'], email: j['email'],
    fullName: j['full_name'], role: j['role'],
  );

  bool get isCoach => role == 'coach';
}

// lib/models/daily_tracking.dart
class DailyTracking {
  final int? id;
  final int userId;
  final String date;
  final double? weightKg;
  final int? stressLevel;
  final double? waterIntakeLiters;
  final int? steps;
  final double? sleepHours;
  final String? mood;
  final String? deviationNotes;

  DailyTracking({this.id, required this.userId, required this.date,
    this.weightKg, this.stressLevel, this.waterIntakeLiters,
    this.steps, this.sleepHours, this.mood, this.deviationNotes});

  factory DailyTracking.fromJson(Map<String, dynamic> j) => DailyTracking(
    id: j['id'],
    userId: j['user_id'],
    date: j['date'],
    weightKg: j['weight_kg'] != null ? double.tryParse(j['weight_kg'].toString()) : null,
    stressLevel: j['stress_level'],
    waterIntakeLiters: j['water_intake_liters'] != null
        ? double.tryParse(j['water_intake_liters'].toString()) : null,
    steps: j['steps'],
    sleepHours: j['sleep_hours'] != null ? double.tryParse(j['sleep_hours'].toString()) : null,
    mood: j['mood'],
    deviationNotes: j['deviation_notes'],
  );
}

// lib/models/meal.dart
class Meal {
  final int id;
  final int userId;
  final String mealName;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  Meal({required this.id, required this.userId, required this.mealName,
        required this.caloriesPer100g, required this.proteinPer100g,
        required this.carbsPer100g, required this.fatPer100g});

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
    id: j['id'],
    userId: j['user_id'],
    mealName: j['meal_name'],
    caloriesPer100g: double.tryParse(j['calories_per_100g'].toString()) ?? 0,
    proteinPer100g:  double.tryParse(j['protein_per_100g'].toString()) ?? 0,
    carbsPer100g:    double.tryParse(j['carbs_per_100g'].toString()) ?? 0,
    fatPer100g:      double.tryParse(j['fat_per_100g'].toString()) ?? 0,
  );
}

// lib/models/diet_plan.dart
class DietPlanMeal {
  final String mealSlot;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  DietPlanMeal({required this.mealSlot, required this.calories,
                required this.proteinG, required this.carbsG, required this.fatG});

  factory DietPlanMeal.fromJson(Map<String, dynamic> j) => DietPlanMeal(
    mealSlot: j['meal_slot'],
    calories: double.tryParse(j['calories'].toString()) ?? 0,
    proteinG: double.tryParse(j['protein_g'].toString()) ?? 0,
    carbsG:   double.tryParse(j['carbs_g'].toString()) ?? 0,
    fatG:     double.tryParse(j['fat_g'].toString()) ?? 0,
  );
}

class DietPlan {
  final int id;
  final String planName;
  final List<DietPlanMeal> meals;

  DietPlan({required this.id, required this.planName, required this.meals});

  factory DietPlan.fromJson(Map<String, dynamic> j) => DietPlan(
    id: j['id'],
    planName: j['plan_name'],
    meals: (j['meals'] as List? ?? []).map((m) => DietPlanMeal.fromJson(m)).toList(),
  );

  double get totalCalories => meals.fold(0, (sum, m) => sum + m.calories);
  double get totalProtein  => meals.fold(0, (sum, m) => sum + m.proteinG);
  double get totalCarbs    => meals.fold(0, (sum, m) => sum + m.carbsG);
  double get totalFat      => meals.fold(0, (sum, m) => sum + m.fatG);
}

// lib/models/exercise.dart
class Exercise {
  final int id;
  final String exerciseName;
  final String muscleGroup;
  final String? description;
  final int defaultSets;
  final int defaultReps;

  Exercise({required this.id, required this.exerciseName, required this.muscleGroup,
            this.description, required this.defaultSets, required this.defaultReps});

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'],
    exerciseName: j['exercise_name'],
    muscleGroup:  j['muscle_group'],
    description:  j['description'],
    defaultSets:  j['default_sets'] ?? 3,
    defaultReps:  j['default_reps'] ?? 10,
  );
}

// lib/models/workout_plan.dart
class WorkoutExercise {
  final String exerciseName;
  final String muscleGroup;
  final int sets;
  final int reps;
  final String? notes;

  WorkoutExercise({required this.exerciseName, required this.muscleGroup,
                   required this.sets, required this.reps, this.notes});

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
    exerciseName: j['exercise_name'],
    muscleGroup:  j['muscle_group'],
    sets: j['sets'] ?? 3,
    reps: j['reps'] ?? 10,
    notes: j['notes'],
  );
}

class WorkoutPlan {
  final int id;
  final String planName;
  final List<WorkoutExercise> exercises;

  WorkoutPlan({required this.id, required this.planName, required this.exercises});

  factory WorkoutPlan.fromJson(Map<String, dynamic> j) => WorkoutPlan(
    id: j['id'],
    planName: j['plan_name'],
    exercises: (j['exercises'] as List? ?? []).map((e) => WorkoutExercise.fromJson(e)).toList(),
  );
}

// lib/models/tip.dart
class Tip {
  final int id;
  final String content;
  final String coachName;
  final String createdAt;

  Tip({required this.id, required this.content, required this.coachName, required this.createdAt});

  factory Tip.fromJson(Map<String, dynamic> j) => Tip(
    id: j['id'],
    content: j['content'],
    coachName: j['coach_name'] ?? 'Coach',
    createdAt: j['created_at'],
  );
}
