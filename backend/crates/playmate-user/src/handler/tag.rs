//! 兴趣标签 HTTP Handler
//!
//! # 路由
//! - GET /api/v1/tags            ← 所有可用标签（公开）
//! - GET /api/v1/users/me/tags   ← 我的标签
//! - PUT /api/v1/users/me/tags   ← 设置我的标签（全量替换）

use axum::{
    extract::{Path, State},
    response::IntoResponse,
    Json,
};
use uuid::Uuid;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::{model::auth::SetTagsRequest, repo::user_repo};

/// 列出所有可用标签
pub async fn list_tags(State(state): State<AppState>) -> Result<impl IntoResponse, AppError> {
    let tags = user_repo::list_all_tags(&state.db).await?;
    Ok(ApiResponse::ok(tags))
}

/// 获取当前用户已选标签
pub async fn get_my_tags(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let tags = user_repo::get_user_tags(&state.db, current_user.id).await?;
    Ok(ApiResponse::ok(tags))
}

/// 获取指定用户的公开标签
pub async fn get_user_tags_by_id(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
    _current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let tags = user_repo::get_user_tags(&state.db, user_id).await?;
    Ok(ApiResponse::ok(tags))
}

/// 设置当前用户标签（全量替换）
pub async fn set_my_tags(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<SetTagsRequest>,
) -> Result<impl IntoResponse, AppError> {
    user_repo::set_user_tags(&state.db, current_user.id, &payload.tag_ids).await?;
    let tags = user_repo::get_user_tags(&state.db, current_user.id).await?;
    Ok(ApiResponse::ok(tags))
}
