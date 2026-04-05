//! IM HTTP Handler + WebSocket Handler
//!
//! # 功能
//! - GET  /api/v1/im/conversations
//! - POST /api/v1/im/conversations
//! - GET  /api/v1/im/conversations/:id/messages
//! - WS   /api/v1/im/ws

use axum::{
    extract::{Path, Query, State, WebSocketUpgrade},
    response::IntoResponse,
    Json,
};
use axum::extract::ws::{Message, WebSocket};
use futures_util::{SinkExt, StreamExt};
use tokio::sync::mpsc;
use uuid::Uuid;

use playmate_common::{
    error::AppError,
    response::{ApiResponse, PageResponse},
    AppState, CurrentUser,
};

use crate::{
    dto::{ConversationResponse, CreateConversationRequest, GetMessagesQuery, MessageResponse},
    protocol::{ClientMessage, ServerMessage},
    repository,
};


// ── REST Handlers ────────────────────────────────────────────────────────────

/// 获取当前用户的会话列表
pub async fn list_conversations(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let convs = repository::list_conversations_full(&state.db, current_user.id).await?;
    let items: Vec<ConversationResponse> = convs.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(items))
}

/// 创建或复用私聊会话
///
/// # 错误
/// - `400 BadRequest` - 不能和自己开聊天
pub async fn create_conversation(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CreateConversationRequest>,
) -> Result<impl IntoResponse, AppError> {
    if payload.target_user_id == current_user.id {
        return Err(AppError::BadRequest("不能和自己创建会话".to_string()));
    }

    // 如果已有私聊会话则复用，否则新建
    let conv_id = if let Some(id) =
        repository::find_private_conversation(&state.db, current_user.id, payload.target_user_id)
            .await?
    {
        id
    } else {
        let conv = repository::create_private_conversation(
            &state.db,
            current_user.id,
            payload.target_user_id,
        )
        .await?;
        conv.id
    };

    Ok(ApiResponse::ok(serde_json::json!({ "id": conv_id })))
}

/// 获取会话消息（分页，最新在前）
///
/// # 错误
/// - `403 Forbidden` - 非会话成员
pub async fn list_messages(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(conversation_id): Path<Uuid>,
    Query(q): Query<GetMessagesQuery>,
) -> Result<impl IntoResponse, AppError> {
    if !repository::is_member(&state.db, conversation_id, current_user.id).await? {
        return Err(AppError::Forbidden("非会话成员".to_string()));
    }

    let limit = q.limit.clamp(1, 100);
    let offset = (q.page - 1) * limit;
    let messages = repository::list_messages(&state.db, conversation_id, limit, offset).await?;
    let total = messages.len() as i64; // MVP 简化：不查 COUNT

    let items: Vec<MessageResponse> = messages.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total,
        page: q.page,
        limit,
        items,
    }))
}

// ── WebSocket Handler ────────────────────────────────────────────────────────

/// WebSocket 升级入口（需携带有效 JWT）
pub async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state, current_user))
}

async fn handle_socket(socket: WebSocket, state: AppState, user: CurrentUser) {
    let (mut ws_sender, mut ws_receiver) = socket.split();
    // 有界 channel：防止客户端拉取过慢时内存无限增长
    let (tx, mut rx) = mpsc::channel::<String>(512);

    // 注册到 Hub
    state.hub.register(user.id, tx);

    // 更新在线状态
    let _ = playmate_common::cache::set_online(&state, user.id).await;

    // 发送任务：从 channel 取消息并写入 WebSocket
    let send_task = tokio::spawn(async move {
        while let Some(text) = rx.recv().await {
            if ws_sender.send(Message::Text(text)).await.is_err() {
                break;
            }
        }
    });

    // 接收任务：从 WebSocket 读取并处理客户端消息
    while let Some(Ok(msg)) = ws_receiver.next().await {
        match msg {
            Message::Text(text) => {
                match serde_json::from_str::<ClientMessage>(&text) {
                    Ok(client_msg) => {
                        handle_client_message(&state, &user, client_msg).await;
                    }
                    Err(_) => {
                        // 协议错误，发送 Error 消息
                        let err = serde_json::to_string(&ServerMessage::Error {
                            code: "PARSE_ERROR".to_string(),
                            message: "消息格式错误".to_string(),
                        })
                        .unwrap_or_default();
                        state.hub.send_to(&user.id, err);
                    }
                }
            }
            Message::Close(_) => break,
            _ => {}
        }
    }

    // 清理
    state.hub.unregister(&user.id);
    let _ = playmate_common::cache::set_offline(&state, user.id).await;
    send_task.abort();
}

async fn handle_client_message(state: &AppState, user: &CurrentUser, msg: ClientMessage) {
    match msg {
        ClientMessage::SendMessage {
            conversation_id,
            msg_type,
            content,
            media_url,
        } => {
            // 验证成员身份
            let ok = repository::is_member(&state.db, conversation_id, user.id)
                .await
                .unwrap_or(false);
            if !ok {
                let err = serde_json::to_string(&ServerMessage::Error {
                    code: "FORBIDDEN".to_string(),
                    message: "非会话成员".to_string(),
                })
                .unwrap_or_default();
                state.hub.send_to(&user.id, err);
                return;
            }

            // 存库
            let message = match repository::insert_message(
                &state.db,
                conversation_id,
                user.id,
                msg_type,
                content,
                media_url,
            )
            .await
            {
                Ok(m) => m,
                Err(e) => {
                    tracing::error!("消息存库失败: {:?}", e);
                    let err = serde_json::to_string(&ServerMessage::MessageAck {
                        message_id: Uuid::nil(),
                        status: "failed".to_string(),
                    })
                    .unwrap_or_default();
                    state.hub.send_to(&user.id, err);
                    return;
                }
            };

            // 给发送方发 Ack
            let ack = serde_json::to_string(&ServerMessage::MessageAck {
                message_id: message.id,
                status: "delivered".to_string(),
            })
            .unwrap_or_default();
            state.hub.send_to(&user.id, ack);

            // 给其他成员推送 NewMessage
            let push = serde_json::to_string(&ServerMessage::NewMessage {
                message_id: message.id,
                conversation_id,
                sender_id: user.id,
                msg_type: message.msg_type,
                content: message.content,
                media_url: message.media_url,
                created_at: message.created_at,
            })
            .unwrap_or_default();

            let members = repository::get_member_ids(&state.db, conversation_id)
                .await
                .unwrap_or_default();
            for member_id in members {
                if member_id != user.id {
                    state.hub.send_to(&member_id, push.clone());
                }
            }
        }

        ClientMessage::MarkRead {
            conversation_id,
            last_read_at,
        } => {
            let _ =
                repository::update_last_read(&state.db, conversation_id, user.id, last_read_at)
                    .await;
        }

        ClientMessage::Ping => {
            let pong = serde_json::to_string(&ServerMessage::Pong).unwrap_or_default();
            state.hub.send_to(&user.id, pong);
        }
    }
}
