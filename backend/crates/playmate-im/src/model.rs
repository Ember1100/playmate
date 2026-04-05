//! IM 数据库模型

use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct Conversation {
    pub id:         Uuid,
    pub user_a_id:  Uuid,
    pub user_b_id:  Uuid,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct Message {
    pub id:              Uuid,
    pub conversation_id: Uuid,
    pub sender_id:       Uuid,
    #[sqlx(rename = "type")]
    pub msg_type:        i16,
    pub content:         Option<String>,
    pub media_url:       Option<String>,
    pub is_recalled:     bool,
    pub created_at:      DateTime<Utc>,
}
