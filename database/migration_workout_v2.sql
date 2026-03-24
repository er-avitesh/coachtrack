-- ============================================
-- Migration Workout v2: Day structure + History
-- Run this on your Supabase SQL editor
-- ============================================

-- Add missing columns to workout_plans
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS total_days  INT DEFAULT 1;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS end_date   DATE;

-- Day-structured workout tables (required by workoutController.js)
CREATE TABLE IF NOT EXISTS workout_days (
  id               SERIAL PRIMARY KEY,
  workout_plan_id  INT NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  day_number       INT NOT NULL,
  day_name         VARCHAR(100) NOT NULL DEFAULT 'Day 1',
  order_index      INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS workout_day_exercises (
  id               SERIAL PRIMARY KEY,
  workout_day_id   INT NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
  exercise_id      INT NOT NULL REFERENCES exercises(id),
  sets             INT NOT NULL DEFAULT 3,
  reps             INT NOT NULL DEFAULT 10,
  notes            TEXT,
  order_index      INT DEFAULT 0
);

-- Workout session history
CREATE TABLE IF NOT EXISTS workout_sessions (
  id               SERIAL PRIMARY KEY,
  user_id          INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workout_plan_id  INT REFERENCES workout_plans(id) ON DELETE SET NULL,
  workout_day_id   INT REFERENCES workout_days(id) ON DELETE SET NULL,
  day_name         VARCHAR(100),
  completed_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Per-set weight logs
CREATE TABLE IF NOT EXISTS workout_set_logs (
  id               SERIAL PRIMARY KEY,
  session_id       INT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id      INT NOT NULL REFERENCES exercises(id),
  exercise_name    VARCHAR(255) NOT NULL,
  set_number       INT NOT NULL,
  reps_done        INT,
  weight_kg        DECIMAL(6,2),  -- NULL = bodyweight
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user    ON workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_set_logs_session ON workout_set_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_workout_days_plan        ON workout_days(workout_plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_day_ex_day       ON workout_day_exercises(workout_day_id);
