//! 投票 HTTP Handler
//!
//! # 路由
//! - GET  /api/v1/polls
//! - POST /api/v1/polls
//! - POST /api/v1/polls/:id/vote

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse,
    Json,
};
use uuid::Uuid;
use validator::Validate;

use playmate_common::{
    error::AppError,
    response::{ApiResponse, PageResponse},
    AppState, CurrentUser,
};

use crate::{
    dto::{CreatePollRequest, ListPollsQuery, PollResponse, VotePollRequest},
    repo::poll_repo,
};

/// 获取投票列表
pub async fn list_polls(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Query(q): Query<ListPollsQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let polls = poll_repo::list_polls(&state.db, limit, offset).await?;
    let items: Vec<PollResponse> = polls.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}

/// 创建投票
pub async fn create_poll(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CreatePollRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    let poll = poll_repo::create_poll(
        &state.db,
        current_user.id,
        &payload.title,
        &payload.pro_argument,
        &payload.con_argument,
    )
    .await?;

    Ok(ApiResponse::ok(PollResponse::from(poll)))
}

/// 投票
pub async fn vote_poll(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<VotePollRequest>,
) -> Result<impl IntoResponse, AppError> {
    let poll = poll_repo::vote(&state.db, id, current_user.id, payload.side).await?;
    Ok(ApiResponse::ok(PollResponse::from(poll)))
}
