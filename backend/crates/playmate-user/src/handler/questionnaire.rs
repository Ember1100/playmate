//! 新人问卷 HTTP Handler
//!
//! # 路由
//! - POST /api/v1/users/me/questionnaire

use axum::{extract::State, response::IntoResponse, Json};

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::{
    model::auth::QuestionnaireRequest,
    repo::user_repo,
};

/// 提交新人问卷（首次完成后清除 is_new_user 标记）
///
/// # 错误
/// - `401 Unauthorized` - 未登录
pub async fn submit_questionnaire(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<QuestionnaireRequest>,
) -> Result<impl IntoResponse, AppError> {
    let interests = serde_json::to_value(payload.interests.unwrap_or_default())
        .map_err(|e| AppError::Internal(anyhow::anyhow!("{}", e)))?;
    let purposes = serde_json::to_value(payload.purposes.unwrap_or_default())
        .map_err(|e| AppError::Internal(anyhow::anyhow!("{}", e)))?;

    let city = payload.city.clone();
    user_repo::upsert_questionnaire(
        &state.db,
        current_user.id,
        payload.identity.as_deref(),
        interests,
        purposes,
        payload.age_range.as_deref(),
        payload.city.as_deref(),
        payload.personality,
        payload.life_goal.as_deref(),
    )
    .await?;

    // 同步城市到 users 表，方便 profile 接口直接读取
    if city.is_some() {
        user_repo::update_user_city(&state.db, current_user.id, city.as_deref()).await?;
    }

    // 清除新人标记，后续登录不再跳转问卷
    user_repo::mark_questionnaire_done(&state.db, current_user.id).await?;

    Ok(ApiResponse::ok_empty())
}
