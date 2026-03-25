-- migration_meal_log.sql
-- Run this on Supabase SQL editor

-- Food cache: stores FatSecret API results to avoid repeated calls
CREATE TABLE IF NOT EXISTS food_cache (
  id                SERIAL PRIMARY KEY,
  food_id           VARCHAR(100) UNIQUE NOT NULL,
  name              VARCHAR(255) NOT NULL,
  name_hi           VARCHAR(255),
  calories_per_100g DECIMAL(8,2) DEFAULT 0,
  protein_g         DECIMAL(8,2) DEFAULT 0,
  carbs_g           DECIMAL(8,2) DEFAULT 0,
  fat_g             DECIMAL(8,2) DEFAULT 0,
  fiber_g           DECIMAL(8,2) DEFAULT 0,
  servings_json     JSONB,
  source            VARCHAR(50) DEFAULT 'fatsecret',
  search_count      INT DEFAULT 1,
  cached_at         TIMESTAMPTZ DEFAULT NOW()
);

-- Daily meal log: tracks what each user ate
CREATE TABLE IF NOT EXISTS meal_logs (
  id            SERIAL PRIMARY KEY,
  user_id       INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date          DATE NOT NULL DEFAULT CURRENT_DATE,
  food_id       VARCHAR(100),
  food_name     VARCHAR(255) NOT NULL,
  food_name_hi  VARCHAR(255),
  serving_label VARCHAR(150),
  serving_grams DECIMAL(8,2) NOT NULL DEFAULT 100,
  calories      DECIMAL(8,2) NOT NULL DEFAULT 0,
  protein_g     DECIMAL(8,2) DEFAULT 0,
  carbs_g       DECIMAL(8,2) DEFAULT 0,
  fat_g         DECIMAL(8,2) DEFAULT 0,
  fiber_g       DECIMAL(8,2) DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meal_logs_user_date ON meal_logs(user_id, date);
CREATE INDEX IF NOT EXISTS idx_food_cache_name     ON food_cache(LOWER(name));
