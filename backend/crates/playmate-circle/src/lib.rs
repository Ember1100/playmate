//! playmate-circle — 圈子模块（话题/投票/评论/社群聊天）
//!
//! # MVP 功能
//! - 话题发布/浏览/点赞/评论
//! - 每日投票（正方/反方）
//! - 社群列表/加入/退出/群消息

mod dto;
mod handler;
mod model;
mod repo;
pub mod routes;

pub use routes::{circle_routes, poll_routes, topic_routes};
