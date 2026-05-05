-- Add missing columns to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS initials TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS best_streak INTEGER NOT NULL DEFAULT 0;

-- User settings (one row per user)
CREATE TABLE IF NOT EXISTS user_settings (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    study_reminder_time   TEXT NOT NULL DEFAULT '09:00',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
