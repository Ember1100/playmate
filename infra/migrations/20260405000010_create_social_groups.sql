CREATE TABLE social_groups (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id   UUID NOT NULL REFERENCES users(id),
    name         VARCHAR(50) NOT NULL,
    description  TEXT,
    avatar_url   TEXT,
    category     VARCHAR(32),
    member_count INTEGER NOT NULL DEFAULT 1,
    is_public    BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE social_group_members (
    group_id  UUID REFERENCES social_groups(id) ON DELETE CASCADE,
    user_id   UUID REFERENCES users(id) ON DELETE CASCADE,
    role      SMALLINT NOT NULL DEFAULT 1,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);

CREATE TABLE social_group_messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id    UUID NOT NULL REFERENCES social_groups(id),
    sender_id   UUID NOT NULL REFERENCES users(id),
    type        SMALLINT NOT NULL DEFAULT 1,
    content     TEXT,
    media_url   TEXT,
    is_recalled BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_social_group_messages ON social_group_messages(group_id, created_at DESC);
