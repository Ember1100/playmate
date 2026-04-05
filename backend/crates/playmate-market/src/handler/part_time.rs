//! 兼职啦 HTTP Handler

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse,
    Json,
};
use uuid::Uuid;
use validator::Validate;

use playmate_common::{
    error::AppError,
    response::{ApiResponse, PageResponse},
    AppState, CurrentUser,
};

use crate::{
    dto::{CreatePartTimeRequest, ListPartTimeQuery, PartTimeResponse, UpdatePartTimeRequest},
    repo::part_time_repo,
};

pub async fn list(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Query(q): Query<ListPartTimeQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let items_raw = part_time_repo::list(&state.db, q.category.as_deref(), limit, offset).await?;
    let items: Vec<PartTimeResponse> = items_raw.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}

pub async fn create(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CreatePartTimeRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    let images = serde_json::to_value(payload.images.unwrap_or_default())
        .map_err(|e| AppError::Internal(anyhow::anyhow!("{}", e)))?;

    let item = part_time_repo::create(
        &state.db,
        current_user.id,
        &payload.title,
        payload.description.as_deref(),
        images,
        payload.salary.as_deref(),
        payload.salary_type,
        payload.category.as_deref(),
        payload.location.as_deref(),
        payload.contact.as_deref(),
    )
    .await?;

    Ok(ApiResponse::ok(PartTimeResponse::from(item)))
}

pub async fn get_one(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let item = part_time_repo::get(&state.db, id).await?;
    Ok(ApiResponse::ok(PartTimeResponse::from(item)))
}

pub async fn update(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdatePartTimeRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    let images = payload
        .images
        .map(|v| serde_json::to_value(v).map_err(|e| AppError::Internal(anyhow::anyhow!("{}", e))))
        .transpose()?;

    let item = part_time_repo::update(
        &state.db,
        id,
        current_user.id,
        payload.title.as_deref(),
        payload.description.as_deref(),
        images,
        payload.salary.as_deref(),
        payload.salary_type,
        payload.category.as_deref(),
        payload.location.as_deref(),
        payload.contact.as_deref(),
    )
    .await?;

    Ok(ApiResponse::ok(PartTimeResponse::from(item)))
}

pub async fn delete(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    part_time_repo::delete(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}
