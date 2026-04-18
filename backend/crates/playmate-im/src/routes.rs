//! IM 模块路由注册

use axum::{
    routing::get,
    Router,
};

use playmate_common::AppState;

use crate::handler;

pub fn im_routes() -> Router<AppState> {
    Router::new()
        .route("/ws", get(handler::ws_handler))
        .route("/conversations", get(handler::list_conversations).post(handler::create_conversation))
        .route("/conversations/:id/messages", get(handler::list_messages))
        .route("/groups", get(handler::list_group_sessions))
        .route("/groups/:id/messages", get(handler::list_group_messages))
}
