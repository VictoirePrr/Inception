# Developer Documentation - Inception

This document describes how to configure, build, launch, and maintain the Inception infrastructure from a development perspective.

---

## Table of Contents

1. [Prerequisites and Initial Setup](#prerequisites-and-initial-setup)
2. [Project Structure](#project-structure)
3. [Makefile Commands](#makefile-commands)
4. [Docker Compose Commands](#docker-compose-commands)
5. [Container and Volume Management](#container-and-volume-management)
6. [Development Workflow](#development-workflow)
7. [Debugging and Inspection](#debugging-and-inspection)
8. [Data Persistence and Storage](#data-persistence-and-storage)
9. [Service Modification](#service-modification)
10. [Best Practices](#best-practices)

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

#### 5. Create data directories
```bash
# Create directories where data will persist
mkdir -p /home/victoire/data/{mariadb,wordpress}

# Verify
ls -la /home/victoire/data/
```

#### 6. Clone the project
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
   echo "secrets/" >> .gitignore
   ```

#### Create secrets/ folder

```bash
# Create folder
mkdir -p secrets

# Create secret files
echo "wp_user:your_secure_password_here" > secrets/credentials.txt
echo "your_secure_password_here" > secrets/db_password.txt
echo "your_root_password_here" > secrets/db_root_password.txt

# Set permissions (600 = owner read/write only)
chmod 600 secrets/*

# Verify
ls -la secrets/
```

---

## Project Structure

```
Inception/                           # Project root
├── Makefile                         # Docker command orchestration
├── README.md                        # General documentation
├── USER_DOC.md                      # User documentation
├── DEV_DOC.md                       # This file
├── .git/                            # Git history
├── .gitignore                       # Files to ignore in Git
├── secrets/                         # Local secrets (NEVER version)
│   ├── credentials.txt              # WordPress credentials
│   ├── db_password.txt              # DB user password
│   └── db_root_password.txt         # DB root password
└── srcs/                            # Source code and configs
    ├── .env                         # Environment variables (NEVER version)
    ├── docker-compose.yml           # Docker service orchestration
    └── requirements/                # Services and dependencies
        ├── mariadb/
        │   ├── Dockerfile           # MariaDB image
        │   ├── .dockerignore        # Files to ignore in image
        │   ├── conf/
        │   │   └── mariadb.cnf      # MariaDB configuration
        │   └── tools/
        │       └── entrypoint.sh    # Initialization script
        ├── wordpress/
        │   ├── Dockerfile           # WordPress image
        │   ├── .dockerignore
        │   └── tools/
        │       └── entrypoint.sh    # Initialization script
        ├── nginx/
        │   ├── Dockerfile           # NGINX image
        │   ├── .dockerignore
        │   ├── conf/
        │   │   ├── nginx.conf       # Main NGINX config
        │   │   └── default.conf     # WordPress site config
        │   └── tools/
        │       └── entrypoint.sh    # Initialization script
        └── bonus/                   # Bonus services (optional)
            └── [bonus services]
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
# ⚠️ Warning: Also deletes /home/victoire/data!

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
# Edit configuration
nano srcs/requirements/mariadb/conf/mariadb.cnf

# Or modify Dockerfile
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

#### 5. Validate and commit

```bash
# Check what changed
git status
git diff

# Add and commit (attention: .env and secrets/ MUST NOT be added)
git add srcs/requirements/mariadb/
git add Makefile  # If modified
git commit -m "feat: update MariaDB configuration"

# Verify
git log --oneline -5
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

### Analyze logs

```bash
# See all logs with timestamps
docker compose logs --timestamps

# Filter errors
docker compose logs | grep -i "error\|fatal\|failed"

# See logs from last hour
docker compose logs --since 1h

# Follow logs in real-time with colors
docker compose logs -f --timestamps

# Search logs from a specific date
docker compose logs mariadb | grep "2026-01"
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

### Inspect environment variables

```bash
# See all environment variables in WordPress container
docker compose exec wordpress env | sort

# Grep for specific variable
docker compose exec wordpress env | grep MYSQL

# See secrets (if used)
docker compose exec wordpress cat /run/secrets/db_password
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

1. **Named volumes** (recommended, used here)
   ```yaml
   volumes:
     mariadb:
       driver: local
     wordpress:
       driver: local
   ```

2. **Host storage** (where data actually lives)
   ```
   /home/victoire/data/mariadb/    # MariaDB data
   /home/victoire/data/wordpress/  # WordPress files
   ```

### Data location

```bash
# See exactly where data is stored
ls -lah /home/victoire/data/

# Content of mariadb volume
ls -la /home/victoire/data/mariadb/ | head -20

# Content of wordpress volume
ls -la /home/victoire/data/wordpress/ | head -20
  # You should see: wp-admin/, wp-content/, wp-includes/, wp-config.php, index.php
```

### Monitor data size

```bash
# Total data size
du -sh /home/victoire/data/

# Size per service
du -sh /home/victoire/data/mariadb/
du -sh /home/victoire/data/wordpress/

# Largest WordPress files
find /home/victoire/data/wordpress/ -type f -exec ls -lh {} + | sort -k5 -rh | head -20
```

### Clean up data

```bash
# ⚠️ Remove ALL volumes and data
docker compose down -v
rm -rf /home/victoire/data/*

# Restart with fresh installation
mkdir -p /home/victoire/data/{mariadb,wordpress}
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

## Service Modification

### Add an environment variable

#### 1. In .env
```bash
# Edit srcs/.env
nano srcs/.env

# Add new variable
MY_NEW_VAR=its_value
```

#### 2. In Dockerfile (if needed)
```dockerfile
# Use the variable
RUN echo "${MY_NEW_VAR}" > /tmp/config
```

#### 3. Or in entrypoint.sh
```bash
#!/bin/bash
echo "Variable received: $MY_NEW_VAR"
```

#### 4. Rebuild and restart
```bash
docker compose build --no-cache wordpress
docker compose down
docker compose up -d
docker compose logs wordpress | grep "Variable received"
```

### Modify a port

⚠️ **Warning**: Only NGINX exposes external ports

```yaml
# In docker-compose.yml
services:
  nginx:
    ports:
      - "443:443"    # Current port
      - "80:80"      # Add HTTP (not recommended)
```

Then restart:
```bash
docker compose down
docker compose up -d
docker compose ps  # Verify ports
```

### Change dependency version

Example: Switch from PHP 8.2 to PHP 8.3

```dockerfile
# In srcs/requirements/wordpress/Dockerfile
FROM debian:bookworm-slim

# Before
RUN apt-get install -y php8.2-fpm ...

# After
RUN apt-get install -y php8.3-fpm ...

# Rebuild
docker compose build --no-cache wordpress
```

### Add a new service

1. **Create structure**
   ```bash
   mkdir -p srcs/requirements/myservice/tools
   mkdir -p srcs/requirements/myservice/conf
   ```

2. **Create Dockerfile**
   ```bash
   nano srcs/requirements/myservice/Dockerfile
   ```

3. **Add to docker-compose.yml**
   ```yaml
   services:
     myservice:
       build: requirements/myservice/
       container_name: myservice
       depends_on:
         - wordpress
       environment:
         - ENV_VAR=${ENV_VAR}
       volumes:
         - wordpress:/var/www/html:ro  # Read-only access
       networks:
         - inception_network
   ```

4. **Add variables to .env**
5. **Rebuild**
   ```bash
   docker compose build
   docker compose up -d
   ```

---

## Best Practices

### Security

✅ **Do**:
```bash
# 1. Never commit secrets
git config core.excludesfile ~/.gitignore_global

# 2. Use .gitignore
echo "srcs/.env" >> .gitignore
echo "secrets/" >> .gitignore

# 3. Verify
git status  # Should NOT show .env or secrets/

# 4. Strong passwords
# Minimum 12 characters, letters + numbers + symbols

# 5. Production certificates
# Use Let's Encrypt, not self-signed
```

❌ **Avoid**:
```bash
# Simple passwords
MYSQL_PASSWORD=1234

# Hardcoded passwords in Dockerfiles
RUN echo "password123" > /tmp/pass

# Passwords in logs
docker compose logs | grep password

# Plaintext data in Git
git add secrets/db_password.txt
```

### Performance

```bash
# Check image sizes
docker images | grep inception

# Clean unused resources
docker system prune -a

# See resource usage
docker stats
# Shows: CPU %, MEM USAGE, NET I/O, BLOCK I/O

# Optimize builds
# 1. Use .dockerignore
# 2. Order layers from least to most modified
# 3. Use lightweight base images
```

### Monitoring

```bash
# See usage in real-time
watch docker stats

# Detailed logs
docker compose logs --tail=1000 | grep -i warning

# Health checks (if implemented)
docker ps --format="table {{.Names}}\t{{.Status}}"
```

### Regular maintenance

```bash
# Weekly
docker system prune -a  # Clean up
docker compose logs > /tmp/logs_backup.txt  # Backup logs

# Monthly
# 1. Renew SSL certificates
# 2. Update passwords
# 3. Check for Debian/Alpine updates

# Before deployment
# 1. Test `docker compose down` then `docker compose up`
# 2. Verify data persistence
# 3. Test all failure scenarios
```

---

*Last updated: January 2026*

**Related files**: [README.md](README.md), [USER_DOC.md](USER_DOC.md), [Makefile](Makefile), [srcs/docker-compose.yml](srcs/docker-compose.yml)

**Quick commands**:
```bash
make up              # Start
make down            # Stop
docker compose logs  # View logs
docker compose exec wordpress bash  # Access WordPress
```
