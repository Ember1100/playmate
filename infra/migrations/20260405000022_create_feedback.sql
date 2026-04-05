CREATE TABLE feedback (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    type       VARCHAR(20) NOT NULL DEFAULT 'suggestion',
    content    TEXT NOT NULL,
    images     JSONB DEFAULT '[]',
    contact    VARCHAR(100),
    status     SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
