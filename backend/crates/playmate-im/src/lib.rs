//! playmate-im — 即时通讯，消息存储，会话管理
//!
//! # 功能
//! - WebSocket 实时推送（连接注册、消息广播、心跳）
//! - 会话 CRUD（私聊创建/复用、成员管理）
//! - 消息存储与分页查询

mod dto;
mod handler;
mod model;
mod protocol;
mod repository;
pub mod routes;

pub use routes::im_routes;
