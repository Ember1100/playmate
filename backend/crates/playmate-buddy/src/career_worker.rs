//! 职业搭子匹配后台 Worker
//!
//! 每 2 秒扫描一次 Redis 队列，找到领域/目标契合的两人，
//! 计算职业契合度，写入匹配结果，并通过 WebSocket 实时推送。

use std::time::Duration;

use serde_json::json;
use tokio::time;
use tracing::{error, info};

use playmate_common::AppState;

use crate::repo::career_match_repo::{self, CareerMatchResult};

pub async fn run(state: AppState) {
    info!("职业匹配 Worker 启动");
    let mut interval = time::interval(Duration::from_secs(2));

    loop {
        interval.tick().await;

        if let Err(e) = try_match(&state).await {
            error!("职业匹配 Worker 出错: {e}");
        }
    }
}

async fn try_match(state: &AppState) -> anyhow::Result<()> {
    let mut redis = state.redis.clone();

    if career_match_repo::queue_len(&mut redis).await? < 2 {
        return Ok(());
    }

    let Some(user_a) = career_match_repo::pop_front(&mut redis).await? else {
        return Ok(());
    };

    // 扫剩余队列，找第一个不同 user_id 的人（职业匹配无性别限制）
    let remaining = career_match_repo::peek_all(&mut redis).await?;
    let match_idx = remaining
        .iter()
        .position(|b| b.user_id != user_a.user_id);

    let user_b = match match_idx {
        None => {
            // 没找到，放回队尾
            career_match_repo::join_queue(&mut redis, &user_a).await?;
            return Ok(());
        }
        Some(idx) => remaining[idx].clone(),
    };

    career_match_repo::remove_from_queue(&mut redis, user_b.user_id).await?;

    // 清除等待标记
    let _: () = redis::cmd("DEL")
        .arg(format!("career_match:waiting:{}", user_a.user_id))
        .arg(format!("career_match:waiting:{}", user_b.user_id))
        .query_async(&mut redis)
        .await?;

    // 计算职业契合度
    let (score, common_skills, common_goal_count, collab_suggestions) =
        career_match_repo::calc_score(&user_a, &user_b);

    info!(
        "职业匹配成功: {} ↔ {}  契合度 {}%  共同技能 {:?}",
        user_a.username, user_b.username, score, common_skills
    );

    // 存储双向结果
    let result_for_a = CareerMatchResult {
        matched_user_id:    user_b.user_id,
        username:           user_b.username.clone(),
        avatar_url:         user_b.avatar_url.clone(),
        career_role:        user_b.career_role.clone(),
        company:            user_b.company.clone(),
        experience:         user_b.experience.clone(),
        score,
        common_skills:      common_skills.clone(),
        common_skill_count: common_skills.len() as i32,
        common_goal_count,
        collab_suggestions: collab_suggestions.clone(),
    };
    let result_for_b = CareerMatchResult {
        matched_user_id:    user_a.user_id,
        username:           user_a.username.clone(),
        avatar_url:         user_a.avatar_url.clone(),
        career_role:        user_a.career_role.clone(),
        company:            user_a.company.clone(),
        experience:         user_a.experience.clone(),
        score,
        common_skills:      common_skills.clone(),
        common_skill_count: common_skills.len() as i32,
        common_goal_count,
        collab_suggestions: collab_suggestions.clone(),
    };

    career_match_repo::store_result(&mut redis, user_a.user_id, &result_for_a).await?;
    career_match_repo::store_result(&mut redis, user_b.user_id, &result_for_b).await?;

    // WebSocket 实时推送
    let msg_a = json!({
        "type":               "career_match_found",
        "matched_user_id":    user_b.user_id.to_string(),
        "username":           user_b.username,
        "avatar_url":         user_b.avatar_url,
        "career_role":        user_b.career_role,
        "company":            user_b.company,
        "experience":         user_b.experience,
        "score":              score,
        "common_skills":      common_skills,
        "common_skill_count": common_skills.len(),
        "common_goal_count":  common_goal_count,
        "collab_suggestions": collab_suggestions,
    })
    .to_string();

    let msg_b = json!({
        "type":               "career_match_found",
        "matched_user_id":    user_a.user_id.to_string(),
        "username":           user_a.username,
        "avatar_url":         user_a.avatar_url,
        "career_role":        user_a.career_role,
        "company":            user_a.company,
        "experience":         user_a.experience,
        "score":              score,
        "common_skills":      result_for_b.common_skills,
        "common_skill_count": result_for_b.common_skill_count,
        "common_goal_count":  result_for_b.common_goal_count,
        "collab_suggestions": result_for_b.collab_suggestions,
    })
    .to_string();

    state.hub.send_to(&user_a.user_id, msg_a);
    state.hub.send_to(&user_b.user_id, msg_b);

    Ok(())
}
