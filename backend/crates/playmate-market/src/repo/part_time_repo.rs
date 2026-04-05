//! 兼职啦数据库查询

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::PartTime;

const COLS: &str =
    "id, user_id, title, description, images, salary, salary_type, category,
     location, contact, status, view_count, created_at";

pub async fn list(
    pool: &PgPool,
    category: Option<&str>,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<PartTime>> {
    if let Some(cat) = category {
        sqlx::query_as::<_, PartTime>(&format!(
            "SELECT {COLS} FROM part_time
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
        sqlx::query_as::<_, PartTime>(&format!(
            "SELECT {COLS} FROM part_time
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
    salary: Option<&str>,
    salary_type: Option<i16>,
    category: Option<&str>,
    location: Option<&str>,
    contact: Option<&str>,
) -> AppResult<PartTime> {
    sqlx::query_as::<_, PartTime>(&format!(
        "INSERT INTO part_time (user_id, title, description, images, salary, salary_type, category, location, contact)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING {COLS}"
    ))
    .bind(user_id)
    .bind(title)
    .bind(description)
    .bind(images)
    .bind(salary)
    .bind(salary_type)
    .bind(category)
    .bind(location)
    .bind(contact)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn get(pool: &PgPool, id: Uuid) -> AppResult<PartTime> {
    sqlx::query_as::<_, PartTime>(&format!(
        "SELECT {COLS} FROM part_time WHERE id = $1"
    ))
    .bind(id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("兼职啦 {} 不存在", id)))
}

pub async fn update(
    pool: &PgPool,
    id: Uuid,
    user_id: Uuid,
    title: Option<&str>,
    description: Option<&str>,
    images: Option<serde_json::Value>,
    salary: Option<&str>,
    salary_type: Option<i16>,
    category: Option<&str>,
    location: Option<&str>,
    contact: Option<&str>,
) -> AppResult<PartTime> {
    let result = sqlx::query_as::<_, PartTime>(&format!(
        "UPDATE part_time SET
             title       = COALESCE($3, title),
             description = COALESCE($4, description),
             images      = COALESCE($5, images),
             salary      = COALESCE($6, salary),
             salary_type = COALESCE($7, salary_type),
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
    .bind(salary)
    .bind(salary_type)
    .bind(category)
    .bind(location)
    .bind(contact)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?;

    result.ok_or_else(|| AppError::Forbidden("无权修改该记录".to_string()))
}

pub async fn delete(pool: &PgPool, id: Uuid, user_id: Uuid) -> AppResult<()> {
    let r = sqlx::query("DELETE FROM part_time WHERE id = $1 AND user_id = $2")
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
