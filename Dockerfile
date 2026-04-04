# ─── 阶段 1：依赖预热（cargo-chef 缓存）──────────────────────────────────────
FROM lukemathwalker/cargo-chef:latest-rust-1 AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# ─── 阶段 2：编译依赖（仅 recipe.json 变化才重跑）────────────────────────────
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

# 编译业务代码
COPY . .
RUN cargo build --release --bin playmate-gateway

# ─── 阶段 3：最小运行镜像 ──────────────────────────────────────────────────────
FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/playmate-gateway /usr/local/bin/playmate-gateway

EXPOSE 8080

# 健康检查：依赖 /health 端点
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -fsS http://localhost:8080/health | grep -q '"status":"ok"' || exit 1

CMD ["playmate-gateway"]
