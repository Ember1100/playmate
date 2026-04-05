CREATE TABLE second_hand (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       VARCHAR(100) NOT NULL,
    description TEXT,
    images      JSONB DEFAULT '[]',
    price       DECIMAL(10,2) NOT NULL DEFAULT 0,
    category    VARCHAR(32),
    condition   SMALLINT NOT NULL DEFAULT 1,
    location    VARCHAR(100),
    contact     VARCHAR(100),
    status      SMALLINT NOT NULL DEFAULT 1,
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_second_hand_category ON second_hand(category, status, created_at DESC);
