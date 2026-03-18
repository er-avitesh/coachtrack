-- Migration: add youtube_video_id to exercises table
-- Run once against your Supabase/PostgreSQL database

ALTER TABLE exercises
  ADD COLUMN IF NOT EXISTS youtube_video_id TEXT;

COMMENT ON COLUMN exercises.youtube_video_id IS
  'YouTube video ID (11-char string) for the exercise tutorial. Set by coach/admin only.';
