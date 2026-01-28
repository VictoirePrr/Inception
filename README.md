*This project has been created as part of the 42 curriculum by victoire.*

---

## Description

Inception is a system administration project focused on Docker. It consists of setting up a complete infrastructure composed of three Docker services orchestrated via Docker Compose:

- **NGINX**: web server with TLS 1.2 and 1.3 support, serving as the unique entry point
- **WordPress**: CMS platform with PHP-FPM for dynamic content processing
- **MariaDB**: database management system for storing WordPress data

The main objective is to learn how to containerize a complete web application by following Docker best practices, with emphasis on security, data persistence, and secret management.

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed on the virtual machine
- An Ubuntu/Debian machine
- Root or sudo access to modify `/etc/hosts`
- Terminal with zsh or bash

### Installation and startup

1. **Clone the project**
   ```bash
   git clone <repository_url>
   cd Inception
   ```

2. **Configure the environment file**
   
   Create `srcs/.env` with the necessary variables:
   ```
   DOMAIN_NAME=victoire.42.fr
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wp_user
   MYSQL_PASSWORD=<your_password>
   MYSQL_ROOT_PASSWORD=<root_password>
   DB_HOST=mariadb
   WP_TITLE=Inception
   WP_ADMIN_USER=<your_admin_user>
   WP_ADMIN_PASSWORD=<admin_password>
   WP_ADMIN_EMAIL=<your_email>
   WP_USER=author_user
   WP_USER_PASSWORD=<author_password>
   ```

3. **Configure the local domain**
   
   Add to the `/etc/hosts` file:
   ```
   127.0.0.1 victoire.42.fr
   ```

4. **Create data directories**
   ```bash
   mkdir -p /home/victoire/data/{mariadb,wordpress}
   ```

5. **Start the infrastructure**
   ```bash
   make up
   ```

   Or manually:
   ```bash
   cd srcs
   docker compose up -d
   ```

### Stop and cleanup

```bash
make down          # Stop containers
make clean         # Remove containers and images
make fclean        # Complete cleanup (containers, images, volumes)
```

### Access to WordPress

- **WordPress Site**: https://victoire.42.fr
- **Admin Dashboard**: https://victoire.42.fr/wp-admin
- **Credentials**: See the `srcs/.env` file

---

## Architecture and design choices

### Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                       Docker Network                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   NGINX      │    │   WordPress  │    │   MariaDB    │      │
│  │   (443)      │───▶│   (9000)     │───▶│   (3306)     │      │
│  │   TLS 1.2/3  │    │   PHP-FPM    │    │   Database   │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│       │                     │                     │               │
│       └─────────────────────┴─────────────────────┘              │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Port 443 (HTTPS)
         │
    ┌────▼─────────────────────────┐
    │   Host Machine (localhost)   │
    │   vicperri.42.fr             │
    └──────────────────────────────┘

Persistent volumes: /home/victoire/data/{mariadb,wordpress}
```

### Service composition

| Service | Image | Internal Port | Function | Volume |
|---------|-------|---------------|----------|--------|
| **NGINX** | Debian Bookworm | 443 | Reverse proxy with TLS | - |
| **WordPress** | Debian Bookworm | 9000 | PHP-FPM Application | wordpress |
| **MariaDB** | Debian Bookworm | 3306 | Database | mariadb |

---

## Technical comparisons

### 1. Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker |
|--------|------------------|--------|
| **Size** | 2-20 GB | 100-500 MB |
| **Boot Time** | 30-120 seconds | 1-5 seconds |
| **Isolation** | Complete (full OS) | Process-level |
| **Resources** | Heavy (RAM, CPU) | Minimal |
| **Portability** | Limited | Excellent |
| **Use Cases** | Full servers, diverse OS | Microservices, containerization |

**Conclusion**: Docker is ideal for lightweight application containers, while VMs are better for complete systems requiring total isolation.

### 2. Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|---|---|
| **Storage** | Encrypted, secure | .env file (unencrypted) |
| **Visibility** | Limited to authorized containers | Visible in `docker inspect` |
| **Persistence** | Yes (Docker Swarm) | Text file |
| **Security** | Excellent | Good (if .gitignore respected) |
| **Complexity** | Medium (Swarm only) | Low |
| **Best Practice** | Passwords, API keys | Configuration, non-sensitive values |

**Implementation in this project**:
- `.env`: non-sensitive variables (names, paths)
- `secrets/`: credentials (passwords, keys) with `.gitignore`

### 3. Docker Network vs Host Network

| Aspect | Docker Network | Host Network |
|--------|---|---|
| **Isolation** | Complete | None |
| **Communication** | By container name | Direct, via localhost |
| **Security** | Excellent | Weak |
| **Performance** | Slightly reduced | Optimal |
| **External Ports** | Explicit via docker-compose | All accessible |
| **Flexibility** | High | Low |

**Project Choice**: Custom Docker Network (`inception_network`) for isolation and security. Only NGINX exposes port 443 to the host.

### 4. Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---|---|
| **Management** | Docker managed | Direct OS path |
| **Performance** | Optimized | Can be slow (especially on Mac) |
| **Persistence** | Complete | Complete |
| **Backup** | Easy with `docker volume` | Manual |
| **Sharing** | Between containers | Between host and containers |
| **Portability** | Excellent | Depends on host paths |
| **Permissions** | Docker managed | Host filesystem |

**Implementation**: 
- **Docker Volumes** (mandatory): `mariadb` and `wordpress` named
- **Source**: `/home/victoire/data/` on host (internal bind mount)
- **Advantage**: Easy to locate, simple to backup, portable

---

## Project structure

```
Inception/
├── Makefile                          # Docker command orchestration
├── README.md                         # This file
├── USER_DOC.md                       # User documentation
├── DEV_DOC.md                        # Developer documentation
├── secrets/                          # Local secrets (NEVER version)
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                          # Environment variables (NEVER version)
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── mariadb.cnf
        │   └── tools/
        │       └── entrypoint.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   └── tools/
        │       └── entrypoint.sh
        └── nginx/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            │   ├── nginx.conf
            │   └── default.conf
            └── tools/
                └── entrypoint.sh
```

---

## Resources

### Official documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Official Documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress Development](https://developer.wordpress.org/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

### Tutorials and guides

- [Best Practices Writing Dockerfiles](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [NGINX TLS Configuration](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [WordPress with Docker](https://wordpress.org/support/article/docker/)

### Technical articles

- Container Orchestration with Docker Compose
- TLS 1.2/1.3 Security Implementation
- Database Persistence in Docker Environments
- FastCGI Protocol and PHP-FPM

---

## AI Usage

AI was used for the following tasks:

### Tasks assisted by AI:

1. **Research**
   - Docker best practices and architecture patterns
   - TLS/SSL configuration and security implementation
   - FastCGI protocol and PHP-FPM setup
   - MariaDB initialization and user management
   - WordPress installation and configuration workflows

2. **Documentation**
   - Finding great resources to help learn and understand Docker. (see Ressources part)

### Tasks NOT assisted by AI:

- Overall architecture and design decisions
- Debugging integration issues (variable mismatches, timeouts)
- Complete functional validation and testing
- Critical configuration decisions and modifications
- Peer review and detailed explanations

---

## Important notes

⚠️ **Security**: 
- Never commit `.env` or `secrets/` folder
- Always use `.gitignore` to exclude sensitive files
- Always regenerate passwords in production
- SSL certificates are self-signed (development only)

✅ **Best practices applied**:
- No pre-made Docker images used (except base Alpine/Debian)
- No `tail -f` commands or infinite loops
- Automatic container restart on crash
- Named volumes for persistence (no bind mounts)
- Custom Docker network for isolation
- Forced TLS (port 443 only)
- No passwords in Dockerfiles

---

*Last updated: January 2026*
