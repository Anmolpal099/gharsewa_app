# Docker Commands for Gharsewa Backend

## Your Setup
You're running Laravel in Docker containers. Use these commands instead of direct `php` commands.

---

## Start/Stop Backend

### Start All Services
```bash
cd e:\gharsewa\backend
docker-compose up -d
```

### Stop All Services
```bash
cd e:\gharsewa\backend
docker-compose down
```

### Restart Services (After .env changes)
```bash
cd e:\gharsewa\backend
docker-compose restart
```

---

## Run Laravel Commands

### Clear Config Cache
```bash
docker-compose exec app php artisan config:clear
```

### Clear All Caches
```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
```

### Generate Application Key
```bash
docker-compose exec app php artisan key:generate
```

### Run Migrations
```bash
docker-compose exec app php artisan migrate
```

### Test Email Sending
```bash
docker-compose exec app php artisan tinker
```
Then in tinker:
```php
Mail::raw('Test from Gharsewa', function ($message) {
    $message->to('anmolpal156@gmail.com')
            ->subject('Test Email');
});
exit;
```

---

## Check Logs

### Laravel Logs
```bash
docker-compose exec app tail -f storage/logs/laravel.log
```

### Nginx Logs
```bash
docker-compose logs -f nginx
```

### App Container Logs
```bash
docker-compose logs -f app
```

### All Logs
```bash
docker-compose logs -f
```

---

## Quick Fix Commands

### After Changing .env File:
```bash
cd e:\gharsewa\backend
docker-compose exec app php artisan config:clear
docker-compose restart app
```

### Check if Services are Running:
```bash
docker-compose ps
```

You should see:
- gharsewa_app (running)
- gharsewa_nginx (running)
- gharsewa_db (running)
- gharsewa_redis (running)

---

## Access Backend

The backend is accessible at:
- **HTTP:** http://localhost:8000
- **API:** http://localhost:8000/api

---

## Test Registration Endpoint

```bash
curl -X POST http://localhost:8000/api/v1/auth/jwt/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"name\":\"Test User\",\"email\":\"test@example.com\",\"password\":\"Test1234\",\"role\":\"customer\"}"
```

---

## Common Issues

### Issue: "Cannot connect to Docker daemon"
**Solution:** Start Docker Desktop

### Issue: "Port 8000 already in use"
**Solution:** 
```bash
docker-compose down
# Wait a few seconds
docker-compose up -d
```

### Issue: "Database connection refused"
**Solution:**
```bash
docker-compose restart db
docker-compose restart app
```

---

## Your Action Plan

### Step 1: Restart Backend Services
```bash
cd e:\gharsewa\backend
docker-compose exec app php artisan config:clear
docker-compose restart app
```

### Step 2: Check Services are Running
```bash
docker-compose ps
```

### Step 3: Test Email
```bash
docker-compose exec app php artisan tinker
```
Then:
```php
Mail::raw('Test', function($m){$m->to('anmolpal156@gmail.com')->subject('Test');});
exit;
```

### Step 4: Check Laravel Logs
```bash
docker-compose exec app tail -f storage/logs/laravel.log
```

### Step 5: Try Registration in Flutter App
- Hot restart Flutter app (press 'R')
- Try registration
- Read the error message

---

## Quick Reference

| Task | Command |
|------|---------|
| Start backend | `docker-compose up -d` |
| Stop backend | `docker-compose down` |
| Restart backend | `docker-compose restart` |
| Clear cache | `docker-compose exec app php artisan config:clear` |
| View logs | `docker-compose logs -f app` |
| Run artisan | `docker-compose exec app php artisan <command>` |
| Access shell | `docker-compose exec app bash` |

---

*Use these Docker commands instead of direct `php` commands!*
