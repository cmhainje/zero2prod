FROM lukemathwalker/cargo-chef:latest-rust-1.63.0 AS chef
WORKDIR /app
RUN apt update && apt install lld clang -y

FROM chef AS planner
COPY . .
# Compute a lock-file for our project
RUN cargo chef prepare --recipe-path recipe.json

# Builder stage
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build project dependencies and cache them
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
ENV SQLX_OFFLINE true
# Build project
RUN cargo build --release --bin zero2prod

# Runtime stage
# FROM rust:1.63.0-slim AS runtime  <- this works out of the box (no apt-get necessary) but is ~10x heavier
FROM debian:bullseye-slim AS runtime
WORKDIR /app
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/zero2prod zero2prod
COPY configuration configuration
ENV APP_ENVIRONMENT production
ENTRYPOINT ["./target/release/zero2prod"]