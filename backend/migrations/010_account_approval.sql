ALTER TABLE users ADD COLUMN IF NOT EXISTS account_status TEXT NOT NULL DEFAULT 'pending';

-- Existing users are already trusted — mark them active
UPDATE users SET account_status = 'active';
