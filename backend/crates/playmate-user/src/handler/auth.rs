//! 认证 HTTP Handler
//!
//! # 路由
//! - POST   /api/v1/auth/sms/send
//! - POST   /api/v1/auth/sms/verify
//! - POST   /api/v1/auth/wechat/login
//! - POST   /api/v1/auth/refresh
//! - POST   /api/v1/auth/logout
//! - DELETE /api/v1/auth/account

use axum::{extract::State, response::IntoResponse, Json};
use validator::Validate;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::{
    model::auth::{DevLoginRequest, RefreshRequest, SmsCodeRequest, SmsVerifyRequest, WechatLoginRequest},
    repo::user_repo,
    service::{auth_service, sms_service},
};

/// 发送短信验证码
pub async fn send_sms(
    State(state): State<AppState>,
    Json(payload): Json<SmsCodeRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;
    sms_service::send_code(&state, &payload.phone).await?;
    Ok(ApiResponse::ok_empty())
}

/// 短信验证码登录（首次自动注册）
///
/// # 响应
/// 返回 `is_new_user: true` 时，Flutter 跳转新人问卷页
pub async fn verify_sms(
    State(state): State<AppState>,
    Json(payload): Json<SmsVerifyRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;
    let resp = auth_service::login_with_sms(&state, &payload.phone, &payload.code).await?;
    Ok(ApiResponse::ok(resp))
}

/// 微信 OAuth 登录（首次自动注册）
pub async fn wechat_login(
    State(state): State<AppState>,
    Json(payload): Json<WechatLoginRequest>,
) -> Result<impl IntoResponse, AppError> {
    let resp = auth_service::login_with_wechat(&state, &payload.code).await?;
    Ok(ApiResponse::ok(resp))
}

/// 用 Refresh Token 换取新 Access Token
pub async fn refresh(
    State(state): State<AppState>,
    Json(payload): Json<RefreshRequest>,
) -> Result<impl IntoResponse, AppError> {
    let resp = auth_service::refresh_token(&state, &payload.refresh_token).await?;
    Ok(ApiResponse::ok(resp))
}

/// 登出（JWT 无状态，客户端丢弃 Token 即可）
pub async fn logout(_current_user: CurrentUser) -> Result<impl IntoResponse, AppError> {
    Ok(ApiResponse::ok_empty())
}

/// 开发环境快速登录（DEV_MODE=true 时生效，否则返回 404）
///
/// ```
/// POST /api/v1/auth/dev/login
/// { "phone": "13800138000", "username": "testuser" }
/// ```
pub async fn dev_login(
    State(state): State<AppState>,
    Json(payload): Json<DevLoginRequest>,
) -> Result<impl IntoResponse, AppError> {
    let dev_mode = std::env::var("DEV_MODE").unwrap_or_default();
    if dev_mode != "true" {
        return Err(AppError::NotFound("接口不存在".to_string()));
    }
    let resp = auth_service::dev_login(
        &state,
        &payload.phone,
        payload.username.as_deref(),
    )
    .await?;
    Ok(ApiResponse::ok(resp))
}

/// 账号注销（软删除，清除手机号）
pub async fn delete_account(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    user_repo::deactivate_user(&state.db, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}
