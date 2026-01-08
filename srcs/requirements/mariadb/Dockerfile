FROM debian:bookworm-slim

# Install MariaDB server
RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user (subject about PID 1)
RUN mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:root /var/lib/mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld

# Copy entrypoint script (creates DB/users from .env)
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose MariaDB port
EXPOSE 3306

# Run entrypoint as root for proper initialization
ENTRYPOINT ["/entrypoint.sh"]