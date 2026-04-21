# CLAUDE.md — 搭伴 (Playmate)

> 本文件是 Claude Code 的核心上下文，代码生成、架构决策、命名约定均以此为准。

---

## MVP 功能边界

**做 ✅**：登录（手机号+短信+微信+问卷）、圈子（话题/投票/评论/社群）、集市（失物/闲置/兼职/换物，纯信息发布无支付）、搭子（推荐/邀约/职业阵地）、趣玩（静态展示）、我的（主页/成长值/收藏/通知/会员/反馈）

**不做 ❌**：支付/交易/拼团、技能卡牌/元宇宙/数字藏品、未成年人模式、兼职评价、活动报名后端接口

---

## 技术栈

- 客户端：Flutter（iOS/Android）+ uni-app（微信小程序）
- 后端：Rust + Axum，Workspace monorepo
- 数据库：PostgreSQL + Redis
- 消息队列：Redis Streams（MVP）
- 实时通信：WebSocket（Axum 原生）
- 对象存储：MinIO（开发）→ 阿里云 OSS（生产）

---

## 项目结构

```
playmate/
├── backend/crates/
│   ├── playmate-common/    ← 错误/响应/JWT/缓存/存储/中间件
│   ├── playmate-gateway/   ← Axum 主进程，路由聚合
│   ├── playmate-user/      ← 用户/认证/问卷/账号管理
│   ├── playmate-circle/    ← 圈子：话题/投票/评论/社群
│   ├── playmate-market/    ← 集市：失物/闲置/兼职/换物
│   ├── playmate-buddy/     ← 搭子：推荐/邀约/职业阵地
│   └── playmate-im/        ← 私信/群聊/WebSocket
├── flutter_app/            ← Flutter 客户端
├── miniprogram/            ← uni-app 微信小程序
└── infra/
    ├── docker-compose.prod.yml
    ├── .env.prod
    └── migrations/
```

---

## 后端规范

### 错误处理

```rust
pub enum AppError {
    Unauthorized(String), Forbidden(String), NotFound(String),
    BadRequest(String), Business(String),
    Database(#[from] sqlx::Error), Redis(#[from] redis::RedisError),
    Internal(#[from] anyhow::Error),
}
pub type AppResult<T> = Result<T, AppError>;
```

- 所有 handler 返回 `Result<impl IntoResponse, AppError>`
- 禁止 `unwrap()` / `expect()`
- `sqlx::Error::RowNotFound` → `AppError::NotFound`

### API 响应格式

```rust
pub struct ApiResponse<T: Serialize>  { success: bool, code: String, message: String, data: Option<T> }
pub struct PageResponse<T: Serialize> { items: Vec<T>, total: i64, page: i64, limit: i64, has_more: bool }
```

### 数据库

- 驱动：SQLx 原始 SQL，禁止 ORM
- 迁移：只写 UP，格式 `{timestamp}_{描述}.sql`，文件位于 `infra/migrations/`

迁移文件（00~23）：users / tags / user_oauth / user_stats / user_questionnaire / topics / topic_comments / topic_likes / polls / poll_votes / social_groups / lost_found / second_hand / part_time / barter / market_collects / buddy_requests / buddy_invitations / career_profiles / conversations / messages / notifications / feedback / learning_notes

### 应用状态

```rust
#[derive(Clone)]
pub struct AppState {
    pub db: PgPool, pub redis: ConnectionManager,
    pub config: Arc<AppConfig>, pub storage: Arc<StorageService>,
    pub hub: Arc<ConnectionHub>,
}
```

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

禁止 handler 层直接写超过3行的 SQL（抽到 repo 函数）、禁止硬编码配置值、禁止异步上下文中阻塞 IO。

### Repo 查询规范：分步查询

**禁止** 在单条 SQL 中使用多层 JOIN + 子查询 + 聚合混合（可读性差、难调试、易 SQL 注入）。

需要关联多张表时，采用**分步查询**：

```rust
// ✅ 正确：分步查询，每步单表或简单 JOIN
pub async fn list(...) -> AppResult<Vec<XxxWithStats>> {
    // Step 1：主表单查，获取基础数据
    let rows: Vec<Xxx> = sqlx::query_as("SELECT ... FROM xxx WHERE ... LIMIT $1 OFFSET $2")
        .bind(limit).bind(offset).fetch_all(pool).await?;
    if rows.is_empty() { return Ok(vec![]); }

    // Step 2：收集关联 ID
    let ids: Vec<Uuid> = rows.iter().map(|r| r.id).collect();

    // Step 3：批量查询关联数据（ANY($1) 传数组）
    let related: Vec<(Uuid, String)> = sqlx::query_as(
        "SELECT foreign_id, value FROM other_table WHERE foreign_id = ANY($1)"
    ).bind(&ids).fetch_all(pool).await?;

    // Step 4：用 HashMap 组装结果，避免嵌套循环
    let map: HashMap<Uuid, String> = related.into_iter().collect();
    let result = rows.into_iter().map(|r| XxxWithStats {
        value: map.get(&r.id).cloned().unwrap_or_default(),
        ..
    }).collect();

    Ok(result)
}

// ❌ 禁止：单 SQL 混合多层 JOIN + 子查询 + 聚合
// SELECT g.*, u.username, (SELECT COUNT(*) FROM members WHERE ...) AS cnt,
//        ARRAY(SELECT avatar FROM ...) AS avatars FROM gathers g JOIN users u ...
```

适用场景：列表页需要聚合统计（计数、头像列表、是否关注等）时。

### WebSocket 协议

统一入口 `WS /api/v1/im/ws`，处理私信 + 社群消息。

ClientMessage：`SendDm` / `SendGroup` / `MarkRead` / `Ping`  
ServerMessage：`NewDm` / `NewGroup` / `NewNotification` / `MessageAck` / `Pong` / `Error`

---

## 认证规范

登录流程：`sms/send` → `sms/verify`（返回 JWT + `is_new_user`）→ 若新用户跳问卷 → `questionnaire` → 首页

JWT：Access Token 2h，Refresh Token 30d  
`Claims { sub: Uuid, username: String, exp: usize, iat: usize }`

Redis Key：
```
sms:code:{phone}                  TTL 300s
sms:limit:{phone}                 TTL 60s
session:refresh:{user_id}:{hash}  TTL 30d
online:user:{user_id}             TTL 60s（心跳续期）
unread:dm:{user_id}:{conv_id}
unread:group:{user_id}:{group_id}
unread:notify:{user_id}
rate:limit:{ip}:{endpoint}        TTL 60s
```

### 用户准入规则

平台仅面向 **35岁及以下**，注册时校验生日字段：

```rust
fn check_age_limit(birthday: NaiveDate) -> AppResult<()> {
    if calculate_age(birthday) > 35 {
        return Err(AppError::Business("抱歉，本平台仅面向35岁及以下用户".to_string()));
    }
    Ok(())
}
```

---

## API 路由规范

```
# 认证
POST   /api/v1/auth/sms/send|sms/verify|wechat/login|refresh|logout
DELETE /api/v1/auth/account

# 用户
GET/PUT /api/v1/users/me
GET     /api/v1/users/me/stats|career|tags
POST    /api/v1/users/me/tags|questionnaire|career
GET/PUT /api/v1/users/:id|users/:id/career

# 圈子
GET/POST        /api/v1/topics
GET/DELETE      /api/v1/topics/:id
POST/DELETE     /api/v1/topics/:id/like
GET/POST        /api/v1/topics/:id/comments
DELETE          /api/v1/topics/comments/:id
POST/GET        /api/v1/polls
POST            /api/v1/polls/:id/vote
GET/POST        /api/v1/circle/groups
GET             /api/v1/circle/groups/:id
POST            /api/v1/circle/groups/:id/join|leave|messages

# 集市（lost-found / second-hand / part-time / barter）
GET/POST        /api/v1/market/{type}
GET/PUT/DELETE  /api/v1/market/{type}/:id
POST            /api/v1/market/lost-found/:id/resolve
POST            /api/v1/market/second-hand/:id/sold
GET/POST/DELETE /api/v1/market/collect|collect/mine

# 搭子
GET             /api/v1/buddy/candidates|mine|career|career/:uid
POST            /api/v1/buddy/request|invitations
PUT             /api/v1/buddy/request/:id/respond|invitations/:id/respond
GET             /api/v1/buddy/invitations/sent|received

# IM
GET/POST        /api/v1/im/conversations
GET             /api/v1/im/conversations/:id/messages
WS              /api/v1/im/ws

# 通知 & 反馈 & 笔记
GET             /api/v1/notifications
POST            /api/v1/notifications/read-all|notifications/:id/read
POST            /api/v1/feedback
GET/POST        /api/v1/notes
GET/PUT/DELETE  /api/v1/notes/:id

# 上传
POST /api/v1/upload/avatar|market|topic|voice
```

---

## 对象存储

Bucket：`avatars` / `market` / `topics` / `voices`

开发（MinIO）：`STORAGE_ENDPOINT=http://localhost:9000`，`STORAGE_PUBLIC_ENDPOINT=http://8.138.190.48:9000`  
生产（阿里云 OSS）：切换 endpoint，代码零改动

---

## 环境变量

```bash
DATABASE_URL=postgres://playmate:playmate@localhost:5432/playmate
REDIS_URL=redis://localhost:6379
JWT_SECRET=<32位+>   JWT_REFRESH_SECRET=<32位+>
SERVER_HOST=0.0.0.0   SERVER_PORT=8080
RUST_LOG=playmate=debug,tower_http=debug,sqlx=warn
WECHAT_APP_ID=wx...   WECHAT_APP_SECRET=...
ALIYUN_SMS_ACCESS_KEY=...   ALIYUN_SMS_SECRET=...
ALIYUN_SMS_SIGN_NAME=搭伴   ALIYUN_SMS_TEMPLATE_CODE=SMS_...
STORAGE_ENDPOINT=http://localhost:9000
STORAGE_PUBLIC_ENDPOINT=http://8.138.190.48:9000
STORAGE_ACCESS_KEY=playmate   STORAGE_SECRET_KEY=playmate123
STORAGE_REGION=us-east-1
POSTGRES_PASSWORD=playmate   MINIO_ROOT_USER=playmate   MINIO_ROOT_PASSWORD=playmate123
```

---

## Flutter 客户端规范

### Tab 顺序（Flutter / uni-app 统一）

| 位置 | Tab | 核心功能 |
|------|-----|---------|
| 1 | 圈子 | 话题/投票/社群 |
| 2 | 集市 | 失物/闲置/兼职/换物 |
| 3 | 搭子 | 推荐/邀约/职业阵地 |
| 4 | 消息 | 私信会话/系统通知/搭子邀约/互动消息 |
| 5 | 趣玩 | 静态展示 |
| 6 | 我的 | 个人中心 |

TabBar 固定高度 **98px**。

### 设计规范

- 主色 `#FF7A00`，辅色 `#5DCAA5`，强调 `#E24B4A`，背景 `#FFF8EC`
- 圆角：卡片 12px，按钮 8px，标签 20px，头像 50%

### 路由（go_router）

```
/auth/login | /auth/questionnaire
/circle | /circle/topic/:id | /circle/poll/:id | /circle/groups | /circle/groups/:id
/market | /market/{lost-found|second-hand|part-time|barter} | /:id | /publish
/buddy | /buddy/candidates | /buddy/invitations | /buddy/career
/fun
/profile | /profile/notifications | /collects | /member | /growth-report | /feedback | /settings | /notes | /notes/:id
/im/chat/:conversationId | /im/group/:groupId
```

### 项目结构

```
flutter_app/lib/
├── app/          ← app.dart, router.dart, theme.dart
├── core/         ← network(Dio+JWT), storage, error
├── shared/widgets/ ← Pm前缀公共组件
└── features/     ← auth, circle, market, buddy, fun, im, profile
```

状态管理：`flutter_riverpod`（AsyncNotifier），禁止跨页面 setState。

### 转场与手势规范

- 统一淡入淡出转场（禁止 iOS 默认跟手侧滑），在 `theme.dart` 配置 `_FadePageTransitionsBuilder`
- 禁用默认侧滑返回后，二级及以上页面最外层必须包 `PmSwipeBack`（向右滑速 > 300px/s 则 pop）
- Tab 根页面不包 `PmSwipeBack`

### PmImage 公共组件规范

- **禁止** `Image.network(url)` → 改用 `PmImage(url, width, height, fit, borderRadius?, placeholder?)`
- **禁止** `NetworkImage(url)` → 改用 `PmImageProvider(url)`
- 依赖 `cached_network_image`，内置 loading/error 处理

### 信用分体系（MVP）

`user_stats` 表含 `credit_score INTEGER DEFAULT 600`（满分1000）。MVP 默认给所有用户 750 分，不做动态计算。展示规则：<700 普通 / 700-799 良好 / 800-899 优秀 / 900+ 极佳。

---

## uni-app 客户端规范（微信小程序）

技术栈：uni-app + Vue3 + Pinia + TypeScript，目标平台 mp-weixin。

与 Flutter 共享后端 API，样式保持一致（rpx 换算：1px = 2rpx）。

结构：`src/api/` + `src/store/` + `src/components/`（Pm前缀）+ `src/pages/`（与 Flutter features 对应）

关键规则：
- 图片上传用 `uni.chooseImage` + `uni.uploadFile`
- WebSocket 用 `uni.connectSocket`
- 本地存储用 `uni.setStorageSync`
- Tab 跳转用 `uni.switchTab`，普通页用 `uni.navigateTo`
- 主包只放6个 Tab 首页（圈子/集市/搭子/消息/趣玩/我的），其他页面放 subPackages

微信登录流程：`wx.login` 获取 code → `POST /api/v1/auth/wechat/login` → 存 `access_token` → 若 `is_new_user` 跳问卷

---

## 新人问卷字段

```json
{ "identity": "student|worker|family|other", "city": "上海",
  "interests": [1,3,7], "purposes": [2,5],
  "age_range": "18-22|23-28|29-35",
  "personality": null, "life_goal": null }
```

---

## 消息通知分类

消息中心4个Tab：全部 / 系统通知 / 搭子邀约 / 互动消息

type 值：`system` / `buddy_request` / `invitation` / `interaction`

---

## IM 页面规范

### 会话列表（消息 Tab）

- 顶部分类 Tab（聊天 / 互动 / 交易 / 活动 / 系统通知）使用自定义 `_SpacedTabBar`：`Row` + `MainAxisAlignment.spaceBetween` + 左右 16px 边距，首末两项贴边、中间均匀分布；选中项下方显示 20px 宽短下划线
- 左上角头像点击打开 `Drawer`，「个人主页」入口跳转 `/profile/edit`（完整个人信息页），不是 `/profile`
- 私信（DM）与群聊（Group）合并为一个列表，按 `last_message_at` 倒序排列
- 群聊头像右下角显示橙色「群」小标记
- 编辑模式（点击右上角「编辑」进入）：
  - 列表左侧出现圆形复选框，选中项橙色高亮背景
  - 快捷通知入口、「私信 & 群聊」分组标签隐藏
  - 底部固定操作栏：「标记已读」（清零 unread_count）+ 「删除」（弹确认框后移除）
  - 未选中时操作按钮置灰不可点
  - 点「完成」或操作完成后退出编辑模式，清空选中状态
- 下拉刷新：`refresher-enabled` / `refresher-triggered`（uni-app），`RefreshIndicator`（Flutter）

### 群聊消息页

- `type === 99`（系统消息）居中灰色展示，不显示头像和气泡
- 其他消息：自己靠右，他人靠左；他人消息气泡上方显示发送者昵称
- 头像颜色池：按 `senderId` 哈希固定取色，避免每次渲染颜色跳变
- 消息时间格式（私聊 + 群聊）：按自然日分界，今天 `HH:mm`，昨天 `昨天 HH:mm`，更早 `yyyy-MM-dd HH:mm:ss`

### Bottom Sheet 规范

- `showModalBottomSheet` 必须设置 `enableDrag: false`（uni-app 遮罩层加 `@touchmove.stop`），防止下拉穿透背景页

---

## 快速参考

| 需求 | 方案 |
|------|------|
| 密码加密 | `argon2` |
| UUID | `Uuid::new_v4()` |
| 时间戳 | `chrono::Utc::now()` |
| 参数校验 | `validator` + `#[derive(Validate)]` |
| 日志 | `tracing::info!` / `tracing::error!` |
| S3存储 | `aws-sdk-s3`，`force_path_style=true` |
| 短信 | `reqwest` 调阿里云 Dysmsapi |
| 验证码 | `rand::thread_rng().gen_range(100000..999999)` |
| 失物编号 | `{MM}-{DD}{HH}-{mm}-{ss}`，如 `05-058-26-32` |
| 通知推送 | WebSocket 实时推送 + notifications 表持久化 |

---

## 开发启动

```bash
cd infra && docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
sqlx migrate run --source infra/migrations
cargo watch -x "run --bin playmate-gateway"
cargo clippy -- -D warnings && cargo fmt --check
```
