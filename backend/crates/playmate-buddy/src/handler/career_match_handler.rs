//! 职业搭子快速匹配 Handler
//!
//! # 路由
//! - POST   /api/v1/buddy/career/match/join    加入职业匹配队列
//! - DELETE /api/v1/buddy/career/match/leave   退出职业匹配队列
//! - GET    /api/v1/buddy/career/match/result  查询匹配结果（短轮询）
//! - POST   /api/v1/buddy/career/match/next    跳过当前结果，重新排队

use axum::{extract::State, response::IntoResponse, Json};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use serde_json::json;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::repo::career_match_repo::{self, CareerQueueEntry};

// ── Request ───────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct JoinCareerMatchRequest {
    /// 选择的职业领域，如 ["产品经理", "设计师"]
    pub fields:     Vec<String>,
    /// 搭子目标，如 ["技能提升", "项目协作"]
    pub goals:      Vec<String>,
    /// 工作年限："应届"|"1-3年"|"3-5年"|"5年+"
    pub experience: String,
}

// ── Response ──────────────────────────────────────────────────────────────────

#[derive(Serialize)]
pub struct CareerMatchResultResponse {
    pub matched:            bool,
    pub matched_user_id:    Option<String>,
    pub username:           Option<String>,
    pub avatar_url:         Option<Option<String>>,
    pub career_role:        Option<String>,
    pub company:            Option<String>,
    pub experience:         Option<String>,
    pub score:              Option<i32>,
    pub common_skills:      Option<Vec<String>>,
    pub common_skill_count: Option<i32>,
    pub common_goal_count:  Option<i32>,
    pub collab_suggestions: Option<Vec<String>>,
}

// ── 内部辅助 ──────────────────────────────────────────────────────────────────

/// 从 career_profiles 读取职位、公司信息，及从 user_tags 读取技能标签
async fn fetch_career_info(
    db: &sqlx::PgPool,
    user_id: uuid::Uuid,
) -> (Option<String>, Option<String>, Vec<String>) {
    use sqlx::Row;

    // 职业档案
    let career = sqlx::query(
        "SELECT job_title, company, skills FROM career_profiles WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_optional(db)
    .await
    .ok()
    .flatten();

    let (career_role, company, skill_tags) = if let Some(row) = career {
        let job_title: Option<String> = row.try_get("job_title").ok().flatten();
        let company: Option<String>   = row.try_get("company").ok().flatten();
        // skills 字段是 jsonb，尝试解析为字符串数组
        let skills: Vec<String> = row
            .try_get::<serde_json::Value, _>("skills")
            .ok()
            .and_then(|v| {
                v.as_array().map(|arr| {
                    arr.iter()
                        .filter_map(|x| x.as_str().map(str::to_string))
                        .collect()
                })
            })
            .unwrap_or_default();
        (job_title, company, skills)
    } else {
        (None, None, vec![])
    };

    // 如果 career_profiles 没有 skills，fallback 到 user_tags
    let skill_tags = if skill_tags.is_empty() {
        sqlx::query(
            "SELECT t.name FROM tags t
             JOIN user_tags ut ON ut.tag_id = t.id
             WHERE ut.user_id = $1",
        )
        .bind(user_id)
        .fetch_all(db)
        .await
        .unwrap_or_default()
        .iter()
        .filter_map(|r| r.try_get::<String, _>("name").ok())
        .collect()
    } else {
        skill_tags
    };

    (career_role, company, skill_tags)
}

// ── Handlers ─────────────────────────────────────────────────────────────────

/// 加入职业匹配队列
pub async fn join_career_match(
    State(state):  State<AppState>,
    current_user:  CurrentUser,
    Json(payload): Json<JoinCareerMatchRequest>,
) -> Result<impl IntoResponse, AppError> {
    // 读取用户基本信息
    let row = sqlx::query("SELECT username, avatar_url FROM users WHERE id = $1")
        .bind(current_user.id)
        .fetch_one(&state.db)
        .await
        .map_err(AppError::Database)?;

    use sqlx::Row;
    let username:   String         = row.try_get("username").map_err(AppError::Database)?;
    let avatar_url: Option<String> = row.try_get("avatar_url").map_err(AppError::Database)?;

    let (career_role, company, skill_tags) =
        fetch_career_info(&state.db, current_user.id).await;

    let entry = CareerQueueEntry {
        user_id: current_user.id,
        username,
        avatar_url,
        career_role,
        company,
        fields:     payload.fields,
        goals:      payload.goals,
        experience: payload.experience,
        skill_tags,
        joined_at:  Utc::now().timestamp(),
    };

    let mut redis = state.redis.clone();
    career_match_repo::join_queue(&mut redis, &entry).await?;

    Ok(ApiResponse::ok(json!({ "status": "queued" })))
}

/// 退出职业匹配队列
pub async fn leave_career_match(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let mut redis = state.redis.clone();
    career_match_repo::leave_queue(&mut redis, current_user.id).await?;
    Ok(ApiResponse::<()>::ok_empty())
}

/// 查询职业匹配结果（短轮询：客户端每 2 秒调一次）
pub async fn get_career_match_result(
    State(state): State<AppState>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let mut redis = state.redis.clone();

    if let Some(result) = career_match_repo::pop_result(&mut redis, current_user.id).await? {
        return Ok(ApiResponse::ok(CareerMatchResultResponse {
            matched:            true,
            matched_user_id:    Some(result.matched_user_id.to_string()),
            username:           Some(result.username),
            avatar_url:         Some(result.avatar_url),
            career_role:        result.career_role,
            company:            result.company,
            experience:         Some(result.experience),
            score:              Some(result.score),
            common_skills:      Some(result.common_skills),
            common_skill_count: Some(result.common_skill_count),
            common_goal_count:  Some(result.common_goal_count),
            collab_suggestions: Some(result.collab_suggestions),
        }));
    }

    Ok(ApiResponse::ok(CareerMatchResultResponse {
        matched:            false,
        matched_user_id:    None,
        username:           None,
        avatar_url:         None,
        career_role:        None,
        company:            None,
        experience:         None,
        score:              None,
        common_skills:      None,
        common_skill_count: None,
        common_goal_count:  None,
        collab_suggestions: None,
    }))
}

/// 跳过当前匹配，重新入队
pub async fn next_career_match(
    State(state):  State<AppState>,
    current_user:  CurrentUser,
    Json(payload): Json<JoinCareerMatchRequest>,
) -> Result<impl IntoResponse, AppError> {
    let row = sqlx::query("SELECT username, avatar_url FROM users WHERE id = $1")
        .bind(current_user.id)
        .fetch_one(&state.db)
        .await
        .map_err(AppError::Database)?;

    use sqlx::Row;
    let username:   String         = row.try_get("username").map_err(AppError::Database)?;
    let avatar_url: Option<String> = row.try_get("avatar_url").map_err(AppError::Database)?;

    let (career_role, company, skill_tags) =
        fetch_career_info(&state.db, current_user.id).await;

    let entry = CareerQueueEntry {
        user_id: current_user.id,
        username,
        avatar_url,
        career_role,
        company,
        fields:     payload.fields,
        goals:      payload.goals,
        experience: payload.experience,
        skill_tags,
        joined_at:  Utc::now().timestamp(),
    };

    let mut redis = state.redis.clone();
    career_match_repo::join_queue(&mut redis, &entry).await?;

    Ok(ApiResponse::ok(json!({ "status": "queued" })))
}
