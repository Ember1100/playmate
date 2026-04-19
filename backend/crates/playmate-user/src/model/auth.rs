//! 认证 / 用户相关 Request & Response DTO

use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::model::user::{CareerProfile, User, UserStats};

// ── Auth Requests ────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(length(min = 2, max = 32, message = "用户名长度 2-32 位"))]
    pub username: String,
    #[validate(email(message = "邮箱格式不正确"))]
    pub email: String,
    #[validate(length(min = 6, max = 72, message = "密码长度 6-72 位"))]
    pub password: String,
}

#[derive(Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email(message = "邮箱格式不正确"))]
    pub email: String,
    #[validate(length(min = 1, message = "请输入密码"))]
    pub password: String,
}

/// 开发环境专用：免短信验证码直接登录 / 注册
/// 仅在环境变量 DEV_MODE=true 时生效
#[derive(Deserialize)]
pub struct DevLoginRequest {
    pub phone:    String,
    pub password: String,          // 需与服务器 DEV_PASSWORD 环境变量匹配
    #[serde(default)]
    pub username: Option<String>,
}

#[derive(Deserialize, Validate)]
pub struct SmsCodeRequest {
    #[validate(length(min = 11, max = 11, message = "手机号格式不正确"))]
    pub phone: String,
}

#[derive(Deserialize, Validate)]
pub struct SmsVerifyRequest {
    #[validate(length(min = 11, max = 11, message = "手机号格式不正确"))]
    pub phone: String,
    #[validate(length(min = 6, max = 6, message = "验证码为 6 位数字"))]
    pub code: String,
}

#[derive(Deserialize)]
pub struct WechatLoginRequest {
    pub code: String,
}

#[derive(Deserialize)]
pub struct RefreshRequest {
    pub refresh_token: String,
}

// ── Profile Requests ─────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct UpdateProfileRequest {
    #[validate(length(min = 2, max = 32, message = "用户名长度 2-32 位"))]
    pub username:   Option<String>,
    #[validate(length(max = 200, message = "简介最多 200 字"))]
    pub bio:        Option<String>,
    pub gender:     Option<i16>,
    pub birthday:   Option<NaiveDate>,
    pub avatar_url: Option<String>,
}

#[derive(Deserialize)]
pub struct SetTagsRequest {
    pub tag_ids: Vec<i32>,
}

// ── Questionnaire Request ─────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct QuestionnaireRequest {
    pub identity:    Option<String>,
    pub interests:   Option<Vec<i32>>,
    pub purposes:    Option<Vec<i32>>,
    pub age_range:   Option<String>,
    pub city:        Option<String>,
    pub personality: Option<serde_json::Value>,
    pub life_goal:   Option<String>,
}

// ── Career Requests ───────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct UpdateCareerRequest {
    pub job_title:   Option<String>,
    pub company:     Option<String>,
    pub skills:      Option<Vec<String>>,
    pub experience:  Option<String>,
    pub looking_for: Option<String>,
    pub is_public:   Option<bool>,
}

// ── Feedback Request ──────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct FeedbackRequest {
    #[serde(default = "default_feedback_type")]
    pub r#type:  String,
    #[validate(length(min = 1, max = 2000, message = "反馈内容 1-2000 字"))]
    pub content: String,
    pub images:  Option<Vec<String>>,
    pub contact: Option<String>,
}

fn default_feedback_type() -> String { "suggestion".to_string() }

// ── Responses ─────────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct UserResponse {
    pub id:          Uuid,
    pub username:    String,
    pub email:       Option<String>,
    pub phone:       Option<String>,
    pub avatar_url:  Option<String>,
    pub bio:         Option<String>,
    pub gender:      i16,
    pub birthday:    Option<NaiveDate>,
    pub is_verified: bool,
    pub is_new_user: bool,
    pub created_at:  DateTime<Utc>,
    pub city:        Option<String>,
    pub tags:        Vec<String>,
}

impl From<User> for UserResponse {
    fn from(u: User) -> Self {
        Self {
            id:          u.id,
            username:    u.username,
            email:       u.email,
            phone:       u.phone,
            avatar_url:  u.avatar_url,
            bio:         u.bio,
            gender:      u.gender,
            birthday:    u.birthday,
            is_verified: u.is_verified,
            is_new_user: u.is_new_user,
            created_at:  u.created_at,
            city:        None,
            tags:        vec![],
        }
    }
}

#[derive(Serialize)]
pub struct AuthResponse {
    pub access_token:  String,
    pub refresh_token: String,
    pub token_type:    String,
    pub expires_in:    i64,
    pub is_new_user:   bool,
    pub user:          UserResponse,
}

#[derive(Serialize)]
pub struct AccessTokenResponse {
    pub access_token: String,
    pub token_type:   String,
    pub expires_in:   i64,
}

#[derive(Serialize)]
pub struct UserStatsResponse {
    pub growth_value:  i32,
    pub points:        i32,
    pub collect_count: i32,
    pub level:         i16,
    pub credit_score:  i32,
    pub credit_label:  String,
}

impl From<UserStats> for UserStatsResponse {
    fn from(s: UserStats) -> Self {
        let credit_label = match s.credit_score {
            900..=i32::MAX => "极佳",
            800..=899      => "优秀",
            700..=799      => "良好",
            _              => "普通",
        }
        .to_string();
        Self {
            growth_value:  s.growth_value,
            points:        s.points,
            collect_count: s.collect_count,
            level:         s.level,
            credit_score:  s.credit_score,
            credit_label,
        }
    }
}

#[derive(Serialize)]
pub struct CareerProfileResponse {
    pub user_id:     Uuid,
    pub job_title:   Option<String>,
    pub company:     Option<String>,
    pub skills:      Vec<String>,
    pub experience:  Option<String>,
    pub looking_for: Option<String>,
    pub is_public:   bool,
}

impl From<CareerProfile> for CareerProfileResponse {
    fn from(c: CareerProfile) -> Self {
        let skills: Vec<String> = serde_json::from_value(c.skills).unwrap_or_default();
        Self {
            user_id:     c.user_id,
            job_title:   c.job_title,
            company:     c.company,
            skills,
            experience:  c.experience,
            looking_for: c.looking_for,
            is_public:   c.is_public,
        }
    }
}

#[derive(Serialize)]
pub struct NotificationResponse {
    pub id:          Uuid,
    pub r#type:      String,
    pub title:       String,
    pub content:     Option<String>,
    pub target_type: Option<String>,
    pub target_id:   Option<Uuid>,
    pub is_read:     bool,
    pub created_at:  DateTime<Utc>,
}
