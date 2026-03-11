-- Migration 003: Add media upload and AI analysis support to reports
-- Run this in the Supabase SQL Editor

-- Add media_url column to store uploaded photo/video URL
ALTER TABLE reports ADD COLUMN IF NOT EXISTS media_url TEXT;

-- Add AI analysis result (JSONB) and status tracking
ALTER TABLE reports ADD COLUMN IF NOT EXISTS ai_analysis JSONB;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS ai_status TEXT
  CHECK (ai_status IN ('analyzing', 'done', 'failed'));

-- NOTE: Also create a Supabase Storage bucket manually:
--   Supabase Dashboard → Storage → New Bucket
--   Name: report-media
--   Public: ON (allow public read for thumbnail display in admin)
