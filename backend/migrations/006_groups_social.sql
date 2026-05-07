-- Groups
CREATE TABLE IF NOT EXISTS groups (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT        NOT NULL,
    emoji      TEXT        NOT NULL DEFAULT '🇰🇷',
    color      TEXT        NOT NULL DEFAULT '#F296BD',
    created_by UUID        REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Group membership
CREATE TABLE IF NOT EXISTS group_members (
    group_id  UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id   UUID        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    role      TEXT        NOT NULL DEFAULT 'member', -- 'owner' | 'member'
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);

-- Invites (email-based, user resolved on accept)
CREATE TABLE IF NOT EXISTS invites (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id         UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    inviter_id       UUID        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    invitee_email    TEXT        NOT NULL,
    invitee_user_id  UUID        REFERENCES users(id) ON DELETE SET NULL,
    status           TEXT        NOT NULL DEFAULT 'pending', -- 'pending' | 'accepted' | 'declined'
    expires_at       TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '7 days',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Friendships (directional request → accepted)
CREATE TABLE IF NOT EXISTS friends (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status       TEXT        NOT NULL DEFAULT 'pending', -- 'pending' | 'accepted'
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (requester_id, addressee_id)
);
