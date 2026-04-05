//! 搭子 HTTP Handler
//!
//! # 路由
//! - GET  /api/v1/buddy/candidates
//! - POST /api/v1/buddy/request
//! - PUT  /api/v1/buddy/request/:id/respond
//! - GET  /api/v1/buddy/mine

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse,
    Json,
};
use uuid::Uuid;
use validator::Validate;

use playmate_common::{
    error::AppError,
    notify::push_notification,
    response::{ApiResponse, PageResponse},
    AppState, CurrentUser,
};

use crate::{
    dto::{
        BuddyRequestResponse, CandidateResponse, CandidatesQuery, MyBuddiesQuery,
        RespondBuddyRequestRequest, SendBuddyRequestRequest,
    },
    repo::buddy_repo,
};

/// 搭子候选人列表
pub async fn list_candidates(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(q): Query<CandidatesQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let candidates =
        buddy_repo::list_candidates(&state.db, current_user.id, q.req_type, limit, offset).await?;
    let items: Vec<CandidateResponse> = candidates.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}

/// 发起搭子请求
pub async fn send_request(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<SendBuddyRequestRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    if payload.to_user_id == current_user.id {
        return Err(AppError::BadRequest("不能向自己发送搭子请求".to_string()));
    }

    let req = buddy_repo::send_request(
        &state.db,
        current_user.id,
        payload.to_user_id,
        payload.req_type,
        payload.message.as_deref(),
    )
    .await?;

    // 通知对方：有人发起了搭子请求
    let _ = push_notification(
        &state,
        payload.to_user_id,
        "buddy_request",
        "有人想和你成为搭子",
        payload.message.as_deref(),
        Some("buddy_request"),
        Some(req.id),
    )
    .await;

    Ok(ApiResponse::ok(BuddyRequestResponse::from(req)))
}

/// 响应搭子请求
pub async fn respond_request(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<RespondBuddyRequestRequest>,
) -> Result<impl IntoResponse, AppError> {
    let req =
        buddy_repo::respond_request(&state.db, id, current_user.id, payload.accept).await?;

    // 通知发起方：请求已被接受 / 拒绝
    if payload.accept {
        let _ = push_notification(
            &state,
            req.from_user_id,
            "buddy_request",
            "你的搭子请求已被接受",
            None,
            Some("buddy_request"),
            Some(req.id),
        )
        .await;
    }

    Ok(ApiResponse::ok(BuddyRequestResponse::from(req)))
}

/// 我的搭子列表
pub async fn list_my_buddies(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(q): Query<MyBuddiesQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let buddies =
        buddy_repo::list_my_buddies(&state.db, current_user.id, limit, offset).await?;
    let items: Vec<CandidateResponse> = buddies.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}
