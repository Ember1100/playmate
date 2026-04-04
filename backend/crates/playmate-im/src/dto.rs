//! IM 模块 Request / Response DTO

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::model::{Conversation, Message};

// ── Requests ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct CreateConversationRequest {
    /// 私聊对象的 user_id
    pub target_user_id: Uuid,
}

#[derive(Deserialize)]
pub struct GetMessagesQuery {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

fn default_page() -> i64 { 1 }
fn default_limit() -> i64 { 20 }

// ── Responses ───────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct ConversationResponse {
    pub id: Uuid,
    pub conv_type: i16,
    pub created_at: DateTime<Utc>,
}

impl From<Conversation> for ConversationResponse {
    fn from(c: Conversation) -> Self {
        Self {
            id: c.id,
            conv_type: c.conv_type,
            created_at: c.created_at,
        }
    }
}

#[derive(Serialize)]
pub struct MessageResponse {
    pub id: Uuid,
    pub conversation_id: Uuid,
    pub sender_id: Uuid,
    pub msg_type: i16,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub is_recalled: bool,
    pub created_at: DateTime<Utc>,
}

impl From<Message> for MessageResponse {
    fn from(m: Message) -> Self {
        Self {
            id: m.id,
            conversation_id: m.conversation_id,
            sender_id: m.sender_id,
            msg_type: m.msg_type,
            content: m.content,
            media_url: m.media_url,
            is_recalled: m.is_recalled,
            created_at: m.created_at,
        }
    }
}
