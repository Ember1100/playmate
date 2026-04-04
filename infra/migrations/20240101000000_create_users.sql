-- 用户主表
-- email 可为 NULL（支持纯手机号/第三方登录注册）
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username      VARCHAR(32)  NOT NULL UNIQUE,
    email         VARCHAR(255) UNIQUE,           -- nullable：微信/手机注册无需邮箱
    phone         VARCHAR(20)  UNIQUE,           -- UNIQUE：手机号唯一
    password_hash VARCHAR(255),                  -- nullable：第三方登录可无密码
    avatar_url    TEXT,
    bio           TEXT,
    gender        SMALLINT NOT NULL DEFAULT 0,   -- 0未知 1男 2女 3其他
    birthday      DATE,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    last_seen_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL;

-- 兴趣标签
CREATE TABLE tags (
    id       SERIAL PRIMARY KEY,
    name     VARCHAR(32) NOT NULL UNIQUE,
    category VARCHAR(32) NOT NULL   -- music/movie/sport/game/food 等
);

CREATE TABLE user_tags (
    user_id UUID    REFERENCES users(id) ON DELETE CASCADE,
    tag_id  INTEGER REFERENCES tags(id),
    PRIMARY KEY (user_id, tag_id)
);
