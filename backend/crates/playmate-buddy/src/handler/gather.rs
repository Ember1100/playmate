//! 搭子局 HTTP Handler
//!
//! # 路由
//! - POST /api/v1/buddy/gathers
//! - GET  /api/v1/buddy/gathers
//! - GET  /api/v1/buddy/gathers/:id
//! - POST /api/v1/buddy/gathers/:id/join
//! - POST /api/v1/buddy/gathers/:id/leave
//! - POST /api/v1/buddy/gathers/:id/cancel

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
    dto::{CreateGatherRequest, GatherListQuery, GatherResponse},
    repo::gather_repo,
};

/// 发起搭子局
pub async fn create_gather(
    State(state):  State<AppState>,
    current_user:  CurrentUser,
    Json(payload): Json<CreateGatherRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    if payload.end_time <= payload.start_time {
        return Err(AppError::BadRequest("结束时间必须晚于开始时间".to_string()));
    }

    let gather = gather_repo::create(
        &state.db,
        current_user.id,
        &payload.title,
        payload.location.as_deref(),
        payload.start_time,
        payload.end_time,
        &payload.category,
        &payload.theme,
        payload.capacity,
        payload.description.as_deref(),
        &payload.vibes,
    )
    .await?;

    // 创建者自动参加
    let _ = gather_repo::join(&state.db, gather.id, current_user.id).await;

    let detail = gather_repo::get(&state.db, current_user.id, gather.id).await?;
    Ok(ApiResponse::ok(GatherResponse::from(detail)))
}

/// 搭子局列表
pub async fn list_gathers(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(q):     Query<GatherListQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit  = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let items  = gather_repo::list(
        &state.db,
        current_user.id,
        q.category.as_deref(),
        limit,
        offset,
    )
    .await?;
    let items: Vec<GatherResponse> = items.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total:    items.len() as i64,
        page:     q.page,
        limit,
        items,
    }))
}

/// 搭子局详情
pub async fn get_gather(
    State(state):   State<AppState>,
    current_user:   CurrentUser,
    Path(gather_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let detail = gather_repo::get(&state.db, current_user.id, gather_id).await?;
    Ok(ApiResponse::ok(GatherResponse::from(detail)))
}

/// 参加搭子局
pub async fn join_gather(
    State(state):   State<AppState>,
    current_user:   CurrentUser,
    Path(gather_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    gather_repo::join(&state.db, gather_id, current_user.id).await?;
    let detail = gather_repo::get(&state.db, current_user.id, gather_id).await?;
    Ok(ApiResponse::ok(GatherResponse::from(detail)))
}

/// 退出搭子局
pub async fn leave_gather(
    State(state):   State<AppState>,
    current_user:   CurrentUser,
    Path(gather_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    gather_repo::leave(&state.db, gather_id, current_user.id).await?;
    let detail = gather_repo::get(&state.db, current_user.id, gather_id).await?;
    Ok(ApiResponse::ok(GatherResponse::from(detail)))
}

/// 取消搭子局（仅创建者）
pub async fn cancel_gather(
    State(state):   State<AppState>,
    current_user:   CurrentUser,
    Path(gather_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    gather_repo::cancel(&state.db, gather_id, current_user.id).await?;
    Ok(ApiResponse::<()>::ok_empty())
}
