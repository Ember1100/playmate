//! Redis 缓存操作封装
//!
//! # 功能
//! - 用户在线状态（set/get）
//! - 未读消息计数

use redis::AsyncCommands;
use uuid::Uuid;

use crate::{error::AppResult, state::AppState};

pub async fn set_online(state: &AppState, user_id: Uuid) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.set_ex::<_, _, ()>(format!("online:user:{}", user_id), "1", 60)
        .await?;
    Ok(())
}

pub async fn set_offline(state: &AppState, user_id: Uuid) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.del::<_, ()>(format!("online:user:{}", user_id)).await?;
    Ok(())
}

pub async fn is_online(state: &AppState, user_id: Uuid) -> AppResult<bool> {
    let mut conn = state.redis.clone();
    let exists: bool = conn.exists(format!("online:user:{}", user_id)).await?;
    Ok(exists)
}

pub async fn incr_unread(
    state: &AppState,
    user_id: Uuid,
    conversation_id: Uuid,
) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.incr::<_, _, ()>(
        format!("unread:{}:{}", user_id, conversation_id),
        1i64,
    )
    .await?;
    Ok(())
}
