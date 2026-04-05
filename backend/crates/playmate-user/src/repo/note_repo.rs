//! 学习笔记数据库查询

use chrono::{DateTime, Utc};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

#[derive(Debug, FromRow)]
pub struct LearningNote {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub title:       Option<String>,
    pub content:     String,
    pub category:    Option<String>,
    pub source_type: Option<String>,
    pub source_id:   Option<Uuid>,
    pub created_at:  DateTime<Utc>,
    pub updated_at:  DateTime<Utc>,
}

const COLS: &str =
    "id, user_id, title, content, category, source_type, source_id, created_at, updated_at";

pub async fn list(pool: &PgPool, user_id: Uuid, limit: i64, offset: i64) -> AppResult<Vec<LearningNote>> {
    sqlx::query_as::<_, LearningNote>(&format!(
        "SELECT {COLS} FROM learning_notes
         WHERE user_id = $1
         ORDER BY created_at DESC LIMIT $2 OFFSET $3"
    ))
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn create(
    pool: &PgPool,
    user_id: Uuid,
    title: Option<&str>,
    content: &str,
    category: Option<&str>,
    source_type: Option<&str>,
    source_id: Option<Uuid>,
) -> AppResult<LearningNote> {
    sqlx::query_as::<_, LearningNote>(&format!(
        "INSERT INTO learning_notes (user_id, title, content, category, source_type, source_id)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING {COLS}"
    ))
    .bind(user_id)
    .bind(title)
    .bind(content)
    .bind(category)
    .bind(source_type)
    .bind(source_id)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn get(pool: &PgPool, id: Uuid, user_id: Uuid) -> AppResult<LearningNote> {
    sqlx::query_as::<_, LearningNote>(&format!(
        "SELECT {COLS} FROM learning_notes WHERE id = $1 AND user_id = $2"
    ))
    .bind(id)
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("笔记 {} 不存在", id)))
}

pub async fn update(
    pool: &PgPool,
    id: Uuid,
    user_id: Uuid,
    title: Option<&str>,
    content: Option<&str>,
    category: Option<&str>,
) -> AppResult<LearningNote> {
    sqlx::query_as::<_, LearningNote>(&format!(
        "UPDATE learning_notes SET
             title    = COALESCE($3, title),
             content  = COALESCE($4, content),
             category = COALESCE($5, category),
             updated_at = NOW()
         WHERE id = $1 AND user_id = $2
         RETURNING {COLS}"
    ))
    .bind(id)
    .bind(user_id)
    .bind(title)
    .bind(content)
    .bind(category)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::Forbidden("无权修改该笔记".to_string()))
}

pub async fn delete(pool: &PgPool, id: Uuid, user_id: Uuid) -> AppResult<()> {
    let r = sqlx::query("DELETE FROM learning_notes WHERE id = $1 AND user_id = $2")
        .bind(id)
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(AppError::Database)?;
    if r.rows_affected() == 0 {
        return Err(AppError::Forbidden("无权删除该笔记".to_string()));
    }
    Ok(())
}
