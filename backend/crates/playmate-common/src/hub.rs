//! WebSocket 全局连接注册表
//!
//! # 功能
//! - 以 user_id + conn_id 为键管理活跃 WebSocket 发送通道
//! - 同一用户可同时持有多条连接（多端登录）
//! - 有界 channel（512 条）防止慢消费者导致 OOM

use std::sync::Arc;

use dashmap::DashMap;
use tokio::sync::mpsc;
use uuid::Uuid;

/// 发送通道（有界，防 OOM）
pub type WsSender = mpsc::Sender<String>;

pub struct ConnectionHub {
    /// user_id → { conn_id → WsSender }
    connections: DashMap<Uuid, DashMap<Uuid, WsSender>>,
}

impl ConnectionHub {
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            connections: DashMap::new(),
        })
    }

    /// 注册一条新连接，返回本次连接的 conn_id（调用方需保存用于注销）
    pub fn register(&self, user_id: Uuid, tx: WsSender) -> Uuid {
        let conn_id = Uuid::new_v4();
        self.connections
            .entry(user_id)
            .or_insert_with(DashMap::new)
            .insert(conn_id, tx);
        conn_id
    }

    /// 注销指定连接；若该用户无其他连接则一并清理外层 entry
    pub fn unregister(&self, user_id: &Uuid, conn_id: &Uuid) {
        if let Some(conns) = self.connections.get(user_id) {
            conns.remove(conn_id);
            if conns.is_empty() {
                drop(conns); // 释放读锁后再 remove 外层
                self.connections.remove(user_id);
            }
        }
    }

    /// 向该用户的所有在线端广播同一条消息，返回成功入队的连接数
    pub fn send_to(&self, user_id: &Uuid, msg: String) -> usize {
        let Some(conns) = self.connections.get(user_id) else {
            return 0;
        };
        let mut ok = 0usize;
        for entry in conns.iter() {
            if entry.value().try_send(msg.clone()).is_ok() {
                ok += 1;
            }
        }
        ok
    }

    pub fn is_connected(&self, user_id: &Uuid) -> bool {
        self.connections
            .get(user_id)
            .map(|c| !c.is_empty())
            .unwrap_or(false)
    }
}

impl Default for ConnectionHub {
    fn default() -> Self {
        Self {
            connections: DashMap::new(),
        }
    }
}
