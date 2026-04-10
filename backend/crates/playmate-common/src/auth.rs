//! JWT 认证工具与 CurrentUser 提取器
//!
//! # 功能
//! - Access Token / Refresh Token 签发与验证
//! - CurrentUser FromRequestParts 提取器（自动校验 Bearer Token）

use async_trait::async_trait;
use axum::{
    extract::FromRequestParts,
    http::{request::Parts, HeaderMap},
};
use chrono::Utc;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{error::AppError, state::AppState};

/// Access Token 有效期：7 天（秒）
pub const ACCESS_TOKEN_DURATION: i64 = 7 * 24 * 60 * 60;
/// Refresh Token 有效期：30 天（秒）
pub const REFRESH_TOKEN_DURATION: i64 = 30 * 24 * 60 * 60;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Claims {
    pub sub: Uuid,
    pub username: String,
    pub exp: usize,
    pub iat: usize,
}

/// 当前登录用户，通过 JWT 提取
#[derive(Clone, Debug)]
pub struct CurrentUser {
    pub id: Uuid,
    pub username: String,
}

// ── Token 签发 ──────────────────────────────────────────────────────────────

pub fn create_access_token(
    user_id: Uuid,
    username: &str,
    secret: &str,
) -> Result<String, AppError> {
    let now = Utc::now().timestamp() as usize;
    let claims = Claims {
        sub: user_id,
        username: username.to_string(),
        iat: now,
        exp: now + ACCESS_TOKEN_DURATION as usize,
    };
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(anyhow::anyhow!("Token 签发失败: {}", e)))
}

pub fn create_refresh_token(
    user_id: Uuid,
    username: &str,
    secret: &str,
) -> Result<String, AppError> {
    let now = Utc::now().timestamp() as usize;
    let claims = Claims {
        sub: user_id,
        username: username.to_string(),
        iat: now,
        exp: now + REFRESH_TOKEN_DURATION as usize,
    };
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(anyhow::anyhow!("Refresh Token 签发失败: {}", e)))
}

pub fn verify_token(token: &str, secret: &str) -> Result<Claims, AppError> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|_| AppError::Unauthorized("Token 无效或已过期".to_string()))?;
    Ok(token_data.claims)
}

// ── FromRequestParts ────────────────────────────────────────────────────────

fn extract_bearer(headers: &HeaderMap) -> Option<String> {
    let value = headers.get("Authorization")?.to_str().ok()?;
    value.strip_prefix("Bearer ").map(|s| s.to_string())
}

/// WebSocket 握手无法携带自定义 header，从 ?token= 查询参数提取
fn extract_query_token(parts: &Parts) -> Option<String> {
    let query = parts.uri.query()?;
    for pair in query.split('&') {
        if let Some(val) = pair.strip_prefix("token=") {
            return Some(val.to_string());
        }
    }
    None
}

#[async_trait]
impl FromRequestParts<AppState> for CurrentUser {
    type Rejection = AppError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        // 优先从 Authorization header 读取，WebSocket 升级时 fallback 到 ?token=
        let token = extract_bearer(&parts.headers)
            .or_else(|| extract_query_token(parts))
            .ok_or_else(|| AppError::Unauthorized("缺少认证信息".to_string()))?;

        let claims = verify_token(&token, &state.config.jwt_secret)?;

        Ok(CurrentUser {
            id: claims.sub,
            username: claims.username,
        })
    }
}
