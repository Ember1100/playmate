//! Match 数据库模型

use chrono::{DateTime, NaiveDate, Utc};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct MatchRecord {
    pub id: Uuid,
    pub user_a_id: Uuid,
    pub user_b_id: Uuid,
    pub score: i16,
    pub status: i16,                    // 0待响应 1双方接受 2已拒绝
    pub matched_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

/// 用于匹配计算的用户画像（含标签列表）
#[derive(Debug, FromRow)]
pub struct UserProfile {
    pub id: Uuid,
    pub username: String,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub gender: i16,
    pub birthday: Option<NaiveDate>,
    pub tag_ids: Vec<i32>,              // postgres int[] → Vec<i32>
}
