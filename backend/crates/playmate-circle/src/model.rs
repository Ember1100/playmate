//! 圈子模块数据模型

use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct Topic {
    pub id:            Uuid,
    pub creator_id:    Uuid,
    pub title:         String,
    pub content:       Option<String>,
    pub cover_url:     Option<String>,
    pub category:      Option<String>,
    pub like_count:    i32,
    pub comment_count: i32,
    pub view_count:    i32,
    pub is_hot:        bool,
    pub created_at:    DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct TopicComment {
    pub id:         Uuid,
    pub topic_id:   Uuid,
    pub user_id:    Uuid,
    pub parent_id:  Option<Uuid>,
    pub content:    String,
    pub like_count: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct Poll {
    pub id:           Uuid,
    pub creator_id:   Uuid,
    pub title:        String,
    pub pro_argument: String,
    pub con_argument: String,
    pub pro_count:    i32,
    pub con_count:    i32,
    pub created_at:   DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct SocialGroup {
    pub id:           Uuid,
    pub creator_id:   Uuid,
    pub name:         String,
    pub description:  Option<String>,
    pub avatar_url:   Option<String>,
    pub category:     Option<String>,
    pub member_count: i32,
    pub is_public:    bool,
    pub created_at:   DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct SocialGroupMessage {
    pub id:          Uuid,
    pub group_id:    Uuid,
    pub sender_id:   Uuid,
    #[sqlx(rename = "type")]
    pub msg_type:    i16,
    pub content:     Option<String>,
    pub media_url:   Option<String>,
    pub is_recalled: bool,
    pub created_at:  DateTime<Utc>,
}
