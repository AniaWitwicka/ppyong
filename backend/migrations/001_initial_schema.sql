-- Users
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT UNIQUE NOT NULL,
    name        TEXT NOT NULL,
    role        TEXT NOT NULL DEFAULT 'learner',
    streak      INTEGER NOT NULL DEFAULT 0,
    last_active DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Collections (folders)
CREATE TABLE collections (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title       TEXT NOT NULL,
    description TEXT,
    created_by  UUID NOT NULL REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Decks (inside collections)
CREATE TABLE decks (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    title         TEXT NOT NULL,
    description   TEXT,
    created_by    UUID NOT NULL REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Cards
CREATE TABLE cards (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id       UUID NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
    korean        TEXT NOT NULL,
    romanisation  TEXT,
    translation   TEXT NOT NULL,
    notes         TEXT,
    position      INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- SRS progress (one row per user per card)
CREATE TABLE srs_progress (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_id         UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    interval_days   INTEGER NOT NULL DEFAULT 1,
    ease_factor     NUMERIC(4,2) NOT NULL DEFAULT 2.5,
    repetitions     INTEGER NOT NULL DEFAULT 0,
    due_date        DATE NOT NULL DEFAULT CURRENT_DATE,
    last_reviewed   TIMESTAMPTZ,
    UNIQUE(user_id, card_id)
);

-- Indexes
CREATE INDEX idx_srs_user_due ON srs_progress(user_id, due_date);
CREATE INDEX idx_cards_deck ON cards(deck_id);
CREATE INDEX idx_decks_collection ON decks(collection_id);
