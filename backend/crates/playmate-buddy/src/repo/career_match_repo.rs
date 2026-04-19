//! 职业搭子匹配 Redis 操作
//!
//! # Redis key 设计
//! - `career_match:queue:global`       LIST   排队中的 CareerQueueEntry JSON（FIFO）
//! - `career_match:waiting:{user_id}`  STRING "1"  TTL=300s  用户在队中的标记
//! - `career_match:result:{user_id}`   STRING CareerMatchResult JSON  TTL=300s

use redis::{aio::ConnectionManager, AsyncCommands};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

pub const QUEUE_KEY: &str = "career_match:queue:global";

// ── 队列条目 ──────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CareerQueueEntry {
    pub user_id:     Uuid,
    pub username:    String,
    pub avatar_url:  Option<String>,
    pub career_role: Option<String>, // 职位（来自 career_profiles）
    pub company:     Option<String>, // 公司
    pub fields:      Vec<String>,    // 选择的职业领域
    pub goals:       Vec<String>,    // 搭子目标
    pub experience:  String,         // "应届"|"1-3年"|"3-5年"|"5年+"
    pub skill_tags:  Vec<String>,    // 技能标签（来自 career_profiles.skills）
    pub joined_at:   i64,
}

// ── 匹配结果 ──────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CareerMatchResult {
    pub matched_user_id:    Uuid,
    pub username:           String,
    pub avatar_url:         Option<String>,
    pub career_role:        Option<String>,
    pub company:            Option<String>,
    pub experience:         String,
    pub score:              i32,
    pub common_skills:      Vec<String>,
    pub common_skill_count: i32,
    pub common_goal_count:  i32,
    pub collab_suggestions: Vec<String>,
}

// ── 操作函数 ──────────────────────────────────────────────────────────────────

/// 加入匹配队列（幂等：已在队中则先移除再重入）
pub async fn join_queue(
    redis: &mut ConnectionManager,
    entry: &CareerQueueEntry,
) -> AppResult<()> {
    let user_key = format!("career_match:waiting:{}", entry.user_id);

    if redis.exists::<_, bool>(&user_key).await.unwrap_or(false) {
        remove_from_queue(redis, entry.user_id).await?;
    }

    let json = serde_json::to_string(entry)
        .map_err(|e| AppError::Internal(anyhow::anyhow!("序列化失败: {e}")))?;

    let _: () = redis.rpush(QUEUE_KEY, &json).await.map_err(AppError::Redis)?;
    let _: () = redis
        .set_ex(&user_key, "1", 300)
        .await
        .map_err(AppError::Redis)?;

    Ok(())
}

/// 离开匹配队列
pub async fn leave_queue(redis: &mut ConnectionManager, user_id: Uuid) -> AppResult<()> {
    remove_from_queue(redis, user_id).await?;
    let _: () = redis
        .del(format!("career_match:waiting:{user_id}"))
        .await
        .map_err(AppError::Redis)?;
    Ok(())
}

/// 从 LIST 中移除指定 user_id 的条目
pub async fn remove_from_queue(
    redis: &mut ConnectionManager,
    user_id: Uuid,
) -> AppResult<()> {
    let all: Vec<String> = redis.lrange(QUEUE_KEY, 0, -1).await.map_err(AppError::Redis)?;
    let filtered: Vec<String> = all
        .into_iter()
        .filter(|s| {
            serde_json::from_str::<CareerQueueEntry>(s)
                .map(|e| e.user_id != user_id)
                .unwrap_or(true)
        })
        .collect();

    let _: () = redis.del(QUEUE_KEY).await.map_err(AppError::Redis)?;
    if !filtered.is_empty() {
        let _: () = redis.rpush(QUEUE_KEY, filtered).await.map_err(AppError::Redis)?;
    }
    Ok(())
}

/// 弹出队首一条
pub async fn pop_front(
    redis: &mut ConnectionManager,
) -> AppResult<Option<CareerQueueEntry>> {
    let raw: Option<String> = redis.lpop(QUEUE_KEY, None).await.map_err(AppError::Redis)?;
    match raw {
        None => Ok(None),
        Some(s) => {
            let entry = serde_json::from_str(&s)
                .map_err(|e| AppError::Internal(anyhow::anyhow!("反序列化失败: {e}")))?;
            Ok(Some(entry))
        }
    }
}

/// 读取队列全部条目（不弹出）
pub async fn peek_all(redis: &mut ConnectionManager) -> AppResult<Vec<CareerQueueEntry>> {
    let all: Vec<String> = redis.lrange(QUEUE_KEY, 0, -1).await.map_err(AppError::Redis)?;
    Ok(all
        .into_iter()
        .filter_map(|s| serde_json::from_str(&s).ok())
        .collect())
}

/// 队列长度
pub async fn queue_len(redis: &mut ConnectionManager) -> AppResult<i64> {
    let len: i64 = redis.llen(QUEUE_KEY).await.map_err(AppError::Redis)?;
    Ok(len)
}

/// 存储匹配结果（TTL 5 分钟）
pub async fn store_result(
    redis: &mut ConnectionManager,
    user_id: Uuid,
    result: &CareerMatchResult,
) -> AppResult<()> {
    let json = serde_json::to_string(result)
        .map_err(|e| AppError::Internal(anyhow::anyhow!("序列化失败: {e}")))?;
    let _: () = redis
        .set_ex(format!("career_match:result:{user_id}"), json, 300)
        .await
        .map_err(AppError::Redis)?;
    Ok(())
}

/// 取出并清除匹配结果
pub async fn pop_result(
    redis: &mut ConnectionManager,
    user_id: Uuid,
) -> AppResult<Option<CareerMatchResult>> {
    let key = format!("career_match:result:{user_id}");
    let raw: Option<String> = redis.get(&key).await.map_err(AppError::Redis)?;
    match raw {
        None => Ok(None),
        Some(s) => {
            let _: () = redis.del(&key).await.map_err(AppError::Redis)?;
            let result = serde_json::from_str(&s)
                .map_err(|e| AppError::Internal(anyhow::anyhow!("反序列化失败: {e}")))?;
            Ok(Some(result))
        }
    }
}

// ── 契合度计算 ─────────────────────────────────────────────────────────────────

/// 返回 (总分, 共同技能列表, 共同目标数, 协作建议列表)
pub fn calc_score(
    a: &CareerQueueEntry,
    b: &CareerQueueEntry,
) -> (i32, Vec<String>, i32, Vec<String>) {
    // 1. 领域交集 40%
    let common_fields: Vec<&String> = a.fields.iter().filter(|x| b.fields.contains(x)).collect();
    let field_union = a.fields.len() + b.fields.len().saturating_sub(common_fields.len());
    let field_jaccard = if field_union == 0 {
        0.5_f64 // 都没填，给中间分
    } else {
        common_fields.len() as f64 / field_union as f64
    };
    let field_score = field_jaccard * 40.0;

    // 2. 目标交集 35%
    let common_goals: Vec<&String> = a.goals.iter().filter(|x| b.goals.contains(x)).collect();
    let goal_union = a.goals.len() + b.goals.len().saturating_sub(common_goals.len());
    let goal_jaccard = if goal_union == 0 {
        0.5_f64
    } else {
        common_goals.len() as f64 / goal_union as f64
    };
    let goal_score = goal_jaccard * 35.0;

    // 3. 工作年限相近 25%
    let exp_score = exp_similarity(&a.experience, &b.experience) * 25.0;

    let total = (field_score + goal_score + exp_score).round() as i32;

    // 共同技能（技能标签交集，最多展示 5 个）
    let common_skills: Vec<String> = a
        .skill_tags
        .iter()
        .filter(|x| b.skill_tags.contains(x))
        .cloned()
        .take(5)
        .collect();

    let common_goal_count = common_goals.len() as i32;

    // 根据共同目标生成协作建议
    let collab_suggestions = build_collab_suggestions(&common_goals);

    (total.clamp(30, 99), common_skills, common_goal_count, collab_suggestions)
}

fn exp_similarity(a: &str, b: &str) -> f64 {
    fn rank(s: &str) -> i32 {
        match s {
            "应届"   => 0,
            "1-3年"  => 1,
            "3-5年"  => 2,
            "5年+"   => 3,
            _        => 1,
        }
    }
    let diff = (rank(a) - rank(b)).unsigned_abs();
    match diff {
        0 => 1.0,
        1 => 0.75,
        2 => 0.4,
        _ => 0.1,
    }
}

fn build_collab_suggestions(common_goals: &[&String]) -> Vec<String> {
    let mut suggestions = Vec::new();
    for goal in common_goals {
        match goal.as_str() {
            "技能提升" => {
                suggestions.push("每周互相 Review 工作成果，提供不同视角".to_string());
            }
            "求职内推" => {
                suggestions.push("互相推荐内部职位机会，扩大求职渠道".to_string());
            }
            "项目协作" => {
                suggestions.push("共同开展副业项目，从 0 到 1 打造产品".to_string());
            }
            "灵感碰撞" => {
                suggestions.push("定期头脑风暴，碰撞行业新思路".to_string());
            }
            _ => {}
        }
    }
    // 补一条通用建议
    if suggestions.is_empty() {
        suggestions.push("互相分享行业动态与机会".to_string());
    }
    suggestions
}
