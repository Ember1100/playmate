//! WebSocket 消息协议定义

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 客户端发送给服务端的消息
#[derive(Deserialize, Debug)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ClientMessage {
    /// 发送私聊消息
    SendMessage {
        conversation_id: Uuid,
        msg_type: i16,              // 1文字 2图片 3语音
        content: Option<String>,
        media_url: Option<String>,
    },
    /// 发送群聊消息
    SendGroupMessage {
        group_id: Uuid,
        msg_type: i16,              // 1文字 2图片 3语音
        content: Option<String>,
        media_url: Option<String>,
    },
    /// 标记私聊已读
    MarkRead {
        conversation_id: Uuid,
        last_read_at: DateTime<Utc>,
    },
    /// 标记群聊已读
    MarkGroupRead {
        group_id: Uuid,
        last_read_at: DateTime<Utc>,
    },
    /// 心跳
    Ping,
}

/// 服务端推送给客户端的消息
#[derive(Serialize, Debug, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ServerMessage {
    /// 新私聊消息推送（给非发送方）
    NewMessage {
        message_id: Uuid,
        conversation_id: Uuid,
        sender_id: Uuid,
        msg_type: i16,
        content: Option<String>,
        media_url: Option<String>,
        created_at: DateTime<Utc>,
    },
    /// 新群聊消息推送（给所有群成员）
    NewGroupMessage {
        message_id: Uuid,
        group_id: Uuid,
        sender_id: Option<Uuid>,
        sender_username: Option<String>,
        sender_avatar_url: Option<String>,
        msg_type: i16,
        content: Option<String>,
        media_url: Option<String>,
        created_at: DateTime<Utc>,
    },
    /// 消息发送确认（给发送方）
    MessageAck {
        message_id: Uuid,
        status: String,             // "delivered" | "failed"
    },
    /// 新通知推送（由 playmate-common::notify::push_notification 触发）
    NewNotification {
        notification_id: Uuid,
        ntype:   String,
        title:   String,
        content: Option<String>,
    },
    /// 心跳响应
    Pong,
    /// 错误通知
    Error {
        code: String,
        message: String,
    },
}
