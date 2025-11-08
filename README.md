# Zensical Docker Image (Unofficial)

[![Build](https://github.com/joshooaj/zensical-image/actions/workflows/ci.yml/badge.svg)](https://github.com/joshooaj/zensical-image/actions/workflows/ci.yml)
![Docker Image Version](https://img.shields.io/docker/v/joshooaj/zensical)
![GitHub License](https://img.shields.io/github/license/joshooaj/zensical-image)

![Screenshot of default Zensical site](https://raw.githubusercontent.com/joshooaj/zensical-image/main/default-site.png)

This is an unofficial [Zensical](https://zensical.org/) container image for building and publishing
static sites using content authored in markdown format. Zensical is a new SSG built by same folks
behind the popular [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) theme.

## Quick start

If you already use Python, it is _very easy_ to install and use Zensical container-free. However, if
you're like me and prefer to run as many tools as possible in a container for security, and
consistent reproducibility, feel free to use this image to scaffold and build your Zensical sites.
Until there's an official first-party image published by Zensical anyway, then definitely use that
one.

```bash
# Pull the image and/or check the version
docker run --rm joshooaj/zensical --version

# Create a new Zensical site in the subfolder "mysite"
docker run --rm -v ./mysite:/docs joshooaj/zensical new

# Serve the site
docker run --rm -v ./mysite:/docs -p 8000:8000 joshooaj/zensical

# Build site (output in ./mysite/site/)
docker run --rm -v ./mysite:/docs joshooaj/zensical build

# Build site with clean cache (output in ./mysite/site/)
docker run --rm -v ./mysite:/docs joshooaj/zensical build --clean
```

### NOTICE

If you're using Docker Desktop on Windows, there's an issue with the way linux containers detect
file changes when those changes are made from outside the container. Consider using a devcontainer
for a better live editing experience if you're on Windows.

## Docker Compose

### Create a site if you don't have one already

```bash
# Create a new Zensical site in the subfolder "mysite"
docker run --rm -v ./mysite:/docs joshooaj/zensical new
```

### Create `compose.yml`

```yaml
services:
  zensical:
    image: joshooaj/zensical:latest
    ports:
      - "8000:8000"
    volumes:
      - ./mysite:/docs
```

### Start it up

```bash
docker compose up -d
```
