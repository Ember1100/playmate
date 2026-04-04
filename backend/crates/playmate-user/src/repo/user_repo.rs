//! 用户数据库查询（Repository 层）

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::user::{Tag, User, UserOauth};

// ── 用户查询 ────────────────────────────────────────────────────────────────

const USER_COLS: &str =
    "id, username, email, phone, password_hash, avatar_url, bio,
     gender, birthday, is_active, last_seen_at, created_at, updated_at";

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

pub async fn find_by_email(pool: &PgPool, email: &str) -> AppResult<User> {
    sqlx::query_as::<_, User>(&format!(
        "SELECT {USER_COLS} FROM users WHERE email = $1 AND is_active = true"
    ))
    .bind(email)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => AppError::NotFound("用户不存在".to_string()),
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

pub async fn email_exists(pool: &PgPool, email: &str) -> AppResult<bool> {
    let row: (bool,) =
        sqlx::query_as("SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)")
            .bind(email)
            .fetch_one(pool)
            .await?;
    Ok(row.0)
}

pub async fn username_exists(pool: &PgPool, username: &str) -> AppResult<bool> {
    let row: (bool,) =
        sqlx::query_as("SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)")
            .bind(username)
            .fetch_one(pool)
            .await?;
    Ok(row.0)
}

/// 邮箱密码注册（email + password 必填）
pub async fn create_user_with_email(
    pool: &PgPool,
    username: &str,
    email: &str,
    password_hash: &str,
) -> AppResult<User> {
    sqlx::query_as::<_, User>(&format!(
        "INSERT INTO users (username, email, password_hash)
         VALUES ($1, $2, $3)
         RETURNING {USER_COLS}"
    ))
    .bind(username)
    .bind(email)
    .bind(password_hash)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

/// 手机号注册（phone 必填，其余可选）
pub async fn create_user_with_phone(pool: &PgPool, username: &str, phone: &str) -> AppResult<User> {
    sqlx::query_as::<_, User>(&format!(
        "INSERT INTO users (username, phone) VALUES ($1, $2) RETURNING {USER_COLS}"
    ))
    .bind(username)
    .bind(phone)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

/// 第三方登录自动创建用户（仅 username）
pub async fn create_user_minimal(pool: &PgPool, username: &str) -> AppResult<User> {
    sqlx::query_as::<_, User>(&format!(
        "INSERT INTO users (username) VALUES ($1) RETURNING {USER_COLS}"
    ))
    .bind(username)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn update_user(
    pool: &PgPool,
    id: Uuid,
    username: Option<&str>,
    bio: Option<&str>,
    gender: Option<i16>,
    birthday: Option<chrono::NaiveDate>,
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

// ── OAuth ────────────────────────────────────────────────────────────────────

pub async fn find_oauth(
    pool: &PgPool,
    provider: &str,
    provider_id: &str,
) -> AppResult<Option<UserOauth>> {
    sqlx::query_as::<_, UserOauth>(
        "SELECT id, user_id, provider, provider_id, access_token, created_at
         FROM user_oauth WHERE provider = $1 AND provider_id = $2",
    )
    .bind(provider)
    .bind(provider_id)
    .fetch_optional(pool)
    .await
    .map_err(AppError::Database)
}

pub async fn create_oauth(
    pool: &PgPool,
    user_id: Uuid,
    provider: &str,
    provider_id: &str,
    access_token: Option<&str>,
) -> AppResult<UserOauth> {
    sqlx::query_as::<_, UserOauth>(
        "INSERT INTO user_oauth (user_id, provider, provider_id, access_token)
         VALUES ($1, $2, $3, $4)
         RETURNING id, user_id, provider, provider_id, access_token, created_at",
    )
    .bind(user_id)
    .bind(provider)
    .bind(provider_id)
    .bind(access_token)
    .fetch_one(pool)
    .await
    .map_err(AppError::Database)
}

// ── 标签 ─────────────────────────────────────────────────────────────────────

pub async fn list_all_tags(pool: &PgPool) -> AppResult<Vec<Tag>> {
    sqlx::query_as::<_, Tag>("SELECT id, name, category FROM tags ORDER BY category, name")
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

/// 全量替换用户标签（先删后插，事务保证一致性）
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
