FROM rust:1.91.0-bookworm AS builder
WORKDIR /app
COPY Cargo.* /app
COPY src/ ./src
RUN cargo build --release -p nodeindex

FROM python:3.14-bookworm AS config
WORKDIR /app
COPY generate.py /app/
RUN python generate.py

FROM rust:1.91.0-bookworm AS runner
WORKDIR /app
COPY --from=builder /app/target/release/nodeindex /app/
COPY --from=config /app/config.json /app/
CMD ["./nodeindex"]
