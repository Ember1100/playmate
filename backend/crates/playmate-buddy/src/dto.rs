//! 搭子模块 Request / Response DTO

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::model::{BuddyCandidate, BuddyGatherWithStats, BuddyInvitation, BuddyRequest};

// ── Requests ─────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct CandidatesQuery {
    pub req_type: Option<i16>, // 1=线上 2=线下 3=职业
    #[serde(default = "default_page")]
    pub page:     i64,
    #[serde(default = "default_limit")]
    pub limit:    i64,
}

#[derive(Deserialize, Validate)]
pub struct SendBuddyRequestRequest {
    pub to_user_id: Uuid,
    pub req_type:   i16,
    #[validate(length(max = 500))]
    pub message:    Option<String>,
}

#[derive(Deserialize)]
pub struct RespondBuddyRequestRequest {
    pub accept: bool,
}

#[derive(Deserialize)]
pub struct MyBuddiesQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

#[derive(Deserialize, Validate)]
pub struct SendInvitationRequest {
    pub to_user_id:    Uuid,
    #[validate(length(min = 1, max = 100))]
    pub title:         String,
    pub content:       Option<String>,
    pub activity_type: Option<String>,
    pub scheduled_at:  Option<DateTime<Utc>>,
    #[validate(length(max = 200))]
    pub location:      Option<String>,
}

#[derive(Deserialize)]
pub struct RespondInvitationRequest {
    pub accept: bool,
}

#[derive(Deserialize)]
pub struct InvitationsQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

// ── 搭子局 Request ────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreateGatherRequest {
    #[validate(length(min = 1, max = 100))]
    pub title:       String,
    #[validate(length(max = 200))]
    pub location:    Option<String>,
    pub start_time:  DateTime<Utc>,
    pub end_time:    DateTime<Utc>,
    pub category:    String, // 生活/学习/兴趣/游戏/自定义
    pub theme:       String, // 吃货/看看/运动/游戏/其他
    #[validate(range(min = 2, max = 50))]
    pub capacity:    i32,
    #[validate(length(max = 1000))]
    pub description: Option<String>,
    #[serde(default)]
    pub vibes:       Vec<String>,
}

#[derive(Deserialize)]
pub struct GatherListQuery {
    pub category: Option<String>,
    #[serde(default = "default_page")]
    pub page:     i64,
    #[serde(default = "default_limit")]
    pub limit:    i64,
}

fn default_page() -> i64 { 1 }
fn default_limit() -> i64 { 20 }

// ── Responses ─────────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct CandidateResponse {
    pub id:         Uuid,
    pub username:   String,
    pub avatar_url: Option<String>,
    pub bio:        Option<String>,
    pub gender:     i16,
}

impl From<BuddyCandidate> for CandidateResponse {
    fn from(c: BuddyCandidate) -> Self {
        Self {
            id:         c.id,
            username:   c.username,
            avatar_url: c.avatar_url,
            bio:        c.bio,
            gender:     c.gender,
        }
    }
}

#[derive(Serialize)]
pub struct BuddyRequestResponse {
    pub id:           Uuid,
    pub from_user_id: Uuid,
    pub to_user_id:   Uuid,
    pub req_type:     i16,
    pub message:      Option<String>,
    pub status:       i16,
    pub created_at:   DateTime<Utc>,
}

impl From<BuddyRequest> for BuddyRequestResponse {
    fn from(r: BuddyRequest) -> Self {
        Self {
            id:           r.id,
            from_user_id: r.from_user_id,
            to_user_id:   r.to_user_id,
            req_type:     r.req_type,
            message:      r.message,
            status:       r.status,
            created_at:   r.created_at,
        }
    }
}

#[derive(Serialize)]
pub struct InvitationResponse {
    pub id:            Uuid,
    pub from_user_id:  Uuid,
    pub to_user_id:    Uuid,
    pub title:         String,
    pub content:       Option<String>,
    pub activity_type: Option<String>,
    pub scheduled_at:  Option<DateTime<Utc>>,
    pub location:      Option<String>,
    pub status:        i16,
    pub created_at:    DateTime<Utc>,
}

// ── 搭子局 Response ───────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct GatherResponse {
    pub id:               String,
    pub creator_id:       String,
    pub creator_username: String,
    pub creator_avatar:   Option<String>,
    pub title:            String,
    pub location:         Option<String>,
    pub start_time:       DateTime<Utc>,
    pub end_time:         DateTime<Utc>,
    pub category:         String,
    pub theme:            String,
    pub capacity:         i32,
    pub description:      Option<String>,
    pub vibes:            Vec<String>,
    pub status:           i16,
    pub joined_count:     i64,
    pub is_joined:        bool,
    pub member_avatars:   Vec<String>,
    pub created_at:       DateTime<Utc>,
}

impl From<BuddyGatherWithStats> for GatherResponse {
    fn from(g: BuddyGatherWithStats) -> Self {
        Self {
            id:               g.id.to_string(),
            creator_id:       g.creator_id.to_string(),
            creator_username: g.creator_username,
            creator_avatar:   g.creator_avatar,
            title:            g.title,
            location:         g.location,
            start_time:       g.start_time,
            end_time:         g.end_time,
            category:         g.category,
            theme:            g.theme,
            capacity:         g.capacity,
            description:      g.description,
            vibes:            g.vibes,
            status:           g.status,
            joined_count:     g.joined_count,
            is_joined:        g.is_joined,
            member_avatars:   g.member_avatars,
            created_at:       g.created_at,
        }
    }
}

impl From<BuddyInvitation> for InvitationResponse {
    fn from(i: BuddyInvitation) -> Self {
        Self {
            id:            i.id,
            from_user_id:  i.from_user_id,
            to_user_id:    i.to_user_id,
            title:         i.title,
            content:       i.content,
            activity_type: i.activity_type,
            scheduled_at:  i.scheduled_at,
            location:      i.location,
            status:        i.status,
            created_at:    i.created_at,
        }
    }
}
