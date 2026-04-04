//! Match 模块 HTTP Handler
//!
//! # 功能
//! - GET  /api/v1/match/candidates  ← 获取匹配候选（按分排序）
//! - POST /api/v1/match/respond     ← 接受或拒绝匹配

use axum::{extract::State, response::IntoResponse, Json};
use chrono::Utc;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::{
    algorithm::{calculate_match_score, rank_candidates},
    dto::{CandidateResponse, RespondMatchRequest, RespondMatchResponse},
    repository,
};

/// 获取匹配候选列表（最多 20 位，按匹配分降序，score > 0）
///
/// # 错误
/// - `401 Unauthorized` - 未登录
pub async fn get_candidates(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let me = repository::get_user_profile(&state.db, current_user.id).await?;
    let raw = repository::get_candidates(&state.db, current_user.id, 50).await?;
    let ranked = rank_candidates(&me, raw);

    let items: Vec<CandidateResponse> = ranked
        .into_iter()
        .take(20)
        .map(|(profile, score)| {
            let common_tags: Vec<i32> = profile
                .tag_ids
                .iter()
                .filter(|t| me.tag_ids.contains(t))
                .copied()
                .collect();
            CandidateResponse {
                user_id: profile.id,
                username: profile.username,
                avatar_url: profile.avatar_url,
                bio: profile.bio,
                gender: profile.gender,
                birthday: profile.birthday,
                score,
                common_tags,
            }
        })
        .collect();

    Ok(ApiResponse::ok(items))
}

/// 响应匹配（接受或拒绝目标用户）
///
/// 匹配成功条件：对方已发起对我的接受记录，我此次也接受 → 双方匹配，自动创建会话。
///
/// # 错误
/// - `400 BadRequest` - 不能对自己操作
/// - `401 Unauthorized` - 未登录
pub async fn respond_match(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<RespondMatchRequest>,
) -> Result<impl IntoResponse, AppError> {
    if payload.target_user_id == current_user.id {
        return Err(AppError::BadRequest("不能对自己操作".to_string()));
    }

    // 检查是否已有对方对我的接受记录（对方先接受了）
    let existing = repository::find_record(&state.db, current_user.id, payload.target_user_id).await?;

    if !payload.accept {
        // 拒绝：创建或更新为 rejected
        if let Some(rec) = existing {
            repository::reject_record(&state.db, rec.id).await?;
        } else {
            // 先计算匹配分再创建记录
            let me = repository::get_user_profile(&state.db, current_user.id).await?;
            let them = repository::get_user_profile(&state.db, payload.target_user_id).await?;
            let score = calculate_match_score(&me, &them) as i16;
            let rec = repository::create_record(&state.db, current_user.id, payload.target_user_id, score).await?;
            repository::reject_record(&state.db, rec.id).await?;
        }
        return Ok(ApiResponse::ok(RespondMatchResponse {
            status: "rejected".to_string(),
            conversation_id: None,
            matched_at: None,
        }));
    }

    // ---- 接受逻辑 ----
    // 情况 A：对方已对我发起接受记录（user_a=target, user_b=me, status=0）
    if let Some(rec) = existing {
        // 对方先接受了我，现在我也接受 → 双向匹配成功
        if rec.user_a_id == payload.target_user_id && rec.status == 0 {
            let now = Utc::now();
            repository::accept_record(&state.db, rec.id, now).await?;

            // 创建私聊会话（若尚不存在）
            let conv_id = if let Some(id) = playmate_common_conv_find(&state, current_user.id, payload.target_user_id).await {
                id
            } else {
                playmate_common_conv_create(&state, current_user.id, payload.target_user_id).await?
            };

            return Ok(ApiResponse::ok(RespondMatchResponse {
                status: "matched".to_string(),
                conversation_id: Some(conv_id),
                matched_at: Some(now),
            }));
        }
        // 已是 rejected 或 matched：返回当前状态
        let status = match rec.status {
            1 => "matched",
            2 => "rejected",
            _ => "pending",
        };
        return Ok(ApiResponse::ok(RespondMatchResponse {
            status: status.to_string(),
            conversation_id: None,
            matched_at: rec.matched_at,
        }));
    }

    // 情况 B：无记录，我先接受，等对方响应
    let me = repository::get_user_profile(&state.db, current_user.id).await?;
    let them = repository::get_user_profile(&state.db, payload.target_user_id).await?;
    let score = calculate_match_score(&me, &them) as i16;
    repository::create_record(&state.db, current_user.id, payload.target_user_id, score).await?;

    Ok(ApiResponse::ok(RespondMatchResponse {
        status: "pending".to_string(),
        conversation_id: None,
        matched_at: None,
    }))
}

// ── 内部辅助：复用 conversations 表（避免循环依赖，直接写 SQL）──────────────

async fn playmate_common_conv_find(state: &AppState, user_a: uuid::Uuid, user_b: uuid::Uuid) -> Option<uuid::Uuid> {
    let row: Option<(uuid::Uuid,)> = sqlx::query_as(
        "SELECT c.id FROM conversations c
         JOIN conversation_members cm1 ON cm1.conversation_id = c.id AND cm1.user_id = $1
         JOIN conversation_members cm2 ON cm2.conversation_id = c.id AND cm2.user_id = $2
         WHERE c.type = 1 LIMIT 1",
    )
    .bind(user_a)
    .bind(user_b)
    .fetch_optional(&state.db)
    .await
    .ok()?;
    row.map(|(id,)| id)
}

async fn playmate_common_conv_create(
    state: &AppState,
    user_a: uuid::Uuid,
    user_b: uuid::Uuid,
) -> playmate_common::error::AppResult<uuid::Uuid> {
    let mut tx = state.db.begin().await?;
    let row: (uuid::Uuid,) =
        sqlx::query_as("INSERT INTO conversations (type) VALUES (1) RETURNING id")
            .fetch_one(&mut *tx)
            .await?;
    sqlx::query(
        "INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2), ($1, $3)",
    )
    .bind(row.0)
    .bind(user_a)
    .bind(user_b)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(row.0)
}
