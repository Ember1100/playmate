//! Feed 数据库查询（Repository 层）

use serde_json::Value;
use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::Post;

/// 帖子 + 用户信息的组合查询结果
pub struct PostWithUser {
    pub post: Post,
    pub username: String,
    pub avatar_url: Option<String>,
}

pub async fn create_post(
    pool: &PgPool,
    user_id: Uuid,
    content: &str,
    media_urls: Value,
    visibility: i16,
) -> AppResult<Post> {
    sqlx::query_as::<_, Post>(
        "INSERT INTO posts (user_id, content, media_urls, visibility)
         VALUES ($1, $2, $3, $4)
         RETURNING id, user_id, content, media_urls, like_count, comment_count, visibility, created_at",
    )
    .bind(user_id)
    .bind(content)
    .bind(media_urls)
    .bind(visibility)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn find_post_by_id(pool: &PgPool, id: Uuid) -> AppResult<Post> {
    sqlx::query_as::<_, Post>(
        "SELECT id, user_id, content, media_urls, like_count, comment_count, visibility, created_at
         FROM posts WHERE id = $1",
    )
    .bind(id)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => AppError::NotFound(format!("帖子 {} 不存在", id)),
        _ => AppError::Database(e),
    })
}

/// 公开 Feed（visibility=1），JOIN users 获取用户信息，按时间倒序分页
pub async fn list_public_posts_with_user(
    pool: &PgPool,
    limit: i64,
    offset: i64,
) -> AppResult<Vec<PostWithUser>> {
    // 第一次查询：获取帖子列表
    let posts = sqlx::query_as::<_, Post>(
        "SELECT id, user_id, content, media_urls, like_count, comment_count, visibility, created_at
         FROM posts WHERE visibility = 1
         ORDER BY created_at DESC
         LIMIT $1 OFFSET $2",
    )
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    if posts.is_empty() {
        return Ok(vec![]);
    }

    // 收集所有不重复的 user_id
    let user_ids: Vec<Uuid> = posts.iter().map(|p| p.user_id).collect::<std::collections::HashSet<_>>().into_iter().collect();

    // 第二次查询：根据 user_id 列表批量查询用户信息
    let users = sqlx::query_as::<_, (Uuid, String, Option<String>)>(
        "SELECT id, username, avatar_url FROM users WHERE id = ANY($1)",
    )
    .bind(&user_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    // 组装用户信息映射
    let user_map: std::collections::HashMap<Uuid, (String, Option<String>)> = users
        .into_iter()
        .map(|(id, username, avatar_url)| (id, (username, avatar_url)))
        .collect();

    // 遍历帖子，填充用户信息
    let result = posts
        .into_iter()
        .map(|post| {
            let (username, avatar_url) = user_map
                .get(&post.user_id)
                .cloned()
                .unwrap_or_else(|| (post.user_id.to_string()[..8].to_string(), None));
            PostWithUser { post, username, avatar_url }
        })
        .collect();

    Ok(result)
}

pub async fn count_public_posts(pool: &PgPool) -> AppResult<i64> {
    let row: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM posts WHERE visibility = 1")
        .fetch_one(pool)
        .await?;
    Ok(row.0)
}

pub async fn delete_post(pool: &PgPool, id: Uuid, user_id: Uuid) -> AppResult<()> {
    let result = sqlx::query("DELETE FROM posts WHERE id = $1 AND user_id = $2")
        .bind(id)
        .bind(user_id)
        .execute(pool)
        .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound("帖子不存在或无权删除".to_string()));
    }
    Ok(())
}

/// 点赞/取消点赞（幂等切换）。返回 (liked, new_like_count)
pub async fn toggle_like(pool: &PgPool, post_id: Uuid, user_id: Uuid) -> AppResult<(bool, i32)> {
    let mut tx = pool.begin().await?;

    // 尝试插入点赞记录
    let inserted = sqlx::query(
        "INSERT INTO post_likes (post_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
    )
    .bind(post_id)
    .bind(user_id)
    .execute(&mut *tx)
    .await?
    .rows_affected();

    let (liked, like_count) = if inserted > 0 {
        // 新点赞
        let row: (i32,) = sqlx::query_as(
            "UPDATE posts SET like_count = like_count + 1 WHERE id = $1 RETURNING like_count",
        )
        .bind(post_id)
        .fetch_one(&mut *tx)
        .await?;
        (true, row.0)
    } else {
        // 已点赞 → 取消
        sqlx::query("DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2")
            .bind(post_id)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;
        let row: (i32,) = sqlx::query_as(
            "UPDATE posts SET like_count = GREATEST(0, like_count - 1) WHERE id = $1 RETURNING like_count",
        )
        .bind(post_id)
        .fetch_one(&mut *tx)
        .await?;
        (false, row.0)
    };

    tx.commit().await?;
    Ok((liked, like_count))
}
