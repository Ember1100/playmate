//! Playmate API Gateway
//!
//! 启动顺序：加载配置 → 连接 DB/Redis → 运行迁移 → 启动 HTTP 服务
//! 关闭顺序：收到 SIGTERM/Ctrl-C → 停止接受新连接 → 等待已有请求完成

use std::sync::Arc;

use axum::{
    extract::State,
    http::{Method, StatusCode},
    response::IntoResponse,
    routing::get,
    Json, Router,
};
use serde_json::json;
use tower_http::{
    cors::{Any, CorsLayer},
    trace::TraceLayer,
};
use tracing::info;

use playmate_common::{
    config::AppConfig,
    db::{create_pool, run_migrations},
    hub::ConnectionHub,
    state::AppState,
    StorageService,
};

mod upload;

// ── 健康检查 ─────────────────────────────────────────────────────────────────

async fn health(State(state): State<AppState>) -> impl IntoResponse {
    // 检查数据库
    let db_ok = sqlx::query("SELECT 1")
        .fetch_one(&state.db)
        .await
        .is_ok();

    // 检查 Redis
    let redis_ok = {
        let mut conn = state.redis.clone();
        redis::cmd("PING")
            .query_async::<_, String>(&mut conn)
            .await
            .map_or(false, |s| s == "PONG")
    };

    let status = if db_ok && redis_ok {
        StatusCode::OK
    } else {
        StatusCode::SERVICE_UNAVAILABLE
    };

    (
        status,
        Json(json!({
            "status": if db_ok && redis_ok { "ok" } else { "degraded" },
            "db":    db_ok,
            "redis": redis_ok,
        })),
    )
}

// ── 优雅关闭信号 ──────────────────────────────────────────────────────────────

async fn shutdown_signal() {
    use tokio::signal;

    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c    => { tracing::info!("收到 Ctrl-C，开始优雅关闭") },
        _ = terminate => { tracing::info!("收到 SIGTERM，开始优雅关闭") },
    }
}

// ── 主函数 ────────────────────────────────────────────────────────────────────

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let _ = dotenvy::dotenv();

    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "playmate=info,tower_http=info,sqlx=warn".into()),
        )
        .init();

    info!("Playmate gateway starting...");

    // ── 配置加载（含校验）──────────────────────────────────────────────────
    let config = AppConfig::from_env()?;
    let addr = format!("{}:{}", config.server_host, config.server_port);

    // ── 数据库 ────────────────────────────────────────────────────────────
    let db = create_pool(&config.database_url).await?;
    info!("数据库连接成功，运行迁移...");
    run_migrations(&db).await?;
    info!("数据库迁移完成");

    // ── Redis ─────────────────────────────────────────────────────────────
    let redis_client = redis::Client::open(config.redis_url.clone())
        .map_err(|e| anyhow::anyhow!("Redis 配置错误: {}", e))?;
    let redis = redis::aio::ConnectionManager::new(redis_client)
        .await
        .map_err(|e| anyhow::anyhow!("Redis 连接失败: {}", e))?;

    let storage = Arc::new(StorageService::from_config(&config).await);

    let state = AppState {
        db,
        redis,
        config: Arc::new(config),
        hub: ConnectionHub::new(),
        storage,
    };

    // ── CORS ──────────────────────────────────────────────────────────────
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PUT,
            Method::DELETE,
            Method::OPTIONS,
        ])
        .allow_headers(Any);

    // ── 路由 ──────────────────────────────────────────────────────────────
    let app = Router::new()
        .route("/health", get(health))
        .nest("/api/v1/auth",   playmate_user::auth_routes())
        .nest("/api/v1/users",  playmate_user::user_routes())
        .nest("/api/v1/tags",   playmate_user::tag_routes())
        .nest("/api/v1/im",     playmate_im::im_routes())
        .nest("/api/v1/feed",   playmate_feed::feed_routes())
        .nest("/api/v1/match",  playmate_match::match_routes())
        .nest("/api/v1/upload", upload::upload_routes())
        .with_state(state)
        .layer(cors)
        .layer(TraceLayer::new_for_http());

    // ── 启动 ──────────────────────────────────────────────────────────────
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    info!("Listening on {addr}");

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    info!("服务已安全关闭");
    Ok(())
}
