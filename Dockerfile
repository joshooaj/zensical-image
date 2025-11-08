ARG BASE_IMAGE="python:3.14-slim"
FROM ${BASE_IMAGE}

ARG ZENSICAL_VERSION="0.0.5"

LABEL org.opencontainers.image.title="Zensical"
LABEL org.opencontainers.image.description="A modern static site generator built by the creators of Material for MkDocs"
LABEL org.opencontainers.image.documentation="https://zensical.org/docs/get-started/"
LABEL org.opencontainers.image.source="https://github.com/joshooaj/zensical-image"
LABEL org.opencontainers.image.url="https://github.com/joshooaj/zensical-image"
LABEL org.opencontainers.image.vendor="joshooaj"
LABEL org.opencontainers.image.version="${ZENSICAL_VERSION}"
LABEL org.opencontainers.image.license="MIT"

RUN groupadd -r zensical && useradd -r -g zensical -m -d /home/zensical zensical

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/* \
    && pip install --upgrade pip \
    && pip install --no-cache-dir zensical==${ZENSICAL_VERSION} \
    && mkdir -p /docs \
    && zensical new /docs \
    && chown -R zensical:zensical /docs /home/zensical

USER zensical
WORKDIR /docs

VOLUME ["/docs"]
EXPOSE 8000/tcp

ENTRYPOINT ["zensical"]
CMD ["serve", "-a", "0.0.0.0:8000"]
