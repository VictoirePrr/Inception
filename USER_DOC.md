# User Documentation - Inception

This document explains how to use the Inception infrastructure as an end user or system administrator.

---

## Table of Contents

1. [Services Overview](#services-overview)
2. [Starting and Stopping](#starting-and-stopping)
3. [Accessing WordPress](#accessing-wordpress)
4. [Managing Credentials](#managing-credentials)
5. [Checking Service Health](#checking-service-health)
6. [Troubleshooting](#troubleshooting)
7. [FAQ](#faq)

---

## Services Overview

### Available Services

The Inception infrastructure provides the following services:

#### 1. **WordPress** (Web Application)
- **Description**: Content Management System (CMS) for creating and managing a website
- **Access URL**: `https://victoire.42.fr`
- **Dashboards**:
  - Public site: `https://victoire.42.fr/`
  - Administration: `https://victoire.42.fr/wp-admin`
  - Content editor: `https://victoire.42.fr/wp-admin/post-new.php`
- **Features**:
  - Article and page publication
  - User and role management (Administrator, Author, Editor)
  - Themes and plugins
  - Media and galleries

#### 2. **NGINX** (Web Server)
- **Description**: Secure web server with TLS encryption
- **Supported Protocols**: HTTPS only (TLS 1.2, TLS 1.3)
- **Exposed Port**: 443 (HTTPS)
- **Role**: 
  - Unique entry point to the infrastructure
  - Reverse proxy to WordPress
  - Static file server
  - SSL/TLS certificate management

#### 3. **MariaDB** (Database)
- **Description**: Database server for storing WordPress data
- **Access**: Internal only (not accessible from outside)
- **Function**: 
  - Storage of posts, pages, users, comments
  - Automatic backup via persistent volumes
  - WordPress table management

---

## Starting and Stopping

### Start the infrastructure

**First use** (after git clone):

```bash
# Go to project directory
cd /path/to/Inception

# Configure the local domain
sudo nano /etc/hosts
# Add the line: 127.0.0.1 victoire.42.fr

# Create data directories
mkdir -p /home/victoire/data/{mariadb,wordpress}

# Create .env file in srcs/
nano srcs/.env
# (Fill with environment variables)

# Start containers
make up
```

**Subsequent startups**:

```bash
cd /path/to/Inception
make up
```

Or manually:

```bash
cd srcs
docker compose up -d
```

### Verify everything started correctly

```bash
# See status of all containers
docker compose ps

# Expected result:
# NAME           COMMAND                 STATE      PORTS
# mariadb        "/entrypoint.sh"        running    
# wordpress      "/entrypoint.sh"        running    
# nginx          "/entrypoint.sh"        running    0.0.0.0:443->443/tcp
```

### Stop the infrastructure

```bash
# Stop all containers (data is preserved)
make down
```

Or:

```bash
cd srcs
docker compose down
```

### Restart services

```bash
# Restart all containers
make restart
```

Or:

```bash
cd srcs
docker compose restart
```

---

## Accessing WordPress

### Access the public website

1. **Open a web browser**
2. **Navigate to**: `https://victoire.42.fr`
   - ⚠️ **Self-signed certificate**: The browser will display a security warning
   - Click "Continue" or "Advanced" → "Go to website"

3. **See the WordPress site**
   - Homepage with articles and pages
   - Sidebar with categories and archives

### Access the admin dashboard

1. **URL**: `https://victoire.42.fr/wp-admin`
2. **Credentials**:
   - **Username**: See the `WP_ADMIN_USER` variable in `srcs/.env`
   - **Password**: See the `WP_ADMIN_PASSWORD` variable in `srcs/.env`
3. **Click "Login"**

### Administrator features

Once logged in, you can:

| Action | Path |
|--------|------|
| Write a new article | Dashboard → Posts → Add |
| Create a page | Dashboard → Pages → Add |
| Manage users | Dashboard → Users |
| Modify settings | Dashboard → Settings |
| Install a plugin | Dashboard → Plugins → Add |
| Change theme | Dashboard → Appearance → Themes |

### Using the author account

An author account is automatically created for testing roles:

- **Username**: See the `WP_USER` variable in `srcs/.env`
- **Password**: See the `WP_USER_PASSWORD` variable in `srcs/.env`
- **Permissions**: Can create and edit own articles (read-only on others)

---

## Managing Credentials

### Where are credentials stored?

Credentials are stored in two places:

#### 1. **.env file** (environment variables)
- **Path**: `srcs/.env`
- **Format**: Text file with key=value
- **Content**:
  ```env
  MYSQL_USER=wp_user
  MYSQL_PASSWORD=your_password
  WP_ADMIN_USER=your_login
  WP_ADMIN_PASSWORD=your_password
  ```
- **Security**: ⚠️ Add to `.gitignore` (never commit)

#### 2. **secrets/ folder** (Docker secrets)
- **Path**: `secrets/` at project root
- **Files**:
  - `credentials.txt`: WordPress credentials
  - `db_password.txt`: MariaDB user password
  - `db_root_password.txt`: MariaDB root password
- **Security**: ⚠️ Add to `.gitignore` (never commit)

### Modifying credentials

#### Before first startup

1. **Edit the file** `srcs/.env`
   ```bash
   nano srcs/.env
   ```

2. **Modify the variables**:
   ```env
   MYSQL_USER=my_db_user
   MYSQL_PASSWORD=my_secure_password
   WP_ADMIN_USER=my_admin_login
   WP_ADMIN_PASSWORD=my_strong_password
   WP_ADMIN_EMAIL=my_email@example.com
   ```

3. **Save**: Ctrl+O, Enter, Ctrl+X

4. **Start the project**: `make up`

#### After first startup

⚠️ **Important**: Credentials are stored in the database. To modify them after initial startup:

**Option 1: Via WordPress interface**
1. Log in to `https://victoire.42.fr/wp-admin`
2. Go to Dashboard → Users
3. Click on the user to modify
4. Change the password and click "Update"

**Option 2: Via command line**
1. Access the MariaDB container:
   ```bash
   docker exec -it mariadb mysql -u wp_user -p wordpress
   ```
   
2. Enter `wp_user` password (variable `MYSQL_PASSWORD`)

3. Update WordPress password:
   ```sql
   UPDATE wp_users SET user_pass=MD5('new_password') 
   WHERE user_login='victoire';
   ```

4. Exit with `exit`

### Security best practices

✅ **Do**:
- Use strong passwords (12+ characters, lowercase, uppercase, numbers, symbols)
- Add `.env` and `secrets/` to `.gitignore`
- Never commit files containing credentials
- Verify `.gitignore` works: `git status` should not show `.env`
- Change passwords regularly in production

❌ **Avoid**:
- Simple passwords (123456, password)
- Storing passwords in git
- Using same password everywhere
- Leaving credentials in Docker logs
- Sharing credentials in plain text

---

## Checking Service Health

### Verify all containers are running

```bash
# See status of all containers
docker compose ps

# Expected result (all in "running"):
# NAME        COMMAND          STATE      PORTS
# mariadb     "/entrypoint.sh" running    
# wordpress   "/entrypoint.sh" running    
# nginx       "/entrypoint.sh" running    0.0.0.0:443->443/tcp
```

### View service logs

```bash
# Logs from all containers
docker compose logs

# Real-time logs (follow)
docker compose logs -f

# Logs from specific service
docker compose logs nginx        # NGINX logs
docker compose logs wordpress    # WordPress logs
docker compose logs mariadb      # MariaDB logs

# Last 50 lines
docker compose logs --tail=50
```

### Test NGINX connectivity

```bash
# Test via curl (ignore self-signed certificate)
curl -k https://victoire.42.fr/

# Expected result: WordPress page HTML (200 OK)
```

### Test MariaDB connection

```bash
# Access MariaDB container
docker exec -it mariadb mysql -u wp_user -p wordpress

# Enter WP_MYSQL_PASSWORD (from .env)

# Check WordPress tables
mysql> SHOW TABLES;

# Expected result: 12 tables (wp_posts, wp_users, etc.)

# List users
mysql> SELECT user_login FROM wp_users;

# Expected result: victoire, author_user

# Exit
mysql> exit
```

### Test PHP-FPM connectivity

```bash
# Access WordPress container
docker exec -it wordpress bash

# Check if PHP-FPM is running
ps aux | grep php-fpm

# Test PHP directly
echo "<?php phpinfo(); ?>" | php

# Exit
exit
```

### Check persistence volumes

```bash
# See MariaDB data
ls -la /home/victoire/data/mariadb/

# See WordPress data
ls -la /home/victoire/data/wordpress/

# Expected result: WordPress files (wp-admin, wp-content, wp-includes, wp-config.php)
```

---

## Troubleshooting

### NGINX not responding (ERR_CONNECTION_REFUSED)

**Symptom**: Cannot connect to `https://victoire.42.fr`

**Solutions**:

1. **Verify containers are running**
   ```bash
   docker compose ps
   ```
   If NGINX is not "running", see the log:
   ```bash
   docker compose logs nginx
   ```

2. **Verify domain points to localhost**
   ```bash
   cat /etc/hosts | grep victoire.42.fr
   # Should show: 127.0.0.1 victoire.42.fr
   ```

3. **Verify port 443 is active**
   ```bash
   netstat -tuln | grep 443
   # Or: ss -tuln | grep 443
   ```

4. **Restart NGINX**
   ```bash
   docker compose restart nginx
   docker compose logs nginx  # See startup errors if any
   ```

### Invalid SSL/TLS certificate (HSTS_HEADER_ERROR)

**Symptom**: HSTS warning or expired certificate

**Solution**: Regenerate the certificate

```bash
# Remove NGINX container data (no effect on data)
docker compose down nginx

# Restart NGINX (automatically generates new certificate)
docker compose up -d nginx

# Verify
curl -k https://victoire.42.fr/
```

### WordPress not displaying (blank page)

**Symptom**: Blank page or 500 errors

**Solutions**:

1. **Check WordPress logs**
   ```bash
   docker compose logs wordpress
   ```

2. **Check MariaDB connection**
   ```bash
   docker exec -it wordpress mysql -h mariadb -u wp_user -p wordpress -e "SHOW TABLES;"
   ```

3. **Verify wp-config.php exists**
   ```bash
   docker exec -it wordpress ls -la /var/www/html/wp-config.php
   ```

4. **Restart WordPress**
   ```bash
   docker compose restart wordpress
   ```

### Database connection errors (Error establishing database connection)

**Symptom**: WordPress cannot connect to MariaDB

**Solutions**:

1. **Verify MariaDB starts correctly**
   ```bash
   docker compose logs mariadb
   ```

2. **Verify environment variables are correct**
   ```bash
   cat srcs/.env | grep MYSQL
   ```

3. **Manually verify connection**
   ```bash
   docker exec -it mariadb mysql -u wp_user -p -h mariadb
   # Enter password (MYSQL_PASSWORD from .env)
   ```

4. **Verify `wordpress` database exists**
   ```bash
   docker exec -it mariadb mysql -u root -p -e "SHOW DATABASES;"
   # Enter root password (MYSQL_ROOT_PASSWORD)
   ```

### Permission denied on data

**Symptom**: Cannot access `/home/victoire/data/`

**Solutions**:

```bash
# Check permissions
ls -ld /home/victoire/data/

# If needed, fix permissions
sudo chmod 755 /home/victoire/data/
sudo chmod -R 755 /home/victoire/data/*

# Verify current user can read
ls -la /home/victoire/data/
```

### Completely reset the infrastructure

⚠️ **Warning**: This deletes all containers, images, and data!

```bash
# Stop and remove everything
make fclean

# Remove volumes
docker volume rm inception_mariadb inception_wordpress

# Remove local data
sudo rm -rf /home/victoire/data/*

# Restart
mkdir -p /home/victoire/data/{mariadb,wordpress}
make up
```

---

## FAQ

### Q: Why does the certificate show a warning?
**A**: The certificate is self-signed (created locally), not issued by a certificate authority. This is normal in development. In production, you would need a valid certificate (Let's Encrypt, etc.).

### Q: Can I access from outside (from another machine)?
**A**: No, by design. The infrastructure only listens on `127.0.0.1`. To expose it, modify `docker-compose.yml` and change NGINX to `0.0.0.0:443:443` (not recommended in development).

### Q: How should I backup my data?
**A**: Data is in `/home/victoire/data/`. You can:
- Copy the folder: `cp -r /home/victoire/data/ backup/`
- Export the database:
  ```bash
  docker exec mariadb mysqldump -u root -p wordpress > backup.sql
  ```

### Q: How do I import an existing database?
**A**: 
```bash
# Copy SQL file into container
docker exec -i mariadb mysql -u root -p wordpress < your_backup.sql

# You will be asked for root password
```

### Q: Can I modify Dockerfiles after first startup?
**A**: Yes, but you need to rebuild:
```bash
docker compose down
docker compose up -d --build  # or: make build && make up
```

### Q: How can I see which ports the infrastructure uses?
**A**:
```bash
docker compose ps
# Or: netstat -tuln | grep LISTEN
```

### Q: Can I use HTTP instead of HTTPS?
**A**: No, the project is HTTPS only (port 443). Switching to HTTP (port 80) requires changes in `default.conf` and docker-compose.

### Q: How much disk space is needed?
**A**: About 1-2 GB per installation (images + data). Volumes can grow with WordPress content.

### Q: Can I stop overnight and restart in the morning?
**A**: Yes! Data persists in volumes. `docker compose up` will restart the same containers.

### Q: How do I change the domain (from victoire.42.fr to something else)?
**A**:
1. Update `/etc/hosts`
2. Update `DOMAIN_NAME` in `srcs/.env`
3. Delete volumes: `docker volume rm inception_mariadb inception_wordpress`
4. Restart: `make fclean && make up`

---

*Last updated: January 2026*

**Need more help?** See [DEV_DOC.md](DEV_DOC.md) for advanced tasks or [README.md](README.md) for general architecture.
