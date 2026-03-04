# docker-image-tika

[![Build & Test](https://github.com/kenchrcum/docker-image-tika/actions/workflows/build-test.yml/badge.svg)](https://github.com/kenchrcum/docker-image-tika/actions/workflows/build-test.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-kenchrcum%2Ftika-blue?logo=github)](https://github.com/kenchrcum/docker-image-tika/pkgs/container/tika)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

A modern, hardened Docker image for [Apache Tika Server](https://tika.apache.org/), built as a drop-in replacement for the unmaintained upstream `apache/tika` image.

## Why this image?

| | Upstream (`apache/tika`) | This image |
|---|---|---|
| Base OS | `ubuntu:plucky` (~80 MB) | `eclipse-temurin:21-jre-alpine` (~55 MB) |
| CVEs | Hundreds of unfixed CVEs | Alpine minimal attack surface, regularly rebuilt |
| Java | Ubuntu OpenJDK (irregular updates) | Eclipse Temurin 21 JRE (Adoptium, actively maintained) |
| Health | No `HEALTHCHECK` | Built-in `HEALTHCHECK` via `wget /version` |
| Supply chain | GPG verify only | GPG + Syft SBOM + Cosign signing |
| CI/CD | Manual | GitHub Actions: build, scan, sign, multi-arch push |
| Arch | `linux/amd64` only | `linux/amd64` + `linux/arm64` |

## Image variants

| Tag | Description |
|-----|-------------|
| `ghcr.io/kenchrcum/tika:{version}` | Minimal: JRE + Tika JAR only |
| `ghcr.io/kenchrcum/tika:{version}-full` | Full: adds Tesseract OCR (6 languages), GDAL, ImageMagick, fonts |
| `ghcr.io/kenchrcum/tika:latest` | Latest minimal release |
| `ghcr.io/kenchrcum/tika:latest-full` | Latest full release |

## Quick start

```bash
# Minimal
docker run -p 9998:9998 ghcr.io/kenchrcum/tika:3.2.3

# Full (OCR + GDAL)
docker run -p 9998:9998 ghcr.io/kenchrcum/tika:3.2.3-full

# Verify it's running
curl http://localhost:9998/version
```

### Extract text from a document

```bash
curl -T document.pdf http://localhost:9998/tika
```

### With a custom tika-config.xml

```bash
docker run -p 9998:9998 \
  -v /path/to/tika-config.xml:/tika-config/tika-config.xml:ro \
  ghcr.io/kenchrcum/tika:3.2.3 \
  -c /tika-config/tika-config.xml
```

## Helm chart compatibility

This image is a drop-in replacement for the [kenchrcum/helm-chart-tika](https://github.com/kenchrcum/helm-chart-tika) chart:

```yaml
# values.yaml
image:
  repository: ghcr.io/kenchrcum/tika
  tag: "3.2.3"        # minimal
  # tag: "3.2.3-full" # full (OCR)
```

### Compatibility contract

| Contract | Value |
|---|---|
| UID / GID | `35002:35002` |
| Port | `9998` |
| Health endpoint | `GET /version` → 200 |
| `TIKA_VERSION` env var | Set in image |
| Classpath | `/tika-server-standard-${TIKA_VERSION}.jar:/tika-extras/*` |
| Config mount | `/tika-config/tika-config.xml` (read-only) |
| Extras mount | `/tika-extras/` |
| Read-only root FS | ✅ (writes only to `/tmp`) |

## Configuration

| Environment Variable | Default | Description |
|---|---|---|
| `JAVA_OPTS` | _(empty)_ | Extra JVM flags (e.g. `-Xmx2g -XX:+UseG1GC`) |
| `TIKA_VERSION` | `3.2.3` | Tika version baked into the image |

Additional Tika CLI arguments can be passed as Docker command arguments, e.g.:

```bash
docker run kenchrcum/tika:3.2.3 \
  -c /tika-config/tika-config.xml \
  --cors "*"
```

## Supply chain security

Every release image is:

- **GPG-verified** at build time (the Tika JAR is verified against the Apache KEYS)
- **Signed with Cosign** (keyless, GitHub OIDC — no long-lived keys stored)
- **Accompanied by an SPDX SBOM** attached to the image manifest

### Verify a release

```bash
# Verify signature
cosign verify ghcr.io/kenchrcum/tika:3.2.3 \
  --certificate-identity-regexp="https://github.com/kenchrcum/docker-image-tika/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"

# Download SBOM
cosign download sbom ghcr.io/kenchrcum/tika:3.2.3
```

## Local development

```bash
# Build both images
make build

# Build + functional test (minimal)
make test

# Vulnerability scan (Trivy)
make scan

# Dockerfile lint (Hadolint)
make lint

# Override version
make build TIKA_VERSION=3.2.3
```

Using Docker Compose:

```bash
# Start minimal (default)
docker compose up

# Start full variant
docker compose --profile full up tika-full
```

## Repository structure

```
docker-image-tika/
├── minimal/Dockerfile        # Alpine-based minimal image
├── full/Dockerfile           # Full image (Tesseract, GDAL, fonts)
├── scripts/
│   ├── entrypoint.sh         # Shared entrypoint
│   └── healthcheck.sh        # HEALTHCHECK script
├── .github/workflows/
│   ├── build-test.yml        # PR: build + scan + test
│   └── release.yml           # Tag: multi-arch build + push + sign
├── docker-compose.yml
├── Makefile
├── renovate.json
└── SECURITY.md
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
