CREATE TABLE buddy_requests (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id UUID NOT NULL REFERENCES users(id),
    to_user_id   UUID NOT NULL REFERENCES users(id),
    type         SMALLINT NOT NULL DEFAULT 1,
    message      TEXT,
    status       SMALLINT NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT no_self_buddy CHECK (from_user_id != to_user_id)
);
CREATE INDEX idx_buddy_requests_to ON buddy_requests(to_user_id, status);
