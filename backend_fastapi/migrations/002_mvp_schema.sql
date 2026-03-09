-- =============================================================================
-- Migration 002: MVP Schema — drop old school/village tables, rename
--                verification→vouch, add personal checklist, evacuation
--                centres, SMS alerts, admin users.
--
-- Run in Supabase Dashboard → SQL Editor → New Query
-- Safe to run multiple times (uses IF EXISTS / IF NOT EXISTS guards).
-- =============================================================================

-- ── 1. Drop out-of-scope tables (school/village system) ──────────────────────
DROP TABLE IF EXISTS family_contacts      CASCADE;
DROP TABLE IF EXISTS school_checklist     CASCADE;
DROP TABLE IF EXISTS drill_participants   CASCADE;
DROP TABLE IF EXISTS drills               CASCADE;
DROP TABLE IF EXISTS resilience_metric_history CASCADE;
DROP TABLE IF EXISTS resilience_metrics   CASCADE;
DROP TABLE IF EXISTS students             CASCADE;
DROP TABLE IF EXISTS villages             CASCADE;
DROP TABLE IF EXISTS river_discharge      CASCADE;
DROP TABLE IF EXISTS social_media_posts   CASCADE;

-- ── 2. Fix reports table ──────────────────────────────────────────────────────

-- Remove out-of-scope columns (safe if they don't exist yet)
ALTER TABLE reports DROP COLUMN IF EXISTS confidence_score;
ALTER TABLE reports DROP COLUMN IF EXISTS validation_receipts;
ALTER TABLE reports DROP COLUMN IF EXISTS gemini_explanation;

-- Rename verification_count → vouch_count
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='reports' AND column_name='verification_count'
  ) THEN
    ALTER TABLE reports RENAME COLUMN verification_count TO vouch_count;
  END IF;
END $$;

-- Fix report_type CHECK: remove help_request
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_report_type_check;
ALTER TABLE reports ADD CONSTRAINT reports_report_type_check
  CHECK (report_type IN ('flood','landslide','blocked_road','medical_emergency'));

-- ── 3. Rename report_verifications → report_vouches ───────────────────────────
ALTER TABLE IF EXISTS report_verifications RENAME TO report_vouches;

-- Drop old index names and recreate
DROP INDEX IF EXISTS idx_report_verif_report;
CREATE INDEX IF NOT EXISTS idx_report_vouches_report ON report_vouches(report_id);

-- ── 4. Fix family_members table ───────────────────────────────────────────────

-- Drop old constraint (safe if already dropped)
ALTER TABLE family_members DROP CONSTRAINT IF EXISTS family_members_safety_status_check;
ALTER TABLE family_members ADD CONSTRAINT family_members_safety_status_check
  CHECK (safety_status IN ('unknown','safe','needs_help'));

-- Add relationship column if missing
ALTER TABLE family_members ADD COLUMN IF NOT EXISTS relationship TEXT NOT NULL DEFAULT '';

-- Remove telegram-only column (safe to drop)
ALTER TABLE family_members DROP COLUMN IF EXISTS telegram_username;
ALTER TABLE family_members DROP COLUMN IF EXISTS telegram_chat_id;

-- ── 5. Personal Preparedness Checklist (per user, not per village) ────────────
CREATE TABLE IF NOT EXISTS personal_checklist (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_name    TEXT NOT NULL,
    category     TEXT NOT NULL DEFAULT 'general'
                 CHECK (category IN ('supplies','training','planning','general')),
    completed    BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    notes        TEXT NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_personal_checklist_user ON personal_checklist(user_id);

-- ── 6. Educational Content Views (track what user has viewed) ─────────────────
CREATE TABLE IF NOT EXISTS educational_content_views (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    topic_id   TEXT NOT NULL,
    viewed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, topic_id)
);

CREATE INDEX IF NOT EXISTS idx_edu_views_user ON educational_content_views(user_id);

-- ── 7. Evacuation Centres ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS evacuation_centres (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         TEXT NOT NULL,
    address      TEXT NOT NULL DEFAULT '',
    latitude     DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude    DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    capacity     INT NOT NULL DEFAULT 0,
    contact_phone TEXT NOT NULL DEFAULT '',
    state        TEXT NOT NULL DEFAULT '',
    district     TEXT NOT NULL DEFAULT '',
    active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_evac_centres_lat_lon ON evacuation_centres(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_evac_centres_active  ON evacuation_centres(active);

-- ── 8. SMS Alerts Log (dedup + delivery tracking) ────────────────────────────
CREATE TABLE IF NOT EXISTS sms_alerts (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    alert_type   TEXT NOT NULL DEFAULT 'flood'
                 CHECK (alert_type IN ('flood','government_warning')),
    event_id     TEXT NOT NULL,           -- report_id or government_alert id
    message_body TEXT NOT NULL DEFAULT '',
    status       TEXT NOT NULL DEFAULT 'sent'
                 CHECK (status IN ('sent','failed','delivered')),
    error_reason TEXT,
    sent_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sms_alerts_user    ON sms_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_sms_alerts_event   ON sms_alerts(event_id);
CREATE INDEX IF NOT EXISTS idx_sms_alerts_sent_at ON sms_alerts(sent_at DESC);

-- ── 9. Admin Users (simple username/password for admin website) ───────────────
CREATE TABLE IF NOT EXISTS admin_users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username     TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 10. Seed evacuation centres (sample Malaysian data) ──────────────────────
INSERT INTO evacuation_centres (name, address, latitude, longitude, capacity, contact_phone, state, district)
VALUES
  ('Dewan Orang Ramai Kuantan',   'Jalan Tun Ismail, Kuantan',          3.8077,  103.3260, 500,  '09-555-1001', 'Pahang',   'Kuantan'),
  ('Sekolah Kebangsaan Sg. Lembing', 'Sungai Lembing, Pahang',          3.8800,  103.0400, 300,  '09-555-1002', 'Pahang',   'Kuantan'),
  ('Dewan Komuniti Bentong',      'Jalan Loke Yew, Bentong',            3.5228,  101.9059, 400,  '09-222-3003', 'Pahang',   'Bentong'),
  ('Pusat Komuniti Temerloh',     'Jalan Bukit Diman, Temerloh',        3.4500,  102.4167, 600,  '09-296-4004', 'Pahang',   'Temerloh'),
  ('Dewan Sri Jaya Pekan',        'Jalan Sultan Ahmad, Pekan',          3.4896,  103.3939, 350,  '09-422-5005', 'Pahang',   'Pekan'),
  ('Balai Raya Kampung Sungai Lui','Kampung Sungai Lui, Hulu Langat',   3.1200,  101.8800, 200,  '03-999-6006', 'Selangor', 'Hulu Langat'),
  ('Dewan Dato Harun Shah Alam',  'Persiaran Perbandaran, Shah Alam',   3.0738,  101.5183, 800,  '03-555-7007', 'Selangor', 'Petaling'),
  ('Sekolah Kebangsaan Batu Caves','Jalan Batu Caves, Selangor',        3.2379,  101.6840, 400,  '03-689-8008', 'Selangor', 'Gombak')
ON CONFLICT DO NOTHING;
