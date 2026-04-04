//! 统一 API 响应格式
//!
//! # 功能
//! - ApiResponse<T> 包装所有成功响应
//! - ok() / ok_empty() 快捷构造器

use axum::Json;
use serde::Serialize;

#[derive(Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub code: String,
    pub message: String,
    pub data: Option<T>,
}

impl<T: Serialize> ApiResponse<T> {
    pub fn ok(data: T) -> Json<Self> {
        Json(Self {
            success: true,
            code: "SUCCESS".to_string(),
            message: "成功".to_string(),
            data: Some(data),
        })
    }
}

impl ApiResponse<()> {
    pub fn ok_empty() -> Json<Self> {
        Json(Self {
            success: true,
            code: "SUCCESS".to_string(),
            message: "成功".to_string(),
            data: None,
        })
    }
}

/// 分页响应包装
#[derive(Serialize)]
pub struct PageResponse<T: Serialize> {
    pub items: Vec<T>,
    pub total: i64,
    pub page: i64,
    pub limit: i64,
    pub has_more: bool,
}
