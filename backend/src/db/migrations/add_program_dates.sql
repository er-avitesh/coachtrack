ALTER TABLE coach_clients
  ADD COLUMN IF NOT EXISTS program_start_date DATE,
  ADD COLUMN IF NOT EXISTS program_end_date   DATE;
