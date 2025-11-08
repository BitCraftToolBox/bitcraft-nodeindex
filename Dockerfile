# Build stage with dependency caching
FROM rust:1.91.0-alpine AS builder
WORKDIR /app

# Install build dependencies for musl
RUN apk add --no-cache \
    musl-dev \
    pkgconfig \
    openssl-dev \
    openssl-libs-static \
    gcc \
    g++ \
    make \
    cmake \
    protobuf-dev \
    perl \
    linux-headers \
    git

# Copy manifests and create dummy source to cache dependencies
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release --target x86_64-unknown-linux-musl && \
    rm -rf src

# Copy actual source and build
COPY src/ ./src/
# Touch main.rs to force rebuild of our code (not deps)
RUN touch src/main.rs && \
    cargo build --release --target x86_64-unknown-linux-musl && \
    strip target/x86_64-unknown-linux-musl/release/nodeindex

# Config generation stage
FROM python:3.9-alpine3.22 AS config
WORKDIR /app
COPY generate.py /app/
RUN python generate.py

# Final runtime stage - minimal Alpine image
FROM alpine:3.22 AS runner

LABEL org.opencontainers.image.source="https://github.com/BitCraftToolBox/bitcraft-nodeindex"
LABEL org.opencontainers.image.description="Node tracking backend for bitcraftmap.com"

# Install only runtime dependencies if needed (likely just ca-certificates for HTTPS)
RUN apk add --no-cache ca-certificates

WORKDIR /app

# Copy the statically linked binary
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/nodeindex /app/
COPY --from=config /app/config.json /app/

# Create non-root user for security
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser && \
    chown -R appuser:appuser /app

USER appuser

CMD ["./nodeindex"]