//! Feed 模块 Request / Response DTO

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::model::Post;

// ── Requests ────────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreatePostRequest {
    #[validate(length(min = 1, max = 2000, message = "内容长度 1-2000 字"))]
    pub content: String,
    #[serde(default)]
    pub media_urls: Vec<String>,
    /// 1公开 2仅关注 3私密
    #[serde(default = "default_visibility")]
    pub visibility: i16,
}

fn default_visibility() -> i16 { 1 }

#[derive(Deserialize)]
pub struct FeedQuery {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

fn default_page() -> i64 { 1 }
fn default_limit() -> i64 { 20 }

// ── Responses ───────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct PostResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub content: String,
    pub media_urls: Vec<String>,
    pub like_count: i32,
    pub comment_count: i32,
    pub visibility: i16,
    pub created_at: DateTime<Utc>,
}

impl From<Post> for PostResponse {
    fn from(p: Post) -> Self {
        let media_urls: Vec<String> =
            serde_json::from_value(p.media_urls).unwrap_or_default();
        Self {
            id: p.id,
            user_id: p.user_id,
            content: p.content,
            media_urls,
            like_count: p.like_count,
            comment_count: p.comment_count,
            visibility: p.visibility,
            created_at: p.created_at,
        }
    }
}

#[derive(Serialize)]
pub struct LikeResponse {
    pub liked: bool,
    pub like_count: i32,
}
