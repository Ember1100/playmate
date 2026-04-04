//! 用户相关数据库模型

use chrono::{DateTime, NaiveDate, Utc};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub password_hash: Option<String>,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub gender: i16,
    pub birthday: Option<NaiveDate>,
    pub is_active: bool,
    pub last_seen_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct UserOauth {
    pub id: Uuid,
    pub user_id: Uuid,
    pub provider: String,
    pub provider_id: String,
    pub access_token: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, FromRow, serde::Serialize)]
pub struct Tag {
    pub id: i32,
    pub name: String,
    pub category: String,
}
