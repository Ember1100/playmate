//! playmate-user — 用户注册/登录/Profile/标签
//!
//! # 登录方式
//! - 邮箱 + 密码
//! - 手机号 + 短信验证码（首次自动注册）
//! - 微信 OAuth（首次自动注册 + user_oauth 绑定）
//!
//! # 内部结构
//! - handler/  HTTP 入口（auth / profile / tag）
//! - service/  业务逻辑（auth_service / sms / wechat / token）
//! - model/    数据模型与 DTO（user / auth）
//! - repo/     数据库查询（user_repo）

mod handler;
mod model;
mod repo;
mod service;
pub mod routes;

pub use routes::{auth_routes, tag_routes, user_routes};
