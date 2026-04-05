//! 失物招领数据库查询

use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::LostFound;

const COLS: &str =
    "id, user_id, type, title, description, images, category, location, contact,
     status, serial_no, view_count, created_at";

/// 生成失物编号：MM-DDHH-mm-ss
pub fn gen_serial_no() -> String {
    let now = Utc::now();
    format!(
        "{:02}-{:02}{}-{:02}-{:02}",
        now.format("%m"),
        now.format("%d"),
        now.format("%-H"),
        now.format("%M"),
        now.format("%S"),
    )
}

pub async fn list(
    pool: &PgPool,
    item_type: Option<i16>,
    category: Option<&str>,
    keyword: Option<&str>,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<LostFound>> {
    // 使用 IS NULL OR 技巧统一处理可选过滤条件，避免动态 SQL 拼接
    sqlx::query_as::<_, LostFound>(&format!(
        "SELECT {COLS} FROM lost_found
         WHERE status = 1
           AND ($1::SMALLINT IS NULL OR type = $1)
           AND ($2::VARCHAR  IS NULL OR category = $2)
           AND ($3::VARCHAR  IS NULL
                OR title       ILIKE '%' || $3 || '%'
                OR description ILIKE '%' || $3 || '%')
         ORDER BY created_at DESC LIMIT $4 OFFSET $5"
    ))
    .bind(item_type)
    .bind(category)
    .bind(keyword)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn create(
    pool: &PgPool,
    user_id: Uuid,
    item_type: i16,
    title: &str,
    description: Option<&str>,
    images: serde_json::Value,
    category: Option<&str>,
    location: Option<&str>,
    contact: Option<&str>,
) -> AppResult<LostFound> {
    let serial_no = gen_serial_no();
    sqlx::query_as::<_, LostFound>(&format!(
        "INSERT INTO lost_found (user_id, type, title, description, images, category, location, contact, serial_no)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING {COLS}"
    ))
    .bind(user_id)
    .bind(item_type)
    .bind(title)
    .bind(description)
    .bind(images)
    .bind(category)
    .bind(location)
    .bind(contact)
    .bind(serial_no)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn get(pool: &PgPool, id: Uuid) -> AppResult<LostFound> {
    sqlx::query_as::<_, LostFound>(&format!(
        "SELECT {COLS} FROM lost_found WHERE id = $1"
    ))
    .bind(id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("失物招领 {} 不存在", id)))
}

pub async fn update(
    pool: &PgPool,
    id: Uuid,
    user_id: Uuid,
    title: Option<&str>,
    description: Option<&str>,
    images: Option<serde_json::Value>,
    category: Option<&str>,
    location: Option<&str>,
    contact: Option<&str>,
) -> AppResult<LostFound> {
    let result = sqlx::query_as::<_, LostFound>(&format!(
        "UPDATE lost_found SET
             title       = COALESCE($3, title),
             description = COALESCE($4, description),
             images      = COALESCE($5, images),
             category    = COALESCE($6, category),
             location    = COALESCE($7, location),
             contact     = COALESCE($8, contact)
         WHERE id = $1 AND user_id = $2
         RETURNING {COLS}"
    ))
    .bind(id)
    .bind(user_id)
    .bind(title)
    .bind(description)
    .bind(images)
    .bind(category)
    .bind(location)
    .bind(contact)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?;

    result.ok_or_else(|| AppError::Forbidden("无权修改该记录".to_string()))
}

pub async fn delete(pool: &PgPool, id: Uuid, user_id: Uuid) -> AppResult<()> {
    let r = sqlx::query("DELETE FROM lost_found WHERE id = $1 AND user_id = $2")
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

pub async fn resolve(pool: &PgPool, id: Uuid, user_id: Uuid) -> AppResult<()> {
    let r = sqlx::query(
        "UPDATE lost_found SET status = 2 WHERE id = $1 AND user_id = $2",
    )
    .bind(id)
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;
    if r.rows_affected() == 0 {
        return Err(AppError::Forbidden("无权操作该记录".to_string()));
    }
    Ok(())
}
