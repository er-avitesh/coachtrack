-- Add start_date / end_date to all plan tables
ALTER TABLE workout_plans   ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE workout_plans   ADD COLUMN IF NOT EXISTS end_date   DATE;
ALTER TABLE diet_plans      ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE diet_plans      ADD COLUMN IF NOT EXISTS end_date   DATE;
ALTER TABLE lifestyle_plans ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE lifestyle_plans ADD COLUMN IF NOT EXISTS end_date   DATE;
