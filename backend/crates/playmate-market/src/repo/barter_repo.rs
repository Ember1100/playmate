//! 以物换物数据库查询

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::Barter;

const COLS: &str =
    "id, user_id, title, description, images, offer_item, want_item, category,
     location, contact, status, view_count, created_at";

pub async fn list(
    pool: &PgPool,
    category: Option<&str>,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<Barter>> {
    if let Some(cat) = category {
        sqlx::query_as::<_, Barter>(&format!(
            "SELECT {COLS} FROM barter
             WHERE status = 1 AND category = $1
             ORDER BY created_at DESC LIMIT $2 OFFSET $3"
        ))
        .bind(cat)
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)
    } else {
        sqlx::query_as::<_, Barter>(&format!(
            "SELECT {COLS} FROM barter
             WHERE status = 1
             ORDER BY created_at DESC LIMIT $1 OFFSET $2"
        ))
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)
    }
}

pub async fn create(
    pool: &PgPool,
    user_id: Uuid,
    title: &str,
    description: Option<&str>,
    images: serde_json::Value,
    offer_item: &str,
    want_item: &str,
    category: Option<&str>,
    location: Option<&str>,
    contact: Option<&str>,
) -> AppResult<Barter> {
    sqlx::query_as::<_, Barter>(&format!(
        "INSERT INTO barter (user_id, title, description, images, offer_item, want_item, category, location, contact)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING {COLS}"
    ))
    .bind(user_id)
    .bind(title)
    .bind(description)
    .bind(images)
    .bind(offer_item)
    .bind(want_item)
    .bind(category)
    .bind(location)
    .bind(contact)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn get(pool: &PgPool, id: Uuid) -> AppResult<Barter> {
    sqlx::query_as::<_, Barter>(&format!(
        "SELECT {COLS} FROM barter WHERE id = $1"
    ))
    .bind(id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("以物换物 {} 不存在", id)))
}

pub async fn update(
    pool: &PgPool,
    id: Uuid,
    user_id: Uuid,
    title: Option<&str>,
    description: Option<&str>,
    images: Option<serde_json::Value>,
    offer_item: Option<&str>,
    want_item: Option<&str>,
    category: Option<&str>,
    location: Option<&str>,
    contact: Option<&str>,
) -> AppResult<Barter> {
    let result = sqlx::query_as::<_, Barter>(&format!(
        "UPDATE barter SET
             title       = COALESCE($3, title),
             description = COALESCE($4, description),
             images      = COALESCE($5, images),
             offer_item  = COALESCE($6, offer_item),
             want_item   = COALESCE($7, want_item),
             category    = COALESCE($8, category),
             location    = COALESCE($9, location),
             contact     = COALESCE($10, contact)
         WHERE id = $1 AND user_id = $2
         RETURNING {COLS}"
    ))
    .bind(id)
    .bind(user_id)
    .bind(title)
    .bind(description)
    .bind(images)
    .bind(offer_item)
    .bind(want_item)
    .bind(category)
    .bind(location)
    .bind(contact)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?;

    result.ok_or_else(|| AppError::Forbidden("无权修改该记录".to_string()))
}

pub async fn delete(pool: &PgPool, id: Uuid, user_id: Uuid) -> AppResult<()> {
    let r = sqlx::query("DELETE FROM barter WHERE id = $1 AND user_id = $2")
        .bind(id)
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(AppError::Database)?;
    if r.rows_affected() == 0 {
        return Err(AppError::Forbidden("无权删除该记录".to_string()));
    }
    Ok(())
}
