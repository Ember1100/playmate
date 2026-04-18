//! 菜单 HTTP Handler
//!
//! # 路由
//! - GET /api/v1/buddy/menus?type=1

use axum::{
    extract::{Query, State},
    response::IntoResponse,
};

use playmate_common::{error::AppError, response::ApiResponse, AppState, CurrentUser};

use crate::{dto::MenuQuery, repo::menu_repo};

/// 获取菜单树（两级）
pub async fn list_menus(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Query(q):      Query<MenuQuery>,
) -> Result<impl IntoResponse, AppError> {
    let tree = menu_repo::list_menu_tree(&state.db, q.menu_type).await?;
    Ok(ApiResponse::ok(tree))
}
