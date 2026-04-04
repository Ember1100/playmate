//! 认证相关 Request / Response DTO

use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::model::user::User;

// ── Requests ────────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(length(min = 2, max = 32, message = "用户名长度 2-32 位"))]
    pub username: String,
    #[validate(email(message = "邮箱格式不正确"))]
    pub email: String,
    #[validate(length(min = 8, max = 72, message = "密码长度 8-72 位"))]
    pub password: String,
}

#[derive(Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email(message = "邮箱格式不正确"))]
    pub email: String,
    pub password: String,
}

/// 发送短信验证码
#[derive(Deserialize, Validate)]
pub struct SmsCodeRequest {
    #[validate(length(min = 11, max = 11, message = "手机号格式不正确"))]
    pub phone: String,
}

/// 短信验证码登录/注册
#[derive(Deserialize, Validate)]
pub struct SmsVerifyRequest {
    #[validate(length(min = 11, max = 11, message = "手机号格式不正确"))]
    pub phone: String,
    #[validate(length(min = 6, max = 6, message = "验证码为 6 位数字"))]
    pub code: String,
}

/// 微信 OAuth 登录
#[derive(Deserialize)]
pub struct WechatLoginRequest {
    pub code: String,
}

#[derive(Deserialize)]
pub struct RefreshRequest {
    pub refresh_token: String,
}

#[derive(Deserialize, Validate)]
pub struct UpdateProfileRequest {
    #[validate(length(min = 2, max = 32, message = "用户名长度 2-32 位"))]
    pub username: Option<String>,
    #[validate(length(max = 200, message = "简介最多 200 字"))]
    pub bio: Option<String>,
    pub gender: Option<i16>,
    pub birthday: Option<NaiveDate>,
    pub avatar_url: Option<String>,
}

/// 设置用户兴趣标签（替换全量）
#[derive(Deserialize)]
pub struct SetTagsRequest {
    pub tag_ids: Vec<i32>,
}

// ── Responses ───────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub username: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub gender: i16,
    pub birthday: Option<NaiveDate>,
    pub created_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(u: User) -> Self {
        Self {
            id: u.id,
            username: u.username,
            email: u.email,
            phone: u.phone,
            avatar_url: u.avatar_url,
            bio: u.bio,
            gender: u.gender,
            birthday: u.birthday,
            created_at: u.created_at,
        }
    }
}

#[derive(Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
    pub user: UserResponse,
}

#[derive(Serialize)]
pub struct AccessTokenResponse {
    pub access_token: String,
    pub token_type: String,
    pub expires_in: i64,
}
