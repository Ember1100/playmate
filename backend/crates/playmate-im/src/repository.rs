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
