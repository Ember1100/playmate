//! 用户数据库查询（Repository 层）

use chrono::NaiveDate;
use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::user::{CareerProfile, Tag, User, UserOauth, UserStats};

// ── 列列表 ────────────────────────────────────────────────────────────────────

const USER_COLS: &str =
    "id, username, phone, password_hash, avatar_url, bio,
     gender, birthday, is_verified, is_new_user, is_active, last_seen_at,
     created_at, updated_at";

// ── 用户查询 ──────────────────────────────────────────────────────────────────

pub async fn find_by_id(pool: &PgPool, id: Uuid) -> AppResult<User> {
    sqlx::query_as::<_, User>(&format!(
        "SELECT {USER_COLS} FROM users WHERE id = $1 AND is_active = true"
    ))
    .bind(id)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => AppError::NotFound(format!("用户 {} 不存在", id)),
        _ => AppError::Database(e),
    })
}

pub async fn find_by_phone(pool: &PgPool, phone: &str) -> AppResult<Option<User>> {
    sqlx::query_as::<_, User>(&format!(
        "SELECT {USER_COLS} FROM users WHERE phone = $1 AND is_active = true"
    ))
    .bind(phone)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn username_exists(pool: &PgPool, username: &str) -> AppResult<bool> {
    let row: (bool,) =
        sqlx::query_as("SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)")
            .bind(username)
            .fetch_one(pool)
            .await?;
    Ok(row.0)
}

// ── 用户创建 ──────────────────────────────────────────────────────────────────

/// 手机号注册（自动注册，同时创建 user_stats）
pub async fn create_user_with_phone(pool: &PgPool, username: &str, phone: &str) -> AppResult<User> {
    let user = sqlx::query_as::<_, User>(&format!(
        "INSERT INTO users (username, phone, is_verified)
         VALUES ($1, $2, true)
         RETURNING {USER_COLS}"
    ))
    .bind(username)
    .bind(phone)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?;

    sqlx::query(
        "INSERT INTO user_stats (user_id, credit_score) VALUES ($1, 750) ON CONFLICT DO NOTHING",
    )
    .bind(user.id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;

    Ok(user)
}

/// 第三方登录自动创建用户（仅 username，同时创建 user_stats）
pub async fn create_user_minimal(pool: &PgPool, username: &str) -> AppResult<User> {
    let user = sqlx::query_as::<_, User>(&format!(
        "INSERT INTO users (username) VALUES ($1) RETURNING {USER_COLS}"
    ))
    .bind(username)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)?;

    sqlx::query(
        "INSERT INTO user_stats (user_id, credit_score) VALUES ($1, 750) ON CONFLICT DO NOTHING",
    )
    .bind(user.id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;

    Ok(user)
}

// ── 用户更新 ──────────────────────────────────────────────────────────────────

pub async fn update_user(
    pool:       &PgPool,
    id:         Uuid,
    username:   Option<&str>,
    bio:        Option<&str>,
    gender:     Option<i16>,
    birthday:   Option<NaiveDate>,
    avatar_url: Option<&str>,
) -> AppResult<User> {
    sqlx::query_as::<_, User>(&format!(
        "UPDATE users SET
             username   = COALESCE($2, username),
             bio        = COALESCE($3, bio),
             gender     = COALESCE($4, gender),
             birthday   = COALESCE($5, birthday),
             avatar_url = COALESCE($6, avatar_url),
             updated_at = NOW()
         WHERE id = $1 AND is_active = true
         RETURNING {USER_COLS}"
    ))
    .bind(id)
    .bind(username)
    .bind(bio)
    .bind(gender)
    .bind(birthday)
    .bind(avatar_url)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => AppError::NotFound(format!("用户 {} 不存在", id)),
        _ => AppError::Database(e),
    })
}

/// 问卷完成后清除 is_new_user 标记
pub async fn mark_questionnaire_done(pool: &PgPool, user_id: Uuid) -> AppResult<()> {
    sqlx::query("UPDATE users SET is_new_user = false, updated_at = NOW() WHERE id = $1")
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(AppError::Database)?;
    Ok(())
}

/// 账号注销（软删除，清除手机号防止占用）
pub async fn deactivate_user(pool: &PgPool, user_id: Uuid) -> AppResult<()> {
    sqlx::query(
        "UPDATE users SET is_active = false, phone = NULL, updated_at = NOW() WHERE id = $1",
    )
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;
    Ok(())
}

// ── OAuth ─────────────────────────────────────────────────────────────────────

pub async fn find_oauth(
    pool:        &PgPool,
    provider:    &str,
    provider_id: &str,
) -> AppResult<Option<UserOauth>> {
    sqlx::query_as::<_, UserOauth>(
        "SELECT id, user_id, provider, provider_id, created_at
         FROM user_oauth WHERE provider = $1 AND provider_id = $2",
    )
    .bind(provider)
    .bind(provider_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn create_oauth(
    pool:        &PgPool,
    user_id:     Uuid,
    provider:    &str,
    provider_id: &str,
) -> AppResult<()> {
    sqlx::query(
        "INSERT INTO user_oauth (user_id, provider, provider_id)
         VALUES ($1, $2, $3) ON CONFLICT DO NOTHING",
    )
    .bind(user_id)
    .bind(provider)
    .bind(provider_id)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;
    Ok(())
}

// ── 统计数据 ──────────────────────────────────────────────────────────────────

pub async fn get_stats(pool: &PgPool, user_id: Uuid) -> AppResult<UserStats> {
    sqlx::query_as::<_, UserStats>(
        "SELECT user_id, growth_value, points, collect_count, level, credit_score, updated_at
         FROM user_stats WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => AppError::NotFound("用户统计数据不存在".to_string()),
        _ => AppError::Database(e),
    })
}

// ── 问卷 ──────────────────────────────────────────────────────────────────────

pub async fn upsert_questionnaire(
    pool:        &PgPool,
    user_id:     Uuid,
    identity:    Option<&str>,
    interests:   serde_json::Value,
    purposes:    serde_json::Value,
    age_range:   Option<&str>,
    city:        Option<&str>,
    personality: Option<serde_json::Value>,
    life_goal:   Option<&str>,
) -> AppResult<()> {
    sqlx::query(
        "INSERT INTO user_questionnaire
             (user_id, identity, interests, purposes, age_range, city, personality, life_goal)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (user_id) DO UPDATE SET
             identity    = EXCLUDED.identity,
             interests   = EXCLUDED.interests,
             purposes    = EXCLUDED.purposes,
             age_range   = EXCLUDED.age_range,
             city        = EXCLUDED.city,
             personality = EXCLUDED.personality,
             life_goal   = EXCLUDED.life_goal,
             completed_at = NOW()",
    )
    .bind(user_id)
    .bind(identity)
    .bind(interests)
    .bind(purposes)
    .bind(age_range)
    .bind(city)
    .bind(personality)
    .bind(life_goal)
    .execute(pool)
    .await
    .map_err(AppError::Database)?;
    Ok(())
}

// ── 职业档案 ──────────────────────────────────────────────────────────────────

pub async fn get_career(pool: &PgPool, user_id: Uuid) -> AppResult<Option<CareerProfile>> {
    sqlx::query_as::<_, CareerProfile>(
        "SELECT user_id, job_title, company, skills, experience, looking_for, is_public, updated_at
         FROM career_profiles WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn upsert_career(
    pool:        &PgPool,
    user_id:     Uuid,
    job_title:   Option<&str>,
    company:     Option<&str>,
    skills:      serde_json::Value,
    experience:  Option<&str>,
    looking_for: Option<&str>,
    is_public:   Option<bool>,
) -> AppResult<CareerProfile> {
    sqlx::query_as::<_, CareerProfile>(
        "INSERT INTO career_profiles
             (user_id, job_title, company, skills, experience, looking_for, is_public)
         VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7, true))
         ON CONFLICT (user_id) DO UPDATE SET
             job_title   = COALESCE(EXCLUDED.job_title, career_profiles.job_title),
             company     = COALESCE(EXCLUDED.company, career_profiles.company),
             skills      = EXCLUDED.skills,
             experience  = COALESCE(EXCLUDED.experience, career_profiles.experience),
             looking_for = COALESCE(EXCLUDED.looking_for, career_profiles.looking_for),
             is_public   = COALESCE($7, career_profiles.is_public),
             updated_at  = NOW()
         RETURNING user_id, job_title, company, skills, experience, looking_for, is_public, updated_at",
    )
    .bind(user_id)
    .bind(job_title)
    .bind(company)
    .bind(skills)
    .bind(experience)
    .bind(looking_for)
    .bind(is_public)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

// ── 标签 ──────────────────────────────────────────────────────────────────────

pub async fn list_all_tags(pool: &PgPool) -> AppResult<Vec<Tag>> {
    sqlx::query_as::<_, Tag>(
        "SELECT id, name, category FROM tags ORDER BY category, sort_order, name",
    )
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn get_user_tags(pool: &PgPool, user_id: Uuid) -> AppResult<Vec<Tag>> {
    sqlx::query_as::<_, Tag>(
        "SELECT t.id, t.name, t.category
         FROM tags t
         JOIN user_tags ut ON ut.tag_id = t.id
         WHERE ut.user_id = $1
         ORDER BY t.category, t.name",
    )
    .bind(user_id)
    .fetch_all(pool)
    .await
    .map_err(AppError::Database)
}

/// 全量替换用户标签（事务）
pub async fn set_user_tags(pool: &PgPool, user_id: Uuid, tag_ids: &[i32]) -> AppResult<()> {
    let mut tx = pool.begin().await?;
    sqlx::query("DELETE FROM user_tags WHERE user_id = $1")
        .bind(user_id)
        .execute(&mut *tx)
        .await?;
    for &tag_id in tag_ids {
        sqlx::query(
            "INSERT INTO user_tags (user_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
        )
        .bind(user_id)
        .bind(tag_id)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    Ok(())
}
