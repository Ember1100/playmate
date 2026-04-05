//! 社群数据库查询

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::{SocialGroup, SocialGroupMessage};

const GROUP_COLS: &str =
    "id, creator_id, name, description, avatar_url, category, member_count, is_public, created_at";

const MSG_COLS: &str =
    "id, group_id, sender_id, type, content, media_url, is_recalled, created_at";

pub async fn list_groups(
    pool: &PgPool,
    category: Option<&str>,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<SocialGroup>> {
    if let Some(cat) = category {
        sqlx::query_as::<_, SocialGroup>(&format!(
            "SELECT {GROUP_COLS} FROM social_groups
             WHERE is_public = true AND category = $1
             ORDER BY member_count DESC LIMIT $2 OFFSET $3"
        ))
        .bind(cat)
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)
    } else {
        sqlx::query_as::<_, SocialGroup>(&format!(
            "SELECT {GROUP_COLS} FROM social_groups
             WHERE is_public = true
             ORDER BY member_count DESC LIMIT $1 OFFSET $2"
        ))
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)
    }
}

pub async fn create_group(
    pool: &PgPool,
    creator_id: Uuid,
    name: &str,
    description: Option<&str>,
    avatar_url: Option<&str>,
    category: Option<&str>,
) -> AppResult<SocialGroup> {
    let mut tx = pool.begin().await?;

    let group: SocialGroup = sqlx::query_as::<_, SocialGroup>(&format!(
        "INSERT INTO social_groups (creator_id, name, description, avatar_url, category)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING {GROUP_COLS}"
    ))
    .bind(creator_id)
    .bind(name)
    .bind(description)
    .bind(avatar_url)
    .bind(category)
    .fetch_one(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    // 创建者自动成为管理员
    sqlx::query(
        "INSERT INTO social_group_members (group_id, user_id, role) VALUES ($1, $2, 2)",
    )
    .bind(group.id)
    .bind(creator_id)
    .execute(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    tx.commit().await?;
    Ok(group)
}

pub async fn get_group(pool: &PgPool, group_id: Uuid) -> AppResult<SocialGroup> {
    sqlx::query_as::<_, SocialGroup>(&format!(
        "SELECT {GROUP_COLS} FROM social_groups WHERE id = $1"
    ))
    .bind(group_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("社群 {} 不存在", group_id)))
}

pub async fn join_group(pool: &PgPool, group_id: Uuid, user_id: Uuid) -> AppResult<()> {
    let mut tx = pool.begin().await?;

    let inserted = sqlx::query(
        "INSERT INTO social_group_members (group_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
    )
    .bind(group_id)
    .bind(user_id)
    .execute(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    if inserted.rows_affected() > 0 {
        sqlx::query(
            "UPDATE social_groups SET member_count = member_count + 1 WHERE id = $1",
        )
        .bind(group_id)
        .execute(&mut *tx)
        .await
        .map_err(AppError::Database)?;
    }

    tx.commit().await?;
    Ok(())
}

pub async fn leave_group(pool: &PgPool, group_id: Uuid, user_id: Uuid) -> AppResult<()> {
    let mut tx = pool.begin().await?;

    let deleted = sqlx::query(
        "DELETE FROM social_group_members WHERE group_id = $1 AND user_id = $2",
    )
    .bind(group_id)
    .bind(user_id)
    .execute(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    if deleted.rows_affected() > 0 {
        sqlx::query(
            "UPDATE social_groups SET member_count = GREATEST(member_count - 1, 0) WHERE id = $1",
        )
        .bind(group_id)
        .execute(&mut *tx)
        .await
        .map_err(AppError::Database)?;
    }

    tx.commit().await?;
    Ok(())
}

pub async fn is_member(pool: &PgPool, group_id: Uuid, user_id: Uuid) -> AppResult<bool> {
    let row: (bool,) = sqlx::query_as(
        "SELECT EXISTS(SELECT 1 FROM social_group_members WHERE group_id=$1 AND user_id=$2)",
    )
    .bind(group_id)
    .bind(user_id)
    .fetch_one(pool)
    .await?;
    Ok(row.0)
}

pub async fn list_group_messages(
    pool: &PgPool,
    group_id: Uuid,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<SocialGroupMessage>> {
    sqlx::query_as::<_, SocialGroupMessage>(&format!(
        "SELECT {MSG_COLS} FROM social_group_messages
         WHERE group_id = $1
         ORDER BY created_at DESC LIMIT $2 OFFSET $3"
    ))
    .bind(group_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}
