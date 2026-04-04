//! 认证核心业务逻辑

use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use rand::Rng;

use playmate_common::{
    auth::verify_token,
    error::{AppError, AppResult},
    AppState,
};

use crate::{
    model::auth::{AccessTokenResponse, AuthResponse},
    repo::user_repo,
    service::{
        sms_service, token_service,
        wechat_service,
    },
};

// ── 密码工具 ─────────────────────────────────────────────────────────────────

pub fn hash_password(password: &str) -> AppResult<String> {
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|h| h.to_string())
        .map_err(|e| AppError::Internal(anyhow::anyhow!("密码加密失败: {}", e)))
}

fn verify_password(password: &str, hash: &str) -> AppResult<()> {
    let parsed = PasswordHash::new(hash)
        .map_err(|e| AppError::Internal(anyhow::anyhow!("哈希解析失败: {}", e)))?;
    Argon2::default()
        .verify_password(password.as_bytes(), &parsed)
        .map_err(|_| AppError::Unauthorized("密码错误".to_string()))
}

fn random_username() -> String {
    let suffix: String = rand::thread_rng()
        .sample_iter(&rand::distributions::Alphanumeric)
        .take(8)
        .map(char::from)
        .collect();
    format!("user_{}", suffix)
}

// ── 邮箱注册 / 登录 ──────────────────────────────────────────────────────────

pub async fn register_with_email(
    state: &AppState,
    username: &str,
    email: &str,
    password: &str,
) -> AppResult<AuthResponse> {
    if user_repo::email_exists(&state.db, email).await? {
        return Err(AppError::Business("邮箱已被注册".to_string()));
    }
    if user_repo::username_exists(&state.db, username).await? {
        return Err(AppError::Business("用户名已被使用".to_string()));
    }

    let password_hash = hash_password(password)?;
    let user = user_repo::create_user_with_email(&state.db, username, email, &password_hash).await?;

    let pair = token_service::create_token_pair(user.id, &user.username, &state.config)?;
    Ok(AuthResponse {
        access_token: pair.access_token,
        refresh_token: pair.refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: token_service::expires_in(),
        user: user.into(),
    })
}

pub async fn login_with_email(
    state: &AppState,
    email: &str,
    password: &str,
) -> AppResult<AuthResponse> {
    let user = user_repo::find_by_email(&state.db, email).await?;

    let hash = user
        .password_hash
        .as_deref()
        .ok_or_else(|| AppError::Unauthorized("该账号未设置密码，请使用其他登录方式".to_string()))?;
    verify_password(password, hash)?;

    let pair = token_service::create_token_pair(user.id, &user.username, &state.config)?;
    Ok(AuthResponse {
        access_token: pair.access_token,
        refresh_token: pair.refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: token_service::expires_in(),
        user: user.into(),
    })
}

// ── 短信验证码登录 / 自动注册 ────────────────────────────────────────────────

pub async fn login_with_sms(
    state: &AppState,
    phone: &str,
    code: &str,
) -> AppResult<AuthResponse> {
    // 校验验证码
    let ok = sms_service::verify_code(state, phone, code).await?;
    if !ok {
        return Err(AppError::Unauthorized("验证码错误".to_string()));
    }

    // 查找或自动注册用户
    let user = match user_repo::find_by_phone(&state.db, phone).await? {
        Some(u) => u,
        None => {
            // 首次登录 → 自动注册
            let username = loop {
                let name = random_username();
                if !user_repo::username_exists(&state.db, &name).await? {
                    break name;
                }
            };
            user_repo::create_user_with_phone(&state.db, &username, phone).await?
        }
    };

    let pair = token_service::create_token_pair(user.id, &user.username, &state.config)?;
    Ok(AuthResponse {
        access_token: pair.access_token,
        refresh_token: pair.refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: token_service::expires_in(),
        user: user.into(),
    })
}

// ── 微信 OAuth 登录 / 自动注册 ───────────────────────────────────────────────

pub async fn login_with_wechat(state: &AppState, wx_code: &str) -> AppResult<AuthResponse> {
    let wx_info = wechat_service::exchange_code(wx_code, &state.config).await?;

    // 查找已绑定的 OAuth 记录
    let user = if let Some(oauth) =
        user_repo::find_oauth(&state.db, "wechat", &wx_info.openid).await?
    {
        user_repo::find_by_id(&state.db, oauth.user_id).await?
    } else {
        // 首次微信登录 → 自动创建用户并绑定
        let username = loop {
            let name = random_username();
            if !user_repo::username_exists(&state.db, &name).await? {
                break name;
            }
        };
        let new_user = user_repo::create_user_minimal(&state.db, &username).await?;
        user_repo::create_oauth(&state.db, new_user.id, "wechat", &wx_info.openid, None).await?;
        new_user
    };

    let pair = token_service::create_token_pair(user.id, &user.username, &state.config)?;
    Ok(AuthResponse {
        access_token: pair.access_token,
        refresh_token: pair.refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: token_service::expires_in(),
        user: user.into(),
    })
}

// ── Token 刷新 ───────────────────────────────────────────────────────────────

pub async fn refresh_token(state: &AppState, refresh_token: &str) -> AppResult<AccessTokenResponse> {
    let claims = verify_token(refresh_token, &state.config.jwt_refresh_secret)?;
    let access_token = playmate_common::auth::create_access_token(
        claims.sub,
        &claims.username,
        &state.config.jwt_secret,
    )?;
    Ok(AccessTokenResponse {
        access_token,
        token_type: "Bearer".to_string(),
        expires_in: token_service::expires_in(),
    })
}
