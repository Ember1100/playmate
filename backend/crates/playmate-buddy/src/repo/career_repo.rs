//! 职业档案数据库查询（只读，写操作在 playmate-user）

use chrono::{DateTime, Utc};
use serde::Serialize;
use serde_json::Value;
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

#[derive(Debug, FromRow, Serialize)]
pub struct CareerProfileRow {
    pub user_id:     Uuid,
    pub job_title:   Option<String>,
    pub company:     Option<String>,
    pub skills:      Value,
    pub experience:  Option<String>,
    pub looking_for: Option<String>,
    pub is_public:   bool,
    pub updated_at:  DateTime<Utc>,
    // 冗余的用户基本信息
    pub username:    String,
    pub avatar_url:  Option<String>,
}

/// 分页获取所有公开职业档案
pub async fn list_public(
    pool:   &PgPool,
    limit:  i64,
    offset: i64,
) -> AppResult<Vec<CareerProfileRow>> {
    sqlx::query_as::<_, CareerProfileRow>(
        "SELECT cp.user_id, cp.job_title, cp.company, cp.skills,
                cp.experience, cp.looking_for, cp.is_public, cp.updated_at,
                u.username, u.avatar_url
         FROM career_profiles cp
         JOIN users u ON u.id = cp.user_id
         WHERE cp.is_public = true AND u.is_active = true
         ORDER BY cp.updated_at DESC LIMIT $1 OFFSET $2",
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

/// 获取指定用户的职业档案（必须公开）
pub async fn get_public(pool: &PgPool, user_id: Uuid) -> AppResult<CareerProfileRow> {
    sqlx::query_as::<_, CareerProfileRow>(
        "SELECT cp.user_id, cp.job_title, cp.company, cp.skills,
                cp.experience, cp.looking_for, cp.is_public, cp.updated_at,
                u.username, u.avatar_url
         FROM career_profiles cp
         JOIN users u ON u.id = cp.user_id
         WHERE cp.user_id = $1 AND cp.is_public = true AND u.is_active = true",
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("用户 {} 未公开职业档案", user_id)))
}
