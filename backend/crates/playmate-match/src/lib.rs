//! playmate-match — 兴趣匹配，推荐算法
//!
//! # 功能
//! - 候选用户查询（排除已匹配/已拒绝）
//! - 匹配分计算（共同标签 + 年龄接近度）
//! - 接受/拒绝匹配，双向匹配后自动创建私聊会话

mod algorithm;
mod dto;
mod handler;
mod model;
mod repository;
pub mod routes;

pub use routes::match_routes;
