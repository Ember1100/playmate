//! 短信验证码服务（阿里云 Dysmsapi）
//!
//! dev 模式（ALIYUN_SMS_ACCESS_KEY 为空时）：验证码打印到日志，不调用 API。

use std::collections::BTreeMap;

use base64::Engine;
use chrono::Utc;
use hmac::{Hmac, Mac};
use redis::AsyncCommands;
use sha1::Sha1;
use uuid::Uuid;

use playmate_common::{config::AppConfig, error::{AppError, AppResult}, AppState};

type HmacSha1 = Hmac<Sha1>;

// ── Redis key helpers ────────────────────────────────────────────────────────

fn code_key(phone: &str) -> String { format!("sms:code:{}", phone) }
fn limit_key(phone: &str) -> String { format!("sms:limit:{}", phone) }

// ── 公开接口 ─────────────────────────────────────────────────────────────────

/// 发送短信验证码
///
/// 限流：同一手机号 60 秒内只能发一次（Redis TTL 控制）
pub async fn send_code(state: &AppState, phone: &str) -> AppResult<()> {
    let mut conn = state.redis.clone();

    // 限流检查
    let limited: bool = conn.exists(limit_key(phone)).await?;
    if limited {
        return Err(AppError::Business("发送过于频繁，请 60 秒后再试".to_string()));
    }

    // 生成 6 位数字验证码
    let code = {
        use rand::Rng;
        format!("{:06}", rand::thread_rng().gen_range(100_000..999_999u32))
    };

    // 存储验证码（TTL 300s）
    conn.set_ex::<_, _, ()>(code_key(phone), &code, 300).await?;

    // 设置发送限流（TTL 60s）
    conn.set_ex::<_, _, ()>(limit_key(phone), "1", 60).await?;

    // 发送（dev 模式或 prod 模式）
    if state.config.aliyun_sms_access_key.is_empty() {
        tracing::warn!("[DEV] 短信验证码 {} → {}", phone, code);
    } else {
        call_aliyun_sms(phone, &code, &state.config).await?;
    }

    Ok(())
}

/// 校验验证码（成功后删除，防止重用）
pub async fn verify_code(state: &AppState, phone: &str, code: &str) -> AppResult<bool> {
    let mut conn = state.redis.clone();
    let stored: Option<String> = conn.get(code_key(phone)).await?;

    match stored {
        None => Err(AppError::Business("验证码已过期，请重新发送".to_string())),
        Some(c) if c == code => {
            conn.del::<_, ()>(code_key(phone)).await?;
            Ok(true)
        }
        Some(_) => Ok(false),
    }
}

// ── 阿里云 API 调用 ───────────────────────────────────────────────────────────

async fn call_aliyun_sms(phone: &str, code: &str, config: &AppConfig) -> AppResult<()> {
    let mut params: BTreeMap<String, String> = BTreeMap::new();
    params.insert("Action".into(), "SendSms".into());
    params.insert("AccessKeyId".into(), config.aliyun_sms_access_key.clone());
    params.insert("Format".into(), "JSON".into());
    params.insert("PhoneNumbers".into(), phone.into());
    params.insert("SignName".into(), config.aliyun_sms_sign_name.clone());
    params.insert("SignatureMethod".into(), "HMAC-SHA1".into());
    params.insert("SignatureNonce".into(), Uuid::new_v4().to_string());
    params.insert("SignatureVersion".into(), "1.0".into());
    params.insert("TemplateCode".into(), config.aliyun_sms_template_code.clone());
    params.insert("TemplateParam".into(), format!(r#"{{"code":"{}"}}"#, code));
    params.insert(
        "Timestamp".into(),
        Utc::now().format("%Y-%m-%dT%H:%M:%SZ").to_string(),
    );
    params.insert("Version".into(), "2017-05-25".into());

    // 构造待签名字符串
    let sorted_query: String = params
        .iter()
        .map(|(k, v)| format!("{}={}", pct(k), pct(v)))
        .collect::<Vec<_>>()
        .join("&");

    let string_to_sign = format!("GET&{}&{}", pct("/"), pct(&sorted_query));
    let signing_key = format!("{}&", config.aliyun_sms_secret);

    let mut mac = HmacSha1::new_from_slice(signing_key.as_bytes())
        .map_err(|e| AppError::Internal(anyhow::anyhow!("HMAC 初始化失败: {}", e)))?;
    mac.update(string_to_sign.as_bytes());
    let signature =
        base64::engine::general_purpose::STANDARD.encode(mac.finalize().into_bytes());

    params.insert("Signature".into(), signature);

    // 最终请求 URL（BTreeMap 保证字母序）
    let final_query: String = params
        .iter()
        .map(|(k, v)| format!("{}={}", pct(k), pct(v)))
        .collect::<Vec<_>>()
        .join("&");

    let url = format!("https://dysmsapi.aliyuncs.com/?{}", final_query);

    let resp: serde_json::Value = reqwest::Client::new()
        .get(&url)
        .send()
        .await
        .map_err(|e| AppError::Internal(anyhow::anyhow!("短信 API 请求失败: {}", e)))?
        .json()
        .await
        .map_err(|e| AppError::Internal(anyhow::anyhow!("短信 API 响应解析失败: {}", e)))?;

    if resp["Code"].as_str() != Some("OK") {
        let msg = resp["Message"].as_str().unwrap_or("未知错误");
        tracing::error!("阿里云短信失败: {:?}", resp);
        return Err(AppError::Internal(anyhow::anyhow!("短信发送失败: {}", msg)));
    }

    Ok(())
}

/// RFC 3986 百分号编码（Aliyun 签名要求）
fn pct(s: &str) -> String {
    urlencoding::encode(s).into_owned()
}
