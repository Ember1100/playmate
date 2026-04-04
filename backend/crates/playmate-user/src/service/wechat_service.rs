//! 微信 OAuth 服务
//!
//! 用 code 换取 openid，供后端完成登录/注册流程。

use playmate_common::{config::AppConfig, error::{AppError, AppResult}};

pub struct WechatUserInfo {
    pub openid: String,
    /// unionid 跨应用唯一标识（需在微信开放平台绑定后才有）
    pub unionid: Option<String>,
}

/// 用微信授权 code 换取 openid
pub async fn exchange_code(code: &str, config: &AppConfig) -> AppResult<WechatUserInfo> {
    if config.wechat_app_id.is_empty() {
        return Err(AppError::Business("微信登录未配置".to_string()));
    }

    let url = format!(
        "https://api.weixin.qq.com/sns/oauth2/access_token\
         ?appid={}&secret={}&code={}&grant_type=authorization_code",
        config.wechat_app_id, config.wechat_app_secret, code
    );

    let resp: serde_json::Value = reqwest::Client::new()
        .get(&url)
        .send()
        .await
        .map_err(|e| AppError::Internal(anyhow::anyhow!("微信 API 请求失败: {}", e)))?
        .json()
        .await
        .map_err(|e| AppError::Internal(anyhow::anyhow!("微信 API 响应解析失败: {}", e)))?;

    // 微信接口错误：errcode != 0
    if let Some(err_code) = resp["errcode"].as_i64() {
        if err_code != 0 {
            let msg = resp["errmsg"].as_str().unwrap_or("未知错误");
            return Err(AppError::Business(format!("微信授权失败: {}", msg)));
        }
    }

    let openid = resp["openid"]
        .as_str()
        .ok_or_else(|| AppError::Business("未能获取微信 openid".to_string()))?
        .to_string();

    let unionid = resp["unionid"].as_str().map(|s| s.to_string());

    Ok(WechatUserInfo { openid, unionid })
}
