-- =============================================================================
-- Migration 001: Community Intelligence + Preparedness tables
-- Run this in your Supabase SQL editor (Dashboard → SQL Editor → New Query)
-- NOTE: users.id is TEXT in this project (Supabase Auth UUID stored as text)
-- =============================================================================

-- ── Community Reports ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reports (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    report_type      TEXT NOT NULL CHECK (report_type IN ('flood','landslide','blocked_road','help_request','medical_emergency')),
    description      TEXT NOT NULL DEFAULT '',
    location_name    TEXT NOT NULL DEFAULT '',
    latitude         DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude        DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    status           TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending','validated','rejected','resolved','expired')),
    confidence_score INT CHECK (confidence_score BETWEEN 0 AND 100),
    validation_receipts JSONB,
    gemini_explanation  TEXT,
    vulnerable_person   BOOLEAN NOT NULL DEFAULT FALSE,
    verification_count  INT NOT NULL DEFAULT 0,
    helpful_count       INT NOT NULL DEFAULT 0,
    resolved_by         TEXT REFERENCES users(id),
    resolution_reason   TEXT,
    resolved_at         TIMESTAMPTZ,
    description_updated_at TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_user_id    ON reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_status     ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_report_type ON reports(report_type);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_lat_lon    ON reports(latitude, longitude);

-- ── Report Verifications ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS report_verifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id  UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (report_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_report_verif_report ON report_verifications(report_id);

-- ── Report Helpful Markings ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS report_helpful (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id  UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (report_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_report_helpful_report ON report_helpful(report_id);

-- ── Villages ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS villages (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL,
    district   TEXT NOT NULL DEFAULT '',
    state      TEXT NOT NULL DEFAULT '',
    latitude   DOUBLE PRECISION,
    longitude  DOUBLE PRECISION,
    population INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Resilience Metrics (current values per village) ──────────────────────────

CREATE TABLE IF NOT EXISTS resilience_metrics (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id          UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE UNIQUE,
    infrastructure      DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (infrastructure BETWEEN 0 AND 100),
    training            DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (training BETWEEN 0 AND 100),
    supplies            DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (supplies BETWEEN 0 AND 100),
    prev_infrastructure DOUBLE PRECISION NOT NULL DEFAULT 0,
    prev_training       DOUBLE PRECISION NOT NULL DEFAULT 0,
    prev_supplies       DOUBLE PRECISION NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Resilience Metric History ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS resilience_metric_history (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id  UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    metric_type TEXT NOT NULL CHECK (metric_type IN ('infrastructure','training','supplies')),
    value       DOUBLE PRECISION NOT NULL,
    changed_by  TEXT REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_metric_hist_village ON resilience_metric_history(village_id);
CREATE INDEX IF NOT EXISTS idx_metric_hist_created ON resilience_metric_history(created_at DESC);

-- ── Emergency Drills ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS drills (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id         UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    drill_type         TEXT NOT NULL CHECK (drill_type IN ('flash_flood_evacuation','earthquake_response','fire_evacuation','typhoon_shelter')),
    scheduled_at       TIMESTAMPTZ NOT NULL,
    started_at         TIMESTAMPTZ,
    completed_at       TIMESTAMPTZ,
    cancelled_at       TIMESTAMPTZ,
    status             TEXT NOT NULL DEFAULT 'scheduled'
                       CHECK (status IN ('scheduled','in_progress','completed','cancelled')),
    mandatory          BOOLEAN NOT NULL DEFAULT FALSE,
    participant_count  INT NOT NULL DEFAULT 0,
    participation_rate DOUBLE PRECISION,
    created_by         TEXT REFERENCES users(id),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_drills_village    ON drills(village_id);
CREATE INDEX IF NOT EXISTS idx_drills_status     ON drills(status);
CREATE INDEX IF NOT EXISTS idx_drills_scheduled  ON drills(scheduled_at ASC);

-- ── Drill Participants ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS drill_participants (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    drill_id     UUID NOT NULL REFERENCES drills(id) ON DELETE CASCADE,
    user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (drill_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_drill_part_drill ON drill_participants(drill_id);

-- ── Students (School Roster) ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS students (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id          UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    name                TEXT NOT NULL,
    grade               TEXT NOT NULL DEFAULT '',
    family_member_count INT NOT NULL DEFAULT 0,
    safety_status       TEXT NOT NULL DEFAULT 'PENDING'
                        CHECK (safety_status IN ('SAFE','PENDING','MISSING')),
    status_updated_at   TIMESTAMPTZ,
    status_updated_by   TEXT REFERENCES users(id),
    safe_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_students_village ON students(village_id);
CREATE INDEX IF NOT EXISTS idx_students_status  ON students(safety_status);
CREATE INDEX IF NOT EXISTS idx_students_name    ON students(name);

-- ── Family Contacts ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS family_contacts (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id   UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    contact_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    relationship TEXT NOT NULL DEFAULT '',
    is_primary   BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_family_contacts_student ON family_contacts(student_id);

-- ── School Checklist ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS school_checklist (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    village_id   UUID NOT NULL REFERENCES villages(id) ON DELETE CASCADE,
    item_name    TEXT NOT NULL,
    category     TEXT NOT NULL DEFAULT 'general',
    completed    BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    completed_by TEXT REFERENCES users(id),
    notes        TEXT NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_checklist_village ON school_checklist(village_id);

-- ── Government Alerts Cache (MetMalaysia / NADMA) ─────────────────────────────

CREATE TABLE IF NOT EXISTS government_alerts (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source     TEXT NOT NULL CHECK (source IN ('metmalaysia','nadma')),
    area       TEXT NOT NULL DEFAULT '',
    latitude   DOUBLE PRECISION,
    longitude  DOUBLE PRECISION,
    severity   TEXT NOT NULL DEFAULT '',
    raw_data   JSONB,
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    active     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_gov_alerts_source    ON government_alerts(source);
CREATE INDEX IF NOT EXISTS idx_gov_alerts_fetched   ON government_alerts(fetched_at DESC);
CREATE INDEX IF NOT EXISTS idx_gov_alerts_active    ON government_alerts(active);

-- ── River Discharge Cache (Open-Meteo GloFAS) ────────────────────────────────

CREATE TABLE IF NOT EXISTS river_discharge (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    station_name   TEXT NOT NULL,
    latitude       DOUBLE PRECISION NOT NULL,
    longitude      DOUBLE PRECISION NOT NULL,
    discharge_m3s  DOUBLE PRECISION NOT NULL DEFAULT 0,
    percentile     DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (percentile BETWEEN 0 AND 100),
    fetched_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_river_discharge_fetched ON river_discharge(fetched_at DESC);

-- ── Social Media Posts Cache (Telegram) ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS social_media_posts (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source           TEXT NOT NULL DEFAULT 'telegram',
    channel          TEXT NOT NULL,
    message_id       BIGINT,
    content          TEXT NOT NULL DEFAULT '',
    location_name    TEXT NOT NULL DEFAULT '',
    latitude         DOUBLE PRECISION,
    longitude        DOUBLE PRECISION,
    posted_at        TIMESTAMPTZ,
    fetched_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    keywords_matched TEXT[] NOT NULL DEFAULT '{}',
    UNIQUE (source, channel, message_id)
);

CREATE INDEX IF NOT EXISTS idx_social_posts_fetched ON social_media_posts(fetched_at DESC);

-- ── Family Groups ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS family_groups (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leader_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name           TEXT NOT NULL DEFAULT 'My Family',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_family_groups_leader ON family_groups(leader_user_id);

-- ── Family Members ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS family_members (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id          UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    name              TEXT NOT NULL,
    phone_number      TEXT NOT NULL DEFAULT '',
    telegram_username TEXT NOT NULL DEFAULT '',
    telegram_chat_id  BIGINT,
    safety_status     TEXT NOT NULL DEFAULT 'unknown'
                      CHECK (safety_status IN ('unknown','safe','needs_help')),
    last_updated      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_family_members_group ON family_members(group_id);
