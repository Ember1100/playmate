//! 话题数据库查询

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::{Topic, TopicComment};

const TOPIC_COLS: &str =
    "id, creator_id, title, content, cover_url, category,
     like_count, comment_count, view_count, is_hot, created_at";

const COMMENT_COLS: &str =
    "id, topic_id, user_id, parent_id, content, like_count, created_at";

pub async fn list_topics(
    pool: &PgPool,
    category: Option<&str>,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<Topic>> {
    if let Some(cat) = category {
        sqlx::query_as::<_, Topic>(&format!(
            "SELECT {TOPIC_COLS} FROM topics
             WHERE category = $1
             ORDER BY created_at DESC LIMIT $2 OFFSET $3"
        ))
        .bind(cat)
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)
    } else {
        sqlx::query_as::<_, Topic>(&format!(
            "SELECT {TOPIC_COLS} FROM topics
             ORDER BY created_at DESC LIMIT $1 OFFSET $2"
        ))
        .bind(limit)
        .bind(offset)
        .fetch_all(pool)
        .await
        .map_err(AppError::Database)
    }
}

pub async fn create_topic(
    pool: &PgPool,
    creator_id: Uuid,
    title: &str,
    content: Option<&str>,
    cover_url: Option<&str>,
    category: Option<&str>,
) -> AppResult<Topic> {
    sqlx::query_as::<_, Topic>(&format!(
        "INSERT INTO topics (creator_id, title, content, cover_url, category)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING {TOPIC_COLS}"
    ))
    .bind(creator_id)
    .bind(title)
    .bind(content)
    .bind(cover_url)
    .bind(category)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn get_topic(pool: &PgPool, topic_id: Uuid) -> AppResult<Topic> {
    sqlx::query_as::<_, Topic>(&format!(
        "SELECT {TOPIC_COLS} FROM topics WHERE id = $1"
    ))
    .bind(topic_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)?
    .ok_or_else(|| AppError::NotFound(format!("话题 {} 不存在", topic_id)))
}

pub async fn delete_topic(pool: &PgPool, topic_id: Uuid, user_id: Uuid) -> AppResult<()> {
    let result = sqlx::query(
        "DELETE FROM topics WHERE id = $1 AND creator_id = $2",
    )
    .bind(topic_id)
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;

    if result.rows_affected() == 0 {
        return Err(AppError::Forbidden("无权删除该话题".to_string()));
    }
    Ok(())
}

pub async fn like_topic(pool: &PgPool, topic_id: Uuid, user_id: Uuid) -> AppResult<()> {
    let mut tx = pool.begin().await?;

    let inserted = sqlx::query(
        "INSERT INTO topic_likes (topic_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
    )
    .bind(topic_id)
    .bind(user_id)
    .execute(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    if inserted.rows_affected() > 0 {
        sqlx::query("UPDATE topics SET like_count = like_count + 1 WHERE id = $1")
            .bind(topic_id)
            .execute(&mut *tx)
            .await
            .map_err(AppError::Database)?;
    }

    tx.commit().await?;
    Ok(())
}

pub async fn unlike_topic(pool: &PgPool, topic_id: Uuid, user_id: Uuid) -> AppResult<()> {
    let mut tx = pool.begin().await?;

    let deleted = sqlx::query(
        "DELETE FROM topic_likes WHERE topic_id = $1 AND user_id = $2",
    )
    .bind(topic_id)
    .bind(user_id)
    .execute(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    if deleted.rows_affected() > 0 {
        sqlx::query(
            "UPDATE topics SET like_count = GREATEST(like_count - 1, 0) WHERE id = $1",
        )
        .bind(topic_id)
        .execute(&mut *tx)
        .await
        .map_err(AppError::Database)?;
    }

    tx.commit().await?;
    Ok(())
}

pub async fn list_comments(
    pool: &PgPool,
    topic_id: Uuid,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<TopicComment>> {
    sqlx::query_as::<_, TopicComment>(&format!(
        "SELECT {COMMENT_COLS} FROM topic_comments
         WHERE topic_id = $1
         ORDER BY created_at ASC LIMIT $2 OFFSET $3"
    ))
    .bind(topic_id)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn create_comment(
    pool: &PgPool,
    topic_id: Uuid,
    user_id: Uuid,
    parent_id: Option<Uuid>,
    content: &str,
) -> AppResult<TopicComment> {
    let mut tx = pool.begin().await?;

    let comment: TopicComment = sqlx::query_as::<_, TopicComment>(&format!(
        "INSERT INTO topic_comments (topic_id, user_id, parent_id, content)
         VALUES ($1, $2, $3, $4)
         RETURNING {COMMENT_COLS}"
    ))
    .bind(topic_id)
    .bind(user_id)
    .bind(parent_id)
    .bind(content)
    .fetch_one(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    sqlx::query("UPDATE topics SET comment_count = comment_count + 1 WHERE id = $1")
        .bind(topic_id)
        .execute(&mut *tx)
        .await
        .map_err(AppError::Database)?;

    tx.commit().await?;
    Ok(comment)
}

pub async fn delete_comment(
    pool: &PgPool,
    comment_id: Uuid,
    user_id: Uuid,
) -> AppResult<()> {
    let mut tx = pool.begin().await?;

    let row: Option<(Uuid,)> = sqlx::query_as(
        "SELECT topic_id FROM topic_comments WHERE id = $1 AND user_id = $2",
    )
    .bind(comment_id)
    .bind(user_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    let (topic_id,) = row.ok_or_else(|| AppError::Forbidden("无权删除该评论".to_string()))?;

    sqlx::query("DELETE FROM topic_comments WHERE id = $1")
        .bind(comment_id)
        .execute(&mut *tx)
        .await
        .map_err(AppError::Database)?;

    sqlx::query(
        "UPDATE topics SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = $1",
    )
    .bind(topic_id)
    .execute(&mut *tx)
    .await
    .map_err(AppError::Database)?;

    tx.commit().await?;
    Ok(())
}
