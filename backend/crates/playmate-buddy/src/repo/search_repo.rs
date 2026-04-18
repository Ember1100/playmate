//! 搭子搜索：用户 + 搭子局关键词匹配

use std::collections::HashMap;

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::dto::SearchUserResponse;

/// 按关键词搜索用户（用户名或签名 ILIKE），返回 (列表, 总数)
pub async fn search_users(
    pool:    &PgPool,
    keyword: &str,
    limit:   i64,
    offset:  i64,
) -> AppResult<(Vec<SearchUserResponse>, i64)> {
    let pattern = format!("%{}%", keyword);

    // Step 1: 匹配用户名或签名的用户
    let users: Vec<(Uuid, String, Option<String>, Option<String>)> = sqlx::query_as(
        "SELECT id, username, avatar_url, bio
         FROM users
         WHERE username ILIKE $1 OR bio ILIKE $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3",
    )
    .bind(&pattern)
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    // Step 2: 总数（与 Step 1 并行，直接复用 pattern）
    let (total,): (i64,) = sqlx::query_as(
        "SELECT COUNT(*)::BIGINT FROM users WHERE username ILIKE $1 OR bio ILIKE $1",
    )
    .bind(&pattern)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?;

    if users.is_empty() {
        return Ok((vec![], total));
    }

    let user_ids: Vec<Uuid> = users.iter().map(|(id, _, _, _)| *id).collect();

    // Step 3: 标签（user_tags JOIN tags）
    let tag_rows: Vec<(Uuid, String)> = sqlx::query_as(
        "SELECT ut.user_id, t.name
         FROM user_tags ut
         JOIN tags t ON t.id = ut.tag_id
         WHERE ut.user_id = ANY($1)",
    )
    .bind(&user_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    let mut tag_map: HashMap<Uuid, Vec<String>> = HashMap::new();
    for (uid, name) in tag_rows {
        tag_map.entry(uid).or_default().push(name);
    }

    // Step 4: 城市（来自问卷）
    let city_rows: Vec<(Uuid, Option<String>)> = sqlx::query_as(
        "SELECT user_id, city FROM user_questionnaire WHERE user_id = ANY($1)",
    )
    .bind(&user_ids)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)?;

    let city_map: HashMap<Uuid, Option<String>> = city_rows.into_iter().collect();

    // Step 5: 组装
    let result = users
        .into_iter()
        .map(|(id, username, avatar_url, bio)| SearchUserResponse {
            id:         id.to_string(),
            username,
            avatar_url,
            bio,
            tags: tag_map.remove(&id).unwrap_or_default(),
            city: city_map.get(&id).and_then(|c| c.clone()),
        })
        .collect();

    Ok((result, total))
}
