CREATE TABLE learning_notes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(200),
    content     TEXT NOT NULL,
    category    VARCHAR(32),
    source_type VARCHAR(20),
    source_id   UUID,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_learning_notes_user ON learning_notes(user_id, created_at DESC);
