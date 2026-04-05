CREATE TABLE buddy_invitations (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id  UUID NOT NULL REFERENCES users(id),
    to_user_id    UUID NOT NULL REFERENCES users(id),
    title         VARCHAR(100) NOT NULL,
    content       TEXT,
    activity_type VARCHAR(32),
    scheduled_at  TIMESTAMPTZ,
    location      VARCHAR(200),
    status        SMALLINT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT no_self_invite CHECK (from_user_id != to_user_id)
);
CREATE INDEX idx_invitations_to   ON buddy_invitations(to_user_id, status);
CREATE INDEX idx_invitations_from ON buddy_invitations(from_user_id, status);
