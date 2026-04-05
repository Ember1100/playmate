//! IM 数据库查询（Repository 层）

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::{Conversation, Message};

// ── 会话 ────────────────────────────────────────────────────────────────────

/// 查找两用户间已有的私聊会话 ID
pub async fn find_private_conversation(
    pool: &PgPool,
    user_a: Uuid,
    user_b: Uuid,
) -> AppResult<Option<Uuid>> {
    let row: Option<(Uuid,)> = sqlx::query_as(
        "SELECT c.id FROM conversations c
         JOIN conversation_members cm1 ON cm1.conversation_id = c.id AND cm1.user_id = $1
         JOIN conversation_members cm2 ON cm2.conversation_id = c.id AND cm2.user_id = $2
         WHERE c.type = 1
         LIMIT 1",
    )
    .bind(user_a)
    .bind(user_b)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|(id,)| id))
}

/// 创建私聊会话并加入两位成员
pub async fn create_private_conversation(
    pool: &PgPool,
    user_a: Uuid,
    user_b: Uuid,
) -> AppResult<Conversation> {
    let mut tx = pool.begin().await?;

    let conv: Conversation = sqlx::query_as(
        "INSERT INTO conversations (type) VALUES (1) RETURNING id, type, created_at",
    )
    .fetch_one(&mut *tx)
    .await?;

    sqlx::query(
        "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2), ($1, $3)",
    )
    .bind(conv.id)
    .bind(user_a)
    .bind(user_b)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(conv)
}

/// 列出用户参与的所有会话
pub async fn list_conversations(pool: &PgPool, user_id: Uuid) -> AppResult<Vec<Conversation>> {
    sqlx::query_as::<_, Conversation>(
        "SELECT c.id, c.type, c.created_at
         FROM conversations c
         JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1
         ORDER BY c.created_at DESC",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub struct ConversationFull {
    pub id: Uuid,
    pub conv_type: i16,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub other_user_id: Option<Uuid>,
    pub other_username: Option<String>,
    pub other_avatar_url: Option<String>,
    pub last_message: Option<String>,
    pub last_message_at: Option<chrono::DateTime<chrono::Utc>>,
    pub unread_count: i64,
}

/// 列出用户参与的所有会话（含对方用户信息、最新消息、未读数）
pub async fn list_conversations_full(
    pool: &PgPool,
    user_id: Uuid,
) -> AppResult<Vec<ConversationFull>> {
    // Step 1: 获取会话列表
    let convs = sqlx::query_as::<_, Conversation>(
        "SELECT c.id, c.type, c.created_at
         FROM conversations c
         JOIN conversation_members cm ON cm.conversation_id = c.id AND cm.user_id = $1
         ORDER BY c.created_at DESC",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    if convs.is_empty() {
        return Ok(vec![]);
    }

    let conv_ids: Vec<Uuid> = convs.iter().map(|c| c.id).collect();

    // Step 2: 批量获取各会话中"对方"的 user_id
    let other_members: Vec<(Uuid, Uuid)> = sqlx::query_as(
        "SELECT conversation_id, user_id FROM conversation_members
         WHERE conversation_id = ANY($1) AND user_id != $2",
    )
    .bind(&conv_ids)
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    // conv_id → other_user_id
    let other_map: std::collections::HashMap<Uuid, Uuid> = other_members
        .into_iter()
        .collect();

    // Step 3: 批量获取对方用户信息
    let other_user_ids: Vec<Uuid> = other_map.values().copied().collect::<std::collections::HashSet<_>>().into_iter().collect();
    let users: Vec<(Uuid, String, Option<String>)> = if other_user_ids.is_empty() {
        vec![]
    } else {
        sqlx::query_as("SELECT id, username, avatar_url FROM users WHERE id = ANY($1)")
            .bind(&other_user_ids)
            .fetch_all(pool)
            .await
            .map_err(AppError::Database)?
    };
    let user_map: std::collections::HashMap<Uuid, (String, Option<String>)> = users
        .into_iter()
        .map(|(id, u, a)| (id, (u, a)))
        .collect();

    // Step 4: 每个会话的最新消息 + 未读数（用 LATERAL 一次搞定）
    type LastMsgRow = (Uuid, Option<String>, Option<chrono::DateTime<chrono::Utc>>, i64);
    let last_msgs: Vec<LastMsgRow> = sqlx::query_as(
        "SELECT c_id, last_content, last_at, unread_cnt FROM (
             SELECT
                 m.conversation_id AS c_id,
                 (SELECT content FROM messages WHERE conversation_id = m.conversation_id ORDER BY created_at DESC LIMIT 1) AS last_content,
                 (SELECT created_at FROM messages WHERE conversation_id = m.conversation_id ORDER BY created_at DESC LIMIT 1) AS last_at,
                 COUNT(*) FILTER (WHERE m.created_at > COALESCE(cm.last_read_at, '1970-01-01') AND m.sender_id != $2) AS unread_cnt
             FROM messages m
             JOIN conversation_members cm ON cm.conversation_id = m.conversation_id AND cm.user_id = $2
             WHERE m.conversation_id = ANY($1)
             GROUP BY m.conversation_id
         ) sub",
    )
    .bind(&conv_ids)
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    let msg_map: std::collections::HashMap<Uuid, (Option<String>, Option<chrono::DateTime<chrono::Utc>>, i64)> = last_msgs
        .into_iter()
        .map(|(cid, content, at, unread)| (cid, (content, at, unread)))
        .collect();

    // Step 5: 组装结果
    let result = convs
        .into_iter()
        .map(|c| {
            let other_uid = other_map.get(&c.id).copied();
            let (other_username, other_avatar_url) = other_uid
                .and_then(|uid| user_map.get(&uid).cloned())
                .map(|(u, a)| (Some(u), a))
                .unwrap_or((None, None));
            let (last_message, last_message_at, unread_count) = msg_map
                .get(&c.id)
                .cloned()
                .map(|(m, at, u)| (m, at, u))
                .unwrap_or((None, None, 0));
            ConversationFull {
                id: c.id,
                conv_type: c.conv_type,
                created_at: c.created_at,
                other_user_id: other_uid,
                other_username,
                other_avatar_url,
                last_message,
                last_message_at,
                unread_count,
            }
        })
        .collect();

    Ok(result)
}

/// 检查用户是否是会话成员
pub async fn is_member(pool: &PgPool, conversation_id: Uuid, user_id: Uuid) -> AppResult<bool> {
    let row: (bool,) = sqlx::query_as(
        "SELECT EXISTS(SELECT 1 FROM conversation_members WHERE conversation_id=$1 AND user_id=$2)",
    )
    .bind(conversation_id)
    .bind(user_id)
    .fetch_one(pool)
    .await?;
    Ok(row.0)
}

/// 获取会话中所有成员的 user_id
pub async fn get_member_ids(pool: &PgPool, conversation_id: Uuid) -> AppResult<Vec<Uuid>> {
    let rows: Vec<(Uuid,)> =
        sqlx::query_as("SELECT user_id FROM conversation_members WHERE conversation_id = $1")
            .bind(conversation_id)
            .fetch_all(pool)
            .await?;
    Ok(rows.into_iter().map(|(id,)| id).collect())
}

// ── 消息 ────────────────────────────────────────────────────────────────────

/// 插入一条消息
pub async fn insert_message(
    pool: &PgPool,
    conversation_id: Uuid,
    sender_id: Uuid,
    msg_type: i16,
    content: Option<String>,
    media_url: Option<String>,
) -> AppResult<Message> {
    sqlx::query_as::<_, Message>(
        "INSERT INTO messages (conversation_id, sender_id, type, content, media_url)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, conversation_id, sender_id, type, content, media_url, is_recalled, created_at",
    )
    .bind(conversation_id)
    .bind(sender_id)
    .bind(msg_type)
    .bind(content)
    .bind(media_url)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

/// 分页获取会话消息（最新在前）
pub async fn list_messages(
    pool: &PgPool,
    conversation_id: Uuid,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<Message>> {
    sqlx::query_as::<_, Message>(
        "SELECT id, conversation_id, sender_id, type, content, media_url, is_recalled, created_at
         FROM messages
         WHERE conversation_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(conversation_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

/// 更新成员最后阅读时间
pub async fn update_last_read(
    pool: &PgPool,
    conversation_id: Uuid,
    user_id: Uuid,
    last_read_at: chrono::DateTime<chrono::Utc>,
) -> AppResult<()> {
    sqlx::query(
        "UPDATE conversation_members SET last_read_at = $3
         WHERE conversation_id = $1 AND user_id = $2",
    )
    .bind(conversation_id)
    .bind(user_id)
    .bind(last_read_at)
    .execute(pool)
    .await?;
    Ok(())
}
