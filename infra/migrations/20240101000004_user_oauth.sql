-- 第三方账号绑定（支持微信 / Apple / Google 等扩展）
CREATE TABLE user_oauth (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider     VARCHAR(20)  NOT NULL,          -- 'wechat' | 'apple' | 'google'
    provider_id  VARCHAR(128) NOT NULL,          -- 微信 openid / Apple sub / Google sub
    access_token TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (provider, provider_id)
);

CREATE INDEX idx_user_oauth_user ON user_oauth(user_id);
