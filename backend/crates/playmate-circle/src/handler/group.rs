//! 社群 HTTP Handler
//!
//! # 路由
//! - GET  /api/v1/circle/groups
//! - POST /api/v1/circle/groups
//! - GET  /api/v1/circle/groups/:id
//! - POST /api/v1/circle/groups/:id/join
//! - POST /api/v1/circle/groups/:id/leave
//! - GET  /api/v1/circle/groups/:id/messages

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
    dto::{
        CreateGroupRequest, GroupMessageResponse, GroupResponse, ListGroupMessagesQuery,
        ListGroupsQuery,
    },
    repo::group_repo,
};

/// 获取社群列表
pub async fn list_groups(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Query(q): Query<ListGroupsQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let groups = group_repo::list_groups(&state.db, q.category.as_deref(), limit, offset).await?;
    let items: Vec<GroupResponse> = groups.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}

/// 创建社群
pub async fn create_group(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CreateGroupRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    let group = group_repo::create_group(
        &state.db,
        current_user.id,
        &payload.name,
        payload.description.as_deref(),
        payload.avatar_url.as_deref(),
        payload.category.as_deref(),
    )
    .await?;

    Ok(ApiResponse::ok(GroupResponse::from(group)))
}

/// 获取社群详情
pub async fn get_group(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let group = group_repo::get_group(&state.db, id).await?;
    Ok(ApiResponse::ok(GroupResponse::from(group)))
}

/// 加入社群
pub async fn join_group(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    group_repo::join_group(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}

/// 离开社群
pub async fn leave_group(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    group_repo::leave_group(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}

/// 获取社群消息列表（需要是成员）
pub async fn list_group_messages(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
    Query(q): Query<ListGroupMessagesQuery>,
) -> Result<impl IntoResponse, AppError> {
    if !group_repo::is_member(&state.db, id, current_user.id).await? {
        return Err(AppError::Forbidden("非社群成员".to_string()));
    }

    let limit = q.limit.clamp(1, 100);
    let offset = (q.page - 1) * limit;
    let messages = group_repo::list_group_messages(&state.db, id, limit, offset).await?;
    let items: Vec<GroupMessageResponse> = messages.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}
