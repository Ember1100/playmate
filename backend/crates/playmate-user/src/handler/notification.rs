//! 消息通知 HTTP Handler
//!
//! # 路由
//! - GET  /api/v1/notifications
//! - POST /api/v1/notifications/read-all
//! - POST /api/v1/notifications/:id/read

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse,
};
use serde::Deserialize;
use uuid::Uuid;

use playmate_common::{error::AppError, response::{ApiResponse, PageResponse}, AppState, CurrentUser};

use crate::{model::auth::NotificationResponse, repo::notification_repo};

#[derive(Deserialize)]
pub struct NotifyQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}
fn default_page() -> i64 { 1 }
fn default_limit() -> i64 { 20 }

/// 获取通知列表（分页）
pub async fn list_notifications(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(q): Query<NotifyQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit  = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let total  = notification_repo::count_notifications(&state.db, current_user.id).await?;
    let items  = notification_repo::list_notifications(&state.db, current_user.id, limit, offset).await?;

    let items: Vec<NotificationResponse> = items
        .into_iter()
        .map(|n| NotificationResponse {
            id:          n.id,
            r#type:      n.r#type,
            title:       n.title,
            content:     n.content,
            target_type: n.target_type,
            target_id:   n.target_id,
            is_read:     n.is_read,
            created_at:  n.created_at,
        })
        .collect();

    Ok(ApiResponse::ok(PageResponse {
        has_more: offset + limit < total,
        total,
        page: q.page,
        limit,
        items,
    }))
}

/// 全部已读
pub async fn read_all(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    notification_repo::mark_all_read(&state.db, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}

/// 单条已读
pub async fn read_one(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    notification_repo::mark_one_read(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}
