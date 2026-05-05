-- Seed users with fixed UUIDs so the app can reference them before auth is wired.
INSERT INTO users (id, email, name, role, initials, streak, best_streak, last_active) VALUES
    ('00000000-0000-0000-0000-000000000001', 'ania@ppyong.app',   'Ania Witwicka', 'teacher', 'AW', 7,  14, CURRENT_DATE),
    ('00000000-0000-0000-0000-000000000002', 'mia@ppyong.app',    'Mia Chen',      'learner', 'MC', 3,  5,  CURRENT_DATE),
    ('00000000-0000-0000-0000-000000000003', 'jake@ppyong.app',   'Jake Kim',      'learner', 'JK', 1,  4,  CURRENT_DATE),
    ('00000000-0000-0000-0000-000000000004', 'sophie@ppyong.app', 'Sophie Park',   'learner', 'SP', 5,  9,  CURRENT_DATE),
    ('00000000-0000-0000-0000-000000000005', 'tom@ppyong.app',    'Tom Lee',       'learner', 'TL', 0,  2,  NULL)
ON CONFLICT (id) DO NOTHING;

-- Default settings for each user
INSERT INTO user_settings (user_id, notifications_enabled, study_reminder_time)
SELECT id, TRUE, '09:00' FROM users
ON CONFLICT (user_id) DO NOTHING;
