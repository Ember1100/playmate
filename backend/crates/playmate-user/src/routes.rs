//! 用户模块路由注册

use axum::{
    routing::{get, post},
    Router,
};

use playmate_common::AppState;

use crate::handler::{auth, profile, tag};

/// 认证相关路由（无需 JWT）
pub fn auth_routes() -> Router<AppState> {
    Router::new()
        .route("/register",      post(auth::register))
        .route("/login",         post(auth::login))
        .route("/sms/send",      post(auth::send_sms))
        .route("/sms/verify",    post(auth::verify_sms))
        .route("/wechat/login",  post(auth::wechat_login))
        .route("/refresh",       post(auth::refresh))
        .route("/logout",        post(auth::logout))
}

/// 用户 Profile 路由（需要 JWT）
pub fn user_routes() -> Router<AppState> {
    Router::new()
        .route("/me",            get(profile::get_me).put(profile::update_me))
        .route("/me/tags",       get(tag::get_my_tags).put(tag::set_my_tags))
        .route("/:id",           get(profile::get_user))
}

/// 标签路由（公开）
pub fn tag_routes() -> Router<AppState> {
    Router::new()
        .route("/",              get(tag::list_tags))
}
