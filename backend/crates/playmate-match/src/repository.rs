//! Match 数据库查询（Repository 层）

use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::{MatchRecord, UserProfile};

/// 获取当前用户的画像（含标签）
pub async fn get_user_profile(pool: &PgPool, user_id: Uuid) -> AppResult<UserProfile> {
    sqlx::query_as::<_, UserProfile>(
        "SELECT u.id, u.username, u.avatar_url, u.bio, u.gender, u.birthday,
                COALESCE(ARRAY_AGG(ut.tag_id) FILTER (WHERE ut.tag_id IS NOT NULL), '{}') AS tag_ids
         FROM users u
         LEFT JOIN user_tags ut ON ut.user_id = u.id
         WHERE u.id = $1 AND u.is_active = true
         GROUP BY u.id",
    )
    .bind(user_id)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => AppError::NotFound("用户不存在".to_string()),
        _ => AppError::Database(e),
    })
}

/// 获取候选用户列表（排除自身、已匹配/已拒绝、非活跃用户）
pub async fn get_candidates(pool: &PgPool, user_id: Uuid, limit: i64) -> AppResult<Vec<UserProfile>> {
    sqlx::query_as::<_, UserProfile>(
        "SELECT u.id, u.username, u.avatar_url, u.bio, u.gender, u.birthday,
                COALESCE(ARRAY_AGG(ut.tag_id) FILTER (WHERE ut.tag_id IS NOT NULL), '{}') AS tag_ids
         FROM users u
         LEFT JOIN user_tags ut ON ut.user_id = u.id
         WHERE u.id != $1
           AND u.is_active = true
           AND u.id NOT IN (
               SELECT CASE WHEN user_a_id = $1 THEN user_b_id ELSE user_a_id END
               FROM match_records
               WHERE (user_a_id = $1 OR user_b_id = $1)
                 AND status != 0
           )
         GROUP BY u.id
         LIMIT $2",
    )
    .bind(user_id)
    .bind(limit)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

/// 查找已有的匹配记录（任意方向）
pub async fn find_record(
    pool: &PgPool,
    user_a: Uuid,
    user_b: Uuid,
) -> AppResult<Option<MatchRecord>> {
    sqlx::query_as::<_, MatchRecord>(
        "SELECT id, user_a_id, user_b_id, score, status, matched_at, created_at
         FROM match_records
         WHERE (user_a_id = $1 AND user_b_id = $2)
            OR (user_a_id = $2 AND user_b_id = $1)
         LIMIT 1",
    )
    .bind(user_a)
    .bind(user_b)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)
}

/// 创建新的匹配记录（status=0，等待对方响应）
pub async fn create_record(
    pool: &PgPool,
    user_a: Uuid,
    user_b: Uuid,
    score: i16,
) -> AppResult<MatchRecord> {
    sqlx::query_as::<_, MatchRecord>(
        "INSERT INTO match_records (user_a_id, user_b_id, score)
         VALUES ($1, $2, $3)
         RETURNING id, user_a_id, user_b_id, score, status, matched_at, created_at",
    )
    .bind(user_a)
    .bind(user_b)
    .bind(score)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

/// 将记录更新为已匹配（status=1）
pub async fn accept_record(pool: &PgPool, id: Uuid, matched_at: DateTime<Utc>) -> AppResult<()> {
    sqlx::query(
        "UPDATE match_records SET status = 1, matched_at = $2 WHERE id = $1",
    )
    .bind(id)
    .bind(matched_at)
    .execute(pool)
    .await?;
    Ok(())
}

/// 将记录更新为已拒绝（status=2）
pub async fn reject_record(pool: &PgPool, id: Uuid) -> AppResult<()> {
    sqlx::query("UPDATE match_records SET status = 2 WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(())
}
