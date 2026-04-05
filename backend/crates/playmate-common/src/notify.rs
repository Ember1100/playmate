//! 通知推送工具
//!
//! 统一封装「写 notifications 表 + WebSocket 实时推送」。
//! 各模块（buddy/circle/market/im）需要发送通知时调用此函数，
//! 避免在多处散落重复的 SQL + hub 调用。
//!
//! # 使用示例
//! ```rust
//! use playmate_common::notify::push_notification;
//!
//! push_notification(
//!     &state,
//!     to_user_id,
//!     "buddy_request",
//!     "有人想和你成为搭子",
//!     Some("点击查看"),
//!     Some("buddy_request"),
//!     Some(request_id),
//! ).await?;
//! ```

use uuid::Uuid;

use crate::{error::AppResult, error::AppError, state::AppState};

/// 持久化通知并通过 WebSocket 实时推送（若用户在线）
///
/// # 参数
/// - `ntype`       通知类型：`buddy_request` / `invitation` / `interaction` / `system`
/// - `title`       通知标题（消息中心展示）
/// - `content`     通知正文（可选）
/// - `target_type` 关联对象类型（可选），如 `"buddy_request"` / `"topic"`
/// - `target_id`   关联对象 ID（可选）
///
/// # 返回
/// 新建通知的 `id`
pub async fn push_notification(
    state:       &AppState,
    user_id:     Uuid,
    ntype:       &str,
    title:       &str,
    content:     Option<&str>,
    target_type: Option<&str>,
    target_id:   Option<Uuid>,
) -> AppResult<Uuid> {
    // 1. 持久化到 notifications 表
    let row: (Uuid,) = sqlx::query_as(
        "INSERT INTO notifications (user_id, type, title, content, target_type, target_id)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id",
    )
    .bind(user_id)
    .bind(ntype)
    .bind(title)
    .bind(content)
    .bind(target_type)
    .bind(target_id)
    .fetch_one(&state.db)
    .await
    .map_err(AppError::Database)?;

    let notification_id = row.0;

    // 2. 若用户在线则实时推送 WebSocket（离线不报错，下次拉列表可见）
    // 消息格式与 playmate-im ServerMessage::NewNotification 保持一致：
    // { "type": "new_notification", "notification_id": "...", "ntype": "...", "title": "...", "content": ... }
    let payload = serde_json::json!({
        "type":            "new_notification",
        "notification_id": notification_id,
        "ntype":           ntype,
        "title":           title,
        "content":         content,
    })
    .to_string();

    state.hub.send_to(&user_id, payload); // 用户离线时静默忽略

    Ok(notification_id)
}
