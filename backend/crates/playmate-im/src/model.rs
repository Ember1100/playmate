//! IM 数据库模型

use chrono::{DateTime, Utc};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct Conversation {
    pub id: Uuid,
    #[sqlx(rename = "type")]
    pub conv_type: i16,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, FromRow)]
pub struct ConversationMember {
    pub conversation_id: Uuid,
    pub user_id: Uuid,
    pub joined_at: DateTime<Utc>,
    pub last_read_at: Option<DateTime<Utc>>,
}

#[derive(Debug, FromRow)]
pub struct Message {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: Uuid,
    #[sqlx(rename = "type")]
    pub msg_type: i16,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub is_recalled: bool,
    pub created_at: DateTime<Utc>,
}
