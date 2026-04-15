TIKA_VERSION ?= 3.2.4
IMAGE_MINIMAL := tika:$(TIKA_VERSION)
IMAGE_FULL    := tika:$(TIKA_VERSION)-full

.PHONY: build-minimal build-full build test scan lint clean help

## build-minimal: Build the minimal Tika image
build-minimal:
	docker build \
	  -f minimal/Dockerfile \
	  --build-arg TIKA_VERSION=$(TIKA_VERSION) \
	  -t $(IMAGE_MINIMAL) \
	  .

## build-full: Build the full Tika image (OCR + GDAL + fonts)
build-full:
	docker build \
	  -f full/Dockerfile \
	  --build-arg TIKA_VERSION=$(TIKA_VERSION) \
	  -t $(IMAGE_FULL) \
	  .

## build: Build both images
build: build-minimal build-full

## test: Build minimal image, start container, run functional tests
test: build-minimal
	@echo "==> Starting Tika container..."
	docker run -d --name tika-test \
	  --read-only \
	  --tmpfs /tmp \
	  -p 9998:9998 \
	  $(IMAGE_MINIMAL)
	@echo "==> Waiting for Tika to start..."
	@for i in $$(seq 1 40); do \
	  if curl -sf http://localhost:9998/version > /dev/null 2>&1; then \
	    echo "==> Tika is ready"; break; \
	  fi; \
	  sleep 1; \
	done
	@echo "==> Version check:"
	curl -sf http://localhost:9998/version | grep -q "$(TIKA_VERSION)" \
	  && echo "  [OK] Version matches $(TIKA_VERSION)" \
	  || (echo "  [FAIL] Version mismatch"; docker logs tika-test; exit 1)
	@echo "==> UID check:"
	docker exec tika-test id | grep -q "uid=35002(tika)" \
	  && echo "  [OK] Running as uid=35002(tika)" \
	  || (echo "  [FAIL] UID mismatch"; exit 1)
	@$(MAKE) _cleanup

## scan: Run Trivy vulnerability scan on both images
scan: build
	@echo "==> Scanning minimal image..."
	docker run --rm \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  aquasec/trivy:latest image \
	  --severity HIGH,CRITICAL \
	  --ignore-unfixed \
	  $(IMAGE_MINIMAL)
	@echo "==> Scanning full image..."
	docker run --rm \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  aquasec/trivy:latest image \
	  --severity HIGH,CRITICAL \
	  --ignore-unfixed \
	  $(IMAGE_FULL)

## lint: Run Hadolint on both Dockerfiles
lint:
	@echo "==> Linting minimal/Dockerfile..."
	docker run --rm -i hadolint/hadolint < minimal/Dockerfile
	@echo "==> Linting full/Dockerfile..."
	docker run --rm -i hadolint/hadolint < full/Dockerfile

## clean: Remove built images and stopped containers
clean: _cleanup
	docker rmi -f $(IMAGE_MINIMAL) $(IMAGE_FULL) 2>/dev/null || true

_cleanup:
	docker stop tika-test 2>/dev/null || true
	docker rm   tika-test 2>/dev/null || true

## help: Show this help message
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
