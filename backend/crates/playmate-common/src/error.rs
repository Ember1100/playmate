//! 统一错误类型
//!
//! # 功能
//! - 定义 AppError 枚举，覆盖业务、数据库、缓存、认证等错误场景
//! - 实现 IntoResponse，统一输出 JSON 错误体

use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("未授权: {0}")]
    Unauthorized(String),

    #[error("禁止访问: {0}")]
    Forbidden(String),

    #[error("资源未找到: {0}")]
    NotFound(String),

    #[error("请求参数错误: {0}")]
    BadRequest(String),

    #[error("业务错误: {0}")]
    Business(String),

    #[error("数据库错误: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Redis错误: {0}")]
    Redis(#[from] redis::RedisError),

    #[error("内部服务器错误")]
    Internal(#[from] anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, message) = match &self {
            AppError::Unauthorized(msg) => (StatusCode::UNAUTHORIZED, "UNAUTHORIZED", msg.clone()),
            AppError::Forbidden(msg) => (StatusCode::FORBIDDEN, "FORBIDDEN", msg.clone()),
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, "NOT_FOUND", msg.clone()),
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, "BAD_REQUEST", msg.clone()),
            AppError::Business(msg) => (StatusCode::UNPROCESSABLE_ENTITY, "BUSINESS_ERROR", msg.clone()),
            AppError::Database(e) => {
                tracing::error!("数据库错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "DB_ERROR", "数据库错误".to_string())
            }
            AppError::Redis(e) => {
                tracing::error!("Redis错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "CACHE_ERROR", "缓存错误".to_string())
            }
            AppError::Internal(e) => {
                tracing::error!("内部错误: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "服务器内部错误".to_string())
            }
        };

        let body = Json(json!({
            "success": false,
            "code": code,
            "message": message,
            "data": null
        }));

        (status, body).into_response()
    }
}

pub type AppResult<T> = Result<T, AppError>;
