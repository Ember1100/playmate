//! IM 数据库查询（Repository 层）

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::{Conversation, GroupMessage, Message};

// ── 会话 ────────────────────────────────────────────────────────────────────

/// 查找两用户间已有的私聊会话 ID
pub async fn find_private_conversation(
    pool: &PgPool,
    user_a: Uuid,
    user_b: Uuid,
) -> AppResult<Option<Uuid>> {
    let row: Option<(Uuid,)> = sqlx::query_as(
        "SELECT id FROM conversations
         WHERE (user_a_id = $1 AND user_b_id = $2)
            OR (user_a_id = $2 AND user_b_id = $1)
         LIMIT 1",
    )
    .bind(user_a)
    .bind(user_b)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(|(id,)| id))
}

/// 创建私聊会话并加入两位成员到 conversation_members
pub async fn create_private_conversation(
    pool: &PgPool,
    user_a: Uuid,
    user_b: Uuid,
) -> AppResult<Conversation> {
    let mut tx = pool.begin().await?;

    // 保持 user_a_id < user_b_id 的顺序，确保 UNIQUE 约束一致
    let (a, b) = if user_a.as_bytes() <= user_b.as_bytes() {
        (user_a, user_b)
    } else {
        (user_b, user_a)
    };

    let conv: Conversation = sqlx::query_as(
        "INSERT INTO conversations (user_a_id, user_b_id) VALUES ($1, $2)
         RETURNING id, user_a_id, user_b_id, created_at",
    )
    .bind(a)
    .bind(b)
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

pub struct ConversationFull {
    pub id:               Uuid,
    pub created_at:       chrono::DateTime<chrono::Utc>,
    pub other_user_id:    Uuid,
    pub other_username:   Option<String>,
    pub other_avatar_url: Option<String>,
    pub last_message:     Option<String>,
    pub last_message_at:  Option<chrono::DateTime<chrono::Utc>>,
    pub unread_count:     i64,
}

/// 列出用户参与的所有私聊会话（含对方信息、最新消息、未读数）
pub async fn list_conversations_full(
    pool: &PgPool,
    user_id: Uuid,
) -> AppResult<Vec<ConversationFull>> {
    // Step 1: 获取所有会话（user_a_id/user_b_id 可直接推导"对方"）
    let convs = sqlx::query_as::<_, Conversation>(
        "SELECT id, user_a_id, user_b_id, created_at
         FROM conversations
         WHERE user_a_id = $1 OR user_b_id = $1",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    if convs.is_empty() {
        return Ok(vec![]);
    }

    let conv_ids: Vec<Uuid> = convs.iter().map(|c| c.id).collect();

    // Step 2: 批量获取对方用户信息
    let other_user_ids: Vec<Uuid> = convs
        .iter()
        .map(|c| if c.user_a_id == user_id { c.user_b_id } else { c.user_a_id })
        .collect::<std::collections::HashSet<_>>()
        .into_iter()
        .collect();

    let users: Vec<(Uuid, String, Option<String>)> =
        sqlx::query_as("SELECT id, username, avatar_url FROM users WHERE id = ANY($1)")
            .bind(&other_user_ids)
            .fetch_all(pool)
            .await
            .map_err(AppError::Database)?;

    let user_map: std::collections::HashMap<Uuid, (String, Option<String>)> =
        users.into_iter().map(|(id, u, a)| (id, (u, a))).collect();

    // Step 3: 每个会话的最新消息 + 未读数
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

    let msg_map: std::collections::HashMap<
        Uuid,
        (Option<String>, Option<chrono::DateTime<chrono::Utc>>, i64),
    > = last_msgs
        .into_iter()
        .map(|(cid, content, at, unread)| (cid, (content, at, unread)))
        .collect();

    // Step 4: 组装结果，按最新消息时间降序排列
    let mut result: Vec<ConversationFull> = convs
        .into_iter()
        .map(|c| {
            let other_uid = if c.user_a_id == user_id { c.user_b_id } else { c.user_a_id };
            let (other_username, other_avatar_url) = user_map
                .get(&other_uid)
                .cloned()
                .map(|(u, a)| (Some(u), a))
                .unwrap_or((None, None));
            let (last_message, last_message_at, unread_count) = msg_map
                .get(&c.id)
                .cloned()
                .map(|(m, at, u)| (m, at, u))
                .unwrap_or((None, None, 0));
            ConversationFull {
                id: c.id,
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

    result.sort_by(|a, b| {
        let ta = a.last_message_at.unwrap_or(a.created_at);
        let tb = b.last_message_at.unwrap_or(b.created_at);
        tb.cmp(&ta)
    });

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

// ── 群聊 ────────────────────────────────────────────────────────────────────

pub struct GroupSessionFull {
    pub id:              Uuid,
    pub name:            String,
    pub avatar_url:      Option<String>,
    pub member_count:    i32,
    pub last_message:    Option<String>,
    pub last_message_at: Option<chrono::DateTime<chrono::Utc>>,
    pub unread_count:    i64,
}

pub struct GroupMessageFull {
    pub id:               Uuid,
    pub group_id:         Uuid,
    pub sender_id:        Option<Uuid>,
    pub sender_username:  Option<String>,
    pub sender_avatar_url: Option<String>,
    pub msg_type:         i16,
    pub content:          Option<String>,
    pub media_url:        Option<String>,
    pub is_recalled:      bool,
    pub created_at:       chrono::DateTime<chrono::Utc>,
}

/// 获取用户参与的所有群聊会话（含最新消息、未读数）
pub async fn list_my_groups(pool: &PgPool, user_id: Uuid) -> AppResult<Vec<GroupSessionFull>> {
    // Step 1：获取用户的群组 ID 列表及 last_read_at
    let memberships: Vec<(Uuid, Option<chrono::DateTime<chrono::Utc>>)> = sqlx::query_as(
        "SELECT group_id, last_read_at FROM social_group_members WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    if memberships.is_empty() {
        return Ok(vec![]);
    }

    let group_ids: Vec<Uuid> = memberships.iter().map(|(id, _)| *id).collect();
    let last_read_map: std::collections::HashMap<Uuid, Option<chrono::DateTime<chrono::Utc>>> =
        memberships.into_iter().collect();

    // Step 2：获取群组基础信息
    let groups: Vec<(Uuid, String, Option<String>, i32)> = sqlx::query_as(
        "SELECT id, name, avatar_url, member_count FROM social_groups WHERE id = ANY($1)",
    )
    .bind(&group_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    // Step 3：获取各群最新消息
    let last_msgs: Vec<(Uuid, Option<String>, Option<chrono::DateTime<chrono::Utc>>)> =
        sqlx::query_as(
            "SELECT DISTINCT ON (group_id) group_id, content, created_at
             FROM social_group_messages
             WHERE group_id = ANY($1)
             ORDER BY group_id, created_at DESC",
        )
        .bind(&group_ids)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)?;
    let msg_map: std::collections::HashMap<Uuid, (Option<String>, Option<chrono::DateTime<chrono::Utc>>)> =
        last_msgs.into_iter().map(|(gid, content, at)| (gid, (content, at))).collect();

    // Step 4：计算未读数
    let unread_rows: Vec<(Uuid, i64)> = sqlx::query_as(
        "SELECT m.group_id, COUNT(*)::BIGINT
         FROM social_group_messages m
         JOIN social_group_members gm ON gm.group_id = m.group_id AND gm.user_id = $2
         WHERE m.group_id = ANY($1)
           AND m.sender_id != $2
           AND (gm.last_read_at IS NULL OR m.created_at > gm.last_read_at)
         GROUP BY m.group_id",
    )
    .bind(&group_ids)
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;
    let unread_map: std::collections::HashMap<Uuid, i64> = unread_rows.into_iter().collect();

    // Step 5：组装，按最新消息时间降序
    let mut result: Vec<GroupSessionFull> = groups
        .into_iter()
        .map(|(id, name, avatar_url, member_count)| {
            let (last_message, last_message_at) =
                msg_map.get(&id).cloned().unwrap_or((None, None));
            let unread_count = unread_map.get(&id).copied().unwrap_or(0);
            GroupSessionFull {
                id,
                name,
                avatar_url,
                member_count,
                last_message,
                last_message_at,
                unread_count,
            }
        })
        .collect();

    result.sort_by(|a, b| {
        let ta = a.last_message_at.unwrap_or_else(|| chrono::DateTime::<chrono::Utc>::MIN_UTC);
        let tb = b.last_message_at.unwrap_or_else(|| chrono::DateTime::<chrono::Utc>::MIN_UTC);
        tb.cmp(&ta)
    });

    Ok(result)
}

/// 检查用户是否是群组成员
pub async fn is_group_member(pool: &PgPool, group_id: Uuid, user_id: Uuid) -> AppResult<bool> {
    let row: (bool,) = sqlx::query_as(
        "SELECT EXISTS(SELECT 1 FROM social_group_members WHERE group_id = $1 AND user_id = $2)",
    )
    .bind(group_id)
    .bind(user_id)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?;
    Ok(row.0)
}

/// 获取群组所有成员 ID
pub async fn get_group_member_ids(pool: &PgPool, group_id: Uuid) -> AppResult<Vec<Uuid>> {
    let rows: Vec<(Uuid,)> =
        sqlx::query_as("SELECT user_id FROM social_group_members WHERE group_id = $1")
            .bind(group_id)
            .fetch_all(pool)
            .await
            .map_err(AppError::Database)?;
    Ok(rows.into_iter().map(|(id,)| id).collect())
}

/// 分页获取群聊消息（最新在前），含发送者信息
pub async fn list_group_messages(
    pool:     &PgPool,
    group_id: Uuid,
    limit:    i64,
    offset:   i64,
) -> AppResult<Vec<GroupMessageFull>> {
    // Step 1：获取消息列表
    let msgs: Vec<GroupMessage> = sqlx::query_as::<_, GroupMessage>(
        "SELECT id, group_id, sender_id, type, content, media_url, is_recalled, created_at
         FROM social_group_messages
         WHERE group_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(group_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    if msgs.is_empty() {
        return Ok(vec![]);
    }

    // Step 2：收集非 NULL 的 sender_id
    let sender_ids: Vec<Uuid> = msgs
        .iter()
        .filter_map(|m| m.sender_id)
        .collect::<std::collections::HashSet<_>>()
        .into_iter()
        .collect();

    let senders: Vec<(Uuid, String, Option<String>)> = if sender_ids.is_empty() {
        vec![]
    } else {
        sqlx::query_as("SELECT id, username, avatar_url FROM users WHERE id = ANY($1)")
            .bind(&sender_ids)
            .fetch_all(pool)
            .await
            .map_err(AppError::Database)?
    };
    let sender_map: std::collections::HashMap<Uuid, (String, Option<String>)> =
        senders.into_iter().map(|(id, u, a)| (id, (u, a))).collect();

    // Step 3：组装
    Ok(msgs
        .into_iter()
        .map(|m| {
            let (sender_username, sender_avatar_url) = m
                .sender_id
                .and_then(|id| sender_map.get(&id).cloned())
                .map(|(u, a)| (Some(u), a))
                .unwrap_or((None, None));
            GroupMessageFull {
                id:               m.id,
                group_id:         m.group_id,
                sender_id:        m.sender_id,
                sender_username,
                sender_avatar_url,
                msg_type:         m.msg_type,
                content:          m.content,
                media_url:        m.media_url,
                is_recalled:      m.is_recalled,
                created_at:       m.created_at,
            }
        })
        .collect())
}

/// 插入一条群聊消息（sender_id 为 None 表示系统消息）
pub async fn insert_group_message(
    pool:      &PgPool,
    group_id:  Uuid,
    sender_id: Option<Uuid>,
    msg_type:  i16,
    content:   Option<String>,
    media_url: Option<String>,
) -> AppResult<GroupMessage> {
    sqlx::query_as::<_, GroupMessage>(
        "INSERT INTO social_group_messages (group_id, sender_id, type, content, media_url)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, group_id, sender_id, type, content, media_url, is_recalled, created_at",
    )
    .bind(group_id)
    .bind(sender_id)
    .bind(msg_type)
    .bind(content)
    .bind(media_url)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

/// 更新群成员最后阅读时间
pub async fn update_group_last_read(
    pool:         &PgPool,
    group_id:     Uuid,
    user_id:      Uuid,
    last_read_at: chrono::DateTime<chrono::Utc>,
) -> AppResult<()> {
    sqlx::query(
        "UPDATE social_group_members SET last_read_at = $3
         WHERE group_id = $1 AND user_id = $2",
    )
    .bind(group_id)
    .bind(user_id)
    .bind(last_read_at)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;
    Ok(())
}
