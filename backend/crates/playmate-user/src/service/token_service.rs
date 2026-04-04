//! JWT Token 签发服务

use uuid::Uuid;

use playmate_common::{
    auth::{create_access_token, create_refresh_token, ACCESS_TOKEN_DURATION},
    config::AppConfig,
    error::AppResult,
};

pub struct TokenPair {
    pub access_token: String,
    pub refresh_token: String,
}

/// 一次性签发 Access + Refresh Token 对
pub fn create_token_pair(user_id: Uuid, username: &str, config: &AppConfig) -> AppResult<TokenPair> {
    Ok(TokenPair {
        access_token: create_access_token(user_id, username, &config.jwt_secret)?,
        refresh_token: create_refresh_token(user_id, username, &config.jwt_refresh_secret)?,
    })
}

pub fn expires_in() -> i64 {
    ACCESS_TOKEN_DURATION
}
