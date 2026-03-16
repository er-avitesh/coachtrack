-- ============================================
-- CoachTrack Database Schema
-- PostgreSQL
-- ============================================

-- USERS
CREATE TABLE users (
  id          SERIAL PRIMARY KEY,
  username    VARCHAR(100) UNIQUE NOT NULL,
  email       VARCHAR(255) UNIQUE NOT NULL,
  password    VARCHAR(255) NOT NULL,         -- bcrypt hashed
  role        VARCHAR(20) NOT NULL CHECK (role IN ('coach', 'participant')),
  full_name   VARCHAR(255) NOT NULL,
  created_at  TIMESTAMP DEFAULT NOW(),
  updated_at  TIMESTAMP DEFAULT NOW()
);

-- COACH → CLIENT RELATIONSHIP
CREATE TABLE coach_clients (
  id             SERIAL PRIMARY KEY,
  coach_id       INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  participant_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at     TIMESTAMP DEFAULT NOW(),
  UNIQUE(coach_id, participant_id)
);

-- CLIENT INTAKE PROFILE
CREATE TABLE profiles (
  id                    SERIAL PRIMARY KEY,
  user_id               INT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  dob                   DATE,
  gender                VARCHAR(20) CHECK (gender IN ('male', 'female', 'other')),
  height_cm             DECIMAL(5,2),
  current_weight_kg     DECIMAL(5,2),
  goal_weight_kg        DECIMAL(5,2),
  activity_level        VARCHAR(20) CHECK (activity_level IN ('sedentary', 'moderate', 'active')),
  health_conditions     TEXT,
  medications           TEXT,
  injuries              TEXT,
  family_type           VARCHAR(20) CHECK (family_type IN ('single', 'joint')),
  family_members_count  INT DEFAULT 1,
  diet_preference       VARCHAR(30) CHECK (diet_preference IN ('vegetarian', 'non_vegetarian', 'vegan')),
  allergies             TEXT,
  created_at            TIMESTAMP DEFAULT NOW(),
  updated_at            TIMESTAMP DEFAULT NOW()
);

-- BODY PHOTOS
CREATE TABLE body_photos (
  id          SERIAL PRIMARY KEY,
  user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  photo_type  VARCHAR(20) NOT NULL CHECK (photo_type IN ('front', 'side', 'back')),
  s3_url      TEXT NOT NULL,
  s3_key      TEXT NOT NULL,
  uploaded_at TIMESTAMP DEFAULT NOW()
);

-- DAILY TRACKING
CREATE TABLE daily_tracking (
  id                  SERIAL PRIMARY KEY,
  user_id             INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date                DATE NOT NULL,
  weight_kg           DECIMAL(5,2),
  stress_level        INT CHECK (stress_level BETWEEN 1 AND 10),
  water_intake_liters DECIMAL(4,2),
  steps               INT,
  sleep_hours         DECIMAL(4,2),
  mood                VARCHAR(50),
  deviation_notes     TEXT,
  created_at          TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- CUSTOM MEALS (created by participants)
CREATE TABLE meals (
  id                  SERIAL PRIMARY KEY,
  user_id             INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  meal_name           VARCHAR(255) NOT NULL,
  calories_per_100g   DECIMAL(6,2) NOT NULL,
  protein_per_100g    DECIMAL(6,2) NOT NULL DEFAULT 0,
  carbs_per_100g      DECIMAL(6,2) NOT NULL DEFAULT 0,
  fat_per_100g        DECIMAL(6,2) NOT NULL DEFAULT 0,
  created_at          TIMESTAMP DEFAULT NOW()
);

-- DIET PLANS (coach assigns macro targets)
CREATE TABLE diet_plans (
  id              SERIAL PRIMARY KEY,
  participant_id  INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coach_id        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_name       VARCHAR(255) NOT NULL DEFAULT 'Current Plan',
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMP DEFAULT NOW(),
  updated_at      TIMESTAMP DEFAULT NOW()
);

-- DIET PLAN MEALS (macro targets per meal slot)
CREATE TABLE diet_plan_meals (
  id            SERIAL PRIMARY KEY,
  diet_plan_id  INT NOT NULL REFERENCES diet_plans(id) ON DELETE CASCADE,
  meal_slot     VARCHAR(30) NOT NULL CHECK (meal_slot IN ('breakfast', 'lunch', 'snack', 'dinner')),
  calories      DECIMAL(7,2) NOT NULL,
  protein_g     DECIMAL(6,2) NOT NULL,
  carbs_g       DECIMAL(6,2) NOT NULL,
  fat_g         DECIMAL(6,2) NOT NULL
);

-- EXERCISE LIBRARY (preloaded)
CREATE TABLE exercises (
  id            SERIAL PRIMARY KEY,
  exercise_name VARCHAR(255) NOT NULL,
  muscle_group  VARCHAR(100) NOT NULL,
  description   TEXT,
  default_sets  INT DEFAULT 3,
  default_reps  INT DEFAULT 10,
  created_at    TIMESTAMP DEFAULT NOW()
);

-- WORKOUT PLANS (coach assigns)
CREATE TABLE workout_plans (
  id              SERIAL PRIMARY KEY,
  participant_id  INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coach_id        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_name       VARCHAR(255) NOT NULL DEFAULT 'Current Workout',
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMP DEFAULT NOW()
);

-- WORKOUT PLAN EXERCISES
CREATE TABLE workout_plan_exercises (
  id              SERIAL PRIMARY KEY,
  workout_plan_id INT NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  exercise_id     INT NOT NULL REFERENCES exercises(id),
  sets            INT NOT NULL DEFAULT 3,
  reps            INT NOT NULL DEFAULT 10,
  notes           TEXT,
  order_index     INT DEFAULT 0
);

-- COACH TIPS / NOTES
CREATE TABLE tips (
  id              SERIAL PRIMARY KEY,
  participant_id  INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coach_id        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content         TEXT NOT NULL,
  created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_daily_tracking_user_date ON daily_tracking(user_id, date);
CREATE INDEX idx_diet_plans_participant ON diet_plans(participant_id, is_active);
CREATE INDEX idx_workout_plans_participant ON workout_plans(participant_id, is_active);
CREATE INDEX idx_tips_participant ON tips(participant_id);
CREATE INDEX idx_meals_user ON meals(user_id);
CREATE INDEX idx_body_photos_user ON body_photos(user_id);

-- ============================================
-- SEED: EXERCISE LIBRARY
-- ============================================

INSERT INTO exercises (exercise_name, muscle_group, description, default_sets, default_reps) VALUES
-- Chest
('Push-Ups', 'Chest', 'Classic bodyweight chest exercise. Keep core tight, lower chest to floor.', 3, 12),
('Bench Press', 'Chest', 'Barbell bench press. Lie flat, grip slightly wider than shoulder width.', 3, 10),
('Incline Dumbbell Press', 'Chest', 'Targets upper chest. Set bench to 30-45 degrees.', 3, 12),
('Dumbbell Flyes', 'Chest', 'Isolation chest exercise. Keep slight bend in elbows.', 3, 12),
-- Back
('Pull-Ups', 'Back', 'Bodyweight back exercise. Grip shoulder width, pull chin above bar.', 3, 8),
('Bent-Over Row', 'Back', 'Hinge at hips, pull barbell to lower chest.', 3, 10),
('Lat Pulldown', 'Back', 'Pull bar to upper chest, squeeze lats at bottom.', 3, 12),
('Seated Cable Row', 'Back', 'Pull to abdomen, keep chest up, squeeze shoulder blades.', 3, 12),
-- Shoulders
('Overhead Press', 'Shoulders', 'Press barbell or dumbbells overhead. Brace core.', 3, 10),
('Lateral Raises', 'Shoulders', 'Raise dumbbells to shoulder height, slight bend in elbows.', 3, 15),
('Front Raises', 'Shoulders', 'Raise dumbbells in front to shoulder height.', 3, 12),
('Face Pulls', 'Shoulders', 'Pull cable to face level, external rotation at top.', 3, 15),
-- Arms
('Bicep Curls', 'Biceps', 'Curl dumbbells from fully extended to chin level.', 3, 12),
('Hammer Curls', 'Biceps', 'Neutral grip curl. Targets brachialis.', 3, 12),
('Tricep Dips', 'Triceps', 'Use parallel bars or bench. Lower body, press back up.', 3, 10),
('Tricep Pushdown', 'Triceps', 'Cable pushdown. Keep elbows tucked at sides.', 3, 15),
-- Legs
('Squats', 'Legs', 'Feet shoulder width, squat to parallel or below.', 4, 10),
('Romanian Deadlift', 'Legs', 'Hip hinge movement. Targets hamstrings and glutes.', 3, 10),
('Lunges', 'Legs', 'Step forward, lower back knee toward floor.', 3, 12),
('Leg Press', 'Legs', 'Push platform with feet shoulder width.', 4, 12),
('Leg Curl', 'Hamstrings', 'Curl legs toward glutes on machine.', 3, 12),
('Calf Raises', 'Calves', 'Rise onto toes. Can be done on step for greater range.', 4, 20),
-- Core
('Plank', 'Core', 'Hold straight body position on forearms. Brace core hard.', 3, 30),
('Crunches', 'Core', 'Curl shoulders toward knees. Do not pull neck.', 3, 20),
('Russian Twists', 'Core', 'Sit at 45 degrees, rotate torso side to side.', 3, 20),
('Dead Bug', 'Core', 'Lying on back, extend opposite arm and leg while keeping low back flat.', 3, 10),
-- Cardio
('Jumping Jacks', 'Cardio', 'Full body warm up. Coordinate arm and leg movement.', 1, 30),
('Burpees', 'Full Body', 'Squat thrust to standing jump. High intensity.', 3, 10),
('Mountain Climbers', 'Core/Cardio', 'Plank position, drive knees to chest alternately.', 3, 20),
('Jump Rope', 'Cardio', 'Skip rope at comfortable pace.', 3, 60);
