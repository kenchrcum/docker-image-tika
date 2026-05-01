# syntax=docker/dockerfile:1

# ── Stage 1: Download & Verify ──────────────────────────────────────────────
FROM alpine:3.23.3 AS downloader

ARG TIKA_VERSION=3.3.0

# hadolint ignore=DL3018,DL4006
RUN apk add --no-cache wget gnupg ca-certificates \
    && wget -qO- https://downloads.apache.org/tika/KEYS | gpg --import \
    && wget --no-verbose \
         "https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar" \
         -O /tika-server.jar \
    && wget --no-verbose \
         "https://archive.apache.org/dist/tika/${TIKA_VERSION}/tika-server-standard-${TIKA_VERSION}.jar.asc" \
         -O /tika-server.jar.asc \
    && gpg --verify /tika-server.jar.asc /tika-server.jar

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:25.0.3_9-jre-alpine-3.23 AS runtime

ARG TIKA_VERSION=3.3.0
ENV TIKA_VERSION=${TIKA_VERSION}

# Non-root user matching Helm chart expectations (UID/GID 35002)
RUN addgroup -g 35002 tika && adduser -u 35002 -G tika -D -h /home/tika tika \
    && mkdir -p /tika-extras /tika-config \
    && chown tika:tika /tika-extras /tika-config

COPY --from=downloader /tika-server.jar /tika-server-standard-${TIKA_VERSION}.jar
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/healthcheck.sh /healthcheck.sh
RUN chmod +x /entrypoint.sh /healthcheck.sh

USER 35002:35002
EXPOSE 9998

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["/healthcheck.sh"]

ENTRYPOINT ["/entrypoint.sh"]

LABEL org.opencontainers.image.title="Apache Tika Server (Minimal)" \
      org.opencontainers.image.description="Apache Tika document analysis server — minimal variant" \
      org.opencontainers.image.version="${TIKA_VERSION}" \
      org.opencontainers.image.vendor="kenchrcum" \
      org.opencontainers.image.source="https://github.com/kenchrcum/docker-image-tika" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="eclipse-temurin:21-jre-alpine"
