//! playmate-feed — 动态广场，Feed 流
//!
//! # 功能
//! - 发布、查看、删除动态
//! - 公开 Feed 分页列表
//! - 点赞 / 取消点赞（事务幂等）

mod dto;
mod handler;
mod model;
mod repository;
pub mod routes;

pub use routes::feed_routes;
