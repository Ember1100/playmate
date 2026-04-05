//! 圈子模块路由注册

use axum::{
    routing::{delete, get, post},
    Router,
};

use playmate_common::AppState;

use crate::handler::{group, poll, topic};

/// 话题路由（注册到 /api/v1/topics）
pub fn topic_routes() -> Router<AppState> {
    Router::new()
        .route("/",                       get(topic::list_topics).post(topic::create_topic))
        .route("/:id",                    get(topic::get_topic).delete(topic::delete_topic))
        .route("/:id/like",               post(topic::like_topic).delete(topic::unlike_topic))
        .route("/:id/comments",           get(topic::list_comments).post(topic::create_comment))
        .route("/comments/:comment_id",   delete(topic::delete_comment))
}

/// 投票路由（注册到 /api/v1/polls）
pub fn poll_routes() -> Router<AppState> {
    Router::new()
        .route("/",           get(poll::list_polls).post(poll::create_poll))
        .route("/:id/vote",   post(poll::vote_poll))
}

/// 社群路由（注册到 /api/v1/circle）
pub fn circle_routes() -> Router<AppState> {
    Router::new()
        .route("/groups",              get(group::list_groups).post(group::create_group))
        .route("/groups/:id",          get(group::get_group))
        .route("/groups/:id/join",     post(group::join_group))
        .route("/groups/:id/leave",    post(group::leave_group))
        .route("/groups/:id/messages", get(group::list_group_messages))
}
