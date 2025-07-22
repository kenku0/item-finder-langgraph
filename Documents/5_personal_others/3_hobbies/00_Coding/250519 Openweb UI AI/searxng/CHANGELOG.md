# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of SearXNG for OpenWebUI
- Pre-configured SearXNG instance with Brave, Wikipedia, and Reddit engines
- Docker and Docker Compose support for easy deployment
- Comprehensive documentation and setup instructions
- GitHub Actions workflows for CI/CD
- Security-focused configuration with image proxy enabled
- Integration guide for OpenWebUI
- Contributing guidelines
- MIT License

### Security
- Implemented secure default settings
- Added security headers in Caddy configuration
- Enabled HTTPS support with automatic certificate management
- Configured proper container security settings

## [1.0.0] - 2024-01-XX

### Added
- First stable release
- Production-ready configuration
- Full OpenWebUI integration support
- Redis caching support (optional)
- Health check endpoints
- Multi-architecture Docker images (amd64, arm64)

[Unreleased]: https://github.com/kenku0/searxng-openwebui/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kenku0/searxng-openwebui/releases/tag/v1.0.0