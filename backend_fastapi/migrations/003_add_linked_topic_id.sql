-- Migration 003: Add linked_topic_id to personal_checklist
-- Safe to re-run (IF NOT EXISTS guards).
-- Run in Supabase Dashboard → SQL Editor before deploying backend.

ALTER TABLE public.personal_checklist
  ADD COLUMN IF NOT EXISTS linked_topic_id TEXT DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_checklist_linked_topic
  ON public.personal_checklist (user_id, linked_topic_id)
  WHERE linked_topic_id IS NOT NULL;
