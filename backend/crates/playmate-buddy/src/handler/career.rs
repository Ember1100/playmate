//! 职业搭子阵地 HTTP Handler
//!
//! # 路由
//! - GET /api/v1/buddy/career              ← 职业搭子阵地列表（公开档案）
//! - GET /api/v1/buddy/career/:user_id     ← 查看指定用户职业档案

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse,
};
use serde::Deserialize;
use uuid::Uuid;

use playmate_common::{
    error::AppError,
    response::{ApiResponse, PageResponse},
    AppState, CurrentUser,
};

use crate::repo::career_repo;

#[derive(Deserialize)]
pub struct CareerListQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

fn default_page()  -> i64 { 1 }
fn default_limit() -> i64 { 20 }

/// 职业搭子阵地列表
pub async fn list_career(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Query(q): Query<CareerListQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit  = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let items  = career_repo::list_public(&state.db, limit, offset).await?;
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total:    items.len() as i64,
        page:     q.page,
        limit,
        items,
    }))
}

/// 查看指定用户职业档案
pub async fn get_career(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Path(user_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let profile = career_repo::get_public(&state.db, user_id).await?;
    Ok(ApiResponse::ok(profile))
}
