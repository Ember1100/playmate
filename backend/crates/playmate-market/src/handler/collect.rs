//! 集市收藏 HTTP Handler

use axum::{
    extract::{Query, State},
    response::IntoResponse,
    Json,
};

use playmate_common::{
    error::AppError,
    response::{ApiResponse, PageResponse},
    AppState, CurrentUser,
};

use crate::{
    dto::CollectRequest,
    repo::collect_repo,
};

#[derive(serde::Deserialize)]
pub struct PageQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

fn default_page() -> i64 { 1 }
fn default_limit() -> i64 { 20 }

pub async fn add_collect(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CollectRequest>,
) -> Result<impl IntoResponse, AppError> {
    collect_repo::add(&state.db, current_user.id, &payload.target_type, payload.target_id).await?;
    Ok(ApiResponse::ok_empty())
}

pub async fn remove_collect(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CollectRequest>,
) -> Result<impl IntoResponse, AppError> {
    collect_repo::remove(&state.db, current_user.id, &payload.target_type, payload.target_id)
        .await?;
    Ok(ApiResponse::ok_empty())
}

pub async fn list_mine(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(q): Query<PageQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let items = collect_repo::list_mine(&state.db, current_user.id, limit, offset).await?;
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}
