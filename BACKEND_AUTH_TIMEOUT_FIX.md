# Backend Auth Timeout Fix

## Problem
Login endpoint (`/api/v1/auth/jwt/login`) was timing out after 30 seconds with DioException.

## Root Cause
The `tymon/jwt-auth` package was listed in `composer.json` but not actually installed in the Docker container's vendor directory. This caused Laravel to fail to bootstrap when handling HTTP requests through PHP-FPM, resulting in connection resets and timeouts.

## Solution Applied

### 1. Installed JWT Auth Package
```bash
docker exec gharsewa_app composer require tymon/jwt-auth
```

### 2. Created .dockerignore
Created `backend/.dockerignore` to exclude problematic files during Docker build:
- `public/storage` (symlink)
- `storage/*` (runtime files)
- `bootstrap/cache/*` (cached files)
- `vendor/` (will be installed during build)

### 3. Rebuilt Docker Image
Rebuilt the app container from scratch to include JWT package in the image:
```bash
docker-compose -f backend/docker-compose.yml build --no-cache app
```

### 4. Removed Old Volumes
Removed old anonymous volumes that contained outdated vendor directory:
```bash
docker-compose -f backend/docker-compose.yml down -v
docker-compose -f backend/docker-compose.yml up -d
```

### 5. Cleared Bootstrap Cache
Removed cached service provider files that referenced wrong classes:
```bash
rm backend/bootstrap/cache/*.php
docker exec gharsewa_app rm -f /var/www/bootstrap/cache/*.php
```

## Current Status
- ✅ JWT Auth package installed in Docker image
- ✅ Laravel can bootstrap successfully (`php artisan --version` works)
- ✅ Login route is registered
- ⚠️ HTTP requests still timing out (nginx → PHP-FPM communication issue)

## Next Steps
The JWT package is now properly installed, but there's still an issue with nginx forwarding requests to PHP-FPM. This needs further investigation:

1. Check PHP-FPM configuration
2. Check nginx FastCGI configuration
3. Verify file permissions
4. Check if index.php exists and is readable

## Files Modified
- `backend/.dockerignore` (created)
- `backend/composer.json` (already had jwt-auth)
- Docker image rebuilt with JWT package

## Commands to Test
```bash
# Test Laravel bootstrap
docker exec gharsewa_app php artisan --version

# Test route exists
docker exec gharsewa_app php artisan route:list --path=auth/jwt/login

# Test from host (currently times out)
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'
```
