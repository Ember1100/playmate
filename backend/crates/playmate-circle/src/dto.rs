//! 圈子模块 Request / Response DTO

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::model::{Poll, SocialGroup, SocialGroupMessage, Topic, TopicComment};

// ── Topic Requests ───────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreateTopicRequest {
    #[validate(length(min = 1, max = 200))]
    pub title:     String,
    pub content:   Option<String>,
    pub cover_url: Option<String>,
    pub category:  Option<String>,
}

#[derive(Deserialize)]
pub struct ListTopicsQuery {
    pub category: Option<String>,
    #[serde(default = "default_page")]
    pub page:     i64,
    #[serde(default = "default_limit")]
    pub limit:    i64,
}

#[derive(Deserialize, Validate)]
pub struct CreateCommentRequest {
    #[validate(length(min = 1, max = 1000))]
    pub content:   String,
    pub parent_id: Option<Uuid>,
}

#[derive(Deserialize)]
pub struct ListCommentsQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

// ── Poll Requests ────────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreatePollRequest {
    #[validate(length(min = 1, max = 200))]
    pub title:        String,
    #[validate(length(min = 1, max = 500))]
    pub pro_argument: String,
    #[validate(length(min = 1, max = 500))]
    pub con_argument: String,
}

#[derive(Deserialize)]
pub struct VotePollRequest {
    pub side: i16, // 1=正方 2=反方
}

#[derive(Deserialize)]
pub struct ListPollsQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

// ── Group Requests ───────────────────────────────────────────────────────────

#[derive(Deserialize, Validate)]
pub struct CreateGroupRequest {
    #[validate(length(min = 1, max = 50))]
    pub name:        String,
    pub description: Option<String>,
    pub avatar_url:  Option<String>,
    pub category:    Option<String>,
}

#[derive(Deserialize)]
pub struct ListGroupsQuery {
    pub category: Option<String>,
    #[serde(default = "default_page")]
    pub page:     i64,
    #[serde(default = "default_limit")]
    pub limit:    i64,
}

#[derive(Deserialize)]
pub struct ListGroupMessagesQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

fn default_page() -> i64 { 1 }
fn default_limit() -> i64 { 20 }

// ── Topic Responses ──────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct TopicResponse {
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

impl From<Topic> for TopicResponse {
    fn from(t: Topic) -> Self {
        Self {
            id:            t.id,
            creator_id:    t.creator_id,
            title:         t.title,
            content:       t.content,
            cover_url:     t.cover_url,
            category:      t.category,
            like_count:    t.like_count,
            comment_count: t.comment_count,
            view_count:    t.view_count,
            is_hot:        t.is_hot,
            created_at:    t.created_at,
        }
    }
}

#[derive(Serialize)]
pub struct CommentResponse {
    pub id:         Uuid,
    pub topic_id:   Uuid,
    pub user_id:    Uuid,
    pub parent_id:  Option<Uuid>,
    pub content:    String,
    pub like_count: i32,
    pub created_at: DateTime<Utc>,
}

impl From<TopicComment> for CommentResponse {
    fn from(c: TopicComment) -> Self {
        Self {
            id:         c.id,
            topic_id:   c.topic_id,
            user_id:    c.user_id,
            parent_id:  c.parent_id,
            content:    c.content,
            like_count: c.like_count,
            created_at: c.created_at,
        }
    }
}

// ── Poll Responses ───────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct PollResponse {
    pub id:           Uuid,
    pub creator_id:   Uuid,
    pub title:        String,
    pub pro_argument: String,
    pub con_argument: String,
    pub pro_count:    i32,
    pub con_count:    i32,
    pub created_at:   DateTime<Utc>,
}

impl From<Poll> for PollResponse {
    fn from(p: Poll) -> Self {
        Self {
            id:           p.id,
            creator_id:   p.creator_id,
            title:        p.title,
            pro_argument: p.pro_argument,
            con_argument: p.con_argument,
            pro_count:    p.pro_count,
            con_count:    p.con_count,
            created_at:   p.created_at,
        }
    }
}

// ── Group Responses ──────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct GroupResponse {
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

impl From<SocialGroup> for GroupResponse {
    fn from(g: SocialGroup) -> Self {
        Self {
            id:           g.id,
            creator_id:   g.creator_id,
            name:         g.name,
            description:  g.description,
            avatar_url:   g.avatar_url,
            category:     g.category,
            member_count: g.member_count,
            is_public:    g.is_public,
            created_at:   g.created_at,
        }
    }
}

#[derive(Serialize)]
pub struct GroupMessageResponse {
    pub id:         Uuid,
    pub group_id:   Uuid,
    pub sender_id:  Uuid,
    pub msg_type:   i16,
    pub content:    Option<String>,
    pub media_url:  Option<String>,
    pub created_at: DateTime<Utc>,
}

impl From<SocialGroupMessage> for GroupMessageResponse {
    fn from(m: SocialGroupMessage) -> Self {
        Self {
            id:         m.id,
            group_id:   m.group_id,
            sender_id:  m.sender_id,
            msg_type:   m.msg_type,
            content:    m.content,
            media_url:  m.media_url,
            created_at: m.created_at,
        }
    }
}
