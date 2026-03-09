-- Migration 004: Add SMS reply tracking to sms_alerts
-- Run in Supabase Dashboard → SQL Editor before deploying backend.

ALTER TABLE public.sms_alerts
  ADD COLUMN IF NOT EXISTS reply_status        TEXT          DEFAULT NULL,  -- 'safe' | 'danger'
  ADD COLUMN IF NOT EXISTS reply_at            TIMESTAMPTZ   DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS rescue_acknowledged BOOLEAN       DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_sms_alerts_danger
  ON public.sms_alerts (reply_status, sent_at DESC)
  WHERE reply_status IS NOT NULL;
