CREATE TABLE topic_comments (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id   UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id),
    parent_id  UUID REFERENCES topic_comments(id),
    content    TEXT NOT NULL,
    like_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_topic_comments ON topic_comments(topic_id, created_at);
