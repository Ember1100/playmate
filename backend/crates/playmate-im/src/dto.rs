//! IM 模块 Request / Response DTO

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{model::Message, repository::{ConversationFull, GroupMessageFull, GroupSessionFull}};

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
    pub id:               Uuid,
    pub created_at:       DateTime<Utc>,
    pub other_user_id:    Uuid,
    pub other_username:   Option<String>,
    pub other_avatar_url: Option<String>,
    pub last_message:     Option<String>,
    pub last_message_at:  Option<DateTime<Utc>>,
    pub unread_count:     i64,
}

impl From<ConversationFull> for ConversationResponse {
    fn from(c: ConversationFull) -> Self {
        Self {
            id:               c.id,
            created_at:       c.created_at,
            other_user_id:    c.other_user_id,
            other_username:   c.other_username,
            other_avatar_url: c.other_avatar_url,
            last_message:     c.last_message,
            last_message_at:  c.last_message_at,
            unread_count:     c.unread_count,
        }
    }
}

#[derive(Serialize)]
pub struct MessageResponse {
    pub id:              Uuid,
    pub conversation_id: Uuid,
    pub sender_id:       Uuid,
    pub msg_type:        i16,
    pub content:         Option<String>,
    pub media_url:       Option<String>,
    pub is_recalled:     bool,
    pub created_at:      DateTime<Utc>,
}

impl From<Message> for MessageResponse {
    fn from(m: Message) -> Self {
        Self {
            id:              m.id,
            conversation_id: m.conversation_id,
            sender_id:       m.sender_id,
            msg_type:        m.msg_type,
            content:         m.content,
            media_url:       m.media_url,
            is_recalled:     m.is_recalled,
            created_at:      m.created_at,
        }
    }
}

// ── 群聊 Responses ─────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct GroupSessionResponse {
    pub id:              Uuid,
    pub name:            String,
    pub avatar_url:      Option<String>,
    pub member_count:    i32,
    pub last_message:    Option<String>,
    pub last_message_at: Option<DateTime<Utc>>,
    pub unread_count:    i64,
}

impl From<GroupSessionFull> for GroupSessionResponse {
    fn from(g: GroupSessionFull) -> Self {
        Self {
            id:              g.id,
            name:            g.name,
            avatar_url:      g.avatar_url,
            member_count:    g.member_count,
            last_message:    g.last_message,
            last_message_at: g.last_message_at,
            unread_count:    g.unread_count,
        }
    }
}

#[derive(Serialize)]
pub struct GroupMessageResponse {
    pub id:               Uuid,
    pub group_id:         Uuid,
    pub sender_id:        Option<Uuid>,
    pub sender_username:  Option<String>,
    pub sender_avatar_url: Option<String>,
    pub msg_type:         i16,
    pub content:          Option<String>,
    pub media_url:        Option<String>,
    pub is_recalled:      bool,
    pub created_at:       DateTime<Utc>,
}

impl From<GroupMessageFull> for GroupMessageResponse {
    fn from(m: GroupMessageFull) -> Self {
        Self {
            id:               m.id,
            group_id:         m.group_id,
            sender_id:        m.sender_id,
            sender_username:  m.sender_username,
            sender_avatar_url: m.sender_avatar_url,
            msg_type:         m.msg_type,
            content:          m.content,
            media_url:        m.media_url,
            is_recalled:      m.is_recalled,
            created_at:       m.created_at,
        }
    }
}
