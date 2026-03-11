-- Migration 004: Family links (Life360-style user-to-user connections)
-- Run this in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS family_links (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status         TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at   TIMESTAMPTZ,

    -- Prevent duplicate links between the same two users
    CONSTRAINT family_links_unique_pair UNIQUE (requester_id, addressee_id)
);

CREATE INDEX IF NOT EXISTS idx_family_links_requester ON family_links(requester_id);
CREATE INDEX IF NOT EXISTS idx_family_links_addressee ON family_links(addressee_id);
