-- migration_meal_slot.sql
-- Run on Supabase SQL editor
ALTER TABLE meal_logs ADD COLUMN IF NOT EXISTS meal_slot VARCHAR(50) DEFAULT 'other';
