# Quick Deployment Guide - Valera Production

🚀 **Get Valera running in production in under 30 minutes**

## Prerequisites

- Ubuntu 20.04+ or CentOS 8+ server
- Domain name pointing to your server
- Docker and Docker Compose installed
- Root or sudo access

## 1️⃣ Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install utilities
sudo apt install -y curl wget git certbot
```

## 2️⃣ Application Setup

```bash
# Clone repository
git clone https://github.com/your-username/valera.git
cd valera

# Switch to production branch
git checkout feature/production-deployment-prep

# Configure environment
cp .env.production.template .env.production
nano .env.production  # Edit with your values
```

## 3️⃣ SSL Setup

```bash
# Setup SSL certificates (choose one)
sudo ./scripts/setup-ssl.sh letsencrypt  # Production
# OR
sudo ./scripts/setup-ssl.sh selfsigned  # Testing
```

## 4️⃣ Deploy Application

```bash
# Run deployment
sudo ./scripts/deploy.sh
```

## 5️⃣ Verify Deployment

```bash
# Health check
curl -f https://your-domain.com/health

# Check logs
docker-compose -f docker-compose.production.yml logs -f app

# Access monitoring
# Grafana: http://your-server:3001 (admin:your_grafana_password)
# Prometheus: http://your-server:9090
```

## 🎯 Quick Commands

```bash
# View application logs
docker-compose -f docker-compose.production.yml logs -f app

# Restart services
docker-compose -f docker-compose.production.yml restart

# Check service status
docker-compose -f docker-compose.production.yml ps

# Database backup
docker-compose -f docker-compose.production.yml exec postgres pg_dump -U valera_user valera_production > backup.sql

# Rollback deployment
sudo ./scripts/deploy.sh rollback

# Update application
git pull
sudo ./scripts/deploy.sh
```

## 📱 Test Telegram Bot

1. Find your bot on Telegram
2. Send a message: `/start`
3. Try booking: "Записаться на диагностику"

## 🔧 Troubleshooting

**Application not responding:**
```bash
# Check container status
docker-compose -f docker-compose.production.yml ps

# Restart nginx
docker-compose -f docker-compose.production.yml restart nginx

# Check SSL certificates
sudo ./scripts/setup-ssl.sh test
```

**Database issues:**
```bash
# Check database connection
docker-compose -f docker-compose.production.yml exec postgres psql -U valera_user -d valera_production -c "SELECT 1;"

# Run migrations
docker-compose -f docker-compose.production.yml run --rm app rails db:migrate
```

**Telegram webhook not working:**
```bash
# Check webhook status
curl -X POST "https://api.telegram.org/botYOUR_BOT_TOKEN/getWebhookInfo"

# Set webhook (replace with your domain)
curl -X POST "https://api.telegram.org/botYOUR_BOT_TOKEN/setWebhook" \
  -d "url=https://your-domain.com/telegram/webhook"
```

## 📊 Monitoring Setup

Access dashboards:
- **Grafana:** `http://your-server:3001`
- **Prometheus:** `http://your-server:9090`

Default Grafana credentials:
- Username: `admin`
- Password: Set in `.env.production` (GRAFANA_PASSWORD)

## 🔄 Maintenance

**Weekly tasks:**
```bash
# Update application
git pull
sudo ./scripts/deploy.sh

# Check SSL certificates
sudo certbot certificates
```

**Monthly tasks:**
```bash
# Test backup restoration
# Clean old logs
docker system prune -f
```

## 🆘 Support

If you encounter issues:

1. Check logs: `docker-compose logs`
2. Review deployment report: `docs/deployment/deployment-readiness-report.md`
3. Check monitoring dashboards
4. Review error handling patterns: `docs/patterns/error-handling.md`

---

**Deployment Time:** ~20 minutes
**Total Setup Time:** ~30 minutes
**Monitoring Available:** ✅
**Backup Configured:** ✅
**SSL Secured:** ✅

🎉 **Your Valera bot is now production-ready!**