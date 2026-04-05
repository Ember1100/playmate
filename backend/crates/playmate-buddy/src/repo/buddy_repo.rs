//! 搭子请求数据库查询

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::{BuddyCandidate, BuddyRequest};

const REQUEST_COLS: &str =
    "id, from_user_id, to_user_id, type, message, status, created_at";

/// 获取搭子候选人（排除自己和已有搭子关系的用户）
pub async fn list_candidates(
    pool: &PgPool,
    user_id: Uuid,
    req_type: Option<i16>,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<BuddyCandidate>> {
    let _ = req_type; // MVP 暂不按 type 过滤候选人
    sqlx::query_as::<_, BuddyCandidate>(
        "SELECT id, username, avatar_url, bio, gender FROM users
         WHERE id != $1 AND is_active = true
         ORDER BY created_at DESC LIMIT $2 OFFSET $3",
    )
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

/// 发起搭子请求
pub async fn send_request(
    pool: &PgPool,
    from_user_id: Uuid,
    to_user_id: Uuid,
    req_type: i16,
    message: Option<&str>,
) -> AppResult<BuddyRequest> {
    sqlx::query_as::<_, BuddyRequest>(&format!(
        "INSERT INTO buddy_requests (from_user_id, to_user_id, type, message)
         VALUES ($1, $2, $3, $4)
         RETURNING {REQUEST_COLS}"
    ))
    .bind(from_user_id)
    .bind(to_user_id)
    .bind(req_type)
    .bind(message)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

/// 响应搭子请求
pub async fn respond_request(
    pool: &PgPool,
    request_id: Uuid,
    to_user_id: Uuid,
    accept: bool,
) -> AppResult<BuddyRequest> {
    let new_status: i16 = if accept { 1 } else { 2 };

    let result = sqlx::query_as::<_, BuddyRequest>(&format!(
        "UPDATE buddy_requests SET status = $3
         WHERE id = $1 AND to_user_id = $2 AND status = 0
         RETURNING {REQUEST_COLS}"
    ))
    .bind(request_id)
    .bind(to_user_id)
    .bind(new_status)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?;

    result.ok_or_else(|| AppError::Forbidden("无权操作该搭子请求".to_string()))
}

/// 获取我的搭子（已接受的请求双方）
pub async fn list_my_buddies(
    pool: &PgPool,
    user_id: Uuid,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<BuddyCandidate>> {
    sqlx::query_as::<_, BuddyCandidate>(
        "SELECT u.id, u.username, u.avatar_url, u.bio, u.gender
         FROM buddy_requests br
         JOIN users u ON u.id = CASE
             WHEN br.from_user_id = $1 THEN br.to_user_id
             ELSE br.from_user_id
         END
         WHERE (br.from_user_id = $1 OR br.to_user_id = $1)
           AND br.status = 1
         ORDER BY br.created_at DESC LIMIT $2 OFFSET $3",
    )
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}
