FROM searxng/searxng:latest

# Install additional dependencies if needed
# RUN apk add --no-cache additional-package

# Copy custom configuration
COPY settings.yml /etc/searxng/settings.yml
COPY limiter.toml /etc/searxng/limiter.toml
COPY uwsgi.ini /etc/searxng/uwsgi.ini

# Set proper permissions
RUN chown -R searxng:searxng /etc/searxng

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -q --spider http://localhost:8080/healthz || exit 1

# Run as non-root user
USER searxng

# Start SearXNG
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/searxng/dockerfiles/docker-entrypoint.sh"]