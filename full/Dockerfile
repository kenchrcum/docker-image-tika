# syntax=docker/dockerfile:1

# ── Stage 1: Download & Verify ──────────────────────────────────────────────
FROM alpine:3.23.4 AS downloader

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
FROM eclipse-temurin:21.0.10_7-jre-alpine-3.23 AS runtime

ARG TIKA_VERSION=3.3.0
ENV TIKA_VERSION=${TIKA_VERSION}

# Install OCR, GDAL, ImageMagick, and font dependencies
# Open-source alternatives to Microsoft Core Fonts: DejaVu + Liberation + Noto CJK
# hadolint ignore=DL3018
RUN apk add --no-cache \
      tesseract-ocr \
      tesseract-ocr-data-eng \
      tesseract-ocr-data-fra \
      tesseract-ocr-data-deu \
      tesseract-ocr-data-ita \
      tesseract-ocr-data-spa \
      tesseract-ocr-data-jpn \
      gdal \
      imagemagick \
      fontconfig \
      ttf-dejavu \
      ttf-liberation \
      font-noto-cjk \
      wget \
    && fc-cache -f

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

# Longer start-period for the full image due to heavier runtime initialization
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD ["/healthcheck.sh"]

ENTRYPOINT ["/entrypoint.sh"]

LABEL org.opencontainers.image.title="Apache Tika Server (Full)" \
      org.opencontainers.image.description="Apache Tika document analysis server — full variant with OCR, GDAL, and fonts" \
      org.opencontainers.image.version="${TIKA_VERSION}" \
      org.opencontainers.image.vendor="kenchrcum" \
      org.opencontainers.image.source="https://github.com/kenchrcum/docker-image-tika" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="eclipse-temurin:21-jre-alpine"
