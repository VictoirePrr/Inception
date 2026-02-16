# User Documentation - Inception

This document explains how to use the Inception infrastructure as an end user or system administrator.

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

| Action              |             Path                |
|---------------------|---------------------------------|
| Write a new article | Dashboard → Posts → Add         |
| Create a page       | Dashboard → Pages → Add         |
| Manage users        | Dashboard → Users               |
| Modify settings     | Dashboard → Settings            |
| Install a plugin    | Dashboard → Plugins → Add       |
| Change theme        | Dashboard → Appearance → Themes |

### Using the author account

An author account is automatically created for testing roles:

- **Username**: See the `WP_USER` variable in `srcs/.env`
- **Password**: See the `WP_USER_PASSWORD` variable in `srcs/.env`
- **Permissions**: Can create and edit own articles (read-only on others)

---

## Managing Credentials

### Where are credentials stored?

#### **.env file** (environment variables)
- **Path**: `srcs/.env`
- **Format**: Text file with key=value
- **Security**: ⚠️ Add to `.gitignore` (never commit)

### Modifying credentials

#### Before first startup

1. **Edit the file** `srcs/.env`
   ```bash
   nano srcs/.env
   ```

2. **Save**: Ctrl+O, Enter, Ctrl+X

3. **Start the project**: `make up`

#### After first startup

⚠️ **Important**: Credentials are stored in the database. To modify them after initial startup:

**Via command line**
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

*Last updated: February 2026*

**Need more help?** See [DEV_DOC.md](DEV_DOC.md) for advanced tasks or [README.md](README.md) for general architecture.
