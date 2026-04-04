//! 应用全局状态
//!
//! # 功能
//! - AppState 持有数据库连接池、Redis 连接管理器、配置、WebSocket Hub

use std::sync::Arc;

use redis::aio::ConnectionManager;
use sqlx::PgPool;

use crate::{config::AppConfig, hub::ConnectionHub};

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub redis: ConnectionManager,
    pub config: Arc<AppConfig>,
    pub hub: Arc<ConnectionHub>,
}
