CREATE TABLE user_stats (
    user_id       UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    growth_value  INTEGER NOT NULL DEFAULT 0,
    points        INTEGER NOT NULL DEFAULT 0,
    collect_count INTEGER NOT NULL DEFAULT 0,
    level         SMALLINT NOT NULL DEFAULT 1,
    credit_score  INTEGER NOT NULL DEFAULT 600,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
