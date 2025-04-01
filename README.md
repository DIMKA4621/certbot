# SSL Certificate Manager with Certbot

A collection of shell scripts to automate SSL certificate generation and renewal using Certbot and Docker.

## Prerequisites

- Docker
- Nginx _(or nginx in docker)_
- Proper user permissions:
   - Docker group membership (`docker`)
   - Nginx configuration access (`www-data` group)

## Scripts

### 1. restart-nginx.sh

Script for restarting Nginx after configuration changes. By default, it's configured for host-based Nginx using:
```bash
sudo nginx -s reload
```

If you're using a different setup, edit `restart-nginx.sh` and uncomment/modify the appropriate command:

```bash
# For host Nginx (default):
sudo nginx -s reload

# For Docker-based Nginx:
# docker exec -it nginx nginx -s reload

# For Docker Swarm Nginx:
# docker service update --force nginx_nginx
```

Choose and uncomment the command that matches your environment.

### 2. generate-ssl.sh

Generates SSL certificates for domains using either HTTP or DNS validation.

```bash
./generate-ssl.sh <domain> [--http|--dns|--renew]
```

Options:
- `--http` (default): Uses HTTP validation
- `--dns`: Uses DNS validation (interactive)
- `--renew`: Forces renewal of existing certificate

Example:
```bash
./generate-ssl.sh example.com
./generate-ssl.sh example.com --dns
./generate-ssl.sh example.com --renew
```

### 3. renew-all-existing.sh

Automatically renews all existing certificates in the current directory.

```bash
./renew-all-existing.sh
```

Features:
- Processes all domain directories
- Implements rate limiting (10 renewals with 3-hour pause)
- Automatically restarts Nginx after completion

#### Automatic Monthly Renewal

To set up automatic monthly renewal, add the following to your crontab (`crontab -e`):

```bash
# Run certificate renewal at 3:00 AM on the first day of each month
0 3 1 * * /bin/bash -c "cd /var/www/certbot && bash renew-all-existing.sh &> last-renew-all.log"
```

Replace `/path/to/certbot` with the actual path to your certbot scripts directory.

## Certificate Storage

Certificates are stored in domain-specific directories:
- `<domain>/fullchain.pem`: Full certificate chain
- `<domain>/privkey.pem`: Private key
- `<domain>/letsencrypt/`: Complete Certbot configuration

## Troubleshooting

If you encounter permission errors:
1. Ensure your user is in the required groups
2. Verify Nginx configuration directory permissions
3. Check Docker daemon access
4. Review logs in `<domain>/letsencrypt.log` for certificate generation issues
