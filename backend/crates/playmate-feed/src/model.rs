//! Feed 数据库模型

use chrono::{DateTime, Utc};
use serde_json::Value;
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct Post {
    pub id: Uuid,
    pub user_id: Uuid,
    pub content: String,
    pub media_urls: Value,       // JSONB → serde_json::Value
    pub like_count: i32,
    pub comment_count: i32,
    pub visibility: i16,
    pub created_at: DateTime<Utc>,
}
