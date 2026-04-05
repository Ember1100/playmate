//! 用户 Profile HTTP Handler
//!
//! # 路由
//! - GET  /api/v1/users/me
//! - PUT  /api/v1/users/me
//! - GET  /api/v1/users/me/stats
//! - GET  /api/v1/users/me/career
//! - PUT  /api/v1/users/me/career
//! - GET  /api/v1/users/:id
//! - GET  /api/v1/users/:id/career

use axum::{
    extract::{Path, State},
    response::IntoResponse,
    Json,
};
use uuid::Uuid;
use validator::Validate;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::{
    model::auth::{
        CareerProfileResponse, UpdateCareerRequest, UpdateProfileRequest, UserResponse,
        UserStatsResponse,
    },
    repo::user_repo,
    service::auth_service,
};

/// 获取当前用户 Profile
pub async fn get_me(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let user = user_repo::find_by_id(&state.db, current_user.id).await?;
    Ok(ApiResponse::ok(UserResponse::from(user)))
}

/// 更新当前用户 Profile
///
/// # 错误
/// - `400 BadRequest` - 参数校验失败
/// - `422 Business`  - 年龄超过 35 岁
pub async fn update_me(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<UpdateProfileRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    // 设置了生日则校验年龄
    if let Some(birthday) = payload.birthday {
        auth_service::check_age_limit(birthday)?;
    }

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

/// 获取当前用户成长值/积分/信用分
pub async fn get_my_stats(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let stats = user_repo::get_stats(&state.db, current_user.id).await?;
    Ok(ApiResponse::ok(UserStatsResponse::from(stats)))
}

/// 获取指定用户公开 Profile
pub async fn get_user(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
    _current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let user = user_repo::find_by_id(&state.db, user_id).await?;
    Ok(ApiResponse::ok(UserResponse::from(user)))
}

/// 获取我的职业档案
pub async fn get_my_career(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let career = user_repo::get_career(&state.db, current_user.id).await?;
    Ok(ApiResponse::ok(career.map(CareerProfileResponse::from)))
}

/// 更新我的职业档案（upsert）
pub async fn update_my_career(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<UpdateCareerRequest>,
) -> Result<impl IntoResponse, AppError> {
    let skills = serde_json::to_value(payload.skills.unwrap_or_default())
        .map_err(|e| AppError::Internal(anyhow::anyhow!("{}", e)))?;

    let career = user_repo::upsert_career(
        &state.db,
        current_user.id,
        payload.job_title.as_deref(),
        payload.company.as_deref(),
        skills,
        payload.experience.as_deref(),
        payload.looking_for.as_deref(),
        payload.is_public,
    )
    .await?;
    Ok(ApiResponse::ok(CareerProfileResponse::from(career)))
}

/// 获取指定用户的职业档案（公开）
pub async fn get_user_career(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
    _current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let career = user_repo::get_career(&state.db, user_id).await?;
    match career {
        Some(c) if c.is_public => Ok(ApiResponse::ok(Some(CareerProfileResponse::from(c)))),
        Some(_) => Err(AppError::NotFound("该用户未公开职业档案".to_string())),
        None => Ok(ApiResponse::ok(Option::<CareerProfileResponse>::None)),
    }
}
