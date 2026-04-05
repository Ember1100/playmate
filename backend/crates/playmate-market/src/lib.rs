//! playmate-market — 集市模块（失物招领/二手闲置/兼职啦/以物换物）
//!
//! # MVP 功能
//! - 失物招领：发布/浏览/标记找到
//! - 二手闲置：发布/浏览/标记已售
//! - 兼职啦：发布/浏览
//! - 以物换物：发布/浏览
//! - 收藏：添加/取消/我的收藏

mod dto;
mod handler;
mod model;
mod repo;
pub mod routes;

pub use routes::market_routes;
