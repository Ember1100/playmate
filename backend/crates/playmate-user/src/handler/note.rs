//! 学习笔记 HTTP Handler
//!
//! # 路由
//! - GET    /api/v1/notes          ← 我的笔记列表
//! - POST   /api/v1/notes          ← 新建笔记
//! - GET    /api/v1/notes/:id      ← 笔记详情
//! - PUT    /api/v1/notes/:id      ← 更新笔记
//! - DELETE /api/v1/notes/:id      ← 删除笔记

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse,
    Json,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use playmate_common::{
    error::AppError,
    response::{ApiResponse, PageResponse},
    AppState, CurrentUser,
};

use crate::repo::note_repo;

// ── DTOs ─────────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub struct NoteListQuery {
    #[serde(default = "default_page")]
    pub page:  i64,
    #[serde(default = "default_limit")]
    pub limit: i64,
}

fn default_page()  -> i64 { 1 }
fn default_limit() -> i64 { 20 }

#[derive(Deserialize, Validate)]
pub struct CreateNoteRequest {
    pub title:       Option<String>,
    #[validate(length(min = 1, message = "笔记内容不能为空"))]
    pub content:     String,
    pub category:    Option<String>,
    pub source_type: Option<String>,
    pub source_id:   Option<Uuid>,
}

#[derive(Deserialize)]
pub struct UpdateNoteRequest {
    pub title:    Option<String>,
    pub content:  Option<String>,
    pub category: Option<String>,
}

#[derive(Serialize)]
pub struct NoteResponse {
    pub id:          Uuid,
    pub title:       Option<String>,
    pub content:     String,
    pub category:    Option<String>,
    pub source_type: Option<String>,
    pub source_id:   Option<Uuid>,
    pub created_at:  DateTime<Utc>,
    pub updated_at:  DateTime<Utc>,
}

impl From<note_repo::LearningNote> for NoteResponse {
    fn from(n: note_repo::LearningNote) -> Self {
        Self {
            id: n.id, title: n.title, content: n.content, category: n.category,
            source_type: n.source_type, source_id: n.source_id,
            created_at: n.created_at, updated_at: n.updated_at,
        }
    }
}

// ── Handlers ─────────────────────────────────────────────────────────────────

pub async fn list_notes(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Query(q): Query<NoteListQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit  = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let items: Vec<NoteResponse> = note_repo::list(&state.db, current_user.id, limit, offset)
        .await?
        .into_iter()
        .map(NoteResponse::from)
        .collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total:    items.len() as i64,
        page:     q.page,
        limit,
        items,
    }))
}

pub async fn create_note(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CreateNoteRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;
    let note = note_repo::create(
        &state.db,
        current_user.id,
        payload.title.as_deref(),
        &payload.content,
        payload.category.as_deref(),
        payload.source_type.as_deref(),
        payload.source_id,
    )
    .await?;
    Ok(ApiResponse::ok(NoteResponse::from(note)))
}

pub async fn get_note(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let note = note_repo::get(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::ok(NoteResponse::from(note)))
}

pub async fn update_note(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateNoteRequest>,
) -> Result<impl IntoResponse, AppError> {
    let note = note_repo::update(
        &state.db,
        id,
        current_user.id,
        payload.title.as_deref(),
        payload.content.as_deref(),
        payload.category.as_deref(),
    )
    .await?;
    Ok(ApiResponse::ok(NoteResponse::from(note)))
}

pub async fn delete_note(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    note_repo::delete(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::<()>::ok_empty())
}
