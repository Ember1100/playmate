//! Feed 模块路由注册

use axum::{
    routing::{get, post},
    Router,
};

use playmate_common::AppState;

use crate::handler;

pub fn feed_routes() -> Router<AppState> {
    Router::new()
        .route("/posts", get(handler::list_posts).post(handler::create_post))
        .route("/posts/mine", get(handler::list_my_posts))
        .route("/posts/liked", get(handler::list_liked_posts))
        .route("/posts/:id", get(handler::get_post).delete(handler::delete_post))
        .route("/posts/:id/like", post(handler::toggle_like))
        .route("/posts/:id/comments", get(handler::list_comments).post(handler::create_comment))
}
