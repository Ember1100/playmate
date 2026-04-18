-- 搭子局主表
CREATE TABLE IF NOT EXISTS buddy_gathers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(100) NOT NULL,
    location    VARCHAR(200),
    start_time  TIMESTAMPTZ NOT NULL,
    end_time    TIMESTAMPTZ NOT NULL,
    category    VARCHAR(20) NOT NULL DEFAULT '生活',  -- 生活/学习/兴趣/游戏
    theme       VARCHAR(50) NOT NULL DEFAULT '其他',  -- 吃货/看看/运动/游戏/其他
    capacity    INT NOT NULL DEFAULT 8,
    description TEXT,
    vibes       TEXT[] NOT NULL DEFAULT '{}',         -- ['轻松','认真','新手友好']
    status      SMALLINT NOT NULL DEFAULT 0,          -- 0=招募中 1=已满 2=已取消
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 搭子局成员表
CREATE TABLE IF NOT EXISTS buddy_gather_members (
    gather_id   UUID NOT NULL REFERENCES buddy_gathers(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (gather_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_buddy_gathers_category    ON buddy_gathers(category);
CREATE INDEX IF NOT EXISTS idx_buddy_gathers_creator_id  ON buddy_gathers(creator_id);
CREATE INDEX IF NOT EXISTS idx_buddy_gathers_start_time  ON buddy_gathers(start_time);
CREATE INDEX IF NOT EXISTS idx_buddy_gather_members_user ON buddy_gather_members(user_id);
