//! 用户相关数据库模型

use chrono::{DateTime, NaiveDate, Utc};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct User {
    pub id:            Uuid,
    pub username:      String,
    pub phone:         Option<String>,
    pub password_hash: Option<String>,
    pub avatar_url:    Option<String>,
    pub bio:           Option<String>,
    pub gender:        i16,
    pub birthday:      Option<NaiveDate>,
    pub is_verified:   bool,
    pub is_new_user:   bool,
    pub is_active:     bool,
    pub last_seen_at:  Option<DateTime<Utc>>,
    pub created_at:    DateTime<Utc>,
    pub updated_at:    DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct UserOauth {
    pub id:          Uuid,
    pub user_id:     Uuid,
    pub provider:    String,
    pub provider_id: String,
    pub created_at:  DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct UserStats {
    pub user_id:       Uuid,
    pub growth_value:  i32,
    pub points:        i32,
    pub collect_count: i32,
    pub level:         i16,
    pub credit_score:  i32,
    pub updated_at:    DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct CareerProfile {
    pub user_id:     Uuid,
    pub job_title:   Option<String>,
    pub company:     Option<String>,
    pub skills:      serde_json::Value,
    pub experience:  Option<String>,
    pub looking_for: Option<String>,
    pub is_public:   bool,
    pub updated_at:  DateTime<Utc>,
}

#[derive(Debug, FromRow, serde::Serialize)]
pub struct Tag {
    pub id:       i32,
    pub name:     String,
    pub category: String,
}
