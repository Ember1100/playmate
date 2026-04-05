//! 文件上传 Handler
//!
//! # 功能
//! - POST /api/v1/upload/avatar  → 上传头像（≤5MB，jpg/png/webp）
//! - POST /api/v1/upload/post    → 上传动态图片/视频（≤50MB）
//! - POST /api/v1/upload/voice   → 上传语音（≤10MB）
//!
//! 返回格式：{ "url": "https://..." }

use axum::{
    extract::{Multipart, State},
    response::IntoResponse,
    routing::post,
    Router,
};

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

const MAX_AVATAR_BYTES: usize = 5 * 1024 * 1024;
const MAX_POST_BYTES: usize = 50 * 1024 * 1024;
const MAX_VOICE_BYTES: usize = 10 * 1024 * 1024;

pub fn upload_routes() -> Router<AppState> {
    Router::new()
        .route("/avatar", post(upload_avatar))
        .route("/post", post(upload_post))
        .route("/voice", post(upload_voice))
}

/// 上传头像
pub async fn upload_avatar(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let url = extract_and_upload(multipart, &state, "avatars", MAX_AVATAR_BYTES).await?;
    Ok(ApiResponse::ok(serde_json::json!({ "url": url })))
}

/// 上传动态图片/视频
pub async fn upload_post(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let url = extract_and_upload(multipart, &state, "posts", MAX_POST_BYTES).await?;
    Ok(ApiResponse::ok(serde_json::json!({ "url": url })))
}

/// 上传语音消息
pub async fn upload_voice(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let url = extract_and_upload(multipart, &state, "voices", MAX_VOICE_BYTES).await?;
    Ok(ApiResponse::ok(serde_json::json!({ "url": url })))
}

async fn extract_and_upload(
    mut multipart: Multipart,
    state: &AppState,
    bucket: &str,
    max_bytes: usize,
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

        let data = field
            .bytes()
            .await
            .map_err(|e| AppError::BadRequest(format!("读取文件失败: {}", e)))?;

        if data.is_empty() {
            continue;
        }

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
