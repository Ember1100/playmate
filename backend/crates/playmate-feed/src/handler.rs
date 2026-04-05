//! Feed 模块 HTTP Handler
//!
//! # 功能
//! - GET    /api/v1/feed/posts           ← 公开 Feed 列表
//! - POST   /api/v1/feed/posts           ← 发布动态
//! - GET    /api/v1/feed/posts/:id       ← 帖子详情
//! - DELETE /api/v1/feed/posts/:id       ← 删除自己的帖子
//! - POST   /api/v1/feed/posts/:id/like  ← 点赞/取消点赞

use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
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
    dto::{CreatePostRequest, FeedQuery, LikeResponse},
    repository,
};

/// 公开 Feed 列表（分页）
pub async fn list_posts(
    State(state): State<AppState>,
    Query(q): Query<FeedQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let total = repository::count_public_posts(&state.db).await?;
    let posts = repository::list_public_posts_with_user(&state.db, limit, offset).await?;
    let items: Vec<crate::dto::PostResponse> = posts.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: offset + limit < total,
        total,
        page: q.page,
        limit,
        items,
    }))
}

/// 发布动态
///
/// # 错误
/// - `400 BadRequest` - 参数校验失败
pub async fn create_post(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Json(payload): Json<CreatePostRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload
        .validate()
        .map_err(|e| AppError::BadRequest(e.to_string()))?;

    let media_urls = serde_json::to_value(&payload.media_urls)
        .map_err(|e| AppError::Internal(anyhow::anyhow!("序列化失败: {}", e)))?;

    let post = repository::create_post(
        &state.db,
        current_user.id,
        &payload.content,
        media_urls,
        payload.visibility,
    )
    .await?;

    Ok((StatusCode::CREATED, ApiResponse::ok(crate::dto::PostResponse::from(post))))
}

/// 帖子详情
///
/// # 错误
/// - `404 NotFound` - 帖子不存在
pub async fn get_post(
    State(state): State<AppState>,
    Path(post_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let post = repository::find_post_by_id(&state.db, post_id).await?;
    Ok(ApiResponse::ok(crate::dto::PostResponse::from(post)))
}

/// 删除自己的帖子
///
/// # 错误
/// - `401 Unauthorized` - 未登录
/// - `404 NotFound`     - 帖子不存在或非本人发布
pub async fn delete_post(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(post_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    repository::delete_post(&state.db, post_id, current_user.id).await?;
    Ok(ApiResponse::ok_empty())
}

/// 点赞 / 取消点赞（幂等切换）
///
/// # 错误
/// - `404 NotFound` - 帖子不存在
pub async fn toggle_like(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(post_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    // 确认帖子存在
    let _ = repository::find_post_by_id(&state.db, post_id).await?;
    let (liked, like_count) = repository::toggle_like(&state.db, post_id, current_user.id).await?;
    Ok(ApiResponse::ok(LikeResponse { liked, like_count }))
}

/// 获取当前用户自己发布的帖子
pub async fn list_my_posts(
    State(state): State<AppState>,
    Query(q): Query<FeedQuery>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let total = repository::count_my_posts(&state.db, current_user.id).await?;
    let posts = repository::list_my_posts_with_user(&state.db, current_user.id, limit, offset).await?;
    let items: Vec<crate::dto::PostResponse> = posts.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: offset + limit < total,
        total,
        page: q.page,
        limit,
        items,
    }))
}

/// 获取当前用户点赞的帖子
pub async fn list_liked_posts(
    State(state): State<AppState>,
    Query(q): Query<FeedQuery>,
    current_user: CurrentUser,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let total = repository::count_liked_posts(&state.db, current_user.id).await?;
    let posts = repository::list_liked_posts_with_user(&state.db, current_user.id, limit, offset).await?;
    let items: Vec<crate::dto::PostResponse> = posts.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: offset + limit < total,
        total,
        page: q.page,
        limit,
        items,
    }))
}

/// 获取帖子评论列表
pub async fn list_comments(
    State(state): State<AppState>,
    Path(post_id): Path<Uuid>,
    Query(q): Query<FeedQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = q.limit.clamp(1, 50);
    let offset = (q.page - 1) * limit;
    let total = repository::count_comments(&state.db, post_id).await?;
    let comments = repository::list_comments(&state.db, post_id, limit, offset).await?;
    let items: Vec<crate::dto::CommentResponse> = comments.into_iter().map(Into::into).collect();
    Ok(ApiResponse::ok(PageResponse {
        has_more: offset + limit < total,
        total,
        page: q.page,
        limit,
        items,
    }))
}

/// 发表评论
pub async fn create_comment(
    State(state): State<AppState>,
    current_user: CurrentUser,
    Path(post_id): Path<Uuid>,
    Json(payload): Json<crate::dto::CreateCommentRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(|e| AppError::BadRequest(e.to_string()))?;
    let (id, created_at) = repository::create_comment(&state.db, post_id, current_user.id, &payload.content).await?;
    Ok((StatusCode::CREATED, ApiResponse::ok(serde_json::json!({
        "id": id,
        "post_id": post_id,
        "user_id": current_user.id,
        "content": payload.content,
        "created_at": created_at,
    }))))
}
