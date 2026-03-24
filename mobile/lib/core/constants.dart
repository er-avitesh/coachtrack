// lib/core/constants.dart

class AppConstants {
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:3000/api');
  static const String version = String.fromEnvironment('BUILD_NUMBER', defaultValue: 'dev');

  // Storage keys
  static const String tokenKey    = 'auth_token';
  static const String userKey     = 'user_data';
  static const String roleKey     = 'user_role';

  // App theme colors
  static const int primaryColor   = 0xFF2563EB;  // Blue
  static const int secondaryColor = 0xFF10B981;  // Green
  static const int bgColor        = 0xFFF8FAFC;
  static const int cardColor      = 0xFFFFFFFF;
  static const int textPrimary    = 0xFF1E293B;
  static const int textSecondary  = 0xFF64748B;

  // Meal slots
  static const List<String> mealSlots = ['breakfast', 'lunch', 'snack', 'dinner'];

  // Mood options
  static const List<String> moods = ['Great', 'Good', 'Okay', 'Tired', 'Stressed', 'Bad'];
}
