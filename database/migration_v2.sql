-- ============================================
-- Migration v2: Onboarding Form Fields
-- Run this against your existing database
-- ============================================

-- Fix diet_preference to include eggetarian
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_diet_preference_check;
ALTER TABLE profiles
  ADD CONSTRAINT profiles_diet_preference_check
  CHECK (diet_preference IN ('vegetarian', 'eggetarian', 'non_vegetarian', 'vegan'));

-- Add health goal (TEXT to support multiple comma-separated goals)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS health_goal TEXT;

-- Daily eating pattern
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS meals_per_day       INT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS meal_timings        TEXT;

-- What you usually eat
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS typical_breakfast   TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS typical_lunch       TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS typical_snacks      TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS typical_dinner      TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS tea_coffee          TEXT;

-- Eating out
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS eating_out_frequency   TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS eating_out_preference  TEXT;

-- Activity level detail
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS currently_workout  BOOLEAN;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS workout_type       TEXT;

-- Lifestyle baselines (separate from daily tracking)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS typical_sleep_hours    DECIMAL(4,2);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS typical_daily_steps    INT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS typical_stress_level   VARCHAR(10)
  CHECK (typical_stress_level IN ('Low', 'Medium', 'High'));
