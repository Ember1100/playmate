//! 线上搭子快速匹配 Handler
//!
//! # 路由
//! - POST   /api/v1/buddy/match/join    加入匹配队列
//! - DELETE /api/v1/buddy/match/leave   退出匹配队列
//! - GET    /api/v1/buddy/match/result  查询匹配结果（短轮询）
//! - POST   /api/v1/buddy/match/next    跳过当前结果，重新排队

use axum::{extract::State, response::IntoResponse, Json};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use serde_json::json;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::repo::match_repo::{self, MatchResult, QueueEntry};

// ── Request ───────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct JoinMatchRequest {
    /// 想玩的活动，如 ["游戏", "追剧"]
    pub activities:  Vec<String>,
    /// 0=开心 1=放松 2=无聊 3=焦虑
    pub mood:        i16,
    /// 0=不限 1=仅男 2=仅女
    pub gender_pref: i16,
}

// ── Response ──────────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct MatchResultResponse {
    pub matched:          bool,
    pub matched_user_id:  Option<String>,
    pub username:         Option<String>,
    pub avatar_url:       Option<Option<String>>,
    pub bio:              Option<Option<String>>,
    pub common_interests: Option<Vec<String>>,
    pub score:            Option<i32>,
}

// ── Handlers ─────────────────────────────────────────────────────────────────

/// 加入匹配队列
pub async fn join_match(
    State(state):  State<AppState>,
    current_user:  CurrentUser,
    Json(payload): Json<JoinMatchRequest>,
) -> Result<impl IntoResponse, AppError> {
    // 查询用户基本信息（用于匹配时展示）
    let row = sqlx::query!(
        "SELECT username, avatar_url, gender, bio FROM users WHERE id = $1",
        current_user.id
    )
    .fetch_one(&state.db)
    .await
    .map_err(AppError::Database)?;

    // 查询用户兴趣标签
    let tags: Vec<String> = sqlx::query_scalar!(
        "SELECT t.name FROM tags t
         JOIN user_tags ut ON ut.tag_id = t.id
         WHERE ut.user_id = $1",
        current_user.id
    )
    .fetch_all(&state.db)
    .await
    .map_err(AppError::Database)?;

    let entry = QueueEntry {
        user_id:     current_user.id,
        username:    row.username,
        avatar_url:  row.avatar_url,
        gender:      row.gender,
        activities:  payload.activities,
        mood:        payload.mood,
        gender_pref: payload.gender_pref,
        tags,
        joined_at:   Utc::now().timestamp(),
    };

    let mut redis = state.redis.clone();
    match_repo::join_queue(&mut redis, &entry).await?;

    Ok(ApiResponse::ok(json!({ "status": "queued" })))
}

/// 退出匹配队列
pub async fn leave_match(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let mut redis = state.redis.clone();
    match_repo::leave_queue(&mut redis, current_user.id).await?;
    Ok(ApiResponse::<()>::ok_empty())
}

/// 查询匹配结果（短轮询：客户端每 2 秒调一次）
pub async fn get_match_result(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let mut redis = state.redis.clone();

    // 先看是否还在等待队列（保留字段供未来使用）
    let _waiting = match_repo::is_waiting(&mut redis, current_user.id).await?;

    // 查结果
    if let Some(result) = match_repo::pop_result(&mut redis, current_user.id).await? {
        return Ok(ApiResponse::ok(MatchResultResponse {
            matched:          true,
            matched_user_id:  Some(result.matched_user_id.to_string()),
            username:         Some(result.username),
            avatar_url:       Some(result.avatar_url),
            bio:              Some(result.bio),
            common_interests: Some(result.common_interests),
            score:            Some(result.score),
        }));
    }

    Ok(ApiResponse::ok(MatchResultResponse {
        matched:          false,
        matched_user_id:  None,
        username:         None,
        avatar_url:       None,
        bio:              None,
        common_interests: None,
        score:            None,
    }))
}

/// 跳过当前匹配，重新入队
pub async fn next_match(
    State(state):  State<AppState>,
    current_user:  CurrentUser,
    Json(payload): Json<JoinMatchRequest>,
) -> Result<impl IntoResponse, AppError> {
    // 复用 join_match 逻辑
    let row = sqlx::query!(
        "SELECT username, avatar_url, gender FROM users WHERE id = $1",
        current_user.id
    )
    .fetch_one(&state.db)
    .await
    .map_err(AppError::Database)?;

    let tags: Vec<String> = sqlx::query_scalar!(
        "SELECT t.name FROM tags t
         JOIN user_tags ut ON ut.tag_id = t.id
         WHERE ut.user_id = $1",
        current_user.id
    )
    .fetch_all(&state.db)
    .await
    .map_err(AppError::Database)?;

    let entry = QueueEntry {
        user_id:     current_user.id,
        username:    row.username,
        avatar_url:  row.avatar_url,
        gender:      row.gender,
        activities:  payload.activities,
        mood:        payload.mood,
        gender_pref: payload.gender_pref,
        tags,
        joined_at:   Utc::now().timestamp(),
    };

    let mut redis = state.redis.clone();
    match_repo::join_queue(&mut redis, &entry).await?;

    Ok(ApiResponse::ok(json!({ "status": "queued" })))
}
