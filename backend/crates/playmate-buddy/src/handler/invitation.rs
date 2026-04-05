//! 邀约 HTTP Handler
//!
//! # 路由
//! - POST /api/v1/buddy/invitations
//! - GET  /api/v1/buddy/invitations/sent
//! - GET  /api/v1/buddy/invitations/received
//! - PUT  /api/v1/buddy/invitations/:id/respond

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
        InvitationResponse, InvitationsQuery, RespondInvitationRequest, SendInvitationRequest,
    },
    repo::invitation_repo,
};

/// 发送邀约
pub async fn send_invitation(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<SendInvitationRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    if payload.to_user_id == current_user.id {
        return Err(AppError::BadRequest("不能向自己发送邀约".to_string()));
    }

    let inv = invitation_repo::send(
        &state.db,
        current_user.id,
        payload.to_user_id,
        &payload.title,
        payload.content.as_deref(),
        payload.activity_type.as_deref(),
        payload.scheduled_at,
        payload.location.as_deref(),
    )
    .await?;

    // 通知对方收到邀约
    let _ = push_notification(
        &state,
        payload.to_user_id,
        "invitation",
        &format!("你收到了一条邀约：{}", payload.title),
        payload.content.as_deref(),
        Some("invitation"),
        Some(inv.id),
    )
    .await;

    Ok(ApiResponse::ok(InvitationResponse::from(inv)))
}

/// 我发出的邀约
pub async fn list_sent(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(q): Query<InvitationsQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let invs =
        invitation_repo::list_sent(&state.db, current_user.id, limit, offset).await?;
    let items: Vec<InvitationResponse> = invs.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}

/// 我收到的邀约
pub async fn list_received(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(q): Query<InvitationsQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let invs =
        invitation_repo::list_received(&state.db, current_user.id, limit, offset).await?;
    let items: Vec<InvitationResponse> = invs.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}

/// 响应邀约
pub async fn respond_invitation(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<RespondInvitationRequest>,
) -> Result<impl IntoResponse, AppError> {
    let inv =
        invitation_repo::respond(&state.db, id, current_user.id, payload.accept).await?;

    // 通知邀约发起方：已被接受
    if payload.accept {
        let _ = push_notification(
            &state,
            inv.from_user_id,
            "invitation",
            "对方接受了你的邀约",
            None,
            Some("invitation"),
            Some(inv.id),
        )
        .await;
    }

    Ok(ApiResponse::ok(InvitationResponse::from(inv)))
}
