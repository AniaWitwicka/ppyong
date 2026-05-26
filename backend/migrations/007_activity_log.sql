CREATE TABLE IF NOT EXISTS activity_log (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    group_id   UUID        REFERENCES groups(id)          ON DELETE SET NULL,
    kind       TEXT        NOT NULL, -- 'mastered' | 'streak' | 'quiz' | 'weak'
    subject    TEXT        NOT NULL, -- Korean word or deck name
    target     TEXT        NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS activity_log_group_created_idx ON activity_log(group_id, created_at DESC);
CREATE INDEX IF NOT EXISTS activity_log_user_created_idx  ON activity_log(user_id,  created_at DESC);
