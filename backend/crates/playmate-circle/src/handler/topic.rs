//! 话题 HTTP Handler
//!
//! # 路由
//! - GET    /api/v1/topics
//! - POST   /api/v1/topics
//! - GET    /api/v1/topics/:id
//! - DELETE /api/v1/topics/:id
//! - POST   /api/v1/topics/:id/like
//! - DELETE /api/v1/topics/:id/like
//! - GET    /api/v1/topics/:id/comments
//! - POST   /api/v1/topics/:id/comments
//! - DELETE /api/v1/topics/comments/:comment_id

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
    dto::{
        CommentResponse, CreateCommentRequest, CreateTopicRequest, ListCommentsQuery,
        ListTopicsQuery, TopicResponse,
    },
    repo::topic_repo,
};

/// 获取话题列表
pub async fn list_topics(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Query(q): Query<ListTopicsQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let topics = topic_repo::list_topics(
        &state.db,
        q.category.as_deref(),
        limit,
        offset,
    )
    .await?;
    let items: Vec<TopicResponse> = topics.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}

/// 发布话题
pub async fn create_topic(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CreateTopicRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    let topic = topic_repo::create_topic(
        &state.db,
        current_user.id,
        &payload.title,
        payload.content.as_deref(),
        payload.cover_url.as_deref(),
        payload.category.as_deref(),
    )
    .await?;

    Ok(ApiResponse::ok(TopicResponse::from(topic)))
}

/// 获取话题详情
pub async fn get_topic(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let topic = topic_repo::get_topic(&state.db, id).await?;
    Ok(ApiResponse::ok(TopicResponse::from(topic)))
}

/// 删除话题（仅创建者）
pub async fn delete_topic(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    topic_repo::delete_topic(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}

/// 点赞话题
pub async fn like_topic(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    topic_repo::like_topic(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}

/// 取消点赞
pub async fn unlike_topic(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    topic_repo::unlike_topic(&state.db, id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}

/// 获取话题评论列表
pub async fn list_comments(
    State(state): State<AppState>,
    _current_user: CurrentUser,
    Path(id): Path<Uuid>,
    Query(q): Query<ListCommentsQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let comments = topic_repo::list_comments(&state.db, id, limit, offset).await?;
    let items: Vec<CommentResponse> = comments.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: items.len() as i64 == limit,
        total: items.len() as i64,
        page: q.page,
        limit,
        items,
    }))
}

/// 发布评论
pub async fn create_comment(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<CreateCommentRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;

    let comment = topic_repo::create_comment(
        &state.db,
        id,
        current_user.id,
        payload.parent_id,
        &payload.content,
    )
    .await?;

    Ok(ApiResponse::ok(CommentResponse::from(comment)))
}

/// 删除评论（仅作者）
pub async fn delete_comment(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(comment_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    topic_repo::delete_comment(&state.db, comment_id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}
