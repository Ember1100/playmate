CREATE TABLE part_time (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       VARCHAR(100) NOT NULL,
    description TEXT,
    images      JSONB DEFAULT '[]',
    salary      VARCHAR(50),
    salary_type SMALLINT DEFAULT 1,
    category    VARCHAR(32),
    location    VARCHAR(100),
    contact     VARCHAR(100),
    status      SMALLINT NOT NULL DEFAULT 1,
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_part_time_category ON part_time(category, status, created_at DESC);
