//! 认证 HTTP Handler
//!
//! # 路由
//! - POST /api/v1/auth/register
//! - POST /api/v1/auth/login
//! - POST /api/v1/auth/sms/send
//! - POST /api/v1/auth/sms/verify
//! - POST /api/v1/auth/wechat/login
//! - POST /api/v1/auth/refresh
//! - POST /api/v1/auth/logout

use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use validator::Validate;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::{
    model::auth::{
        LoginRequest, RefreshRequest, RegisterRequest, SmsCodeRequest, SmsVerifyRequest,
        WechatLoginRequest,
    },
    service::{auth_service, sms_service},
};

/// 邮箱注册
pub async fn register(
    State(state): State<AppState>,
    Json(payload): Json<RegisterRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;
    let resp = auth_service::register_with_email(
        &state,
        &payload.username,
        &payload.email,
        &payload.password,
    )
    .await?;
    Ok((StatusCode::CREATED, ApiResponse::ok(resp)))
}

/// 邮箱密码登录
pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;
    let resp = auth_service::login_with_email(&state, &payload.email, &payload.password).await?;
    Ok(ApiResponse::ok(resp))
}

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

/// 登出（无状态，客户端丢弃 Token 即可）
pub async fn logout(_current_user: CurrentUser) -> Result<impl IntoResponse, AppError> {
    Ok(ApiResponse::ok_empty())
}
