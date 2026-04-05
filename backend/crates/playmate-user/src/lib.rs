//! playmate-user — 用户认证/Profile/问卷/通知/反馈
//!
//! # 登录方式
//! - 手机号 + 短信验证码（首次自动注册）
//! - 微信 OAuth（首次自动注册 + user_oauth 绑定）
//!
//! # 内部结构
//! - handler/  HTTP 入口（auth/profile/tag/questionnaire/notification/feedback）
//! - service/  业务逻辑（auth_service/sms/wechat/token）
//! - model/    数据模型与 DTO
//! - repo/     数据库查询

mod handler;
mod model;
mod repo;
mod service;
pub mod routes;

pub use routes::{auth_routes, feedback_routes, note_routes, notification_routes, tag_routes, user_routes};
