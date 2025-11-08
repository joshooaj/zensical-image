# Copilot instructions — Building & Publishing a Zensical site Docker image

Purpose
-------
This repository will build, test, and publish a Docker image used to build and publish static websites with Zensical. The image is published to Docker Hub by a GitHub Actions workflow.

Goals
-----
- Provide clear instructions for GitHub Actions to build, test, and publish the image.
- Follow public-container best practices (small, reproducible images; non-root runtime; clear labels; secure secrets handling; signed images and scanning).

Prerequisites
-------------
- A Docker Hub account and repository (e.g. `dockerhub_username/zensical`).
- GitHub repository with the source for this image.
- GitHub Secrets configured in the repo:
  - `DOCKERHUB_USERNAME` — Docker Hub username.
  - `DOCKERHUB_TOKEN` — Docker Hub access token or password (use token when possible).
  - (Optional) `IMAGE_NAME` — image name to publish. If omitted, the workflow falls back to a default.

High-level workflow
-------------------
- Build using Docker Buildx (multi-platform capable).
- Run lightweight tests (lint, smoke test the generated site) inside CI.
- Scan the final image for vulnerabilities (e.g., Trivy) and fail the build on high-severity issues when desired.
- Push image only for protected branches (e.g., `main`) and on release tags — avoid pushing from forked PRs.
- Sign the image (optional but recommended) with cosign and publish provenance.

Best practices (short checklist)
-------------------------------
- Use multi-stage builds to keep runtime images minimal.
- Prefer smaller base images (alpine/distroless) for runtime.
- Run the app as a non-root user in the final image.
- Pin base image versions and tool versions in the Dockerfile.
- Keep build secrets out of image layers (use build args, Docker BuildKit secret mounts when needed).
- Add standard OCI labels (org.opencontainers.image.*) and license information.
- Use build cache (GitHub Actions cache or registry cache) to speed repeated builds.
- Scan and sign images before publishing.
- Only publish from trusted branches or CI runs with appropriate permissions.
- Use immutable tags (semver and/or git tags) and publish `latest` only when appropriate.

Example Dockerfile (multi-stage)
--------------------------------
This is a minimal example of a builder image that builds a Zensical static site and produces a minimal runtime image (served by nginx). Adjust the steps to match your real build commands and Zensical CLI usage.

```dockerfile
# ---- builder ----
FROM node:20-alpine AS builder
WORKDIR /app

# install any native build deps if needed
RUN apk add --no-cache git ca-certificates

# copy sources and install
COPY package.json package-lock.json ./
RUN npm ci --silent

# copy rest and run the zensical build (replace with actual build command)
COPY . .
RUN npx zensical build --output ./out

# ---- runtime ----
FROM nginx:alpine AS runtime
LABEL org.opencontainers.image.source="https://github.com/<your-org>/<your-repo>"
LABEL org.opencontainers.image.license="MIT"

# Use a non-root user where possible (nginx alpine runs as nginx user)
COPY --from=builder /app/out /usr/share/nginx/html:ro

EXPOSE 80
USER nginx

CMD ["/usr/sbin/nginx","-g","daemon off;"]
```

Notes about the example
-----------------------
- Replace `npx zensical build` with your project's actual build commands.
- If you need binaries not present in Alpine, consider an intermediate build image (debian/bullseye-slim) and copy artifacts to a distroless or alpine runtime.

Sample GitHub Actions workflow
------------------------------
Below is a sample workflow named `docker-publish.yml` that demonstrates building, testing, scanning, and publishing a Docker image to Docker Hub. It:
- Only pushes on `main` branch pushes and when a tag is created (typical release flow).
- Uses Buildx and cache-from to speed builds.
- Runs a simple smoke test by launching the image and curling the site.

```yaml
name: Build, test, and publish Docker image

on:
  push:
    branches: [ 'main' ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ 'main' ]

permissions:
  contents: read
  id-token: write

jobs:
  build-and-publish:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          platforms: linux/amd64,linux/arm64
          tags: |
            ${{ secrets.DOCKERHUB_USERNAME }}/zensical:latest
            ${{ secrets.DOCKERHUB_USERNAME }}/zensical:${{ github.sha }}
            ${{ secrets.DOCKERHUB_USERNAME }}/zensical:${{ github.ref_name }}
          labels: |
            org.opencontainers.image.revision=${{ github.sha }}
            org.opencontainers.image.source=${{ github.server_url }}/${{ github.repository }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Run quick smoke test
        # a short, best-effort test: start container and curl
        run: |
          img=${{ secrets.DOCKERHUB_USERNAME }}/zensical:${{ github.sha }}
          docker run -d --rm -p 8080:80 --name zensical-smoke $img || exit 1
          # allow the server to come up
          for i in {1..10}; do
            if curl -sSf http://localhost:8080 >/dev/null; then
              break
            fi
            sleep 1
          done
          docker ps -a
          curl -sSf http://localhost:8080 || (docker logs zensical-smoke && exit 1)
          docker stop zensical-smoke

      - name: Optionally scan image with Trivy
        if: success()
        uses: aquasecurity/trivy-action@v1
        with:
          image-ref: ${{ secrets.DOCKERHUB_USERNAME }}/zensical:${{ github.sha }}

      - name: (Optional) Sign image with cosign
        if: success() && github.ref_type == 'tag'
        run: |
          # This assumes COSIGN_PASSWORD and COSIGN_PRIVATE_KEY are in secrets and cosign is available
          echo "$COSIGN_PASSWORD" | cosign sign --key ${{ secrets.COSIGN_KEY_REF }} ${{ secrets.DOCKERHUB_USERNAME }}/zensical:${{ github.ref_name }}

```

Security & CI notes
--------------------
- Do not store Docker credentials in repository files. Use GitHub Secrets.
- Avoid pushing images on PRs from forks — those runs may expose secrets. Configure workflows so push/publish steps only run for trusted runs (push to main or release tags).
- Limit the GitHub Actions permissions for the workflow to the minimum required.
- Use image scanning (Trivy) and fail builds for critical vulnerabilities when appropriate.
- For reproducibility, pin action versions (e.g., actions/checkout@v4) and Docker base images.

Tagging and release strategy
---------------------------
- Use semantic versions for releases (e.g., `v1.2.3` tags). Push images with both the semver tag and the immutable digest.
- Keep `latest` for convenience but prefer digests in production deployments:

```sh
# build locally
docker build -t dockerhub_username/zensical:1.2.3 .
docker push dockerhub_username/zensical:1.2.3
# get digest
docker pull dockerhub_username/zensical:1.2.3
docker inspect --format='{{index .RepoDigests 0}}' dockerhub_username/zensical:1.2.3
```

Recommended repository settings
-------------------------------
- Protect the `main` branch and require reviews for PRs.
- Require status checks to pass before merging (CI build, tests, scan).
- Enable Dependabot for base image and action version updates.

---
Created by Copilot instructions generator — adjust values (image name, repo, build commands) to match your project.
