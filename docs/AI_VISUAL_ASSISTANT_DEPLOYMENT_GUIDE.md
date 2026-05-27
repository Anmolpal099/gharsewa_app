# AI Visual Assistant - Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the AI Visual Assistant feature to production environments.

## Prerequisites

### Backend Requirements

- **PHP**: 8.2 or higher
- **Laravel**: 11.x
- **MySQL**: 8.0 or higher
- **Ollama**: Latest version with qwen3-vl:2b model
- **Docker**: 20.10 or higher (for containerized deployment)
- **Composer**: 2.x
- **Storage**: Minimum 50GB for image storage

### Frontend Requirements

- **Flutter**: 3.x or higher
- **Dart**: 3.x or higher
- **Android SDK**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Xcode**: 14+ (for iOS builds)

### Infrastructure Requirements

- **Server**: 4 CPU cores, 16GB RAM minimum
- **GPU**: Recommended for Ollama (NVIDIA with CUDA support)
- **Network**: Stable internet connection
- **SSL Certificate**: For HTTPS endpoints
- **Domain**: Configured DNS

## Backend Deployment

### Step 1: Database Migration

Run the AI consultations migration:

```bash
cd backend

# Run migration
php artisan migrate

# Verify table creation
php artisan db:show ai_consultations
```

**Expected Output**:
```
Table: ai_consultations
Columns: 15
Indexes: 3
Foreign Keys: 1
```

### Step 2: Storage Configuration

Set up image storage directories:

```bash
# Create storage directories
mkdir -p storage/app/public/consultations
chmod -R 775 storage/app/public/consultations
chown -R www-data:www-data storage/app/public/consultations

# Create symbolic link
php artisan storage:link

# Verify link
ls -la public/storage
```

### Step 3: Environment Configuration

Update `.env` file with production settings:

```env
# Application
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.gharsewa.com

# Database
DB_CONNECTION=mysql
DB_HOST=your-db-host
DB_PORT=3306
DB_DATABASE=gharsewa_prod
DB_USERNAME=gharsewa_user
DB_PASSWORD=your-secure-password

# Ollama Configuration
OLLAMA_HOST=http://ollama-server:11434
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=60

# AI Consultation Settings
AI_CONSULTATION_MAX_IMAGE_SIZE_KB=10240
AI_CONSULTATION_MAX_MARKERS=10
AI_CONSULTATION_RETENTION_DAYS=365

# Storage
FILESYSTEM_DISK=public

# Cache
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis

# Redis
REDIS_HOST=your-redis-host
REDIS_PASSWORD=your-redis-password
REDIS_PORT=6379
```

### Step 4: Ollama Service Setup

#### Option A: Docker Deployment

Create `docker-compose.ollama.yml`:

```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: gharsewa_ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped

volumes:
  ollama_data:
```

Deploy Ollama:

```bash
# Start Ollama service
docker-compose -f docker-compose.ollama.yml up -d

# Pull qwen3-vl:2b model
docker exec gharsewa_ollama ollama pull qwen3-vl:2b

# Verify model
docker exec gharsewa_ollama ollama list
```

#### Option B: Native Installation

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama service
systemctl start ollama
systemctl enable ollama

# Pull model
ollama pull qwen3-vl:2b

# Verify
ollama list
```


### Step 5: Optimize Laravel

```bash
# Clear and cache configuration
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Optimize autoloader
composer install --optimize-autoloader --no-dev

# Generate application key (if not set)
php artisan key:generate
```

### Step 6: Set Up Scheduled Tasks

Add to crontab for cleanup command:

```bash
# Edit crontab
crontab -e

# Add Laravel scheduler
* * * * * cd /path/to/backend && php artisan schedule:run >> /dev/null 2>&1
```

Verify cleanup command is scheduled:

```bash
php artisan schedule:list
```

Expected output should include:
```
0 0 * * * php artisan ai:cleanup-consultations
```

### Step 7: Configure Web Server

#### Nginx Configuration

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name api.gharsewa.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.gharsewa.com;

    root /var/www/gharsewa/backend/public;
    index index.php;

    # SSL Configuration
    ssl_certificate /etc/ssl/certs/gharsewa.crt;
    ssl_certificate_key /etc/ssl/private/gharsewa.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Increase upload size for images
    client_max_body_size 15M;

    # Logging
    access_log /var/log/nginx/gharsewa-access.log;
    error_log /var/log/nginx/gharsewa-error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

Restart Nginx:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

### Step 8: Set Up Monitoring

#### Laravel Logs

```bash
# Set up log rotation
sudo nano /etc/logrotate.d/laravel

# Add configuration
/var/www/gharsewa/backend/storage/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
}
```

#### Ollama Monitoring

```bash
# Check Ollama status
curl http://localhost:11434/api/tags

# Monitor Ollama logs
docker logs -f gharsewa_ollama

# Check GPU usage (if using GPU)
nvidia-smi
```

### Step 9: Test Backend Deployment

```bash
# Test API health
curl https://api.gharsewa.com/api/health

# Test authentication
curl -X POST https://api.gharsewa.com/api/v1/auth/jwt/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"password"}'

# Test AI consultation endpoint (with valid JWT)
curl -X GET https://api.gharsewa.com/api/v1/customer/ai/consultations \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

## Flutter Deployment

### Step 1: Update Configuration

Update API base URL in Flutter app:

**File**: `lib/core/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'https://api.gharsewa.com/api/v1';
  static const Duration timeout = Duration(seconds: 60);
  static const int maxRetries = 3;
}
```

### Step 2: Build Android APK/AAB

```bash
# Clean build
flutter clean
flutter pub get

# Build APK (for testing)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### Step 3: Build iOS IPA

```bash
# Clean build
flutter clean
flutter pub get

# Build iOS
flutter build ios --release

# Archive in Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device" as target
# 2. Product → Archive
# 3. Distribute App → App Store Connect
```

### Step 4: Configure App Permissions

#### Android Permissions

**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera permission -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Storage permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="28" />
    
    <!-- Internet permission -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Camera feature -->
    <uses-feature android:name="android.hardware.camera" 
                  android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" 
                  android:required="false" />
</manifest>
```

#### iOS Permissions

**File**: `ios/Runner/Info.plist`

```xml
<dict>
    <!-- Camera permission -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to capture images of service issues for AI analysis</string>
    
    <!-- Photo library permission -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need photo library access to select images for AI analysis</string>
    
    <!-- Photo library add permission -->
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>We need permission to save consultation images</string>
</dict>
```


### Step 5: App Store Submission

#### Google Play Store

1. **Prepare Store Listing**:
   - App name: Gharsewa
   - Short description: Home services marketplace with AI diagnosis
   - Full description: Include AI Visual Assistant features
   - Screenshots: Include AI consultation flow
   - Feature graphic: Highlight AI capabilities

2. **Upload AAB**:
   - Go to Google Play Console
   - Select app → Production → Create new release
   - Upload `app-release.aab`
   - Add release notes mentioning AI Visual Assistant

3. **Content Rating**:
   - Complete questionnaire
   - Ensure appropriate rating for image upload feature

4. **Privacy Policy**:
   - Update to include AI image analysis
   - Mention data retention (12 months)
   - Explain image storage and processing

#### Apple App Store

1. **Prepare App Store Connect**:
   - App name: Gharsewa
   - Subtitle: AI-Powered Home Services
   - Description: Highlight AI Visual Assistant
   - Keywords: Include "AI", "diagnosis", "home services"
   - Screenshots: iOS-specific screenshots

2. **Upload Build**:
   - Use Xcode or Transporter app
   - Upload IPA from Archive
   - Wait for processing

3. **App Review Information**:
   - Demo account credentials
   - Notes about AI feature
   - Test images for reviewers

4. **Privacy**:
   - Data collection disclosure
   - Camera and photo library usage
   - Image processing and storage

## Post-Deployment

### Step 1: Smoke Testing

Test critical paths in production:

```bash
# Backend health check
curl https://api.gharsewa.com/api/health

# Create test consultation
# (Use Postman or mobile app)

# Check logs
tail -f /var/www/gharsewa/backend/storage/logs/laravel.log

# Monitor Ollama
docker logs -f gharsewa_ollama
```

### Step 2: Performance Monitoring

#### Set Up Application Performance Monitoring (APM)

**Option A: Laravel Telescope (Development/Staging)**

```bash
composer require laravel/telescope
php artisan telescope:install
php artisan migrate
```

**Option B: New Relic (Production)**

```bash
# Install New Relic PHP agent
# Follow: https://docs.newrelic.com/docs/apm/agents/php-agent/

# Configure in .env
NEW_RELIC_ENABLED=true
NEW_RELIC_APP_NAME="Gharsewa API"
```

**Option C: Sentry (Error Tracking)**

```bash
composer require sentry/sentry-laravel
php artisan sentry:publish --dsn=YOUR_DSN
```

#### Monitor Key Metrics

- **API Response Time**: Target < 2s for consultation creation
- **AI Processing Time**: Target 15-35s
- **Error Rate**: Target < 1%
- **Image Upload Success**: Target > 99%
- **Storage Usage**: Monitor disk space

### Step 3: Set Up Alerts

#### Disk Space Alert

```bash
# Create monitoring script
sudo nano /usr/local/bin/check_disk_space.sh

#!/bin/bash
THRESHOLD=80
USAGE=$(df -h /var/www/gharsewa/backend/storage | awk 'NR==2 {print $5}' | sed 's/%//')

if [ $USAGE -gt $THRESHOLD ]; then
    echo "Disk usage is at ${USAGE}%" | mail -s "Disk Space Alert" admin@gharsewa.com
fi

# Make executable
sudo chmod +x /usr/local/bin/check_disk_space.sh

# Add to crontab (check hourly)
0 * * * * /usr/local/bin/check_disk_space.sh
```

#### Ollama Service Alert

```bash
# Create monitoring script
sudo nano /usr/local/bin/check_ollama.sh

#!/bin/bash
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "Ollama service is down" | mail -s "Ollama Alert" admin@gharsewa.com
    docker restart gharsewa_ollama
fi

# Add to crontab (check every 5 minutes)
*/5 * * * * /usr/local/bin/check_ollama.sh
```

### Step 4: Backup Strategy

#### Database Backups

```bash
# Create backup script
sudo nano /usr/local/bin/backup_db.sh

#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/database"
DB_NAME="gharsewa_prod"
DB_USER="gharsewa_user"
DB_PASS="your-password"

mkdir -p $BACKUP_DIR

mysqldump -u $DB_USER -p$DB_PASS $DB_NAME | gzip > $BACKUP_DIR/gharsewa_$DATE.sql.gz

# Keep only last 30 days
find $BACKUP_DIR -name "gharsewa_*.sql.gz" -mtime +30 -delete

# Make executable
sudo chmod +x /usr/local/bin/backup_db.sh

# Add to crontab (daily at 2 AM)
0 2 * * * /usr/local/bin/backup_db.sh
```

#### Image Storage Backups

```bash
# Create backup script
sudo nano /usr/local/bin/backup_images.sh

#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backups/images"
SOURCE_DIR="/var/www/gharsewa/backend/storage/app/public/consultations"

mkdir -p $BACKUP_DIR

# Incremental backup using rsync
rsync -av --delete $SOURCE_DIR $BACKUP_DIR/consultations_$DATE/

# Keep only last 7 days
find $BACKUP_DIR -name "consultations_*" -mtime +7 -exec rm -rf {} \;

# Add to crontab (daily at 3 AM)
0 3 * * * /usr/local/bin/backup_images.sh
```

### Step 5: Documentation Updates

Update production documentation:

1. **API Documentation**: Update base URLs
2. **User Guide**: Add production-specific notes
3. **Support Documentation**: Include production troubleshooting
4. **Runbook**: Create operations runbook for on-call team

## Rollback Plan

### Backend Rollback

```bash
# Revert migration
php artisan migrate:rollback --step=1

# Restore previous code version
git checkout previous-tag
composer install --no-dev
php artisan config:cache
php artisan route:cache

# Restart services
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx
```

### Flutter Rollback

#### Android

1. Go to Google Play Console
2. Select app → Production
3. Click "Manage" on current release
4. Select "Halt rollout" or "Roll back"

#### iOS

1. Go to App Store Connect
2. Select app → App Store
3. Remove current version from sale
4. Submit previous version for review

## Security Checklist

- [ ] SSL certificate installed and valid
- [ ] HTTPS enforced for all API endpoints
- [ ] Database credentials secured
- [ ] JWT secret key rotated
- [ ] File upload validation enabled
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] Debug mode disabled in production
- [ ] Error messages don't expose sensitive info
- [ ] Image storage directory permissions correct
- [ ] Backup encryption enabled
- [ ] Monitoring and alerting active

## Performance Checklist

- [ ] Laravel caches enabled (config, route, view)
- [ ] Database indexes created
- [ ] Image compression configured
- [ ] CDN configured for image delivery (optional)
- [ ] Redis cache configured
- [ ] Queue workers running
- [ ] Ollama service optimized (GPU if available)
- [ ] Nginx gzip compression enabled
- [ ] PHP opcache enabled
- [ ] Database connection pooling configured

## Compliance Checklist

- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Data retention policy documented
- [ ] GDPR compliance (if applicable)
- [ ] User consent for image processing
- [ ] Data deletion process implemented
- [ ] Audit logging enabled
- [ ] Incident response plan documented

---

**Version**: 1.0  
**Last Updated**: January 2024  
**For**: Gharsewa - AI Visual Assistant Feature Deployment
