//! 邀约数据库查询

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::BuddyInvitation;

const COLS: &str =
    "id, from_user_id, to_user_id, title, content, activity_type,
     scheduled_at, location, status, created_at";

pub async fn send(
    pool: &PgPool,
    from_user_id: Uuid,
    to_user_id: Uuid,
    title: &str,
    content: Option<&str>,
    activity_type: Option<&str>,
    scheduled_at: Option<chrono::DateTime<chrono::Utc>>,
    location: Option<&str>,
) -> AppResult<BuddyInvitation> {
    sqlx::query_as::<_, BuddyInvitation>(&format!(
        "INSERT INTO buddy_invitations
             (from_user_id, to_user_id, title, content, activity_type, scheduled_at, location)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING {COLS}"
    ))
    .bind(from_user_id)
    .bind(to_user_id)
    .bind(title)
    .bind(content)
    .bind(activity_type)
    .bind(scheduled_at)
    .bind(location)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn list_sent(
    pool: &PgPool,
    user_id: Uuid,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<BuddyInvitation>> {
    sqlx::query_as::<_, BuddyInvitation>(&format!(
        "SELECT {COLS} FROM buddy_invitations
         WHERE from_user_id = $1
         ORDER BY created_at DESC LIMIT $2 OFFSET $3"
    ))
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn list_received(
    pool: &PgPool,
    user_id: Uuid,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<BuddyInvitation>> {
    sqlx::query_as::<_, BuddyInvitation>(&format!(
        "SELECT {COLS} FROM buddy_invitations
         WHERE to_user_id = $1
         ORDER BY created_at DESC LIMIT $2 OFFSET $3"
    ))
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn respond(
    pool: &PgPool,
    invitation_id: Uuid,
    to_user_id: Uuid,
    accept: bool,
) -> AppResult<BuddyInvitation> {
    let new_status: i16 = if accept { 1 } else { 2 };

    let result = sqlx::query_as::<_, BuddyInvitation>(&format!(
        "UPDATE buddy_invitations SET status = $3
         WHERE id = $1 AND to_user_id = $2 AND status = 0
         RETURNING {COLS}"
    ))
    .bind(invitation_id)
    .bind(to_user_id)
    .bind(new_status)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?;

    result.ok_or_else(|| AppError::Forbidden("无权操作该邀约".to_string()))
}
