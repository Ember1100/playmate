//! 数据库连接池
//!
//! # 功能
//! - 创建 PgPool 连接池（返回 Result，启动失败可优雅退出）
//! - 运行 SQLx 数据库迁移

use sqlx::PgPool;

/// 创建数据库连接池，失败时返回 Err（不 panic）
pub async fn create_pool(database_url: &str) -> anyhow::Result<PgPool> {
    let pool = sqlx::PgPool::connect(database_url)
        .await
        .map_err(|e| anyhow::anyhow!("数据库连接失败: {}", e))?;
    Ok(pool)
}

/// 运行所有待执行的 SQLx 迁移文件
pub async fn run_migrations(pool: &PgPool) -> anyhow::Result<()> {
    sqlx::migrate!("../../../infra/migrations")
        .run(pool)
        .await
        .map_err(|e| anyhow::anyhow!("数据库迁移失败: {}", e))?;
    Ok(())
}
