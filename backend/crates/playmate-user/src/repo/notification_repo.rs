//! 通知数据库查询

use chrono::{DateTime, Utc};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

#[derive(Debug, FromRow)]
pub struct Notification {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub r#type:      String,
    pub title:       String,
    pub content:     Option<String>,
    pub target_type: Option<String>,
    pub target_id:   Option<Uuid>,
    pub is_read:     bool,
    pub created_at:  DateTime<Utc>,
}

pub async fn list_notifications(
    pool:    &PgPool,
    user_id: Uuid,
    limit:   i64,
    offset:  i64,
) -> AppResult<Vec<Notification>> {
    sqlx::query_as::<_, Notification>(
        "SELECT id, user_id, type, title, content, target_type, target_id, is_read, created_at
         FROM notifications
         WHERE user_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn count_notifications(pool: &PgPool, user_id: Uuid) -> AppResult<i64> {
    let row: (i64,) =
        sqlx::query_as("SELECT COUNT(*) FROM notifications WHERE user_id = $1")
            .bind(user_id)
            .fetch_one(pool)
            .await?;
    Ok(row.0)
}

pub async fn mark_one_read(pool: &PgPool, id: Uuid, user_id: Uuid) -> AppResult<()> {
    sqlx::query(
        "UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2",
    )
    .bind(id)
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;
    Ok(())
}

pub async fn mark_all_read(pool: &PgPool, user_id: Uuid) -> AppResult<()> {
    sqlx::query("UPDATE notifications SET is_read = true WHERE user_id = $1")
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(AppError::Database)?;
    Ok(())
}
