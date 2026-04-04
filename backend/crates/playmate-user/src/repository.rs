//! 用户数据库查询（Repository 层）
//!
//! # 功能
//! - 用户创建、查询、更新

use sqlx::PgPool;
use uuid::Uuid;

use playmate_common::error::{AppError, AppResult};

use crate::model::User;

pub async fn find_by_id(pool: &PgPool, id: Uuid) -> AppResult<User> {
    sqlx::query_as::<_, User>(
        "SELECT id, username, email, phone, password_hash, avatar_url, bio,
                gender, birthday, is_active, last_seen_at, created_at, updated_at
         FROM users WHERE id = $1 AND is_active = true",
    )
    .bind(id)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => AppError::NotFound(format!("用户 {} 不存在", id)),
        _ => AppError::Database(e),
    })
}

pub async fn find_by_email(pool: &PgPool, email: &str) -> AppResult<User> {
    sqlx::query_as::<_, User>(
        "SELECT id, username, email, phone, password_hash, avatar_url, bio,
                gender, birthday, is_active, last_seen_at, created_at, updated_at
         FROM users WHERE email = $1 AND is_active = true",
    )
    .bind(email)
    .fetch_one(pool)
    .await
    .map_err(|e| match e {
        sqlx::Error::RowNotFound => AppError::NotFound("用户不存在".to_string()),
        _ => AppError::Database(e),
    })
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

pub async fn create_user(
    pool: &PgPool,
    username: &str,
    email: &str,
    password_hash: &str,
) -> AppResult<User> {
    sqlx::query_as::<_, User>(
        "INSERT INTO users (username, email, password_hash)
         VALUES ($1, $2, $3)
         RETURNING id, username, email, phone, password_hash, avatar_url, bio,
                   gender, birthday, is_active, last_seen_at, created_at, updated_at",
    )
    .bind(username)
    .bind(email)
    .bind(password_hash)
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
    sqlx::query_as::<_, User>(
        "UPDATE users SET
            username    = COALESCE($2, username),
            bio         = COALESCE($3, bio),
            gender      = COALESCE($4, gender),
            birthday    = COALESCE($5, birthday),
            avatar_url  = COALESCE($6, avatar_url),
            updated_at  = NOW()
         WHERE id = $1 AND is_active = true
         RETURNING id, username, email, phone, password_hash, avatar_url, bio,
                   gender, birthday, is_active, last_seen_at, created_at, updated_at",
    )
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
