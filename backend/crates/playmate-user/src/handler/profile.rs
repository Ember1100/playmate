//! 用户 Profile HTTP Handler
//!
//! # 路由
//! - GET /api/v1/users/me
//! - PUT /api/v1/users/me
//! - GET /api/v1/users/:id

use axum::{extract::{Path, State}, response::IntoResponse, Json};
use uuid::Uuid;
use validator::Validate;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::{model::auth::{UpdateProfileRequest, UserResponse}, repo::user_repo};

/// 获取当前用户 Profile
pub async fn get_me(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let user = user_repo::find_by_id(&state.db, current_user.id).await?;
    Ok(ApiResponse::ok(UserResponse::from(user)))
}

/// 获取指定用户 Profile（公开信息）
pub async fn get_user(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
    _current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let user = user_repo::find_by_id(&state.db, user_id).await?;
    Ok(ApiResponse::ok(UserResponse::from(user)))
}

/// 更新当前用户 Profile
pub async fn update_me(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<UpdateProfileRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;
    let user = user_repo::update_user(
        &state.db,
        current_user.id,
        payload.username.as_deref(),
        payload.bio.as_deref(),
        payload.gender,
        payload.birthday,
        payload.avatar_url.as_deref(),
    )
    .await?;
    Ok(ApiResponse::ok(UserResponse::from(user)))
}
