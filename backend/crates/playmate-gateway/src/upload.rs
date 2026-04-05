//! 文件上传 Handler
//!
//! # 路由
//! - POST /api/v1/upload/avatar  → 头像（≤5MB，jpg/png/webp）→ bucket: avatars
//! - POST /api/v1/upload/market  → 集市图片（≤5MB，jpg/png/webp）→ bucket: market
//! - POST /api/v1/upload/topic   → 话题配图（≤5MB，jpg/png/webp）→ bucket: topics
//! - POST /api/v1/upload/voice   → 语音消息（≤10MB，m4a/mp3）→ bucket: voices
//!
//! 返回：`{ "url": "https://..." }`

use axum::{
    extract::{Multipart, State},
    response::IntoResponse,
    routing::post,
    Router,
};

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

const MAX_IMAGE_BYTES: usize = 5 * 1024 * 1024;   // 5 MB
const MAX_VOICE_BYTES: usize = 10 * 1024 * 1024;  // 10 MB

/// 允许的图片 MIME 类型
const ALLOWED_IMAGE_MIME: &[&str] = &["image/jpeg", "image/png", "image/webp"];

/// 允许的语音 MIME 类型
const ALLOWED_VOICE_MIME: &[&str] = &["audio/m4a", "audio/mpeg", "audio/aac", "audio/mp4"];

pub fn upload_routes() -> Router<AppState> {
    Router::new()
        .route("/avatar", post(upload_avatar))
        .route("/market", post(upload_market))
        .route("/topic",  post(upload_topic))
        .route("/voice",  post(upload_voice))
}

/// 上传头像
pub async fn upload_avatar(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let url = extract_and_upload(
        multipart,
        &state,
        "avatars",
        MAX_IMAGE_BYTES,
        ALLOWED_IMAGE_MIME,
    )
    .await?;
    Ok(ApiResponse::ok(serde_json::json!({ "url": url })))
}

/// 上传集市图片（失物招领/二手闲置/兼职啦/以物换物通用）
pub async fn upload_market(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let url = extract_and_upload(
        multipart,
        &state,
        "market",
        MAX_IMAGE_BYTES,
        ALLOWED_IMAGE_MIME,
    )
    .await?;
    Ok(ApiResponse::ok(serde_json::json!({ "url": url })))
}

/// 上传话题配图
pub async fn upload_topic(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let url = extract_and_upload(
        multipart,
        &state,
        "topics",
        MAX_IMAGE_BYTES,
        ALLOWED_IMAGE_MIME,
    )
    .await?;
    Ok(ApiResponse::ok(serde_json::json!({ "url": url })))
}

/// 上传语音消息
pub async fn upload_voice(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let url = extract_and_upload(
        multipart,
        &state,
        "voices",
        MAX_VOICE_BYTES,
        ALLOWED_VOICE_MIME,
    )
    .await?;
    Ok(ApiResponse::ok(serde_json::json!({ "url": url })))
}

/// 通用上传逻辑：读取 multipart 第一个文件字段，校验类型和大小后上传
async fn extract_and_upload(
    mut multipart: Multipart,
    state: &AppState,
    bucket: &str,
    max_bytes: usize,
    allowed_mime: &[&str],
) -> Result<String, AppError> {
    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::BadRequest(format!("解析文件失败: {}", e)))?
    {
        let content_type = field
            .content_type()
            .map(|s| s.to_string())
            .unwrap_or_else(|| "application/octet-stream".to_string());

        // MIME 类型校验
        if !allowed_mime.contains(&content_type.as_str()) {
            return Err(AppError::BadRequest(format!(
                "不支持的文件类型: {}，允许: {}",
                content_type,
                allowed_mime.join(", ")
            )));
        }

        let data = field
            .bytes()
            .await
            .map_err(|e| AppError::BadRequest(format!("读取文件失败: {}", e)))?;

        if data.is_empty() {
            continue;
        }

        // 文件大小校验
        if data.len() > max_bytes {
            return Err(AppError::BadRequest(format!(
                "文件超出大小限制（最大 {} MB）",
                max_bytes / 1024 / 1024
            )));
        }

        let url = state
            .storage
            .upload(bucket, data.to_vec(), &content_type)
            .await?;

        return Ok(url);
    }

    Err(AppError::BadRequest("未找到上传文件".to_string()))
}
