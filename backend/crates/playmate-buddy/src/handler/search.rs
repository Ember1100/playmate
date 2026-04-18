//! 搭子搜索 Handler

use axum::{
    extract::{Query, State},
    response::IntoResponse,
};

use playmate_common::{error::AppError, middleware::auth::CurrentUser, response::ApiResponse, AppState};

use crate::{
    dto::{BuddySearchResponse, GatherResponse, SearchQuery},
    repo::{gather_repo, search_repo},
};

/// GET /api/v1/buddy/search?q=keyword&page=1&limit=10
pub async fn search_buddy(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(query): Query<SearchQuery>,
) -> Result<impl IntoResponse, AppError> {
    let keyword = query.q.trim().to_string();
    if keyword.is_empty() {
        return Ok(ApiResponse::ok(BuddySearchResponse {
            users: vec![], user_total: 0,
            gathers: vec![], gather_total: 0,
        }));
    }

    let limit  = query.limit.clamp(1, 20);
    let offset = (query.page - 1).max(0) * limit;

    let (users, user_total) =
        search_repo::search_users(&state.db, &keyword, limit, offset).await?;
    let (raw_gathers, gather_total) =
        gather_repo::search(&state.db, current_user.id, &keyword, limit, offset).await?;

    let gathers = raw_gathers.into_iter().map(GatherResponse::from).collect();

    Ok(ApiResponse::ok(BuddySearchResponse {
        users,
        user_total,
        gathers,
        gather_total,
    }))
}
