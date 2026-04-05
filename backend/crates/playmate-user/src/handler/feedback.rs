//! 需求反馈 HTTP Handler
//!
//! # 路由
//! - POST /api/v1/feedback

use axum::{extract::State, response::IntoResponse, Json};
use validator::Validate;

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::model::auth::FeedbackRequest;

/// 提交需求反馈
pub async fn submit_feedback(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<FeedbackRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    let images = serde_json::to_value(payload.images.unwrap_or_default())
        .map_err(|e| AppError::Internal(anyhow::anyhow!("{}", e)))?;

    sqlx::query(
        "INSERT INTO feedback (user_id, type, content, images, contact)
         VALUES ($1, $2, $3, $4, $5)",
    )
    .bind(current_user.id)
    .bind(&payload.r#type)
    .bind(&payload.content)
    .bind(&images)
    .bind(payload.contact.as_deref())
    .execute(&state.db)
    .await
    .map_err(AppError::Database)?;

    Ok(ApiResponse::ok_empty())
}
