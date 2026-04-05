CREATE TABLE polls (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id   UUID NOT NULL REFERENCES users(id),
    title        VARCHAR(200) NOT NULL,
    pro_argument TEXT NOT NULL,
    con_argument TEXT NOT NULL,
    pro_count    INTEGER NOT NULL DEFAULT 0,
    con_count    INTEGER NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
