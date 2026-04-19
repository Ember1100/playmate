//! 搭子模块数据模型

use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct BuddyRequest {
    pub id:           Uuid,
    pub from_user_id: Uuid,
    pub to_user_id:   Uuid,
    #[sqlx(rename = "type")]
    pub req_type:     i16, // 1=线上 2=线下 3=职业
    pub message:      Option<String>,
    pub status:       i16, // 0=待响应 1=接受 2=拒绝
    pub created_at:   DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct BuddyInvitation {
    pub id:            Uuid,
    pub from_user_id:  Uuid,
    pub to_user_id:    Uuid,
    pub title:         String,
    pub content:       Option<String>,
    pub activity_type: Option<String>,
    pub scheduled_at:  Option<DateTime<Utc>>,
    pub location:      Option<String>,
    pub status:        i16, // 0=待响应 1=接受 2=拒绝
    pub created_at:    DateTime<Utc>,
}

/// 搭子候选人（简要用户信息）
#[derive(Debug, FromRow)]
pub struct BuddyCandidate {
    pub id:         Uuid,
    pub username:   String,
    pub avatar_url: Option<String>,
    pub bio:        Option<String>,
    pub gender:     i16,
}

// ── 搭子局 ────────────────────────────────────────────────────────────────────

#[derive(Debug, FromRow)]
pub struct BuddyGather {
    pub id:                 Uuid,
    pub creator_id:         Uuid,
    pub title:              String,
    pub location:           Option<String>,
    pub landmark:           Option<String>,
    pub start_time:         DateTime<Utc>,
    pub end_time:           DateTime<Utc>,
    pub first_menu_id:      Option<i64>,
    pub second_menu_id:     Option<i64>,
    pub capacity:           i32,
    pub description:        Option<String>,
    pub vibes:              Vec<String>,
    pub activity_mode:      String, // "offline" | "online" | "invite"
    pub status:             i16,
    pub group_id:           Option<Uuid>,
    pub created_at:         DateTime<Utc>,
    pub schedule:           Option<String>,
    pub deadline:           Option<DateTime<Utc>>,
    pub fee_type:           i16,           // 0=免费 1=按需付费 2=AA制
    pub fee_amount:         Option<f64>,
    pub age_min:            i16,
    pub age_max:            i16,
    pub gender_pref:        i16,           // 0=不限 1=仅男 2=仅女
    pub cover_url:          Option<String>,
    pub require_real_name:  bool,
    pub require_review:     bool,
    pub allow_transfer:     bool,
}

/// 搭子局列表项（附带统计信息）
#[derive(Debug, FromRow)]
pub struct BuddyGatherWithStats {
    pub id:                Uuid,
    pub creator_id:        Uuid,
    pub creator_username:  String,
    pub creator_avatar:    Option<String>,
    pub title:             String,
    pub location:          Option<String>,
    pub landmark:          Option<String>,
    pub start_time:        DateTime<Utc>,
    pub end_time:          DateTime<Utc>,
    pub first_menu_id:     Option<i64>,
    pub first_menu_name:   Option<String>,
    pub second_menu_id:    Option<i64>,
    pub second_menu_name:  Option<String>,
    pub capacity:          i32,
    pub description:       Option<String>,
    pub vibes:             Vec<String>,
    pub activity_mode:     String,
    pub status:            i16,
    pub group_id:          Option<Uuid>,
    pub created_at:        DateTime<Utc>,
    pub schedule:          Option<String>,
    pub deadline:          Option<DateTime<Utc>>,
    pub fee_type:          i16,
    pub fee_amount:        Option<f64>,
    pub age_min:           i16,
    pub age_max:           i16,
    pub gender_pref:       i16,
    pub cover_url:         Option<String>,
    pub require_real_name: bool,
    pub require_review:    bool,
    pub allow_transfer:    bool,
    pub joined_count:      i64,
    pub is_joined:         bool,
    pub member_avatars:    Vec<String>,
    pub member_usernames:  Vec<String>,
}
