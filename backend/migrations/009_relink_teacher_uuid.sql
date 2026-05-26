-- ─────────────────────────────────────────────────────────────────────────────
-- 009_relink_teacher_uuid.sql
-- Relinks all seeded data from the placeholder teacher UUID
-- to the real account UUID created by auth signup.
--
-- Old (placeholder): 00000000-0000-0000-0000-000000000001
-- New (real):        60b55b40-125f-4846-910b-6296fd587996
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Ensure real account has teacher profile ─────────────────────────────────
UPDATE users
SET role        = 'teacher',
    name        = 'Ania Witwicka',
    initials    = 'AW',
    streak      = 7,
    best_streak = 14,
    last_active = CURRENT_DATE
WHERE id = '60b55b40-125f-4846-910b-6296fd587996';

INSERT INTO user_settings (user_id)
VALUES ('60b55b40-125f-4846-910b-6296fd587996')
ON CONFLICT (user_id) DO NOTHING;

-- ── 2. Relink collections ─────────────────────────────────────────────────────
UPDATE collections
SET created_by = '60b55b40-125f-4846-910b-6296fd587996'
WHERE created_by = '00000000-0000-0000-0000-000000000001';

-- ── 3. Relink decks ───────────────────────────────────────────────────────────
UPDATE decks
SET created_by = '60b55b40-125f-4846-910b-6296fd587996'
WHERE created_by = '00000000-0000-0000-0000-000000000001';

-- ── 4. Relink groups ──────────────────────────────────────────────────────────
UPDATE groups
SET created_by = '60b55b40-125f-4846-910b-6296fd587996'
WHERE created_by = '00000000-0000-0000-0000-000000000001';

-- ── 5. Relink group_members (PK = group_id + user_id, so insert + delete) ─────
INSERT INTO group_members (group_id, user_id, role, joined_at)
SELECT group_id, '60b55b40-125f-4846-910b-6296fd587996', role, joined_at
FROM group_members
WHERE user_id = '00000000-0000-0000-0000-000000000001'
ON CONFLICT (group_id, user_id) DO NOTHING;

DELETE FROM group_members
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- ── 6. Relink activity_log ────────────────────────────────────────────────────
UPDATE activity_log
SET user_id = '60b55b40-125f-4846-910b-6296fd587996'
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- ── 7. Relink srs_progress ────────────────────────────────────────────────────
UPDATE srs_progress
SET user_id = '60b55b40-125f-4846-910b-6296fd587996'
WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- ── 8. Remove placeholder user (all FK refs are gone now) ────────────────────
DELETE FROM users
WHERE id = '00000000-0000-0000-0000-000000000001';
