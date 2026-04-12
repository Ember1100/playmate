# CLAUDE.md — 搭伴 (Playmate)

## 最近更新（Claude Code 每次启动必读）

| 日期 | 章节 | 变更内容 |
|------|------|---------|
| 2026-04-12 | Flutter公共组件 | 新增PmImage/PmImageProvider规范，禁止直接使用Image.network/NetworkImage |
| 2026-04-12 | Tab顺序 | 修正为圈子/集市/搭子/趣玩/我的，uni-app pages.json同步更新 |
| 2026-04-11 | uni-app 规范 | 新增微信小程序客户端规范，与Flutter共享后端API |
| 2026-04-05 | Flutter转场手势 | 淡入淡出转场、PmSwipeBack手势返回组件规范 |
| 2026-04-05 | 全面重写v2 | 根据功能架构全览图补全所有模块，明确MVP边界 |

> 本文件是 Claude Code 的核心上下文。每次开始新任务前必须完整阅读。
> 所有代码生成、架构决策、命名约定均以此文件为准。
> 遇到冲突以本文件为准，忽略历史对话中的旧方案。

---

## MVP 功能边界（开发前必读）

### 做 ✅
- 登录：手机号验证 + 短信验证码 + 微信登录 + 新人问卷 + 账号找回/注销
- 圈子：话题/投票/评论/社群聊天
- 集市：失物招领/二手闲置/兼职啦/以物换物（纯信息发布，无支付）
- 搭子：搭子推荐/邀约发送/邀约管理/职业搭子阵地
- 趣玩：静态展示（无报名/拼团后端接口）
- 我的：个人主页/成长值积分展示/收藏/消息通知/会员中心/成长报告/需求反馈

### 不做 ❌（后期迭代）
- 支付/交易担保/拼团订单
- 技能卡牌、元宇宙社交、数字藏品
- 未成年人模式
- 兼职评价、交易纠纷处理
- 活动报名（趣玩模块后端接口）

---

## 产品定位

**搭伴（Playmate）** — 兴趣社交 + 本地生活服务 App

底部 5 个 Tab：

| Tab | 名称 | MVP 核心功能 |
|-----|------|-------------|
| Tab1 | 圈子 | 话题/投票/评论/社群聊天 |
| Tab2 | 集市 | 失物招领/二手闲置/兼职啦/以物换物 |
| Tab3 | 搭子 | 搭子推荐/邀约/职业搭子阵地 |
| Tab4 | 趣玩 | 静态展示活动内容 |
| Tab5 | 我的 | 个人主页/成长值/收藏/消息/会员 |

---

## 技术栈

- 客户端：Flutter（iOS / Android）
- 后端：Rust + Axum，Workspace monorepo
- 数据库：PostgreSQL + Redis
- 消息队列：Redis Streams（MVP），后期迁移 Kafka
- 实时通信：WebSocket（Axum 原生）
- 对象存储：MinIO（开发）→ 阿里云 OSS（生产）
- 部署：GitHub Actions → 阿里云服务器 systemd

---

## 项目结构

```
playmate/
├── CLAUDE.md
├── Cargo.toml
├── backend/
│   └── crates/
│       ├── playmate-common/    ← 错误/响应/JWT/缓存/存储/中间件
│       ├── playmate-gateway/   ← Axum 主进程，路由聚合
│       ├── playmate-user/      ← 用户/认证/问卷/账号管理
│       ├── playmate-circle/    ← 圈子：话题/投票/评论/社群
│       ├── playmate-market/    ← 集市：失物/闲置/兼职/换物
│       ├── playmate-buddy/     ← 搭子：推荐/邀约/职业阵地
│       └── playmate-im/        ← 私信/群聊/WebSocket
├── flutter_app/                ← Flutter 客户端（iOS/Android）
├── miniprogram/                ← uni-app 客户端（微信小程序）
└── infra/
    ├── docker-compose.prod.yml
    ├── .env.prod
    └── migrations/
```

### Workspace Cargo.toml

```toml
[workspace]
members = [
    "backend/crates/playmate-common",
    "backend/crates/playmate-gateway",
    "backend/crates/playmate-user",
    "backend/crates/playmate-circle",
    "backend/crates/playmate-market",
    "backend/crates/playmate-buddy",
    "backend/crates/playmate-im",
]
resolver = "2"

[workspace.dependencies]
axum = { version = "0.7", features = ["ws", "multipart", "macros"] }
tokio = { version = "1", features = ["full"] }
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio-native-tls", "uuid", "chrono", "json"] }
redis = { version = "0.24", features = ["tokio-comp", "connection-manager"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace", "compression-gzip", "request-id"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
jsonwebtoken = "9"
uuid = { version = "1", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
anyhow = "1"
thiserror = "1"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
validator = { version = "0.18", features = ["derive"] }
argon2 = "0.5"
rand = "0.8"
aws-sdk-s3 = "1"
aws-config = { version = "1", default-features = false, features = ["behavior-version-latest"] }
reqwest = { version = "0.11", features = ["json", "rustls-tls"] }
dashmap = "5"
```

---

## 错误处理规范

```rust
// playmate-common/src/error.rs
#[derive(Error, Debug)]
pub enum AppError {
    #[error("未授权: {0}")]       Unauthorized(String),
    #[error("禁止访问: {0}")]     Forbidden(String),
    #[error("资源未找到: {0}")]   NotFound(String),
    #[error("请求参数错误: {0}")] BadRequest(String),
    #[error("业务错误: {0}")]     Business(String),
    #[error("数据库错误: {0}")]   Database(#[from] sqlx::Error),
    #[error("Redis错误: {0}")]    Redis(#[from] redis::RedisError),
    #[error("内部服务器错误")]    Internal(#[from] anyhow::Error),
}
pub type AppResult<T> = Result<T, AppError>;
```

规则：
- 所有 handler 返回 `Result<impl IntoResponse, AppError>`
- 禁止在 handler 层 `unwrap()` / `expect()`
- `sqlx::Error::RowNotFound` → `AppError::NotFound`

---

## API 响应格式

```json
{ "success": true,  "code": "SUCCESS",     "message": "成功",     "data": {...} }
{ "success": false, "code": "BAD_REQUEST", "message": "参数错误", "data": null  }
```

```rust
pub struct ApiResponse<T: Serialize>  { success: bool, code: String, message: String, data: Option<T> }
pub struct PageResponse<T: Serialize> { items: Vec<T>, total: i64, page: i64, limit: i64, has_more: bool }
```

---

## 数据库规范

- 驱动：**SQLx 原始 SQL**，禁止 ORM
- 迁移：只写 UP，格式 `{timestamp}_{描述}.sql`
- RowNotFound 统一转 `AppError::NotFound`

### 迁移文件顺序

```
20260405000000_create_users.sql
20260405000001_create_tags.sql
20260405000002_create_user_oauth.sql
20260405000003_create_user_stats.sql
20260405000004_create_user_questionnaire.sql
20260405000005_create_topics.sql
20260405000006_create_topic_comments.sql
20260405000007_create_topic_likes.sql
20260405000008_create_polls.sql
20260405000009_create_poll_votes.sql
20260405000010_create_social_groups.sql
20260405000011_create_lost_found.sql
20260405000012_create_second_hand.sql
20260405000013_create_part_time.sql
20260405000014_create_barter.sql
20260405000015_create_market_collects.sql
20260405000016_create_buddy_requests.sql
20260405000017_create_buddy_invitations.sql
20260405000018_create_career_profiles.sql
20260405000019_create_conversations.sql
20260405405020_create_messages.sql
20260405000021_create_notifications.sql
20260405000022_create_feedback.sql
```

### 完整表结构 SQL

```sql
-- ════════════════════════════════
-- 用户体系
-- ════════════════════════════════

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username      VARCHAR(32) NOT NULL UNIQUE,
    phone         VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255),
    avatar_url    TEXT,
    bio           TEXT,
    gender        SMALLINT DEFAULT 0,      -- 0未知 1男 2女 3其他
    birthday      DATE,
    is_verified   BOOLEAN NOT NULL DEFAULT false,  -- 手机号验证完成
    is_new_user   BOOLEAN NOT NULL DEFAULT true,   -- 是否完成新人问卷
    is_active     BOOLEAN NOT NULL DEFAULT true,
    last_seen_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_users_phone ON users(phone);

-- 兴趣标签
CREATE TABLE tags (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(32) NOT NULL UNIQUE,
    category   VARCHAR(32) NOT NULL,
    sort_order INTEGER DEFAULT 0
);
CREATE TABLE user_tags (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tag_id  INTEGER REFERENCES tags(id),
    PRIMARY KEY (user_id, tag_id)
);

-- 第三方登录
CREATE TABLE user_oauth (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider    VARCHAR(20) NOT NULL,    -- 'wechat' | 'apple'
    provider_id VARCHAR(128) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (provider, provider_id)
);

-- 用户统计（成长值/积分/收藏，MVP展示）
CREATE TABLE user_stats (
    user_id       UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    growth_value  INTEGER NOT NULL DEFAULT 0,
    points        INTEGER NOT NULL DEFAULT 0,
    collect_count INTEGER NOT NULL DEFAULT 0,
    level         SMALLINT NOT NULL DEFAULT 1,  -- 会员等级 Lv.1~10
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 新人问卷（登录后引导填写）
CREATE TABLE user_questionnaire (
    user_id      UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    interests    JSONB DEFAULT '[]',   -- 选择的兴趣标签ID数组
    purposes     JSONB DEFAULT '[]',   -- 使用目的：找搭子/逛集市/看圈子等
    age_range    VARCHAR(10),          -- '18-22'/'23-28'/'29-35'/'35+'
    city         VARCHAR(50),
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ════════════════════════════════
-- 圈子（Tab1）
-- ════════════════════════════════

-- 话题
CREATE TABLE topics (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id    UUID NOT NULL REFERENCES users(id),
    title         VARCHAR(200) NOT NULL,
    content       TEXT,
    cover_url     TEXT,
    category      VARCHAR(32),  -- hot/follow/growth/career
    like_count    INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    view_count    INTEGER NOT NULL DEFAULT 0,
    is_hot        BOOLEAN NOT NULL DEFAULT false,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_topics_category ON topics(category, created_at DESC);
CREATE INDEX idx_topics_hot      ON topics(is_hot, like_count DESC);

-- 话题评论（支持二级回复）
CREATE TABLE topic_comments (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id   UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id),
    parent_id  UUID REFERENCES topic_comments(id),
    content    TEXT NOT NULL,
    like_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_topic_comments ON topic_comments(topic_id, created_at);

CREATE TABLE topic_likes (
    topic_id   UUID REFERENCES topics(id) ON DELETE CASCADE,
    user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (topic_id, user_id)
);

-- 观点投票
CREATE TABLE polls (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id   UUID NOT NULL REFERENCES users(id),
    title        VARCHAR(200) NOT NULL,
    pro_argument TEXT NOT NULL,
    con_argument TEXT NOT NULL,
    pro_count    INTEGER NOT NULL DEFAULT 0,
    con_count    INTEGER NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE poll_votes (
    poll_id    UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    side       SMALLINT NOT NULL,  -- 1=正方 2=反方
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (poll_id, user_id)
);

-- 社群（圈子内的群聊，独立于私信群聊）
CREATE TABLE social_groups (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id   UUID NOT NULL REFERENCES users(id),
    name         VARCHAR(50) NOT NULL,
    description  TEXT,
    avatar_url   TEXT,
    category     VARCHAR(32),           -- 对应圈子分类
    member_count INTEGER NOT NULL DEFAULT 1,
    is_public    BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE social_group_members (
    group_id  UUID REFERENCES social_groups(id) ON DELETE CASCADE,
    user_id   UUID REFERENCES users(id) ON DELETE CASCADE,
    role      SMALLINT NOT NULL DEFAULT 1,  -- 1成员 2管理员 3群主
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

-- ════════════════════════════════
-- 集市（Tab2）— 4个子功能
-- ════════════════════════════════

-- 失物招领
CREATE TABLE lost_found (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    type        SMALLINT NOT NULL,       -- 1=失物 2=招领
    title       VARCHAR(100) NOT NULL,
    description TEXT,
    images      JSONB DEFAULT '[]',
    category    VARCHAR(32),             -- 证件/电子/衣物/其他
    location    VARCHAR(200),
    contact     VARCHAR(100),
    status      SMALLINT NOT NULL DEFAULT 1,  -- 1发布中 2已解决
    serial_no   VARCHAR(30) NOT NULL,    -- 编号，如 05-058-26-32
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_lost_found_type     ON lost_found(type, status, created_at DESC);
CREATE INDEX idx_lost_found_category ON lost_found(category);
CREATE UNIQUE INDEX idx_lost_found_serial ON lost_found(serial_no);

-- 二手闲置
CREATE TABLE second_hand (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       VARCHAR(100) NOT NULL,
    description TEXT,
    images      JSONB DEFAULT '[]',
    price       DECIMAL(10,2) NOT NULL DEFAULT 0,
    category    VARCHAR(32),             -- 数码/服装/书籍/家具/其他
    condition   SMALLINT NOT NULL DEFAULT 1,  -- 1全新 2九成新 3八成新 4其他
    location    VARCHAR(100),
    contact     VARCHAR(100),
    status      SMALLINT NOT NULL DEFAULT 1,  -- 1在售 2已售
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_second_hand_category ON second_hand(category, status, created_at DESC);

-- 兼职啦
CREATE TABLE part_time (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       VARCHAR(100) NOT NULL,
    description TEXT,
    images      JSONB DEFAULT '[]',
    salary      VARCHAR(50),             -- "150元/天"
    salary_type SMALLINT DEFAULT 1,      -- 1按天 2按小时 3按次 4面议
    category    VARCHAR(32),             -- 促销/家教/配送/文职/其他
    location    VARCHAR(100),
    contact     VARCHAR(100),
    status      SMALLINT NOT NULL DEFAULT 1,  -- 1招募中 2已结束
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_part_time_category ON part_time(category, status, created_at DESC);

-- 以物换物
CREATE TABLE barter (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       VARCHAR(100) NOT NULL,
    description TEXT,
    images      JSONB DEFAULT '[]',
    offer_item  VARCHAR(100) NOT NULL,   -- 我有
    want_item   VARCHAR(100) NOT NULL,   -- 我想要
    category    VARCHAR(32),
    location    VARCHAR(100),
    contact     VARCHAR(100),
    status      SMALLINT NOT NULL DEFAULT 1,  -- 1换物中 2已完成
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_barter_category ON barter(category, status, created_at DESC);

-- 集市收藏（统一收藏4种内容）
CREATE TABLE market_collects (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL,   -- 'lost_found'|'second_hand'|'part_time'|'barter'
    target_id   UUID NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, target_type, target_id)
);

-- ════════════════════════════════
-- 搭子（Tab3）
-- ════════════════════════════════

-- 搭子匹配请求
CREATE TABLE buddy_requests (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id UUID NOT NULL REFERENCES users(id),
    to_user_id   UUID NOT NULL REFERENCES users(id),
    type         SMALLINT NOT NULL DEFAULT 1,  -- 1线上 2线下 3职业
    message      TEXT,
    status       SMALLINT NOT NULL DEFAULT 0,  -- 0待响应 1已接受 2已拒绝
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT no_self_buddy CHECK (from_user_id != to_user_id)
);
CREATE INDEX idx_buddy_requests_to ON buddy_requests(to_user_id, status);

-- 邀约（发送/管理页）
CREATE TABLE buddy_invitations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id UUID NOT NULL REFERENCES users(id),
    to_user_id   UUID NOT NULL REFERENCES users(id),
    title        VARCHAR(100) NOT NULL,   -- 邀约主题
    content      TEXT,                    -- 邀约描述
    activity_type VARCHAR(32),            -- 活动类型：爬山/看电影/打球等
    scheduled_at TIMESTAMPTZ,             -- 约定时间
    location     VARCHAR(200),
    status       SMALLINT NOT NULL DEFAULT 0,  -- 0待响应 1已接受 2已拒绝 3已过期
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT no_self_invite CHECK (from_user_id != to_user_id)
);
CREATE INDEX idx_invitations_to   ON buddy_invitations(to_user_id, status);
CREATE INDEX idx_invitations_from ON buddy_invitations(from_user_id, status);

-- 职业搭子阵地（职业名片/展示）
CREATE TABLE career_profiles (
    user_id      UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    job_title    VARCHAR(100),            -- 职位
    company      VARCHAR(100),            -- 公司/行业
    skills       JSONB DEFAULT '[]',      -- 技能标签
    experience   TEXT,                    -- 经验描述
    looking_for  TEXT,                    -- 寻找方向
    is_public    BOOLEAN NOT NULL DEFAULT true,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ════════════════════════════════
-- IM：私信
-- ════════════════════════════════

CREATE TABLE conversations (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id  UUID NOT NULL REFERENCES users(id),
    user_b_id  UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_a_id, user_b_id)
);
CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    sender_id       UUID NOT NULL REFERENCES users(id),
    type            SMALLINT NOT NULL DEFAULT 1,  -- 1文字 2图片 3语音
    content         TEXT,
    media_url       TEXT,
    is_recalled     BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at DESC);

-- ════════════════════════════════
-- 通知 & 反馈
-- ════════════════════════════════

-- 消息通知（消息中心页）
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(30) NOT NULL,     -- 'buddy_request'|'invitation'|'topic_comment'|'system'
    title       VARCHAR(100) NOT NULL,
    content     TEXT,
    target_type VARCHAR(30),              -- 关联对象类型
    target_id   UUID,                     -- 关联对象ID
    is_read     BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- 需求反馈（我的模块）
CREATE TABLE feedback (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    type       VARCHAR(20) NOT NULL DEFAULT 'suggestion',  -- suggestion/bug/other
    content    TEXT NOT NULL,
    images     JSONB DEFAULT '[]',
    contact    VARCHAR(100),
    status     SMALLINT NOT NULL DEFAULT 0,  -- 0待处理 1已处理
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## API 路由规范

```
# ── 认证（playmate-user）─────────────────────────────────
POST   /api/v1/auth/sms/send
POST   /api/v1/auth/sms/verify             ← 验证成功返回 JWT + is_new_user
POST   /api/v1/auth/wechat/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
DELETE /api/v1/auth/account                ← 账号注销

# ── 用户（playmate-user）─────────────────────────────────
GET    /api/v1/users/me
PUT    /api/v1/users/me
GET    /api/v1/users/me/stats              ← 成长值/积分/收藏数/等级
POST   /api/v1/users/me/tags
POST   /api/v1/users/me/questionnaire      ← 新人问卷提交
GET    /api/v1/users/me/career             ← 我的职业名片
PUT    /api/v1/users/me/career
GET    /api/v1/users/:id
GET    /api/v1/users/:id/career

# ── 圈子（playmate-circle）───────────────────────────────
GET    /api/v1/topics                      ← ?category=hot&page=1
POST   /api/v1/topics
GET    /api/v1/topics/:id
DELETE /api/v1/topics/:id
POST   /api/v1/topics/:id/like
DELETE /api/v1/topics/:id/like
GET    /api/v1/topics/:id/comments
POST   /api/v1/topics/:id/comments
DELETE /api/v1/topics/comments/:comment_id

POST   /api/v1/polls
GET    /api/v1/polls                       ← 今日投票列表
POST   /api/v1/polls/:id/vote              ← { "side": 1|2 }

GET    /api/v1/circle/groups               ← 社群列表
POST   /api/v1/circle/groups
GET    /api/v1/circle/groups/:id
POST   /api/v1/circle/groups/:id/join
POST   /api/v1/circle/groups/:id/leave
GET    /api/v1/circle/groups/:id/messages

# ── 集市-失物招领（playmate-market）─────────────────────
GET    /api/v1/market/lost-found           ← ?type=1&category=证件&keyword=xx&page=1
POST   /api/v1/market/lost-found
GET    /api/v1/market/lost-found/:id
PUT    /api/v1/market/lost-found/:id
DELETE /api/v1/market/lost-found/:id
POST   /api/v1/market/lost-found/:id/resolve

# ── 集市-二手闲置（playmate-market）─────────────────────
GET    /api/v1/market/second-hand          ← ?category=数码&page=1
POST   /api/v1/market/second-hand
GET    /api/v1/market/second-hand/:id
PUT    /api/v1/market/second-hand/:id
DELETE /api/v1/market/second-hand/:id
POST   /api/v1/market/second-hand/:id/sold

# ── 集市-兼职啦（playmate-market）───────────────────────
GET    /api/v1/market/part-time            ← ?category=促销&page=1
POST   /api/v1/market/part-time
GET    /api/v1/market/part-time/:id
PUT    /api/v1/market/part-time/:id
DELETE /api/v1/market/part-time/:id

# ── 集市-以物换物（playmate-market）─────────────────────
GET    /api/v1/market/barter               ← ?page=1
POST   /api/v1/market/barter
GET    /api/v1/market/barter/:id
PUT    /api/v1/market/barter/:id
DELETE /api/v1/market/barter/:id

# ── 集市-收藏（playmate-market）─────────────────────────
POST   /api/v1/market/collect
DELETE /api/v1/market/collect
GET    /api/v1/market/collect/mine

# ── 搭子（playmate-buddy）───────────────────────────────
GET    /api/v1/buddy/candidates            ← ?type=1（线上/线下/职业）
POST   /api/v1/buddy/request               ← 发起搭子请求
PUT    /api/v1/buddy/request/:id/respond   ← { "accept": true|false }
GET    /api/v1/buddy/mine                  ← 我的搭子列表

POST   /api/v1/buddy/invitations           ← 发送邀约
GET    /api/v1/buddy/invitations/sent      ← 我发出的邀约
GET    /api/v1/buddy/invitations/received  ← 我收到的邀约
PUT    /api/v1/buddy/invitations/:id/respond

GET    /api/v1/buddy/career                ← 职业搭子阵地列表
GET    /api/v1/buddy/career/:user_id

# ── 趣玩（静态，无后端接口）────────────────────────────

# ── IM 私信（playmate-im）───────────────────────────────
GET    /api/v1/im/conversations
POST   /api/v1/im/conversations
GET    /api/v1/im/conversations/:id/messages
WS     /api/v1/im/ws                       ← 统一 WebSocket（私信+社群消息）

# ── 通知（playmate-user）────────────────────────────────
GET    /api/v1/notifications               ← ?page=1
POST   /api/v1/notifications/read-all      ← 全部已读
POST   /api/v1/notifications/:id/read

# ── 反馈（playmate-user）────────────────────────────────
POST   /api/v1/feedback

# ── 文件上传（playmate-common）──────────────────────────
POST   /api/v1/upload/avatar
POST   /api/v1/upload/market               ← 集市图片（通用）
POST   /api/v1/upload/topic
POST   /api/v1/upload/voice
```

---

## 应用状态（AppState）

```rust
#[derive(Clone)]
pub struct AppState {
    pub db:      PgPool,
    pub redis:   ConnectionManager,
    pub config:  Arc<AppConfig>,
    pub storage: Arc<StorageService>,
    pub hub:     Arc<ConnectionHub>,   // WebSocket 连接注册表
}
```

---

## WebSocket 协议

统一入口 `WS /api/v1/im/ws`，处理私信 + 社群消息。

```rust
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ClientMessage {
    SendDm          { conversation_id: Uuid, msg_type: u8, content: Option<String>, media_url: Option<String> },
    SendGroup       { group_id: Uuid, msg_type: u8, content: Option<String>, media_url: Option<String> },
    MarkRead        { conversation_id: Uuid },
    Ping,
}

#[serde(tag = "type", rename_all = "snake_case")]
pub enum ServerMessage {
    NewDm           { message_id: Uuid, conversation_id: Uuid, sender_id: Uuid, msg_type: u8, content: Option<String>, created_at: String },
    NewGroup        { message_id: Uuid, group_id: Uuid, sender_id: Uuid, msg_type: u8, content: Option<String>, created_at: String },
    NewNotification { notification_id: Uuid, ntype: String, title: String, content: Option<String> },
    MessageAck      { message_id: Uuid, status: String },
    Pong,
    Error           { code: String, message: String },
}
```

---

## 认证规范

### 登录流程

```
1. POST /auth/sms/send        → 发送验证码
2. POST /auth/sms/verify      → 验证 → 返回 JWT + { is_new_user: bool }
3. 若 is_new_user=true        → Flutter 跳转新人问卷页
4. POST /users/me/questionnaire → 提交问卷 → 跳转首页
```

### JWT

```rust
pub struct Claims { pub sub: Uuid, pub username: String, pub exp: usize, pub iat: usize }
// Access Token: 2h，Refresh Token: 30d
```

### Redis Key 规范

```
sms:code:{phone}                  → 验证码（TTL 300s）
sms:limit:{phone}                 → 发送限流（TTL 60s）
session:refresh:{user_id}:{hash}  → refresh token（TTL 30d）
online:user:{user_id}             → 在线状态（TTL 60s，心跳续期）
unread:dm:{user_id}:{conv_id}     → 私信未读数
unread:group:{user_id}:{group_id} → 社群未读数
unread:notify:{user_id}           → 通知未读数
rate:limit:{ip}:{endpoint}        → 限流计数（TTL 60s）
```

---

## 对象存储规范

```bash
# 开发（MinIO）
STORAGE_ENDPOINT=http://localhost:9000
STORAGE_PUBLIC_ENDPOINT=http://8.138.190.48:9000
STORAGE_ACCESS_KEY=playmate
STORAGE_SECRET_KEY=playmate123
STORAGE_REGION=us-east-1

# 生产（阿里云 OSS，上线切换，代码零改动）
# STORAGE_ENDPOINT=https://oss-cn-hangzhou-internal.aliyuncs.com
# STORAGE_PUBLIC_ENDPOINT=https://bucket.oss-cn-hangzhou.aliyuncs.com
# STORAGE_ACCESS_KEY=...  STORAGE_SECRET_KEY=...  STORAGE_REGION=cn-hangzhou
```

| Bucket | 用途 |
|--------|------|
| `avatars` | 用户头像 |
| `market` | 集市图片（4种内容通用） |
| `topics` | 话题配图 |
| `voices` | 语音消息 |

---

## 环境变量完整清单

```bash
DATABASE_URL=postgres://playmate:playmate@localhost:5432/playmate
REDIS_URL=redis://localhost:6379
JWT_SECRET=至少32位随机字符串
JWT_REFRESH_SECRET=另一个32位随机字符串
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
RUST_LOG=playmate=debug,tower_http=debug,sqlx=warn
WECHAT_APP_ID=wx...
WECHAT_APP_SECRET=...
ALIYUN_SMS_ACCESS_KEY=...
ALIYUN_SMS_SECRET=...
ALIYUN_SMS_SIGN_NAME=搭伴
ALIYUN_SMS_TEMPLATE_CODE=SMS_...
STORAGE_ENDPOINT=http://localhost:9000
STORAGE_PUBLIC_ENDPOINT=http://8.138.190.48:9000
STORAGE_ACCESS_KEY=playmate
STORAGE_SECRET_KEY=playmate123
STORAGE_REGION=us-east-1
POSTGRES_PASSWORD=playmate
MINIO_ROOT_USER=playmate
MINIO_ROOT_PASSWORD=playmate123
```

---

## Flutter 客户端规范

### 路由（go_router）

```
/auth/login
/auth/register
/auth/questionnaire          ← 新人问卷（is_new_user=true 时跳转）

/circle                      ← Tab1 圈子
/circle/topic/:id
/circle/poll/:id
/circle/groups               ← 社群列表
/circle/groups/:id           ← 社群聊天页

/market                      ← Tab2 集市
/market/lost-found
/market/lost-found/:id
/market/lost-found/publish
/market/second-hand
/market/second-hand/:id
/market/second-hand/publish
/market/part-time
/market/part-time/:id
/market/part-time/publish
/market/barter
/market/barter/:id
/market/barter/publish

/buddy                       ← Tab3 搭子
/buddy/candidates
/buddy/invitations           ← 邀约管理
/buddy/career                ← 职业搭子阵地

/fun                         ← Tab4 趣玩（静态）

/profile                     ← Tab5 我的
/profile/notifications       ← 消息中心
/profile/collects            ← 收藏列表
/profile/member              ← 会员中心
/profile/growth-report       ← 成长报告
/profile/feedback            ← 需求反馈
/profile/settings            ← 设置（账号找回/注销入口）

/im/chat/:conversationId     ← 私信聊天
```

### 设计规范

- 主色：`#FF7A00`（活力橙）
- 辅色：`#5DCAA5`（绿）
- 强调：`#E24B4A`（红）
- 页面背景：`#FFF8EC`（暖米黄）
- 圆角：卡片 12px，按钮 8px，标签 20px，头像 50%
- Tab 激活色：`#FF7A00`

### 项目结构

```
flutter_app/lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── core/
│   ├── network/       ← Dio + JWT interceptor
│   ├── storage/       ← flutter_secure_storage
│   └── error/
├── shared/
│   └── widgets/       ← Pm 前缀公共组件
└── features/
    ├── auth/          ← 登录/注册/问卷
    ├── circle/        ← 话题/投票/社群
    ├── market/
    │   ├── lost_found/
    │   ├── second_hand/
    │   ├── part_time/
    │   └── barter/
    ├── buddy/         ← 搭子/邀约/职业阵地
    ├── fun/           ← 趣玩静态
    ├── im/            ← 私信
    └── profile/       ← 我的/通知/收藏/反馈
```

### 状态管理

统一用 `flutter_riverpod`（AsyncNotifier），禁止跨页面 setState。

---

## 代码规范

### Handler 模板

```rust
pub async fn handler_name(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<RequestType>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;
    let result = repo_fn(&state.db, &payload).await?;
    Ok(ApiResponse::ok(result))
}
```

### 禁止事项

- handler 层禁止直接写复杂 SQL（超过3行抽到 repo 函数）
- 禁止 `unwrap()` / `expect()`（测试和 main 初始化除外）
- 禁止硬编码任何配置值
- 禁止在异步上下文使用阻塞 IO

---

## 开发启动

```bash
cd infra && docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
sqlx migrate run --source infra/migrations
cargo watch -x "run --bin playmate-gateway"
cargo clippy -- -D warnings && cargo fmt --check
```

---

## 当前开发状态

### 后端（按优先级）
- [ ] infra/migrations/ — 22个迁移文件
- [ ] playmate-common — error/response/state/jwt/cache/storage
- [ ] playmate-gateway — 路由聚合、main.rs
- [ ] playmate-user — 注册/登录/短信/微信/问卷/通知/反馈
- [ ] playmate-circle — 话题/投票/评论/社群
- [ ] playmate-market — 失物/闲置/兼职/换物（优先失物招领）
- [ ] playmate-buddy — 搭子/邀约/职业阵地
- [ ] playmate-im — 私信/WebSocket

### Flutter（按优先级）
- [ ] 项目骨架（app/core/shared）
- [ ] 登录 + 新人问卷流程
- [ ] Tab2 集市（失物招领优先）
- [ ] Tab1 圈子
- [ ] Tab3 搭子
- [ ] Tab5 我的
- [ ] Tab4 趣玩（静态）

---

## 快速参考

| 需求 | 方案 |
|------|------|
| 密码加密 | `argon2` |
| UUID | `Uuid::new_v4()` |
| 时间戳 | `chrono::Utc::now()` |
| 参数校验 | `validator` + `#[derive(Validate)]` |
| 日志 | `tracing::info!` / `tracing::error!` |
| HTTP客户端 | `reqwest` with `rustls-tls` |
| S3存储 | `aws-sdk-s3`，`force_path_style=true` |
| 短信 | `reqwest` 调阿里云 Dysmsapi |
| 微信换openid | `reqwest` GET `api.weixin.qq.com/sns/oauth2/access_token` |
| 验证码 | `rand::thread_rng().gen_range(100000..999999)` |
| 失物编号 | `{MM}-{DD}{HH}-{mm}-{ss}` 格式如 `05-058-26-32` |
| 通知推送 | WebSocket 实时推送 + notifications 表持久化 |

---

## 补充规范（来自设计规范PPT，2026-04-05）

### Tab 顺序（以此为准）

底部导航顺序（Flutter / uni-app 均以此为准）：

| 位置 | Tab | 说明 |
|------|-----|------|
| 1 | 圈子 | 话题/投票/社群 |
| 2 | 集市 | 失物/闲置/兼职/换物 |
| 3 | 搭子 | 搭子推荐/邀约/职业搭子阵地 |
| 4 | 趣玩 | 活动中心（MVP静态） |
| 5 | 我的 | 个人中心 |

### 用户准入规则

- 平台仅面向 **35岁及以下** 用户开放
- 注册时需校验年龄（生日字段必填）
- 超龄用户注册时提示不符合准入条件

```rust
// playmate-user 注册逻辑中加入年龄校验
fn check_age_limit(birthday: NaiveDate) -> AppResult<()> {
    let age = calculate_age(birthday);
    if age > 35 {
        return Err(AppError::Business("抱歉，本平台仅面向35岁及以下用户".to_string()));
    }
    Ok(())
}
```

### 信用分体系（MVP展示，后期迭代计算逻辑）

```sql
-- 补充到 user_stats 表
ALTER TABLE user_stats ADD COLUMN IF NOT EXISTS
    credit_score INTEGER NOT NULL DEFAULT 600;  -- 600起步，满分1000
-- 展示规则：< 700 普通，700-799 良好，800-899 优秀，900+ 极佳
```

信用分在以下页面展示：
- 搭子详情页：「信用分：850 (优秀)」
- 搭子管理页：列表项显示信用分
- MVP 阶段：默认给所有用户 750 分，不做动态计算

### 新人问卷字段（补充详情）

```sql
-- 更新 user_questionnaire 表字段说明
-- interests: JSONB          多选 3-10 个兴趣标签ID
-- purposes:  JSONB          搭子需求 1-5 个，如饭搭子/学习搭子/运动搭子
-- identity:  VARCHAR(20)    单选：student/worker/family/other
-- city:      VARCHAR(50)    所在城市（地级市）
-- age_range: VARCHAR(10)    '18-22'/'23-28'/'29-35'
-- personality: JSONB NULL   性格测试结果（选填，后期接入MBTI）
-- life_goal: TEXT NULL      生活习惯/目标（选填）
```

问卷接口补充：
```
POST /api/v1/users/me/questionnaire
{
  "identity": "student",
  "city": "上海",
  "interests": [1, 3, 7, 12],     // tag_id 数组，3-10个
  "purposes": [2, 5],              // tag_id 数组，1-5个
  "age_range": "23-28",
  "personality": null,             // 选填
  "life_goal": null                // 选填
}
```

### 学习笔记模块（补充）

「我的」功能中心新增「学习笔记」入口，MVP 先做基础功能：

```sql
-- 新增迁移文件 20260405000023_create_learning_notes.sql
CREATE TABLE learning_notes (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title      VARCHAR(200),
    content    TEXT NOT NULL,
    category   VARCHAR(32),    -- 话题笔记/活动笔记/个人记录
    source_type VARCHAR(20),   -- 'topic'|'activity'|'manual'
    source_id  UUID,           -- 来源ID（话题/活动）
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_learning_notes_user ON learning_notes(user_id, created_at DESC);
```

路由补充：
```
GET    /api/v1/notes               ← 我的笔记列表
POST   /api/v1/notes               ← 新建笔记
GET    /api/v1/notes/:id
PUT    /api/v1/notes/:id
DELETE /api/v1/notes/:id
```

Flutter 路由补充：
```
/profile/notes          ← 学习笔记列表
/profile/notes/:id      ← 笔记详情/编辑
```

### TabBar 高度规范

PPT 明确：底部 TabBar 固定高度 **98px**，悬浮于底部，全局固定显示。

### 搭子详情页核心字段

```
搭子名片展示内容：
- 头像 + 昵称
- 认证标签：「实名认证 · 职业搭子」或「实名认证 · 兴趣搭子」
- 信用分 + 评级（优秀/极佳等）
- 兴趣标签（最多5个）
- 自我介绍（关于我）
- 能提供的服务描述
- 用户评价（最近3条）
- 操作按钮：「发起邀约」「查看阵地」
```

### 消息通知分类（补充）

消息中心分4个 Tab：**全部 / 系统通知 / 搭子邀约 / 互动消息**

对应 notifications 表的 type 字段值：
```
system          → 系统通知（活动提醒等）
buddy_request   → 搭子邀约（接受/拒绝）
interaction     → 互动消息（点赞/评论/回复）
invitation      → 邀约消息
```

---

## Flutter 页面转场与手势规范（2026-04-05）

### 转场动画

统一使用**淡入淡出**转场，禁止 iOS 默认的跟手侧滑动画（页面会跟着手指移动）。

在 `app/theme.dart` 中配置：

```dart
// app/theme.dart
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

// 应用到 ThemeData
ThemeData get theme => ThemeData(
  // ... 其他配置
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS:     _FadePageTransitionsBuilder(),
      TargetPlatform.android: _FadePageTransitionsBuilder(),
    },
  ),
);
```

### 返回手势规范

禁用系统默认侧滑返回后，在每个页面最外层包 `GestureDetector` 实现手势返回：

```dart
// shared/widgets/pm_swipe_back.dart
// 封装成公共组件，所有页面复用

class PmSwipeBack extends StatelessWidget {
  final Widget child;
  const PmSwipeBack({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // 向右滑动速度 > 300px/s 且有页面可返回，则 pop
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300 &&
            Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: child,
    );
  }
}
```

使用方式——每个二级页面（非 Tab 根页面）最外层包裹：

```dart
// 示例：集市详情页
class LostFoundDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PmSwipeBack(          // ← 最外层包裹
      child: Scaffold(
        // ... 页面内容
      ),
    );
  }
}
```

### 规则

- **Tab 根页面**（搭子/趣玩/圈子/集市/我的）：不需要包 `PmSwipeBack`，没有返回操作
- **所有二级及以上页面**：必须包 `PmSwipeBack`
- 拖动过程中页面完全静止，只在手指松开后判断是否返回
- 禁止在单个页面里自定义其他侧滑逻辑，统一用 `PmSwipeBack`

---

## Flutter 公共组件规范（shared/widgets/）

### PmImage — 网络图片（磁盘缓存）

> 文件：`shared/widgets/pm_image.dart`
> 依赖：`cached_network_image`（已在 pubspec.yaml 中）

**禁止**在任何地方直接使用 `Image.network` 或 `NetworkImage`，统一用以下两个封装：

#### `PmImage` — 替代 `Image.network`

```dart
// 基本用法
PmImage(url, width: 80, height: 80, fit: BoxFit.cover)

// 带圆角（PmImage 内部用 ClipRRect，无需外层再套）
PmImage(url, width: 102, height: 82, borderRadius: BorderRadius.circular(10))

// 全尺寸铺满
PmImage(url, width: double.infinity, height: double.infinity)

// 自定义占位符
PmImage(url, placeholder: Container(color: Colors.grey))
```

参数说明：

| 参数 | 类型 | 说明 |
|------|------|------|
| `url` | `String?` | 图片 URL，null 或空字符串显示占位符 |
| `width` | `double?` | 宽度 |
| `height` | `double?` | 高度 |
| `fit` | `BoxFit` | 默认 `BoxFit.cover` |
| `borderRadius` | `BorderRadius?` | 圆角，内部用 ClipRRect 处理 |
| `placeholder` | `Widget?` | 加载中/URL为空时的占位，默认浅黄色块 |

#### `PmImageProvider` — 替代 `NetworkImage`

用于 `CircleAvatar.backgroundImage`、`BoxDecoration.image` 等需要 `ImageProvider` 的场景：

```dart
// 替代 NetworkImage(url)
CircleAvatar(
  backgroundImage: avatarUrl != null ? PmImageProvider(avatarUrl!) : null,
)
```

#### 规则

- **禁止** `Image.network(url, ...)` → 改用 `PmImage(url, ...)`
- **禁止** `NetworkImage(url)` → 改用 `PmImageProvider(url)`
- `loadingBuilder` / `errorBuilder` 已内置，无需手写
- 已在 `ClipRRect` 内的图片：直接把 `Image.network` 换成 `PmImage`，不需要额外传 `borderRadius`

### PmSwipeBack — 手势返回

## uni-app 客户端规范（微信小程序）
 
### 定位
 
与 Flutter App 共享同一套后端 API，样式与交互保持一致，针对小程序平台适配。
 
### 技术栈
 
```
uni-app + Vue3 + Pinia + TypeScript
目标平台：微信小程序（mp-weixin）
```
 
### 项目结构
 
```
miniprogram/
├── src/
│   ├── App.vue
│   ├── main.ts
│   ├── pages.json           ← 页面路由配置（等同 Flutter router.dart）
│   ├── manifest.json        ← 小程序配置
│   ├── uni.scss             ← 全局样式变量
│   ├── api/                 ← 接口封装（对应 Flutter core/network）
│   │   ├── request.ts       ← 封装 uni.request，自动注入 JWT
│   │   ├── auth.ts
│   │   ├── buddy.ts
│   │   ├── circle.ts
│   │   ├── market.ts
│   │   └── im.ts
│   ├── store/               ← Pinia 状态管理（对应 Flutter Riverpod）
│   │   ├── user.ts
│   │   ├── buddy.ts
│   │   └── market.ts
│   ├── components/          ← 公共组件，命名加 Pm 前缀
│   │   ├── PmAvatar.vue
│   │   ├── PmButton.vue
│   │   ├── PmTagChip.vue
│   │   ├── PmEmpty.vue
│   │   └── PmLoading.vue
│   └── pages/               ← 页面，结构与 Flutter features 对应
│       ├── auth/
│       │   ├── login.vue
│       │   └── questionnaire.vue
│       ├── buddy/
│       │   ├── index.vue        ← Tab1 搭子首页
│       │   ├── candidates.vue
│       │   ├── detail.vue
│       │   ├── invitations.vue
│       │   └── career.vue
│       ├── fun/
│       │   └── index.vue        ← Tab2 趣玩（静态）
│       ├── circle/
│       │   ├── index.vue        ← Tab3 圈子首页
│       │   ├── topic-detail.vue
│       │   ├── poll-detail.vue
│       │   ├── groups.vue
│       │   └── group-chat.vue
│       ├── market/
│       │   ├── index.vue        ← Tab4 集市首页
│       │   ├── lost-found/
│       │   │   ├── index.vue
│       │   │   ├── detail.vue
│       │   │   └── publish.vue
│       │   ├── second-hand/
│       │   │   ├── index.vue
│       │   │   ├── detail.vue
│       │   │   └── publish.vue
│       │   ├── part-time/
│       │   │   ├── index.vue
│       │   │   ├── detail.vue
│       │   │   └── publish.vue
│       │   └── barter/
│       │       ├── index.vue
│       │       ├── detail.vue
│       │       └── publish.vue
│       ├── profile/
│       │   ├── index.vue        ← Tab5 我的
│       │   ├── notifications.vue
│       │   ├── collects.vue
│       │   ├── member.vue
│       │   ├── growth-report.vue
│       │   ├── feedback.vue
│       │   ├── notes.vue
│       │   └── settings.vue
│       └── im/
│           └── chat.vue
├── package.json
├── tsconfig.json
└── vite.config.ts
```
 
### 页面路由配置（pages.json）
 
```json
{
  "pages": [
    { "path": "pages/circle/index",   "style": { "navigationBarTitleText": "圈子" } },
    { "path": "pages/market/index",   "style": { "navigationBarTitleText": "集市" } },
    { "path": "pages/buddy/index",    "style": { "navigationBarTitleText": "搭子" } },
    { "path": "pages/fun/index",      "style": { "navigationBarTitleText": "趣玩" } },
    { "path": "pages/profile/index",  "style": { "navigationBarTitleText": "我的" } }
  ],
  "tabBar": {
    "color": "#888780",
    "selectedColor": "#FF7A00",
    "backgroundColor": "#FFFFFF",
    "borderStyle": "white",
    "list": [
      { "pagePath": "pages/circle/index",  "text": "圈子" },
      { "pagePath": "pages/market/index",  "text": "集市" },
      { "pagePath": "pages/buddy/index",   "text": "搭子" },
      { "pagePath": "pages/fun/index",     "text": "趣玩" },
      { "pagePath": "pages/profile/index", "text": "我的" }
    ]
  },
  "subPackages": [
    {
      "root": "pages/auth",
      "pages": ["login", "questionnaire"]
    },
    {
      "root": "pages/buddy",
      "pages": ["candidates", "detail", "invitations", "career"]
    },
    {
      "root": "pages/circle",
      "pages": ["topic-detail", "poll-detail", "groups", "group-chat"]
    },
    {
      "root": "pages/market/lost-found",
      "pages": ["index", "detail", "publish"]
    },
    {
      "root": "pages/market/second-hand",
      "pages": ["index", "detail", "publish"]
    },
    {
      "root": "pages/market/part-time",
      "pages": ["index", "detail", "publish"]
    },
    {
      "root": "pages/market/barter",
      "pages": ["index", "detail", "publish"]
    },
    {
      "root": "pages/profile",
      "pages": ["notifications", "collects", "member", "growth-report", "feedback", "notes", "settings"]
    },
    {
      "root": "pages/im",
      "pages": ["chat"]
    }
  ]
}
```
 
### 全局样式变量（uni.scss）
 
```scss
// 与 Flutter theme.dart 保持一致
$color-primary:    #FF7A00;   // 主色（活力橙）
$color-secondary:  #5DCAA5;   // 辅色（绿）
$color-danger:     #E24B4A;   // 强调（红）
$color-bg:         #FFF8EC;   // 页面背景（暖米黄）
$color-text:       #2C2C2A;   // 主文字
$color-text-gray:  #888780;   // 次要文字
$color-border:     #E8E6E0;   // 边框
 
$radius-card:   24rpx;    // 卡片圆角（12px × 2）
$radius-button: 16rpx;    // 按钮圆角（8px × 2）
$radius-tag:    40rpx;    // 标签圆角（20px × 2）
```
 
> 小程序单位用 `rpx`，换算：`1px = 2rpx`
 
### API 封装（api/request.ts）
 
```typescript
// api/request.ts
const BASE_URL = 'http://8.138.190.48:8080'  // 开发环境
 
export function request<T>(options: {
  url: string
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  data?: object
}): Promise<T> {
  const token = uni.getStorageSync('access_token')
  return new Promise((resolve, reject) => {
    uni.request({
      url: BASE_URL + options.url,
      method: options.method || 'GET',
      data: options.data,
      header: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      success: (res: any) => {
        if (res.data.success) {
          resolve(res.data.data)
        } else {
          // 401 自动跳登录
          if (res.statusCode === 401) {
            uni.navigateTo({ url: '/pages/auth/login' })
          }
          reject(new Error(res.data.message))
        }
      },
      fail: reject,
    })
  })
}
```
 
### 登录流程（小程序特有）
 
微信小程序优先使用微信一键登录：
 
```typescript
// 1. 获取微信 code
wx.login({ success: ({ code }) => {
  // 2. 传给后端换 JWT
  request({ url: '/api/v1/auth/wechat/login', method: 'POST', data: { code } })
    .then((res: any) => {
      uni.setStorageSync('access_token', res.access_token)
      if (res.is_new_user) {
        uni.navigateTo({ url: '/pages/auth/questionnaire' })
      } else {
        uni.switchTab({ url: '/pages/buddy/index' })
      }
    })
}})
```
 
### 状态管理（Pinia）
 
```typescript
// store/user.ts
export const useUserStore = defineStore('user', {
  state: () => ({
    profile: null as UserProfile | null,
    stats: null as UserStats | null,
    isLoggedIn: false,
  }),
  actions: {
    async fetchProfile() {
      this.profile = await request({ url: '/api/v1/users/me' })
    },
  },
})
```
 
### 小程序开发注意事项
 
- **图片上传**：用 `uni.chooseImage` + `uni.uploadFile`，不用 axios
- **WebSocket**：用 `uni.connectSocket` / `uni.onSocketMessage`
- **本地存储**：用 `uni.setStorageSync` / `uni.getStorageSync`（对应 Flutter `flutter_secure_storage`）
- **页面跳转**：Tab 页用 `uni.switchTab`，普通页用 `uni.navigateTo`，返回用 `uni.navigateBack`
- **分包加载**：主包只放5个 Tab 首页，其他页面放 subPackages，减小主包体积
- **rpx 换算**：所有尺寸乘以2，如 Flutter 的 `12.0` → 小程序的 `24rpx`
 
### 核心依赖
 
```json
{
  "dependencies": {
    "pinia": "^2.1",
    "@dcloudio/uni-app": "latest"
  },
  "devDependencies": {
    "typescript": "^5.0",
    "vite": "^5.0",
    "@dcloudio/uni-cli-shared": "latest"
  }
}
```
 
---