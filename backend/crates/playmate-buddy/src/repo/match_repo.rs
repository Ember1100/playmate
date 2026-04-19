//! 线上匹配 Redis 操作
//!
//! # Redis key 设计
//! - `match:queue:global`          LIST  排队中的 QueueEntry JSON（FIFO）
//! - `match:waiting:{user_id}`     STRING "1"  TTL=300s  用户在队中的标记
//! - `match:result:{user_id}`      STRING MatchResult JSON  TTL=300s

use redis::{aio::ConnectionManager, AsyncCommands};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

pub const QUEUE_KEY: &str = "match:queue:global";

// ── 队列条目 ──────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueueEntry {
    pub user_id:     Uuid,
    pub username:    String,
    pub avatar_url:  Option<String>,
    pub gender:      i16,        // 用户实际性别（1=男 2=女 0=未知）
    pub activities:  Vec<String>,// 选择的想玩项目
    pub mood:        i16,        // 0=开心 1=放松 2=无聊 3=焦虑
    pub gender_pref: i16,        // 0=不限 1=男 2=女
    pub tags:        Vec<String>,// 兴趣标签（来自 user_tags）
    pub joined_at:   i64,        // Unix 秒时间戳
}

// ── 匹配结果 ──────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MatchResult {
    pub matched_user_id:  Uuid,
    pub username:         String,
    pub avatar_url:       Option<String>,
    pub bio:              Option<String>,
    pub common_interests: Vec<String>,
    pub score:            i32,
}

// ── 操作函数 ──────────────────────────────────────────────────────────────────

/// 加入匹配队列（幂等：已在队中则先移除再重入）
pub async fn join_queue(redis: &mut ConnectionManager, entry: &QueueEntry) -> AppResult<()> {
    let user_key = format!("match:waiting:{}", entry.user_id);

    // 若已在等待，先清理旧条目（简单实现：移除同 user_id 的条目）
    if redis.exists::<_, bool>(&user_key).await.unwrap_or(false) {
        remove_from_queue(redis, entry.user_id).await?;
    }

    let json = serde_json::to_string(entry)
        .map_err(|e| AppError::Internal(anyhow::anyhow!("序列化失败: {e}")))?;

    // 入队（尾部插入）
    let _: () = redis.rpush(QUEUE_KEY, &json).await.map_err(AppError::Redis)?;
    // 标记在等待（TTL 5 分钟）
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
        .del(format!("match:waiting:{user_id}"))
        .await
        .map_err(AppError::Redis)?;
    Ok(())
}

/// 从 LIST 中移除指定 user_id 的条目（扫描+LREM）
pub async fn remove_from_queue(
    redis: &mut ConnectionManager,
    user_id: Uuid,
) -> AppResult<()> {
    // 取出全部，过滤掉目标 user_id，再整体写回（小队列 OK）
    let all: Vec<String> = redis.lrange(QUEUE_KEY, 0, -1).await.map_err(AppError::Redis)?;
    let filtered: Vec<String> = all
        .into_iter()
        .filter(|s| {
            serde_json::from_str::<QueueEntry>(s)
                .map(|e| e.user_id != user_id)
                .unwrap_or(true)
        })
        .collect();

    // 清空再重写
    let _: () = redis.del(QUEUE_KEY).await.map_err(AppError::Redis)?;
    if !filtered.is_empty() {
        let _: () = redis
            .rpush(QUEUE_KEY, filtered)
            .await
            .map_err(AppError::Redis)?;
    }
    Ok(())
}

/// 弹出队首一条
pub async fn pop_front(redis: &mut ConnectionManager) -> AppResult<Option<QueueEntry>> {
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
pub async fn peek_all(redis: &mut ConnectionManager) -> AppResult<Vec<QueueEntry>> {
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
    result: &MatchResult,
) -> AppResult<()> {
    let json = serde_json::to_string(result)
        .map_err(|e| AppError::Internal(anyhow::anyhow!("序列化失败: {e}")))?;
    let _: () = redis
        .set_ex(format!("match:result:{user_id}"), json, 300)
        .await
        .map_err(AppError::Redis)?;
    Ok(())
}

/// 取出并清除匹配结果
pub async fn pop_result(
    redis: &mut ConnectionManager,
    user_id: Uuid,
) -> AppResult<Option<MatchResult>> {
    let key = format!("match:result:{user_id}");
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

/// 用户是否在等待队列中
pub async fn is_waiting(redis: &mut ConnectionManager, user_id: Uuid) -> AppResult<bool> {
    let exists: bool = redis
        .exists(format!("match:waiting:{user_id}"))
        .await
        .map_err(AppError::Redis)?;
    Ok(exists)
}

// ── 契合度计算 ─────────────────────────────────────────────────────────────────

pub fn calc_score(a: &QueueEntry, b: &QueueEntry) -> (i32, Vec<String>) {
    // 1. 共同兴趣 50%：活动交集 + 标签 Jaccard
    let common_activities: Vec<String> = a
        .activities
        .iter()
        .filter(|x| b.activities.contains(x))
        .cloned()
        .collect();
    let act_union = a.activities.len() + b.activities.len() - common_activities.len();
    let act_jaccard = if act_union == 0 {
        0.0_f64
    } else {
        common_activities.len() as f64 / act_union as f64
    };

    let common_tags: Vec<String> = a
        .tags
        .iter()
        .filter(|x| b.tags.contains(x))
        .cloned()
        .collect();
    let tag_union = a.tags.len() + b.tags.len() - common_tags.len();
    let tag_jaccard = if tag_union == 0 {
        0.0_f64
    } else {
        common_tags.len() as f64 / tag_union as f64
    };

    let interest_score = (act_jaccard * 0.5 + tag_jaccard * 0.5) * 50.0;

    // 2. 心情相似度 20%
    let mood_score = mood_similarity(a.mood, b.mood) * 20.0;

    // 3. 活跃时段重叠 20%（MVP：统一给 70%）
    let hours_score = 14.0_f64;

    // 4. 互动历史 10%（MVP：0）
    let interact_score = 0.0_f64;

    let total = (interest_score + mood_score + hours_score + interact_score).round() as i32;

    // 共同标签 = 活动 + 兴趣标签，去重，最多展示 5 个
    let mut common: Vec<String> = common_activities;
    for t in common_tags {
        if !common.contains(&t) {
            common.push(t);
        }
    }
    common.truncate(5);

    (total.clamp(10, 99), common)
}

fn mood_similarity(a: i16, b: i16) -> f64 {
    if a == b {
        return 1.0;
    }
    match (a.min(b), a.max(b)) {
        (0, 1) => 0.8, // 开心 + 放松
        (1, 2) => 0.6, // 放松 + 无聊
        (0, 2) => 0.5, // 开心 + 无聊
        (2, 3) => 0.4, // 无聊 + 焦虑
        (0, 3) => 0.2, // 开心 + 焦虑
        _ => 0.3,
    }
}

/// 性别偏好兼容性检查
pub fn gender_compatible(a: &QueueEntry, b: &QueueEntry) -> bool {
    let a_ok = a.gender_pref == 0 || a.gender_pref == b.gender || b.gender == 0;
    let b_ok = b.gender_pref == 0 || b.gender_pref == a.gender || a.gender == 0;
    a_ok && b_ok
}
