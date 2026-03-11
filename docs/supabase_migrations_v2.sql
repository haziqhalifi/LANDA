-- ==========================================================================
-- Disaster Resilience AI — Complete Supabase Migration (v2)
-- Run this in the Supabase Dashboard → SQL Editor.
-- This adds ALL missing tables that the backend code references.
-- It is safe to re-run (uses IF NOT EXISTS / idempotent DO blocks).
-- ==========================================================================

-- ── 1. Users (already exists from v1 migration) ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
    id            TEXT PRIMARY KEY,
    username      TEXT        NOT NULL UNIQUE,
    email         TEXT        NOT NULL UNIQUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.users DROP COLUMN IF EXISTS hashed_password;
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users (email);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users (username);

-- ── 2. Warnings ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.warnings (
    id            TEXT PRIMARY KEY,
    title         TEXT        NOT NULL,
    description   TEXT        NOT NULL,
    hazard_type   TEXT        NOT NULL,
    alert_level   TEXT        NOT NULL,
    latitude      DOUBLE PRECISION NOT NULL,
    longitude     DOUBLE PRECISION NOT NULL,
    radius_km     DOUBLE PRECISION NOT NULL,
    source        TEXT        NOT NULL DEFAULT 'system',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    active        BOOLEAN     NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_warnings_active ON public.warnings (active) WHERE active = true;

-- ── 3. Devices ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.devices (
    user_id       TEXT PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    latitude      DOUBLE PRECISION,
    longitude     DOUBLE PRECISION,
    fcm_token     TEXT,
    phone_number  TEXT,
    updated_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_devices_location ON public.devices (latitude, longitude) WHERE latitude IS NOT NULL;

-- ── 4. Risk Zones ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.risk_zones (
    id            TEXT PRIMARY KEY,
    name          TEXT        NOT NULL,
    zone_type     TEXT        NOT NULL,
    hazard_type   TEXT        NOT NULL,
    latitude      DOUBLE PRECISION NOT NULL,
    longitude     DOUBLE PRECISION NOT NULL,
    radius_km     DOUBLE PRECISION NOT NULL,
    risk_score    DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    description   TEXT        NOT NULL DEFAULT '',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    active        BOOLEAN     NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_risk_zones_active ON public.risk_zones (active) WHERE active = true;

-- ── 5. Evacuation Centres ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.evacuation_centres (
    id                TEXT PRIMARY KEY,
    name              TEXT        NOT NULL,
    latitude          DOUBLE PRECISION NOT NULL,
    longitude         DOUBLE PRECISION NOT NULL,
    capacity          INTEGER     NOT NULL DEFAULT 0,
    current_occupancy INTEGER     NOT NULL DEFAULT 0,
    contact_phone     TEXT,
    address           TEXT        NOT NULL DEFAULT '',
    active            BOOLEAN     NOT NULL DEFAULT true
);

-- ── 6. Evacuation Routes ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.evacuation_routes (
    id                TEXT PRIMARY KEY,
    name              TEXT        NOT NULL,
    start_lat         DOUBLE PRECISION NOT NULL,
    start_lon         DOUBLE PRECISION NOT NULL,
    end_lat           DOUBLE PRECISION NOT NULL,
    end_lon           DOUBLE PRECISION NOT NULL,
    waypoints         JSONB       NOT NULL DEFAULT '[]',
    distance_km       DOUBLE PRECISION NOT NULL DEFAULT 0,
    estimated_minutes INTEGER     NOT NULL DEFAULT 0,
    elevation_gain_m  DOUBLE PRECISION NOT NULL DEFAULT 0,
    status            TEXT        NOT NULL DEFAULT 'clear',
    active            BOOLEAN     NOT NULL DEFAULT true
);

-- ── 7. User Profiles ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_profiles (
    user_id                        TEXT PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    full_name                      TEXT,
    phone_number                   TEXT,
    blood_type                     TEXT,
    allergies                      TEXT NOT NULL DEFAULT '',
    medical_conditions             TEXT NOT NULL DEFAULT '',
    emergency_contact_name         TEXT,
    emergency_contact_relationship TEXT,
    emergency_contact_phone        TEXT,
    updated_at                     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 8. Community Reports ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reports (
    id                     TEXT PRIMARY KEY,
    user_id                TEXT REFERENCES public.users(id) ON DELETE SET NULL,
    report_type            TEXT        NOT NULL,
    description            TEXT        NOT NULL,
    location_name          TEXT        NOT NULL DEFAULT '',
    latitude               DOUBLE PRECISION NOT NULL,
    longitude              DOUBLE PRECISION NOT NULL,
    status                 TEXT        NOT NULL DEFAULT 'pending',
    vulnerable_person      BOOLEAN     NOT NULL DEFAULT false,
    vouch_count            INTEGER     NOT NULL DEFAULT 0,
    helpful_count          INTEGER     NOT NULL DEFAULT 0,
    resolved_by            TEXT,
    resolution_reason      TEXT,
    resolved_at            TIMESTAMPTZ,
    description_updated_at TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports (status);
CREATE INDEX IF NOT EXISTS idx_reports_type ON public.reports (report_type);
CREATE INDEX IF NOT EXISTS idx_reports_user ON public.reports (user_id);
CREATE INDEX IF NOT EXISTS idx_reports_location ON public.reports (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_reports_created ON public.reports (created_at DESC);

-- ── 9. Report Vouches ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.report_vouches (
    id          TEXT PRIMARY KEY,
    report_id   TEXT NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    user_id     TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(report_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_vouches_report ON public.report_vouches (report_id);
CREATE INDEX IF NOT EXISTS idx_vouches_user ON public.report_vouches (user_id);

-- ── 10. Report Helpful ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.report_helpful (
    id          TEXT PRIMARY KEY,
    report_id   TEXT NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    user_id     TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(report_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_helpful_report ON public.report_helpful (report_id);

-- ── 11. Family Groups ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.family_groups (
    id             TEXT PRIMARY KEY,
    leader_user_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name           TEXT NOT NULL DEFAULT 'My Family',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_family_groups_leader ON public.family_groups (leader_user_id);

-- ── 12. Family Members ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.family_members (
    id             TEXT PRIMARY KEY,
    group_id       TEXT NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
    name           TEXT NOT NULL,
    phone_number   TEXT NOT NULL DEFAULT '',
    relationship   TEXT NOT NULL DEFAULT '',
    safety_status  TEXT NOT NULL DEFAULT 'unknown',
    last_updated   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_family_members_group ON public.family_members (group_id);
CREATE INDEX IF NOT EXISTS idx_family_members_phone ON public.family_members (phone_number);

-- ── 13. Personal Checklist ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.personal_checklist (
    id           TEXT PRIMARY KEY,
    user_id      TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    item_name    TEXT NOT NULL,
    category     TEXT NOT NULL DEFAULT 'general',
    completed    BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ,
    notes        TEXT NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_checklist_user ON public.personal_checklist (user_id);

-- ── 14. Educational Content Views ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.educational_content_views (
    id         TEXT PRIMARY KEY,
    user_id    TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    topic_id   TEXT NOT NULL,
    viewed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, topic_id)
);
CREATE INDEX IF NOT EXISTS idx_edu_views_user ON public.educational_content_views (user_id);

-- ── 15. Admin Users ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_users (
    id            TEXT PRIMARY KEY,
    username      TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 16. Government Alerts (MetMalaysia) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.government_alerts (
    id          TEXT PRIMARY KEY,
    source      TEXT NOT NULL DEFAULT 'metmalaysia',
    area        TEXT NOT NULL,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    severity    TEXT,
    raw_data    JSONB,
    fetched_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_gov_alerts_fetched ON public.government_alerts (fetched_at DESC);

-- ── 17. SMS Alerts Log (deduplication & delivery tracking) ──────────────────
CREATE TABLE IF NOT EXISTS public.sms_alerts (
    id            TEXT PRIMARY KEY,
    user_id       TEXT REFERENCES public.users(id) ON DELETE SET NULL,
    phone_number  TEXT NOT NULL,
    alert_type    TEXT NOT NULL DEFAULT 'flood',
    event_id      TEXT NOT NULL,
    message_body  TEXT NOT NULL DEFAULT '',
    status        TEXT NOT NULL DEFAULT 'pending',
    error_reason  TEXT,
    sent_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_sms_alerts_user_event ON public.sms_alerts (user_id, event_id, sent_at DESC);

-- ── RLS Policies ─────────────────────────────────────────────────────────────
-- Using service role key — all access via backend (not client-side Supabase)
ALTER TABLE public.users                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warnings                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.risk_zones               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evacuation_centres       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evacuation_routes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_vouches           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_helpful           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_groups            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_checklist       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.educational_content_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.government_alerts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_alerts               ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    tbls TEXT[] := ARRAY[
        'users', 'warnings', 'devices', 'risk_zones',
        'evacuation_centres', 'evacuation_routes', 'user_profiles',
        'reports', 'report_vouches', 'report_helpful',
        'family_groups', 'family_members', 'personal_checklist',
        'educational_content_views', 'admin_users', 'government_alerts',
        'sms_alerts'
    ];
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY tbls LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = tbl AND policyname = 'Service role full access'
        ) THEN
            EXECUTE format(
                'CREATE POLICY "Service role full access" ON public.%I FOR ALL USING (true) WITH CHECK (true)',
                tbl
            );
        END IF;
    END LOOP;
END $$;

-- ── Sample Evacuation Centres (Malaysia) ─────────────────────────────────────
INSERT INTO public.evacuation_centres (id, name, latitude, longitude, capacity, contact_phone, address, active)
VALUES
  ('ec-001', 'Dewan Orang Ramai Kampung Baru', 3.1710, 101.7050, 500, '+60123456789', 'Jalan Kampung Baru, Kuala Lumpur', true),
  ('ec-002', 'SK Sungai Lui', 3.2158, 101.8925, 300, '+60198765432', 'Jalan Sekolah, Hulu Langat', true),
  ('ec-003', 'Dewan Komuniti Ampang', 3.1478, 101.7649, 400, '+60112345678', 'Jalan Ampang, Ampang', true),
  ('ec-004', 'Pusat Komuniti Klang', 3.0449, 101.4462, 600, '+60167654321', 'Jalan Meru, Klang', true),
  ('ec-005', 'Dewan Serbaguna Rawang', 3.3188, 101.5747, 350, '+60134567890', 'Jalan Rawang, Rawang, Selangor', true),
  ('ec-006', 'SK Bukit Tinggi', 3.3667, 101.7833, 250, '+60189876543', 'Jalan Bukit Tinggi, Bentong, Pahang', true),
  ('ec-007', 'Dewan Komuniti Gombak', 3.2333, 101.7167, 450, '+60156789012', 'Jalan Gombak, Gombak', true),
  ('ec-008', 'Balai Raya Banting', 2.8156, 101.5039, 300, '+60145678901', 'Jalan Dato Hamzah, Banting, Selangor', true)
ON CONFLICT (id) DO NOTHING;

