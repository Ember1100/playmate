//! Match 模块路由注册

use axum::{
    routing::{get, post},
    Router,
};

use playmate_common::AppState;

use crate::handler;

pub fn match_routes() -> Router<AppState> {
    Router::new()
        .route("/candidates", get(handler::get_candidates))
        .route("/respond", post(handler::respond_match))
}
