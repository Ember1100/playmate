//! 集市收藏数据库查询

use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

#[derive(Debug, FromRow, Serialize)]
pub struct MarketCollect {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub target_type: String,
    pub target_id:   Uuid,
    pub created_at:  DateTime<Utc>,
}

pub async fn add(
    pool: &PgPool,
    user_id: Uuid,
    target_type: &str,
    target_id: Uuid,
) -> AppResult<()> {
    sqlx::query(
        "INSERT INTO market_collects (user_id, target_type, target_id)
         VALUES ($1, $2, $3) ON CONFLICT DO NOTHING",
    )
    .bind(user_id)
    .bind(target_type)
    .bind(target_id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;
    Ok(())
}

pub async fn remove(
    pool: &PgPool,
    user_id: Uuid,
    target_type: &str,
    target_id: Uuid,
) -> AppResult<()> {
    sqlx::query(
        "DELETE FROM market_collects WHERE user_id = $1 AND target_type = $2 AND target_id = $3",
    )
    .bind(user_id)
    .bind(target_type)
    .bind(target_id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;
    Ok(())
}

pub async fn list_mine(
    pool: &PgPool,
    user_id: Uuid,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<MarketCollect>> {
    sqlx::query_as::<_, MarketCollect>(
        "SELECT id, user_id, target_type, target_id, created_at
         FROM market_collects
         WHERE user_id = $1
         ORDER BY created_at DESC LIMIT $2 OFFSET $3",
    )
    .bind(user_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}
