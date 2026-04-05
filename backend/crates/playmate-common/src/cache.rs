//! Redis 缓存操作封装
//!
//! # 功能
//! - 用户在线状态（set/get/del）
//! - 私信/社群/通知 未读计数
//! - 短信验证码存储与校验

use redis::AsyncCommands;
use uuid::Uuid;

use crate::{error::AppResult, state::AppState};

// ── 在线状态 ─────────────────────────────────────────────────────────────────

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

// ── 未读计数 ─────────────────────────────────────────────────────────────────

/// 私信未读 +1
pub async fn incr_dm_unread(
    state: &AppState,
    user_id: Uuid,
    conv_id: Uuid,
) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.incr::<_, _, ()>(format!("unread:dm:{}:{}", user_id, conv_id), 1i64)
        .await?;
    Ok(())
}

/// 清零私信未读
pub async fn clear_dm_unread(
    state: &AppState,
    user_id: Uuid,
    conv_id: Uuid,
) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.del::<_, ()>(format!("unread:dm:{}:{}", user_id, conv_id))
        .await?;
    Ok(())
}

/// 获取私信未读数
pub async fn get_dm_unread(
    state: &AppState,
    user_id: Uuid,
    conv_id: Uuid,
) -> AppResult<i64> {
    let mut conn = state.redis.clone();
    let count: i64 = conn
        .get(format!("unread:dm:{}:{}", user_id, conv_id))
        .await
        .unwrap_or(0);
    Ok(count)
}

/// 社群未读 +1
pub async fn incr_group_unread(
    state: &AppState,
    user_id: Uuid,
    group_id: Uuid,
) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.incr::<_, _, ()>(
        format!("unread:group:{}:{}", user_id, group_id),
        1i64,
    )
    .await?;
    Ok(())
}

/// 通知未读 +1
pub async fn incr_notify_unread(state: &AppState, user_id: Uuid) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.incr::<_, _, ()>(format!("unread:notify:{}", user_id), 1i64)
        .await?;
    Ok(())
}

/// 清零通知未读
pub async fn clear_notify_unread(state: &AppState, user_id: Uuid) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.del::<_, ()>(format!("unread:notify:{}", user_id))
        .await?;
    Ok(())
}

/// 获取通知未读数
pub async fn get_notify_unread(state: &AppState, user_id: Uuid) -> AppResult<i64> {
    let mut conn = state.redis.clone();
    let count: i64 = conn
        .get(format!("unread:notify:{}", user_id))
        .await
        .unwrap_or(0);
    Ok(count)
}

// ── 短信验证码 ────────────────────────────────────────────────────────────────

/// 存储验证码，TTL 300s
pub async fn set_sms_code(state: &AppState, phone: &str, code: &str) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.set_ex::<_, _, ()>(format!("sms:code:{}", phone), code, 300)
        .await?;
    Ok(())
}

/// 读取验证码
pub async fn get_sms_code(state: &AppState, phone: &str) -> AppResult<Option<String>> {
    let mut conn = state.redis.clone();
    let code: Option<String> = conn.get(format!("sms:code:{}", phone)).await.ok().flatten();
    Ok(code)
}

/// 删除验证码（验证成功后调用）
pub async fn del_sms_code(state: &AppState, phone: &str) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.del::<_, ()>(format!("sms:code:{}", phone)).await?;
    Ok(())
}

/// 检查是否在发送限流（60s 内已发过）
pub async fn check_sms_limit(state: &AppState, phone: &str) -> AppResult<bool> {
    let mut conn = state.redis.clone();
    let exists: bool = conn.exists(format!("sms:limit:{}", phone)).await?;
    Ok(exists)
}

/// 设置发送限流，TTL 60s
pub async fn set_sms_limit(state: &AppState, phone: &str) -> AppResult<()> {
    let mut conn = state.redis.clone();
    conn.set_ex::<_, _, ()>(format!("sms:limit:{}", phone), "1", 60)
        .await?;
    Ok(())
}
