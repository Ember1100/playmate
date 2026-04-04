//! Match 模块 Request / Response DTO

use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Requests ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct RespondMatchRequest {
    pub target_user_id: Uuid,
    pub accept: bool,
}

// ── Responses ───────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct CandidateResponse {
    pub user_id: Uuid,
    pub username: String,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub gender: i16,
    pub birthday: Option<NaiveDate>,
    pub score: u8,
    pub common_tags: Vec<i32>,
}

#[derive(Serialize)]
pub struct RespondMatchResponse {
    /// "pending"（等待对方响应）| "matched"（双方匹配成功）| "rejected"
    pub status: String,
    /// 匹配成功时自动创建的会话 ID
    pub conversation_id: Option<Uuid>,
    pub matched_at: Option<DateTime<Utc>>,
}
