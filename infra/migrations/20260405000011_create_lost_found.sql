CREATE TABLE lost_found (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    type        SMALLINT NOT NULL,
    title       VARCHAR(100) NOT NULL,
    description TEXT,
    images      JSONB DEFAULT '[]',
    category    VARCHAR(32),
    location    VARCHAR(200),
    contact     VARCHAR(100),
    status      SMALLINT NOT NULL DEFAULT 1,
    serial_no   VARCHAR(30) NOT NULL,
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_lost_found_type     ON lost_found(type, status, created_at DESC);
CREATE INDEX idx_lost_found_category ON lost_found(category);
CREATE UNIQUE INDEX idx_lost_found_serial ON lost_found(serial_no);
