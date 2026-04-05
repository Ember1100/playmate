# CLAUDE.md — 玩伴 (Playmate)

## 最近更新（Claude Code 每次启动必读）

| 日期 | 章节 | 变更内容 |
|------|------|---------|
| 2026-04-05 | 对象存储规范 | 新增MinIO开发/OSS生产策略、S3接入代码、docker-compose配置 |
| 2026-04-04 | 认证方式规范 | 新增短信验证码/微信登录/user_oauth表/新增环境变量 |
| 2026-04-04 | Flutter 客户端规范 | 新增项目结构/状态管理/路由/设计规范/页面UI描述 |
| 2026-04-04 | 初始版本 | 后端架构/数据库表/WebSocket/JWT/Redis规范 |

> 本文件是 Claude Code 的核心上下文。每次开始新任务前必须完整阅读。
> 所有代码生成、架构决策、命名约定均以此文件为准。

---

## 项目概览

**玩伴（Playmate）** — 一款类 Soul 的兴趣社交 App，核心差异化是**兴趣标签匹配 + 即时通讯 + 动态广场**。

- 客户端：Flutter（iOS / Android）
- 后端：Rust + Axum，Workspace monorepo
- 数据库：PostgreSQL（主存储）+ Redis（缓存/在线状态）
- 消息队列：Redis Streams（MVP），后期迁移 Kafka
- 实时通信：WebSocket（Axum 原生）
- 媒体服务：LiveKit（语音/视频，后期引入）

---

## 项目结构

```
playmate/
├── CLAUDE.md                      ← 本文件
├── Cargo.toml                     ← workspace 根
├── backend/
│   └── crates/
│       ├── playmate-common/       ← 共享：错误类型、DB pool、JWT、中间件
│       ├── playmate-gateway/      ← Axum 主进程，路由聚合，WebSocket 升级
│       ├── playmate-user/         ← 用户注册/登录/Profile/标签
│       ├── playmate-im/           ← 即时通讯，消息存储，会话管理
│       ├── playmate-match/        ← 兴趣匹配，推荐算法
│       └── playmate-feed/         ← 动态广场，Feed 流
├── flutter_app/
│   └── ...
└── infra/
    ├── docker-compose.yml         ← 本地开发环境（PG + Redis）
    └── migrations/                ← SQLx 数据库迁移文件
```

### Workspace Cargo.toml

```toml
[workspace]
members = [
    "backend/crates/playmate-common",
    "backend/crates/playmate-gateway",
    "backend/crates/playmate-user",
    "backend/crates/playmate-im",
    "backend/crates/playmate-match",
    "backend/crates/playmate-feed",
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
```

---

## 错误处理规范（严格遵守）

### 统一错误类型定义在 `common` crate

```rust
// playmate-common/src/error.rs
use axum::{http::StatusCode, response::{IntoResponse, Response}, Json};
use serde_json::json;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("未授权: {0}")]
    Unauthorized(String),

    #[error("禁止访问: {0}")]
    Forbidden(String),

    #[error("资源未找到: {0}")]
    NotFound(String),

    #[error("请求参数错误: {0}")]
    BadRequest(String),

    #[error("业务错误: {0}")]
    Business(String),

    #[error("数据库错误: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Redis错误: {0}")]
    Redis(#[from] redis::RedisError),

    #[error("内部服务器错误")]
    Internal(#[from] anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, message) = match &self {
            AppError::Unauthorized(msg) => (StatusCode::UNAUTHORIZED, "UNAUTHORIZED", msg.clone()),
            AppError::Forbidden(msg) => (StatusCode::FORBIDDEN, "FORBIDDEN", msg.clone()),
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, "NOT_FOUND", msg.clone()),
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, "BAD_REQUEST", msg.clone()),
            AppError::Business(msg) => (StatusCode::UNPROCESSABLE_ENTITY, "BUSINESS_ERROR", msg.clone()),
            AppError::Database(e) => {
                tracing::error!("数据库错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "DB_ERROR", "数据库错误".to_string())
            }
            AppError::Redis(e) => {
                tracing::error!("Redis错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "CACHE_ERROR", "缓存错误".to_string())
            }
            AppError::Internal(e) => {
                tracing::error!("内部错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "服务器内部错误".to_string())
            }
        };

        let body = Json(json!({
            "success": false,
            "code": code,
            "message": message,
            "data": null
        }));

        (status, body).into_response()
    }
}

pub type AppResult<T> = Result<T, AppError>;
```

### 规则

- **所有 handler 函数**返回类型必须是 `Result<impl IntoResponse, AppError>`
- **禁止** 在 handler 层使用 `unwrap()` 或 `expect()`，只允许在测试和 main 初始化中使用
- 跨 crate 调用用 `anyhow::Context` 添加上下文：`.context("查询用户失败")?`
- 数据库 not found 统一转换：`sqlx::Error::RowNotFound` → `AppError::NotFound`

---

## API 响应格式（所有接口必须遵守）

```rust
// playmate-common/src/response.rs
use serde::Serialize;
use axum::{response::{IntoResponse, Response}, Json, http::StatusCode};

#[derive(Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub code: String,
    pub message: String,
    pub data: Option<T>,
}

impl<T: Serialize> ApiResponse<T> {
    pub fn ok(data: T) -> Json<Self> {
        Json(Self {
            success: true,
            code: "SUCCESS".to_string(),
            message: "成功".to_string(),
            data: Some(data),
        })
    }

    pub fn ok_empty() -> Json<ApiResponse<()>> {
        Json(ApiResponse {
            success: true,
            code: "SUCCESS".to_string(),
            message: "成功".to_string(),
            data: None,
        })
    }
}
```

所有成功响应示例：
```json
{ "success": true, "code": "SUCCESS", "message": "成功", "data": { ... } }
```

所有失败响应示例：
```json
{ "success": false, "code": "NOT_FOUND", "message": "用户不存在", "data": null }
```

---

## 数据库规范

### 驱动

使用 **SQLx**（原始 SQL + 编译期检查），**不使用** Diesel、SeaORM 等 ORM。

### 连接池初始化

```rust
// playmate-common/src/db.rs
use sqlx::PgPool;

pub async fn create_pool(database_url: &str) -> PgPool {
    sqlx::PgPool::connect(database_url)
        .await
        .expect("无法连接数据库")
}
```

### 查询模式

```rust
// 单条查询
let user = sqlx::query_as!(
    User,
    "SELECT id, username, email, created_at FROM users WHERE id = $1",
    user_id
)
.fetch_one(&pool)
.await
.map_err(|e| match e {
    sqlx::Error::RowNotFound => AppError::NotFound(format!("用户 {} 不存在", user_id)),
    _ => AppError::Database(e),
})?;

// 分页查询（统一格式）
let users = sqlx::query_as!(
    User,
    "SELECT * FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2",
    limit as i64,
    ((page - 1) * limit) as i64
)
.fetch_all(&pool)
.await?;
```

### 迁移文件命名规范

```
infra/migrations/
├── 20240101000000_create_users.sql
├── 20240101000001_create_messages.sql
├── 20240101000002_create_posts.sql
└── 20240101000003_create_matches.sql
```

格式：`{timestamp}_{描述}.sql`，只有 UP migration，不写 DOWN。

### 核心表结构

#### users（用户表）
```sql
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username    VARCHAR(32) NOT NULL UNIQUE,
    email       VARCHAR(255) NOT NULL UNIQUE,
    phone       VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    avatar_url  TEXT,
    bio         TEXT,
    gender      SMALLINT DEFAULT 0,        -- 0未知 1男 2女 3其他
    birthday    DATE,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    last_seen_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
```

#### user_tags（用户兴趣标签）
```sql
CREATE TABLE tags (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(32) NOT NULL UNIQUE,
    category VARCHAR(32) NOT NULL   -- music/movie/sport/game/food 等
);

CREATE TABLE user_tags (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tag_id  INTEGER REFERENCES tags(id),
    PRIMARY KEY (user_id, tag_id)
);
```

#### conversations + messages（IM 核心）
```sql
CREATE TABLE conversations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type        SMALLINT NOT NULL DEFAULT 1,   -- 1私聊 2群聊
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE conversation_members (
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_read_at    TIMESTAMPTZ,
    PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    sender_id       UUID NOT NULL REFERENCES users(id),
    type            SMALLINT NOT NULL DEFAULT 1,  -- 1文字 2图片 3语音 4视频
    content         TEXT,
    media_url       TEXT,
    is_recalled     BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
```

#### posts（动态广场）
```sql
CREATE TABLE posts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    media_urls  JSONB DEFAULT '[]',
    like_count  INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    visibility  SMALLINT NOT NULL DEFAULT 1,  -- 1公开 2仅关注 3私密
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_user ON posts(user_id, created_at DESC);
CREATE INDEX idx_posts_feed ON posts(created_at DESC) WHERE visibility = 1;
```

#### match_records（匹配记录）
```sql
CREATE TABLE match_records (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id   UUID NOT NULL REFERENCES users(id),
    user_b_id   UUID NOT NULL REFERENCES users(id),
    score       SMALLINT NOT NULL,             -- 匹配分 0-100
    status      SMALLINT NOT NULL DEFAULT 0,   -- 0待响应 1双方接受 2已拒绝
    matched_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT no_self_match CHECK (user_a_id != user_b_id)
);
```

---

## 应用状态与依赖注入

```rust
// playmate-common/src/state.rs
use sqlx::PgPool;
use redis::aio::ConnectionManager;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub redis: ConnectionManager,
    pub config: Arc<AppConfig>,
}

// playmate-gateway/src/main.rs 中初始化
let state = AppState {
    db: create_pool(&config.database_url).await,
    redis: ConnectionManager::new(redis::Client::open(config.redis_url.clone())?).await?,
    config: Arc::new(config),
};

let app = Router::new()
    .nest("/api/v1/users", user_routes())
    .nest("/api/v1/im", im_routes())
    .nest("/api/v1/feed", feed_routes())
    .nest("/api/v1/match", match_routes())
    .with_state(state)
    .layer(cors_layer())
    .layer(TraceLayer::new_for_http());
```

---

## WebSocket / IM 架构

### 连接管理

```rust
// playmate-im/src/hub.rs
use dashmap::DashMap;
use tokio::sync::mpsc;
use uuid::Uuid;

pub type WsSender = mpsc::UnboundedSender<WsMessage>;

// 全局连接注册表：user_id -> 发送通道
pub struct ConnectionHub {
    connections: DashMap<Uuid, WsSender>,
}

impl ConnectionHub {
    pub fn new() -> Arc<Self> {
        Arc::new(Self { connections: DashMap::new() })
    }

    pub fn register(&self, user_id: Uuid, tx: WsSender) {
        self.connections.insert(user_id, tx);
    }

    pub fn unregister(&self, user_id: &Uuid) {
        self.connections.remove(user_id);
    }

    pub fn send_to(&self, user_id: &Uuid, msg: WsMessage) -> bool {
        if let Some(tx) = self.connections.get(user_id) {
            tx.send(msg).is_ok()
        } else {
            false
        }
    }
}
```

### WebSocket 消息协议（JSON）

```rust
// playmate-im/src/protocol.rs
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ClientMessage {
    /// 发送消息
    SendMessage {
        conversation_id: Uuid,
        msg_type: u8,     // 1文字 2图片 3语音
        content: Option<String>,
        media_url: Option<String>,
    },
    /// 标记已读
    MarkRead {
        conversation_id: Uuid,
        last_read_at: String,
    },
    /// 心跳
    Ping,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ServerMessage {
    /// 新消息推送
    NewMessage {
        message_id: Uuid,
        conversation_id: Uuid,
        sender_id: Uuid,
        msg_type: u8,
        content: Option<String>,
        media_url: Option<String>,
        created_at: String,
    },
    /// 消息发送确认
    MessageAck {
        message_id: Uuid,
        status: String,   // "delivered" | "failed"
    },
    /// 对方正在输入
    Typing {
        conversation_id: Uuid,
        user_id: Uuid,
    },
    /// 心跳响应
    Pong,
    /// 错误通知
    Error {
        code: String,
        message: String,
    },
}
```

### WebSocket Handler 模板

```rust
// playmate-im/src/handler.rs
pub async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    Extension(current_user): Extension<CurrentUser>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state, current_user))
}

async fn handle_socket(socket: WebSocket, state: AppState, user: CurrentUser) {
    let (mut sender, mut receiver) = socket.split();
    let (tx, mut rx) = mpsc::unbounded_channel::<ServerMessage>();

    // 注册连接
    state.hub.register(user.id, tx);

    // 更新在线状态到 Redis
    let _ = set_online(&state.redis, user.id).await;

    // 发送任务
    let send_task = tokio::spawn(async move {
        while let Some(msg) = rx.recv().await {
            let text = serde_json::to_string(&msg).unwrap();
            if sender.send(Message::Text(text)).await.is_err() {
                break;
            }
        }
    });

    // 接收任务
    while let Some(Ok(msg)) = receiver.next().await {
        if let Message::Text(text) = msg {
            match serde_json::from_str::<ClientMessage>(&text) {
                Ok(client_msg) => {
                    handle_client_message(&state, &user, client_msg).await;
                }
                Err(_) => {
                    // 忽略解析失败的消息
                }
            }
        }
    }

    // 清理
    state.hub.unregister(&user.id);
    let _ = set_offline(&state.redis, user.id).await;
    send_task.abort();
}
```

---

## 认证规范

### JWT 结构

```rust
// playmate-common/src/auth.rs
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Claims {
    pub sub: Uuid,          // user_id
    pub username: String,
    pub exp: usize,         // 过期时间戳
    pub iat: usize,         // 签发时间戳
}

// Token 有效期：Access Token 2小时，Refresh Token 30天
pub const ACCESS_TOKEN_DURATION: i64 = 2 * 60 * 60;
pub const REFRESH_TOKEN_DURATION: i64 = 30 * 24 * 60 * 60;
```

### Auth 中间件

```rust
// playmate-common/src/middleware/auth.rs
// 使用 axum 的 FromRequestParts 实现提取器
pub struct CurrentUser {
    pub id: Uuid,
    pub username: String,
}

#[async_trait]
impl<S> FromRequestParts<S> for CurrentUser
where
    S: Send + Sync + AsRef<AppConfig>,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let token = extract_bearer_token(parts)
            .ok_or_else(|| AppError::Unauthorized("缺少 Authorization header".to_string()))?;

        let config = state.as_ref();
        let claims = verify_token(token, &config.jwt_secret)
            .map_err(|_| AppError::Unauthorized("Token 无效或已过期".to_string()))?;

        Ok(CurrentUser {
            id: claims.sub,
            username: claims.username,
        })
    }
}
```

### 路由保护方式

```rust
// 需要认证的路由，直接在 handler 参数中加 CurrentUser
pub async fn get_profile(
    State(state): State<AppState>,
    current_user: CurrentUser,         // ← 自动验证 JWT
) -> Result<impl IntoResponse, AppError> {
    // ...
}

// 公开路由，不加 CurrentUser
pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<impl IntoResponse, AppError> {
    // ...
}
```

---

## Redis 使用规范

### Key 命名约定

```
# 用户在线状态
online:user:{user_id}                    → "1"（TTL: 60s，心跳续期）

# 用户 Session
session:refresh:{user_id}:{token_hash}  → refresh_token（TTL: 30d）

# 消息未读数
unread:{user_id}:{conversation_id}      → 数字

# 匹配队列
match:queue:{gender}                    → List，存 user_id

# Feed 缓存
feed:user:{user_id}                     → List，存 post_id（最新50条）

# 限流
rate:limit:{ip}:{endpoint}             → 计数器（TTL: 60s）
```

### Redis 操作封装

```rust
// playmate-common/src/cache.rs
use redis::AsyncCommands;
use uuid::Uuid;

pub async fn set_online(redis: &ConnectionManager, user_id: Uuid) -> AppResult<()> {
    let mut conn = redis.clone();
    conn.set_ex(
        format!("online:user:{}", user_id),
        "1",
        60,  // 60秒 TTL，客户端每30秒发心跳续期
    ).await?;
    Ok(())
}

pub async fn is_online(redis: &ConnectionManager, user_id: Uuid) -> AppResult<bool> {
    let mut conn = redis.clone();
    let exists: bool = conn.exists(format!("online:user:{}", user_id)).await?;
    Ok(exists)
}

pub async fn incr_unread(
    redis: &ConnectionManager,
    user_id: Uuid,
    conversation_id: Uuid,
) -> AppResult<()> {
    let mut conn = redis.clone();
    conn.incr(
        format!("unread:{}:{}", user_id, conversation_id),
        1i64,
    ).await?;
    Ok(())
}
```

---

## 配置管理

### 环境变量（本地开发用 .env 文件）

```bash
# .env（不提交 git）
DATABASE_URL=postgres://playmate:playmate@localhost:5432/playmate
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-secret-change-in-production-min-32-chars
JWT_REFRESH_SECRET=dev-refresh-secret-change-in-production

SERVER_HOST=0.0.0.0
SERVER_PORT=8080

# 日志级别
RUST_LOG=playmate=debug,tower_http=debug,sqlx=warn
```

### 配置结构

```rust
// playmate-common/src/config.rs
use serde::Deserialize;

#[derive(Deserialize, Clone)]
pub struct AppConfig {
    pub database_url: String,
    pub redis_url: String,
    pub jwt_secret: String,
    pub jwt_refresh_secret: String,
    pub server_host: String,
    pub server_port: u16,
}

impl AppConfig {
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(envy::from_env::<AppConfig>()?)
    }
}
```

### docker-compose.yml（本地开发）

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: playmate
      POSTGRES_PASSWORD: playmate
      POSTGRES_DB: playmate
    ports:
      - "5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru

volumes:
  pg_data:
```

---

## API 路由规范

### URL 风格

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout

GET    /api/v1/users/me
PUT    /api/v1/users/me
GET    /api/v1/users/:id
POST   /api/v1/users/me/tags

GET    /api/v1/im/conversations
POST   /api/v1/im/conversations
GET    /api/v1/im/conversations/:id/messages
POST   /api/v1/im/conversations/:id/messages       ← REST备用（主要用WS）
WS     /api/v1/im/ws                               ← WebSocket 主入口

GET    /api/v1/feed/posts
POST   /api/v1/feed/posts
GET    /api/v1/feed/posts/:id
DELETE /api/v1/feed/posts/:id
POST   /api/v1/feed/posts/:id/like

GET    /api/v1/match/candidates                    ← 获取匹配候选
POST   /api/v1/match/respond                       ← 响应匹配
```

### Request/Response 命名

- Request 结构体：`{动作}{资源}Request`，如 `CreatePostRequest`、`LoginRequest`
- Response 结构体：`{资源}Response`，如 `UserResponse`、`MessageResponse`
- 分页响应统一包装：

```rust
#[derive(Serialize)]
pub struct PageResponse<T: Serialize> {
    pub items: Vec<T>,
    pub total: i64,
    pub page: i64,
    pub limit: i64,
    pub has_more: bool,
}
```

---

## 匹配算法规范

### 匹配分计算逻辑

```rust
// playmate-match/src/algorithm.rs

pub fn calculate_match_score(user_a: &UserProfile, user_b: &UserProfile) -> u8 {
    let mut score = 0u32;

    // 共同标签（最高 60 分）
    let common_tags = user_a.tag_ids.iter()
        .filter(|t| user_b.tag_ids.contains(t))
        .count();
    let tag_score = (common_tags as f32 / user_a.tag_ids.len().max(1) as f32 * 60.0) as u32;
    score += tag_score;

    // 年龄差（最高 20 分）
    if let (Some(age_a), Some(age_b)) = (user_a.age(), user_b.age()) {
        let age_diff = (age_a as i32 - age_b as i32).abs();
        let age_score = if age_diff <= 2 { 20 }
            else if age_diff <= 5 { 15 }
            else if age_diff <= 10 { 10 }
            else { 0 };
        score += age_score;
    }

    // 性别偏好（20 分）
    // 按需扩展...

    score.min(100) as u8
}
```

---

## 代码生成规则（Claude Code 必须遵守）

### 文件头注释格式

```rust
//! {模块简要说明}
//!
//! # 功能
//! - 功能点1
//! - 功能点2
```

### 每个 handler 的结构模板

```rust
/// {接口说明}
///
/// # 错误
/// - `401 Unauthorized` - Token 缺失或无效
/// - `404 NotFound` - 资源不存在
pub async fn handler_name(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<RequestType>,
) -> Result<impl IntoResponse, AppError> {
    // 1. 参数验证
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    // 2. 业务逻辑
    let result = do_something(&state.db, &payload).await?;

    // 3. 返回响应
    Ok(ApiResponse::ok(result))
}
```

### 禁止事项

- 禁止在 handler 层直接写复杂 SQL，超过 3 行 SQL 抽成 repository 函数
- 禁止在不同 crate 间直接访问对方的数据库表（通过 common 的 repository 函数共享）
- 禁止硬编码任何配置（端口、密钥、URL）
- 禁止 `clone()` PgPool 以外的大型结构体（PgPool 本身是 Arc，clone 是廉价的）
- 禁止在异步上下文中使用阻塞 IO（用 `tokio::fs`、`tokio::io`）

---

## 开发启动流程

```bash
# 1. 启动基础设施
cd infra && docker-compose up -d

# 2. 运行数据库迁移
sqlx migrate run --source infra/migrations

# 3. 启动后端（开发模式，文件变更自动重启）
cargo install cargo-watch
cargo watch -x "run --bin playmate-gateway"

# 4. 检查代码
cargo clippy -- -D warnings
cargo fmt --check
```

---

## 当前开发状态

### 已完成
- [ ] 项目骨架和 Workspace 配置
- [ ] 基础设施 docker-compose
- [ ] common crate（错误类型、响应格式、AppState）

### 进行中
- [ ] 用户注册/登录接口
- [ ] JWT 认证中间件

### 待开始
- [ ] IM WebSocket 核心
- [ ] 动态广场 CRUD
- [ ] 匹配算法实现
- [ ] Flutter 客户端

---

## 快速参考

| 需求 | 方案 |
|------|------|
| 密码加密 | `argon2` crate |
| UUID生成 | `Uuid::new_v4()` |
| 时间戳 | `chrono::Utc::now()` |
| JSON序列化 | `serde_json` |
| 参数校验 | `validator` crate + `#[derive(Validate)]` |
| 日志 | `tracing::info!` / `tracing::error!` |
| 随机数 | `rand::thread_rng()` |
| Base64 | `base64` crate |
| HTTP客户端（服务间） | `reqwest` with `rustls-tls` feature |

### 页面 UI 规范

#### 1. 登录页（/auth/login）
- 顶部：Logo圆角方块（44px，主色背景）+ "欢迎来到玩伴" 标题 + "遇见有趣的灵魂" 副标题
- 表单：手机号/邮箱输入框、密码输入框（高度36px，圆角8px，背景次要色）
- 主按钮：高度36px，圆角10px，主色 #7F77DD，文字"登录"
- 底部：注册跳转链接（主色文字）、第三方登录（微信/Apple，并排）

#### 2. 发现页（/discover，底部导航第1个Tab）
- 顶部栏：左"筛选"文字、中"发现玩伴"标题、右头像圆形按钮
- 主卡片（圆角16px）：
  - 上半：用户大头像 + 右上角匹配分徽章（主色背景，白字，"匹配 XX%"）
  - 下半：姓名+年龄、城市+职业、兴趣标签（胶囊，主色浅背景）
- 底部操作：左"跳过"（描边按钮）、右"心动"（主色填充按钮）
- 下方：其他候选人小卡片（2列网格，60px高）

#### 3. 消息列表页（/im，底部导航第2个Tab）
- 顶部栏：中"消息"标题、右"编辑"文字（主色）
- 列表项（高度56px）：左头像（36px圆形，各用户不同颜色）、
  中间姓名+最新消息预览（截断）、右侧时间+未读数红点（主色背景）

#### 4. 聊天页（/im/:conversationId）
- 顶部栏：左"‹"返回、中头像+名字+在线状态（辅色绿点）、右"···"菜单
- 消息区：对方气泡（左对齐，次要色背景）、我的气泡（右对齐，主色背景白字）
- 底部输入栏：左表情按钮、中输入框（胶囊形）、右发送按钮（主色圆形）

#### 5. 动态广场（/feed，底部导航第3个Tab）
- 顶部栏：中"动态"标题、右"+"发帖按钮（主色圆形）
- 帖子卡片：头像+名字+标签分类+时间、正文文字、可选图片（圆角8px）
  底部操作栏：点赞数、评论数、更多（···）

#### 6. 个人主页（/profile，底部导航第4个Tab）
- 顶部：渐变封面（主色到辅色）、大头像（48px，压住封面底部）
- 信息区：昵称（500weight）、个性签名（次要色，多行）
- 数据栏：关注/粉丝/玩伴 三列，竖线分隔
- 兴趣标签：标签胶囊列表
- 底部："编辑资料"描边按钮（全宽）

---

## 认证方式规范（playmate-user 服务）

### 支持的登录方式
1. 手机号 + 短信验证码（主要登录方式）
2. 微信 OAuth（openid 换 JWT）
3. 账号 + 密码（注册时可选设置）

### playmate-user 内部结构

```
playmate-user/
└── src/
    ├── main.rs
    ├── routes.rs
    ├── handler/
    │   ├── auth.rs            ← 登录/注册/刷新token/登出
    │   ├── profile.rs         ← 用户资料
    │   └── tag.rs             ← 兴趣标签
    ├── service/
    │   ├── auth_service.rs    ← 认证核心逻辑
    │   ├── sms_service.rs     ← 短信验证码（阿里云）
    │   ├── wechat_service.rs  ← 微信 OAuth
    │   └── token_service.rs   ← JWT 签发/刷新
    ├── model/
    │   ├── user.rs
    │   └── auth.rs            ← 请求/响应结构体
    └── repo/
        └── user_repo.rs       ← 数据库操作
```

### 短信验证码接口

```
POST /api/v1/auth/sms/send    → { "phone": "13800138000" }
POST /api/v1/auth/sms/verify  → { "phone": "13800138000", "code": "123456" }
```

Redis Key 规范：
```
sms:code:{phone}   → 验证码明文（TTL: 300s）
sms:limit:{phone}  → 发送限流（TTL: 60s，存在则拒绝重发）
```

供应商：阿里云 SMS（Dysmsapi），通过 `reqwest` 调 HTTP API。

### 微信登录接口

```
POST /api/v1/auth/wechat/login → { "code": "wx_oauth_code" }
```

流程：客户端完成微信授权拿到 code → 传给后端 → 后端用 code 换 openid（调微信接口）
→ 查 user_oauth 表，存在直接登录，不存在自动创建用户 → 返回 JWT。

### 新增数据库表

```sql
-- 第三方账号绑定（支持后续扩展 Apple/Google）
CREATE TABLE user_oauth (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider    VARCHAR(20) NOT NULL,    -- 'wechat' | 'apple' | 'google'
    provider_id VARCHAR(128) NOT NULL,   -- 微信的 openid / unionid
    access_token TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (provider, provider_id)
);
```

users 表 phone 字段已有（见核心表结构），确保加了 UNIQUE 约束。

### 新增环境变量

```bash
# 微信开放平台
WECHAT_APP_ID=wx...
WECHAT_APP_SECRET=...

# 阿里云短信
ALIYUN_SMS_ACCESS_KEY=...
ALIYUN_SMS_SECRET=...
ALIYUN_SMS_SIGN_NAME=玩伴
ALIYUN_SMS_TEMPLATE_CODE=SMS_...
```

### AppConfig 补充字段

```rust
// playmate-common/src/config.rs 补充
pub struct AppConfig {
    // ... 原有字段 ...
    pub wechat_app_id: String,
    pub wechat_app_secret: String,
    pub aliyun_sms_access_key: String,
    pub aliyun_sms_secret: String,
    pub aliyun_sms_sign_name: String,
    pub aliyun_sms_template_code: String,
}
```

### 快速参考补充

| 需求 | 方案 |
|------|------|
| 短信发送 | `reqwest` 调阿里云 Dysmsapi HTTP 接口 |
| 微信换 openid | `reqwest` GET `api.weixin.qq.com/sns/oauth2/access_token` |
| 验证码生成 | `rand::thread_rng().gen_range(100000..999999).to_string()` |
| 第三方登录绑定 | `user_oauth` 表，provider + provider_id 唯一索引 |

---

## 对象存储规范

### 策略：开发用 MinIO，生产换阿里云 OSS

代码只写一套 S3 兼容接口，通过环境变量切换，上线时**零代码改动**。

```
开发环境：MinIO（本地 Docker）
生产环境：阿里云 OSS（S3 兼容模式）
```

### docker-compose.yml 新增 MinIO

```yaml
# 追加到 infra/docker-compose.yml 的 services 里
  minio:
    image: minio/minio:latest
    container_name: playmate-minio
    restart: always
    ports:
      - "9000:9000"    # API 端口
      - "9001:9001"    # 控制台端口
    environment:
      MINIO_ROOT_USER: playmate
      MINIO_ROOT_PASSWORD: playmate123
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data

# volumes 里追加
  minio_data:
```

启动后访问 http://localhost:9001，用 playmate / playmate123 登录，手动创建 bucket：`avatars`、`posts`、`voices`。

### Cargo.toml 新增依赖

```toml
# workspace.dependencies 追加
aws-sdk-s3 = "1"
aws-config = { version = "1", default-features = false, features = ["behavior-version-latest"] }
tokio-multipart = "0.1"   # 文件上传解析
```

### 存储服务封装（playmate-common/src/storage.rs）

```rust
//! 对象存储服务封装
//! 兼容 MinIO（开发）和阿里云 OSS（生产），通过环境变量切换

use aws_sdk_s3::{Client, Config};
use aws_sdk_s3::config::{Credentials, Region};
use uuid::Uuid;

pub struct StorageService {
    client: Client,
    bucket_prefix: String,  // 可选前缀，区分环境
}

impl StorageService {
    pub async fn from_config(config: &AppConfig) -> Self {
        let creds = Credentials::new(
            &config.storage_access_key,
            &config.storage_secret_key,
            None, None, "playmate",
        );

        let s3_config = Config::builder()
            .endpoint_url(&config.storage_endpoint)
            .credentials_provider(creds)
            .region(Region::new(config.storage_region.clone()))
            .force_path_style(true)   // MinIO 必须开启，OSS 也兼容
            .build();

        Self {
            client: Client::from_conf(s3_config),
            bucket_prefix: config.storage_bucket_prefix.clone(),
        }
    }

    /// 上传文件，返回公开访问 URL
    pub async fn upload(
        &self,
        bucket: &str,          // "avatars" | "posts" | "voices"
        data: Vec<u8>,
        content_type: &str,    // "image/jpeg" | "image/png" | "audio/m4a"
    ) -> AppResult<String> {
        let key = format!("{}/{}.{}", 
            chrono::Utc::now().format("%Y/%m/%d"),
            Uuid::new_v4(),
            mime_to_ext(content_type),
        );

        self.client
            .put_object()
            .bucket(bucket)
            .key(&key)
            .body(data.into())
            .content_type(content_type)
            .send()
            .await
            .map_err(|e| AppError::Internal(anyhow::anyhow!("上传失败: {}", e)))?;

        // 返回可访问的 URL
        Ok(format!("{}/{}/{}", self.endpoint_public_url, bucket, key))
    }

    /// 删除文件
    pub async fn delete(&self, bucket: &str, key: &str) -> AppResult<()> {
        self.client
            .delete_object()
            .bucket(bucket)
            .key(key)
            .send()
            .await
            .map_err(|e| AppError::Internal(anyhow::anyhow!("删除失败: {}", e)))?;
        Ok(())
    }
}

fn mime_to_ext(mime: &str) -> &str {
    match mime {
        "image/jpeg" => "jpg",
        "image/png"  => "png",
        "image/webp" => "webp",
        "audio/m4a"  => "m4a",
        "audio/mpeg" => "mp3",
        "video/mp4"  => "mp4",
        _            => "bin",
    }
}
```

### Bucket 规划

| Bucket | 用途 | 文件类型 |
|--------|------|---------|
| `avatars` | 用户头像 | jpg / png / webp |
| `posts` | 动态图片/视频 | jpg / png / mp4 |
| `voices` | 语音消息 | m4a / mp3 |

### 环境变量

```bash
# 开发环境（MinIO）
STORAGE_ENDPOINT=http://localhost:9000
STORAGE_PUBLIC_ENDPOINT=http://localhost:9000
STORAGE_ACCESS_KEY=playmate
STORAGE_SECRET_KEY=playmate123
STORAGE_REGION=us-east-1

# 生产环境（阿里云 OSS）—— 只改这几行，代码不动
# STORAGE_ENDPOINT=https://oss-cn-hangzhou-internal.aliyuncs.com  # 内网节点（服务器访问免费）
# STORAGE_PUBLIC_ENDPOINT=https://你的bucket.oss-cn-hangzhou.aliyuncs.com
# STORAGE_ACCESS_KEY=阿里云AccessKeyId
# STORAGE_SECRET_KEY=阿里云AccessKeySecret
# STORAGE_REGION=cn-hangzhou
```

### AppConfig 补充字段

```rust
pub struct AppConfig {
    // ... 原有字段 ...
    pub storage_endpoint: String,
    pub storage_public_endpoint: String,
    pub storage_access_key: String,
    pub storage_secret_key: String,
    pub storage_region: String,
}
```

### AppState 补充

```rust
#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub redis: ConnectionManager,
    pub config: Arc<AppConfig>,
    pub storage: Arc<StorageService>,   // ← 新增
}
```

### 文件上传接口规范

```
POST /api/v1/upload/avatar   → 头像上传，返回 avatar_url
POST /api/v1/upload/post     → 动态图片/视频，返回 media_url
POST /api/v1/upload/voice    → 语音消息，返回 voice_url

限制：
- 图片最大 5MB，支持 jpg/png/webp
- 视频最大 50MB，支持 mp4
- 语音最大 10MB，支持 m4a/mp3
- 上传接口需要 JWT 认证
```

### 快速参考补充

| 需求 | 方案 |
|------|------|
| 本地对象存储 | MinIO Docker（端口9000/9001） |
| 生产对象存储 | 阿里云 OSS（内网节点，免流量费） |
| S3 客户端 | `aws-sdk-s3` crate，`force_path_style=true` |
| 文件名生成 | `年/月/日/{uuid}.{ext}` 防冲突 |
| 切换环境 | 只改 STORAGE_* 环境变量，代码零改动 |