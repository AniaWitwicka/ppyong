-- ─────────────────────────────────────────────────────────────────────────────
-- relink_teacher.sql
-- Links a real registered account to all seeded mock data and sets it as teacher.
--
-- USAGE: Replace <YOUR_UUID> below with the real account's UUID, then run in
--        the Supabase SQL editor.
--
-- Tables covered:
--   users            → role, account_status, last_active
--   user_settings    → ensure row exists
--   collections      → created_by
--   decks            → created_by  (cards have no user ref — covered implicitly)
--   groups           → created_by
--   group_members    → user_id (owner rows)
--   invites          → inviter_id
--   activity_log     → user_id
--   srs_progress     → user_id
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
    new_id  UUID := '<YOUR_UUID>';           -- ← paste the real UUID here
    old_id  UUID := '00000000-0000-0000-0000-000000000001';
BEGIN

-- 1. Set role to teacher and activate the account
UPDATE users
SET role           = 'teacher',
    account_status = 'active',
    last_active    = CURRENT_DATE
WHERE id = new_id;

-- Ensure user_settings row exists
INSERT INTO user_settings (user_id)
VALUES (new_id)
ON CONFLICT (user_id) DO NOTHING;

-- 2. Relink collections
UPDATE collections SET created_by = new_id WHERE created_by = old_id;

-- 3. Relink decks (cards have no user ref, they follow their deck)
UPDATE decks SET created_by = new_id WHERE created_by = old_id;

-- 4. Relink groups
UPDATE groups SET created_by = new_id WHERE created_by = old_id;

-- 5. Relink group_members (composite PK — insert new row, delete old)
INSERT INTO group_members (group_id, user_id, role, joined_at)
SELECT group_id, new_id, role, joined_at
FROM group_members
WHERE user_id = old_id
ON CONFLICT (group_id, user_id) DO NOTHING;

DELETE FROM group_members WHERE user_id = old_id;

-- 6. Relink invites
UPDATE invites SET inviter_id = new_id WHERE inviter_id = old_id;

-- 7. Relink activity_log
UPDATE activity_log SET user_id = new_id WHERE user_id = old_id;

-- 8. Relink srs_progress
UPDATE srs_progress SET user_id = new_id WHERE user_id = old_id;

-- 9. Delete the placeholder user (all FK refs are gone now)
DELETE FROM users WHERE id = old_id;

END $$;
