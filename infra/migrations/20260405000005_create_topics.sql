CREATE TABLE topics (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id    UUID NOT NULL REFERENCES users(id),
    title         VARCHAR(200) NOT NULL,
    content       TEXT,
    cover_url     TEXT,
    category      VARCHAR(32),
    like_count    INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    view_count    INTEGER NOT NULL DEFAULT 0,
    is_hot        BOOLEAN NOT NULL DEFAULT false,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_topics_category ON topics(category, created_at DESC);
CREATE INDEX idx_topics_hot      ON topics(is_hot, like_count DESC);
