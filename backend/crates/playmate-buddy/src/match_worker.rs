//! 线上匹配后台 Worker
//!
//! 每 2 秒扫描一次 Redis 队列，找到兼容的两人，
//! 计算契合度，写入匹配结果，并通过 WebSocket 实时推送。

use std::time::Duration;

use serde_json::json;
use tokio::time;
use tracing::{error, info};

use playmate_common::AppState;

use crate::repo::match_repo::{self, MatchResult};

pub async fn run(state: AppState) {
    info!("线上匹配 Worker 启动");
    let mut interval = time::interval(Duration::from_secs(2));

    loop {
        interval.tick().await;

        if let Err(e) = try_match(&state).await {
            error!("匹配 Worker 出错: {e}");
        }
    }
}

async fn try_match(state: &AppState) -> anyhow::Result<()> {
    let mut redis = state.redis.clone();

    // 队列不足 2 人直接跳过
    if match_repo::queue_len(&mut redis).await? < 2 {
        return Ok(());
    }

    // 弹出队首一个人
    let Some(user_a) = match_repo::pop_front(&mut redis).await? else {
        return Ok(());
    };

    // 扫剩余队列，找第一个性别兼容的人
    let remaining = match_repo::peek_all(&mut redis).await?;
    let match_idx = remaining
        .iter()
        .position(|b| b.user_id != user_a.user_id && match_repo::gender_compatible(&user_a, b));

    let user_b = match match_idx {
        None => {
            // 没找到兼容的，放回队尾继续等
            match_repo::join_queue(&mut redis, &user_a).await?;
            return Ok(());
        }
        Some(idx) => remaining[idx].clone(),
    };

    // 从队列中移除 user_b
    match_repo::remove_from_queue(&mut redis, user_b.user_id).await?;

    // 清除等待标记
    let _: () = redis::cmd("DEL")
        .arg(format!("match:waiting:{}", user_a.user_id))
        .arg(format!("match:waiting:{}", user_b.user_id))
        .query_async(&mut redis)
        .await?;

    // 计算契合度
    let (score, common_interests) = match_repo::calc_score(&user_a, &user_b);

    info!(
        "匹配成功: {} ↔ {}  契合度 {}%  共同兴趣 {:?}",
        user_a.username, user_b.username, score, common_interests
    );

    // 存储双向匹配结果
    let result_for_a = MatchResult {
        matched_user_id:  user_b.user_id,
        username:         user_b.username.clone(),
        avatar_url:       user_b.avatar_url.clone(),
        bio:              None, // handler 层从 DB 补充
        common_interests: common_interests.clone(),
        score,
    };
    let result_for_b = MatchResult {
        matched_user_id:  user_a.user_id,
        username:         user_a.username.clone(),
        avatar_url:       user_a.avatar_url.clone(),
        bio:              None,
        common_interests: common_interests.clone(),
        score,
    };

    match_repo::store_result(&mut redis, user_a.user_id, &result_for_a).await?;
    match_repo::store_result(&mut redis, user_b.user_id, &result_for_b).await?;

    // WebSocket 推送 match_found 给双方
    let msg_a = json!({
        "type":             "match_found",
        "matched_user_id":  user_b.user_id.to_string(),
        "username":         user_b.username,
        "avatar_url":       user_b.avatar_url,
        "common_interests": common_interests,
        "score":            score,
    })
    .to_string();

    let msg_b = json!({
        "type":             "match_found",
        "matched_user_id":  user_a.user_id.to_string(),
        "username":         user_a.username,
        "avatar_url":       user_a.avatar_url,
        "common_interests": common_interests,
        "score":            score,
    })
    .to_string();

    state.hub.send_to(&user_a.user_id, msg_a);
    state.hub.send_to(&user_b.user_id, msg_b);

    Ok(())
}
