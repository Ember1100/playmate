//! WebSocket 全局连接注册表
//!
//! # 功能
//! - 以 user_id 为键管理活跃 WebSocket 发送通道
//! - 有界 channel（512 条）防止慢消费者导致 OOM

use std::sync::Arc;

use dashmap::DashMap;
use tokio::sync::mpsc;
use uuid::Uuid;

/// 发送通道（有界，防 OOM）
pub type WsSender = mpsc::Sender<String>;

pub struct ConnectionHub {
    connections: DashMap<Uuid, WsSender>,
}

impl ConnectionHub {
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            connections: DashMap::new(),
        })
    }

    pub fn register(&self, user_id: Uuid, tx: WsSender) {
        self.connections.insert(user_id, tx);
    }

    pub fn unregister(&self, user_id: &Uuid) {
        self.connections.remove(user_id);
    }

    /// 非阻塞推送：通道满或用户离线时静默丢弃，返回是否入队成功
    pub fn send_to(&self, user_id: &Uuid, msg: String) -> bool {
        if let Some(tx) = self.connections.get(user_id) {
            tx.try_send(msg).is_ok()
        } else {
            false
        }
    }

    pub fn is_connected(&self, user_id: &Uuid) -> bool {
        self.connections.contains_key(user_id)
    }
}

impl Default for ConnectionHub {
    fn default() -> Self {
        Self {
            connections: DashMap::new(),
        }
    }
}
