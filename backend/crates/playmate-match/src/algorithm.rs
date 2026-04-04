//! 匹配分计算算法
//!
//! # 评分维度
//! - 共同兴趣标签（最高 60 分）
//! - 年龄差（最高 20 分）
//! - 预留性别偏好（20 分，暂不启用）

use chrono::Utc;

use crate::model::UserProfile;

/// 计算两位用户的匹配分（0-100）
pub fn calculate_match_score(a: &UserProfile, b: &UserProfile) -> u8 {
    let mut score = 0u32;

    // 共同标签（最高 60 分）
    let common = a
        .tag_ids
        .iter()
        .filter(|t| b.tag_ids.contains(t))
        .count();
    if !a.tag_ids.is_empty() {
        let tag_score = (common as f32 / a.tag_ids.len() as f32 * 60.0) as u32;
        score += tag_score;
    }

    // 年龄差（最高 20 分）
    if let (Some(bd_a), Some(bd_b)) = (a.birthday, b.birthday) {
        let today = Utc::now().date_naive();
        let age_a = (today - bd_a).num_days() / 365;
        let age_b = (today - bd_b).num_days() / 365;
        let diff = (age_a - age_b).unsigned_abs() as u32;
        score += match diff {
            0..=2  => 20,
            3..=5  => 15,
            6..=10 => 10,
            _      => 0,
        };
    }

    score.min(100) as u8
}

/// 从候选中过滤并排序（score > 0，降序）
pub fn rank_candidates(
    me: &UserProfile,
    candidates: Vec<UserProfile>,
) -> Vec<(UserProfile, u8)> {
    let mut scored: Vec<(UserProfile, u8)> = candidates
        .into_iter()
        .map(|c| {
            let score = calculate_match_score(me, &c);
            (c, score)
        })
        .filter(|(_, s)| *s > 0)
        .collect();

    scored.sort_by(|a, b| b.1.cmp(&a.1));
    scored
}
