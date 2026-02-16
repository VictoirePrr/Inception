# Developer Documentation - Inception

This document describes how to configure, build, launch, and maintain the Inception infrastructure from a development perspective.

---

## Prerequisites and Initial Setup

### Required Hardware and OS

- **OS**: Ubuntu 20.04 LTS or Debian 11+ (on VM or native machine)
- **RAM**: Minimum 2 GB (recommended 4 GB)
- **Disk**: Minimum 20 GB free
- **CPU**: 2 cores minimum

### Installation of Prerequisites

#### 1. Update the system
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Install Docker
```bash
# Install Docker
sudo apt install -y docker.io

# Add your user to docker group (to avoid sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker run hello-world
```

#### 3. Install Docker Compose
```bash
# Install Docker Compose
sudo apt install -y docker-compose

# Verify installation
docker-compose --version
```

#### 4. Configure local domain
```bash
# Add to /etc/hosts file
sudo nano /etc/hosts

# Add the line:
# 127.0.0.1 victoire.42.fr

# Verify
cat /etc/hosts | grep victoire.42.fr
```

#### 5. Clone the project
```bash
# Clone from Git
git clone <repository_url> Inception
cd Inception

# Verify structure
ls -la
```

### Environment Configuration

#### Create .env file

1. **Navigate to directory**
   ```bash
   cd srcs
   ```

2. **Create and edit .env file**
   ```bash
   nano .env
   ```

3. **Add environment variables**
   ```env
   # Domain
   DOMAIN_NAME=victoire.42.fr

   # MariaDB
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wp_user
   MYSQL_PASSWORD=your_secure_password_here
   MYSQL_ROOT_PASSWORD=your_root_password_here
   DB_HOST=mariadb
   DB_NAME=wordpress
   DB_USER=wp_user
   DB_PASSWORD=your_secure_password_here

   # WordPress
   WP_TITLE=Inception
   WP_ADMIN_USER=victoire
   WP_ADMIN_PASSWORD=your_admin_password_here
   WP_ADMIN_EMAIL=victoire@42.fr
   WP_USER=author_user
   WP_USER_EMAIL=author@42.fr
   WP_USER_PASSWORD=your_author_password_here
   ```

4. **Add .env to .gitignore**
   ```bash
   cd ..
   echo "srcs/.env" >> .gitignore
   ```

---

## Makefile Commands

The Makefile simplifies Docker Compose operations.

### Display help

```bash
make help
# Shows all available commands
```

### Build images

```bash
# Build all images
make build

# Build without cache (force rebuild)
make build-no-cache

# Build specific image
docker compose build mariadb
docker compose build wordpress
docker compose build nginx
```

### Start the infrastructure

```bash
# Start containers in background
make up

# Start and display logs in real-time
make up-logs

# Equivalent docker compose
cd srcs && docker compose up -d
```

### Stop and cleanup

```bash
# Stop containers (data preserved)
make down

# Remove completely (containers, images, volumes)
make fclean

# Remove only stopped containers
docker container prune -f

# Remove unused images
docker image prune -f
```

### Restart

```bash
# Restart containers
make restart

# Restart specific service
docker compose restart nginx
docker compose restart wordpress
docker compose restart mariadb
```

### Manage logs

```bash
# Display logs in real-time
make logs

# Logs for specific service
docker compose logs nginx
docker compose logs wordpress
docker compose logs mariadb

# Last 50 lines
docker compose logs --tail=50

# Real-time logs for specific service
docker compose logs -f nginx
```

### Status and inspection

```bash
# See container status
make ps
# Or: docker compose ps

# See built images
docker images | grep inception

# See volumes
docker volume ls | grep inception
```

---

## Docker Compose Commands

Main commands used directly (from `srcs/`):

### Launch the infrastructure

```bash
cd srcs

# Complete startup (build + create + start)
docker compose up -d --build

# Simple startup (reuses existing images)
docker compose up -d

# Startup with log display
docker compose up
```

### Stop and remove

```bash
# Stop containers
docker compose stop

# Stop and remove containers
docker compose down

# Stop, remove containers, and remove volumes
docker compose down -v
```

### Inspect services

```bash
# List all containers and their status
docker compose ps

# See effective configuration (after variable interpolation)
docker compose config

# Validate docker-compose.yml syntax
docker compose config --quiet  # Returns 0 if valid
```

### Access containers

```bash
# Execute command in container
docker compose exec wordpress ls -la /var/www/html
docker compose exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# Get interactive shell in container
docker compose exec -it wordpress bash
docker compose exec -it nginx sh
docker compose exec -it mariadb bash

# Exit shell
exit
```

### Logs

```bash
# See all logs
docker compose logs

# Follow logs in real-time
docker compose logs -f

# Logs for specific service
docker compose logs wordpress

# Last 100 lines
docker compose logs --tail=100

# Logs with timestamps
docker compose logs --timestamps
```

---

## Container and Volume Management

### Inspect a container

```bash
# See container details
docker compose inspect wordpress

# See environment variables in container
docker compose exec wordpress env | sort

# See mounted volumes
docker inspect <container_id> | grep -A 5 "Mounts"
```

### Volume management

```bash
# List all volumes
docker volume ls

# Inspect specific volume
docker volume inspect inception_wordpress

# See where data is stored on host
docker volume inspect inception_wordpress | grep Mountpoint

# Remove volume (destroys data!)
docker volume rm inception_wordpress

# See volume sizes
docker ps -a --format "table {{.ID}}\t{{.Size}}\t{{.RunningFor}}"
```

### Data backup

#### Backup database

```bash
# Export WordPress database
docker exec mariadb mysqldump -u root -p wordpress > /tmp/backup.sql
# Enter root password

# Verify backup
head -20 /tmp/backup.sql
wc -l /tmp/backup.sql
```

#### Backup WordPress files

```bash
# Copy WordPress volume
cp -r /home/victoire/data/wordpress /home/victoire/wordpress_backup

# Verify
ls -la /home/victoire/wordpress_backup | head -10
```

#### Complete backup

```bash
# Complete archive
tar -czf Inception_backup_$(date +%Y%m%d).tar.gz \
  /home/victoire/data/ \
  srcs/ \
  Makefile

# Verify
ls -lh Inception_backup_*.tar.gz
```

### Restore data

#### Restore database

```bash
# Import from backup
cat /tmp/backup.sql | docker exec -i mariadb mysql -u root -p wordpress
# Enter root password

# Verify
docker exec mariadb mysql -u root -p -e "SELECT COUNT(*) FROM wordpress.wp_posts;"
```

#### Restore WordPress files

```bash
# Copy restored files
cp -r /home/victoire/wordpress_backup/* /home/victoire/data/wordpress/

# Verify permissions
sudo chown -R 33:33 /home/victoire/data/wordpress
ls -la /home/victoire/data/wordpress | head -10
```

---

## Development Workflow

### Typical development cycle

#### 1. Make a modification

Example: Modify MariaDB configuration file

```bash
# modify Dockerfile
nano srcs/requirements/mariadb/Dockerfile

# Or modify entrypoint
nano srcs/requirements/mariadb/tools/entrypoint.sh
```

#### 2. Rebuild affected image

```bash
# Rebuild WITHOUT cache (force complete rebuild)
cd srcs
docker compose build --no-cache mariadb

# Or rebuild all services
docker compose build --no-cache
```

#### 3. Restart the service

```bash
# Stop and restart
docker compose down
docker compose up -d

# Or restart only the modified service
docker compose restart mariadb

# Wait for MariaDB to be ready (approximately 10 seconds)
sleep 10
```

#### 4. Test the modification

```bash
# See service logs
docker compose logs mariadb

# Test connectivity
docker exec -it mariadb mysql -u wp_user -p wordpress -e "SELECT VERSION();"

# Test complete application
curl -k https://victoire.42.fr/
```

### Testing and validation

#### Test each service

```bash
# Test MariaDB
echo "Testing MariaDB..."
docker exec -it mariadb mysql -u wp_user -p wordpress -e "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'wordpress';"

# Test WordPress
echo "Testing WordPress..."
docker exec -it wordpress wp --allow-root --path=/var/www/html core version

# Test NGINX
echo "Testing NGINX..."
docker exec -it nginx nginx -t  # Validate configuration
curl -k https://victoire.42.fr/ | head -50

# Test network
echo "Testing network..."
docker exec -it wordpress ping -c 2 mariadb
docker exec -it wordpress ping -c 2 nginx
```

#### Complete integration test

```bash
# Restart everything "cold"
docker compose down
docker compose up -d --build

# Wait for startup (approximately 30 seconds)
sleep 30

# Test access
curl -k https://victoire.42.fr/ | grep -o '<title>.*</title>'

# Check users
docker exec mariadb mysql -u wp_user -p wordpress -e "SELECT user_login FROM wp_users;"
```

---

## Debugging and Inspection

### Access a container

```bash
# Interactive shell in WordPress
docker compose exec -it wordpress bash
  # You are now in the container
  ls -la /var/www/html/
  cat /var/www/html/wp-config.php | head -30
  exit

# Interactive shell in MariaDB
docker compose exec -it mariadb bash
  # Linux shell commands
  ps aux | grep mariadb
  exit

# Shell in NGINX
docker compose exec -it nginx sh
  # NGINX uses alpine (more minimal shell)
  exit
```

### Test connectivity

```bash
# From WordPress to MariaDB
docker compose exec wordpress nc -zv mariadb 3306
# Expected result: "Connection succeeded"

# From NGINX to WordPress
docker compose exec nginx nc -zv wordpress 9000
# Expected result: "Connection succeeded"

# Internal HTTP request (from NGINX)
docker compose exec nginx curl -v http://wordpress:9000/index.php
```

### Test SSL certificates

```bash
# See certificate details
docker compose exec nginx openssl x509 -in /etc/nginx/ssl/nginx.crt -text -noout

# Check expiration date
docker compose exec nginx openssl x509 -enddate -noout -in /etc/nginx/ssl/nginx.crt

# Test TLS connection
echo | openssl s_client -connect localhost:443 -servername victoire.42.fr 2>/dev/null | grep -A 5 "Verify return code"
```

---

## Data Persistence and Storage

### Understanding volumes

#### Storage types in project

This project uses **named Docker volumes** (NOT bind mounts):

```yaml
volumes:
  mariadb:
    driver: local     # Docker-managed named volume
  wordpress:
    driver: local     # Docker-managed named volume
```

**Key point**: You do NOT need to create `/home/victoire/data/` directories. Docker automatically manages volume storage at:
- `/var/lib/docker/volumes/mariadb/_data/`
- `/var/lib/docker/volumes/wordpress/_data/`

### Data location

```bash
# Docker manages these locations automatically
sudo ls -lah /var/lib/docker/volumes/

# See MariaDB data (requires sudo)
sudo ls -la /var/lib/docker/volumes/mariadb/_data/

# See WordPress data (requires sudo)
sudo ls -la /var/lib/docker/volumes/wordpress/_data/
  # You should see: wp-admin/, wp-content/, wp-includes/, wp-config.php, index.php

# Alternative: Use Docker commands (no sudo needed)
docker volume ls | grep inception
docker volume inspect inception_mariadb
docker volume inspect inception_wordpress
```

### Monitor data size

```bash
# See volume sizes using Docker
docker volume inspect inception_mariadb
docker volume inspect inception_wordpress

# Or access directly on filesystem
sudo du -sh /var/lib/docker/volumes/mariadb/_data/
sudo du -sh /var/lib/docker/volumes/wordpress/_data/

# Largest WordPress files
sudo find /var/lib/docker/volumes/wordpress/_data/ -type f -exec ls -lh {} + | sort -k5 -rh | head -20
```

### Clean up data

```bash
# ⚠️ Remove containers AND volumes (destroys all data)
docker compose down -v

# Verify volumes are removed
docker volume ls | grep inception

# Restart with fresh installation
docker compose up -d --build
```

### Verify persistence

```bash
# Add a WordPress post/page
# 1. Access https://victoire.42.fr/wp-admin
# 2. Create an article

# Stop containers
docker compose stop

# Restart containers
docker compose start

# Verify data persists
# The article you created should still be there

# Verify via CLI
docker exec wordpress wp --allow-root post list --format=csv
```

---

*Last updated: February 2026*

**Related files**: [README.md](README.md), [USER_DOC.md](USER_DOC.md), [Makefile](Makefile), [srcs/docker-compose.yml](srcs/docker-compose.yml)

