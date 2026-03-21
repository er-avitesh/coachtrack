#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────────────
# FILL IN THESE VALUES BEFORE PASTING INTO AWS EC2 USER DATA
# ─────────────────────────────────────────────────────────────────────────────

GITHUB_REPO="https://github.com/yourusername/coachtrack.git"

# Supabase: dashboard -> Settings -> Database -> Connection string -> URI
DATABASE_URL="postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres"

# Generate with: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET="replace_with_long_random_string"

# Used by Let's Encrypt only for expiry notification emails
EMAIL="your@email.com"

# AWS S3 (for photo uploads — leave blank if not using)
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_REGION="ap-south-1"
AWS_S3_BUCKET="coachtrack-photos"

# ─────────────────────────────────────────────────────────────────────────────
# EVERYTHING BELOW RUNS AUTOMATICALLY — DO NOT EDIT
# ─────────────────────────────────────────────────────────────────────────────

APP_DIR="/home/ubuntu/coachtrack"
LOG="/var/log/coachtrack-setup.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== CoachTrack Setup Started ==="

# Auto-detect public IP and build sslip.io domain (no domain purchase needed)
# sslip.io maps e.g. 54-123-45-67.sslip.io -> 54.123.45.67 automatically
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
DOMAIN="${PUBLIC_IP//./-}.sslip.io"
echo ">>> Instance IP: $PUBLIC_IP"
echo ">>> API will be at: https://$DOMAIN/api"

# System update
apt-get update -y && apt-get upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Nginx, Certbot, Git
apt-get install -y nginx certbot python3-certbot-nginx git

# Install PM2 globally (keeps Node.js running, restarts on crash)
npm install -g pm2

# Clone repo
git clone "$GITHUB_REPO" "$APP_DIR"
chown -R ubuntu:ubuntu "$APP_DIR"

# Write backend .env
cat > "$APP_DIR/backend/.env" << EOF
PORT=3000
NODE_ENV=production
DATABASE_URL=$DATABASE_URL
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=7d
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_REGION=$AWS_REGION
AWS_S3_BUCKET=$AWS_S3_BUCKET
EOF

# Install backend dependencies
cd "$APP_DIR/backend"
npm install --omit=dev

# Start app with PM2 as ubuntu user
sudo -u ubuntu bash -c "
  cd $APP_DIR/backend
  pm2 start src/server.js --name coachtrack
  pm2 save
"

# Register PM2 as a systemd service so it survives reboots
env PATH="$PATH:/usr/bin" pm2 startup systemd -u ubuntu --hp /home/ubuntu
systemctl enable pm2-ubuntu

# Configure Nginx as reverse proxy
cat > /etc/nginx/sites-available/coachtrack << NGINX
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass         http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection 'upgrade';
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINX

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/coachtrack /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Get free SSL certificate — certbot edits Nginx config to add HTTPS automatically
# Certificate auto-renews every 90 days via a cron job certbot installs
certbot --nginx \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  -m "$EMAIL"

echo ""
echo "============================================================"
echo "  Setup complete!"
echo "  API URL:  https://$DOMAIN/api"
echo ""
echo "  Update your Flutter app:"
echo "  mobile/lib/core/constants.dart"
echo "  -> baseUrl = 'https://$DOMAIN/api'"
echo "============================================================"
