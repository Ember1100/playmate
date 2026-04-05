CREATE TABLE barter (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       VARCHAR(100) NOT NULL,
    description TEXT,
    images      JSONB DEFAULT '[]',
    offer_item  VARCHAR(100) NOT NULL,
    want_item   VARCHAR(100) NOT NULL,
    category    VARCHAR(32),
    location    VARCHAR(100),
    contact     VARCHAR(100),
    status      SMALLINT NOT NULL DEFAULT 1,
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_barter_category ON barter(category, status, created_at DESC);
