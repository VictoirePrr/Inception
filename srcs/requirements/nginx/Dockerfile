FROM debian:bookworm-slim

# Install Nginx, OpenSSL, and netcat for health checks
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    netcat-openbsd

# Create directories for SSL certificates and nginx config
RUN mkdir -p /etc/nginx/ssl \
    && mkdir -p /etc/nginx/conf.d

# Copy nginx configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint script
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose HTTPS port
EXPOSE 443

# Run entrypoint
ENTRYPOINT ["/entrypoint.sh"]
