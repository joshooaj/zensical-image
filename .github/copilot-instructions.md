# Copilot instructions — Building & Publishing an unofficial Zensical container image

## Purpose

This repository is used to automatically build, test, and publish a Docker image for a tool called
Zensical. Zensical is a static site generator built by the team behind the popular Material for MkDocs
theme for mkdocs.

## Goals

- Use dependabot to automatically create PRs when a new version of Zensical is available.
- When the version of Zensical is updated in `requirements.txt` on the main branch, the CI workflow
  builds and publishes a new container image to Docker Hub.
- Follow best practices for building, tagging, and publishing container images for public use.

## Security

- Do not store Docker credentials in repository files. Use GitHub Secrets.
- Avoid pushing images on PRs from forks — those runs may expose secrets. Configure workflows so push/publish steps only run for trusted runs (push to main or release tags).
- Limit the GitHub Actions permissions for the workflow to the minimum required.
- For reproducibility, pin action versions (e.g., actions/checkout@v4) and Docker base images.

## Tagging and release strategy

- Mirror the version of Zensical used in the image.
- Publish images with both version tags (e.g., `1.2.3`) and `latest` tag.

## Recommended repository settings

- Protect the `main` branch and require reviews for PRs.
- Require status checks to pass before merging (CI build, tests, scan).
- Enable Dependabot for base image and action version updates.
