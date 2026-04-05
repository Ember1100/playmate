//! 用户模块路由注册

use axum::{
    routing::{delete, get, post},
    Router,
};

use playmate_common::AppState;

use crate::handler::{auth, feedback, note, notification, profile, questionnaire, tag};

/// 认证路由（无需 JWT）
pub fn auth_routes() -> Router<AppState> {
    Router::new()
        .route("/sms/send",     post(auth::send_sms))
        .route("/sms/verify",   post(auth::verify_sms))
        .route("/wechat/login", post(auth::wechat_login))
        .route("/refresh",      post(auth::refresh))
        .route("/logout",       post(auth::logout))
        .route("/account",      delete(auth::delete_account))
}

/// 用户 Profile 路由（需要 JWT，由 CurrentUser 提取器自动校验）
pub fn user_routes() -> Router<AppState> {
    Router::new()
        .route("/me",                 get(profile::get_me).put(profile::update_me))
        .route("/me/stats",           get(profile::get_my_stats))
        .route("/me/tags",            get(tag::get_my_tags).put(tag::set_my_tags))
        .route("/me/questionnaire",   post(questionnaire::submit_questionnaire))
        .route("/me/career",          get(profile::get_my_career).put(profile::update_my_career))
        .route("/:id",                get(profile::get_user))
        .route("/:id/career",         get(profile::get_user_career))
}

/// 标签路由（公开）
pub fn tag_routes() -> Router<AppState> {
    Router::new()
        .route("/", get(tag::list_tags))
}

/// 通知路由（需要 JWT）
pub fn notification_routes() -> Router<AppState> {
    Router::new()
        .route("/",          get(notification::list_notifications))
        .route("/read-all",  post(notification::read_all))
        .route("/:id/read",  post(notification::read_one))
}

/// 反馈路由（需要 JWT）
pub fn feedback_routes() -> Router<AppState> {
    Router::new()
        .route("/", post(feedback::submit_feedback))
}

/// 学习笔记路由（需要 JWT）
pub fn note_routes() -> Router<AppState> {
    Router::new()
        .route("/",    get(note::list_notes).post(note::create_note))
        .route("/:id", get(note::get_note).put(note::update_note).delete(note::delete_note))
}
