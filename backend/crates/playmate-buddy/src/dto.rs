//! 搭子模块 Request / Response DTO

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::model::{BuddyCandidateWithProfile, BuddyGatherWithStats, BuddyInvitation, BuddyRequest};

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
    pub title:              String,
    #[validate(length(max = 200))]
    pub location:           Option<String>,
    #[validate(length(max = 200))]
    pub landmark:           Option<String>,
    pub start_time:         DateTime<Utc>,
    pub end_time:           DateTime<Utc>,
    pub first_menu_id:      Option<i64>,
    pub second_menu_id:     Option<i64>,
    #[validate(range(min = 2, max = 50))]
    pub capacity:           i32,
    #[validate(length(max = 1000))]
    pub description:        Option<String>,
    #[serde(default)]
    pub vibes:              Vec<String>,
    /// "offline"（线下）| "online"（线上）| "invite"（约人），默认线下
    #[serde(default = "default_activity_mode")]
    pub activity_mode:      String,
    #[validate(length(max = 2000))]
    pub schedule:           Option<String>,
    pub deadline:           Option<DateTime<Utc>>,
    #[serde(default)]
    pub fee_type:           i16,           // 0=免费 1=按需付费 2=AA制
    pub fee_amount:         Option<f64>,
    #[serde(default = "default_age_min")]
    pub age_min:            i16,
    #[serde(default = "default_age_max")]
    pub age_max:            i16,
    #[serde(default)]
    pub gender_pref:        i16,           // 0=不限 1=仅男 2=仅女
    pub cover_url:          Option<String>,
    #[serde(default)]
    pub require_real_name:  bool,
    #[serde(default)]
    pub require_review:     bool,
    #[serde(default)]
    pub allow_transfer:     bool,
}

#[derive(Deserialize)]
pub struct GatherListQuery {
    pub first_menu_id: Option<i64>,
    #[serde(default = "default_page")]
    pub page:          i64,
    #[serde(default = "default_limit")]
    pub limit:         i64,
}

// ── 菜单 Request ──────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct MenuQuery {
    #[serde(rename = "type", default = "default_menu_type")]
    pub menu_type: i16,
}

fn default_menu_type() -> i16 { 1 }
fn default_activity_mode() -> String { "offline".to_string() }
fn default_age_min() -> i16 { 18 }
fn default_age_max() -> i16 { 35 }

fn default_page() -> i64 { 1 }
fn default_limit() -> i64 { 20 }

// ── 搜索 Request / Response ───────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct SearchQuery {
    pub q:     String,
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

#[derive(Serialize)]
pub struct SearchUserResponse {
    pub id:         String,
    pub username:   String,
    pub avatar_url: Option<String>,
    pub bio:        Option<String>,
    pub tags:       Vec<String>,
    pub city:       Option<String>,
}

#[derive(Serialize)]
pub struct BuddySearchResponse {
    pub users:        Vec<SearchUserResponse>,
    pub user_total:   i64,
    pub gathers:      Vec<GatherResponse>,
    pub gather_total: i64,
}

// ── 菜单 Response ─────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct SubMenuItemResponse {
    pub id:   i64,
    pub name: String,
    pub sort: i32,
}

#[derive(Serialize)]
pub struct MenuItemResponse {
    pub id:       i64,
    pub name:     String,
    pub sort:     i32,
    pub children: Vec<SubMenuItemResponse>,
}

// ── Responses ─────────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct CandidateResponse {
    pub id:         Uuid,
    pub username:   String,
    pub avatar_url: Option<String>,
    pub bio:        Option<String>,
    pub gender:     i16,
    pub tags:       Vec<String>,
    pub city:       Option<String>,
}

impl From<BuddyCandidateWithProfile> for CandidateResponse {
    fn from(c: BuddyCandidateWithProfile) -> Self {
        Self {
            id:         c.id,
            username:   c.username,
            avatar_url: c.avatar_url,
            bio:        c.bio,
            gender:     c.gender,
            tags:       c.tags,
            city:       c.city,
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
    pub landmark:         Option<String>,
    pub start_time:       DateTime<Utc>,
    pub end_time:         DateTime<Utc>,
    pub first_menu_id:    Option<i64>,
    pub first_menu_name:  Option<String>,
    pub second_menu_id:   Option<i64>,
    pub second_menu_name: Option<String>,
    pub capacity:         i32,
    pub description:      Option<String>,
    pub vibes:            Vec<String>,
    pub activity_mode:    String,
    pub status:           i16,
    pub group_id:         Option<String>,
    pub schedule:         Option<String>,
    pub deadline:         Option<DateTime<Utc>>,
    pub fee_type:         i16,
    pub fee_amount:       Option<f64>,
    pub age_min:          i16,
    pub age_max:          i16,
    pub gender_pref:      i16,
    pub cover_url:        Option<String>,
    pub require_real_name: bool,
    pub require_review:   bool,
    pub allow_transfer:   bool,
    pub joined_count:     i64,
    pub is_joined:        bool,
    pub member_avatars:   Vec<String>,
    pub member_usernames: Vec<String>,
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
            landmark:         g.landmark,
            start_time:       g.start_time,
            end_time:         g.end_time,
            first_menu_id:    g.first_menu_id,
            first_menu_name:  g.first_menu_name,
            second_menu_id:   g.second_menu_id,
            second_menu_name: g.second_menu_name,
            capacity:         g.capacity,
            description:      g.description,
            vibes:            g.vibes,
            activity_mode:    g.activity_mode,
            status:           g.status,
            group_id:         g.group_id.map(|id| id.to_string()),
            schedule:         g.schedule,
            deadline:         g.deadline,
            fee_type:         g.fee_type,
            fee_amount:       g.fee_amount,
            age_min:          g.age_min,
            age_max:          g.age_max,
            gender_pref:      g.gender_pref,
            cover_url:        g.cover_url,
            require_real_name: g.require_real_name,
            require_review:   g.require_review,
            allow_transfer:   g.allow_transfer,
            joined_count:     g.joined_count,
            is_joined:        g.is_joined,
            member_avatars:   g.member_avatars,
            member_usernames: g.member_usernames,
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
