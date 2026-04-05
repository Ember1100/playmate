//! 认证核心业务逻辑

use chrono::{Datelike, NaiveDate, Utc};
use rand::Rng;

use playmate_common::{
    auth::verify_token,
    error::{AppError, AppResult},
    AppState,
};

use crate::{
    model::auth::{AccessTokenResponse, AuthResponse},
    repo::user_repo,
    service::{sms_service, token_service, wechat_service},
};

// ── 年龄校验 ──────────────────────────────────────────────────────────────────

/// 校验年龄不超过 35 岁（周岁）
pub fn check_age_limit(birthday: NaiveDate) -> AppResult<()> {
    let today = Utc::now().date_naive();
    let mut age = today.year() - birthday.year();
    if (today.month(), today.day()) < (birthday.month(), birthday.day()) {
        age -= 1;
    }
    if age > 35 {
        return Err(AppError::Business(
            "抱歉，本平台仅面向 35 岁及以下用户".to_string(),
        ));
    }
    Ok(())
}

// ── 随机用户名 ────────────────────────────────────────────────────────────────

fn random_username() -> String {
    let suffix: String = rand::thread_rng()
        .sample_iter(&rand::distributions::Alphanumeric)
        .take(8)
        .map(char::from)
        .collect();
    format!("user_{}", suffix)
}

// ── 短信验证码登录 / 自动注册 ────────────────────────────────────────────────

pub async fn login_with_sms(
    state: &AppState,
    phone: &str,
    code:  &str,
) -> AppResult<AuthResponse> {
    let ok = sms_service::verify_code(state, phone, code).await?;
    if !ok {
        return Err(AppError::Unauthorized("验证码错误".to_string()));
    }

    let user = match user_repo::find_by_phone(&state.db, phone).await? {
        Some(u) => u,
        None => {
            let username = loop {
                let name = random_username();
                if !user_repo::username_exists(&state.db, &name).await? {
                    break name;
                }
            };
            user_repo::create_user_with_phone(&state.db, &username, phone).await?
        }
    };

    let is_new = user.is_new_user;
    let pair   = token_service::create_token_pair(user.id, &user.username, &state.config)?;

    Ok(AuthResponse {
        access_token:  pair.access_token,
        refresh_token: pair.refresh_token,
        token_type:    "Bearer".to_string(),
        expires_in:    token_service::expires_in(),
        is_new_user:   is_new,
        user:          user.into(),
    })
}

// ── 微信 OAuth 登录 / 自动注册 ───────────────────────────────────────────────

pub async fn login_with_wechat(state: &AppState, wx_code: &str) -> AppResult<AuthResponse> {
    let wx_info = wechat_service::exchange_code(wx_code, &state.config).await?;

    let user = if let Some(oauth) =
        user_repo::find_oauth(&state.db, "wechat", &wx_info.openid).await?
    {
        user_repo::find_by_id(&state.db, oauth.user_id).await?
    } else {
        let username = loop {
            let name = random_username();
            if !user_repo::username_exists(&state.db, &name).await? {
                break name;
            }
        };
        let new_user = user_repo::create_user_minimal(&state.db, &username).await?;
        user_repo::create_oauth(&state.db, new_user.id, "wechat", &wx_info.openid).await?;
        new_user
    };

    let is_new = user.is_new_user;
    let pair   = token_service::create_token_pair(user.id, &user.username, &state.config)?;

    Ok(AuthResponse {
        access_token:  pair.access_token,
        refresh_token: pair.refresh_token,
        token_type:    "Bearer".to_string(),
        expires_in:    token_service::expires_in(),
        is_new_user:   is_new,
        user:          user.into(),
    })
}

// ── Token 刷新 ───────────────────────────────────────────────────────────────

pub async fn refresh_token(
    state:         &AppState,
    refresh_token: &str,
) -> AppResult<AccessTokenResponse> {
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
