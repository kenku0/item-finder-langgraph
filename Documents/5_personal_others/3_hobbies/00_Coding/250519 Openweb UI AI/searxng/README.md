# SearXNG for OpenWebUI

A lightweight, privacy-respecting metasearch engine configuration optimized for integration with OpenWebUI. This repository provides a pre-configured SearXNG instance that works seamlessly with OpenWebUI's AI assistant capabilities.

## Features

- **Privacy-First**: No tracking, no profiling, no data collection
- **Optimized Configuration**: Pre-configured with Brave, Wikipedia, and Reddit engines
- **OpenWebUI Integration**: Designed to work seamlessly with OpenWebUI's search capabilities
- **Docker Support**: Easy deployment with Docker and Docker Compose
- **Customizable**: Simple configuration through `settings.yml`
- **Image Proxy**: Built-in image proxy for enhanced privacy
- **JSON API**: RESTful API for programmatic access

## Prerequisites

- Docker and Docker Compose (recommended)
- Python 3.8+ (for manual installation)
- Git

## Quick Start

### Using Docker Compose (Recommended)

1. Clone the repository:
```bash
git clone https://github.com/kenku0/searxng-openwebui.git
cd searxng-openwebui
```

2. Start the services:
```bash
docker-compose up -d
```

3. Access SearXNG at `http://localhost:8080`

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/kenku0/searxng-openwebui.git
cd searxng-openwebui
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install SearXNG:
```bash
git clone https://github.com/searxng/searxng.git searxng-src
cd searxng-src
pip install -e .
cd ..
```

4. Copy configuration files:
```bash
cp settings.yml searxng-src/searx/settings.yml
cp limiter.toml searxng-src/limiter.toml
cp uwsgi.ini searxng-src/uwsgi.ini
```

5. Run SearXNG:
```bash
cd searxng-src
python searx/webapp.py
```

## Integration with OpenWebUI

### Method 1: Docker Network

If you're running OpenWebUI in Docker:

```bash
# Create a shared network
docker network create openwebui-network

# Run SearXNG
docker-compose up -d

# Connect SearXNG to the network
docker network connect openwebui-network searxng-openwebui

# In OpenWebUI, use http://searxng-openwebui:8080 as the search endpoint
```

### Method 2: Direct Connection

Configure OpenWebUI to use your SearXNG instance:

1. In OpenWebUI settings, navigate to Search Configuration
2. Set the search endpoint to: `http://localhost:8080`
3. Enable JSON format for search results

## Configuration

### Search Engines

The default configuration includes:
- **Brave**: General web search
- **Wikipedia**: Encyclopedia queries
- **Reddit**: Community discussions

To add more engines, edit `settings.yml`:

```yaml
use_default_settings:
  engines:
    keep_only:
      - brave
      - wikipedia
      - reddit
      - duckduckgo  # Add more engines
      - google
```

### Security

**Important**: Change the secret key in production!

```yaml
server:
  secret_key: "YOUR_SECRET_KEY_HERE"
```

Generate a new secret key:
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

### Performance Tuning

Adjust timeout and connection settings in `settings.yml`:

```yaml
outgoing:
  request_timeout: 6.0
  max_request_timeout: 10.0
  pool_connections: 50
  pool_maxsize: 10
```

## API Usage

### Basic Search

```bash
# HTML format
curl "http://localhost:8080/search?q=openai&format=html"

# JSON format (for OpenWebUI integration)
curl "http://localhost:8080/search?q=openai&format=json"
```

### Advanced Search

```bash
# Language-specific search
curl "http://localhost:8080/search?q=machine+learning&language=en"

# Category-specific search
curl "http://localhost:8080/search?q=python&categories=it"
```

## Development

### Running Tests

```bash
cd searxng-src
python -m pytest tests/
```

### Adding Custom Engines

1. Create a new engine file in `searxng-src/searx/engines/`
2. Register it in `settings.yml`
3. Restart the service

## Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Change the port in settings.yml
   server:
     port: 8081
   ```

2. **Search engines not responding**
   - Check your internet connection
   - Verify engine availability
   - Increase timeout values

3. **OpenWebUI connection issues**
   - Ensure both services are on the same network
   - Check firewall settings
   - Verify the endpoint URL

### Logs

View logs for debugging:
```bash
# Docker
docker-compose logs -f

# Manual installation
tail -f searxng.log
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Reporting Issues

- Use the GitHub issue tracker
- Include your configuration (without secrets)
- Provide steps to reproduce

## Security Considerations

- Always use HTTPS in production
- Regularly update dependencies
- Monitor rate limits to prevent abuse
- Configure appropriate access controls

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [SearXNG](https://github.com/searxng/searxng) - The privacy-respecting metasearch engine
- [OpenWebUI](https://github.com/open-webui/open-webui) - The AI-powered web interface
- All contributors and maintainers

## Support

- **Issues**: [GitHub Issues](https://github.com/kenku0/searxng-openwebui/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kenku0/searxng-openwebui/discussions)
- **Wiki**: [Project Wiki](https://github.com/kenku0/searxng-openwebui/wiki)

---

Made with ❤️ for the privacy-conscious AI community