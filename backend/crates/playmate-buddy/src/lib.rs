//! playmate-buddy — 搭子模块（推荐/邀约/职业搭子阵地）
//!
//! # MVP 功能
//! - 搭子候选人推荐
//! - 搭子请求发送/响应
//! - 我的搭子列表
//! - 邀约发送/管理

mod dto;
mod handler;
mod model;
mod repo;
pub mod routes;

pub use routes::buddy_routes;
