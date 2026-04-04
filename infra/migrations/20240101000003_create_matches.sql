-- 匹配记录表
CREATE TABLE match_records (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id   UUID NOT NULL REFERENCES users(id),
    user_b_id   UUID NOT NULL REFERENCES users(id),
    score       SMALLINT NOT NULL,              -- 匹配分 0-100
    status      SMALLINT NOT NULL DEFAULT 0,   -- 0待对方响应 1双方接受 2已拒绝
    matched_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT no_self_match CHECK (user_a_id != user_b_id)
);

CREATE INDEX idx_match_user_a ON match_records(user_a_id, status);
CREATE INDEX idx_match_user_b ON match_records(user_b_id, status);
