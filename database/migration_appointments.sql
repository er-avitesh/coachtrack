-- ============================================
-- Appointments Migration
-- Run this on your Supabase SQL editor
-- ============================================

-- Recurring series (one per coach-client pair)
CREATE TABLE appointment_series (
  id               SERIAL PRIMARY KEY,
  coach_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title            VARCHAR(255) NOT NULL DEFAULT 'Weekly Connect',
  day_of_week      SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun, 1=Mon ... 6=Sat
  time_of_day      TIME NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 30,
  is_active        BOOLEAN DEFAULT true,
  created_at       TIMESTAMP DEFAULT NOW(),
  UNIQUE(coach_id, client_id)
);

-- Individual appointments (recurring occurrences + adhoc)
CREATE TABLE appointments (
  id               SERIAL PRIMARY KEY,
  coach_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  series_id        INT REFERENCES appointment_series(id) ON DELETE SET NULL,
  title            VARCHAR(255) NOT NULL DEFAULT 'Connect',
  type             VARCHAR(20) NOT NULL DEFAULT 'adhoc' CHECK (type IN ('recurring', 'adhoc')),
  scheduled_at     TIMESTAMPTZ NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 30,
  status           VARCHAR(20) NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'cancelled', 'completed')),
  notes            TEXT,
  is_exception     BOOLEAN DEFAULT false, -- true = single reschedule of a recurring slot
  created_at       TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_appointments_coach     ON appointments(coach_id);
CREATE INDEX idx_appointments_client    ON appointments(client_id);
CREATE INDEX idx_appointments_scheduled ON appointments(scheduled_at);
CREATE INDEX idx_appointments_series    ON appointments(series_id);
