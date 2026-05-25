# Docker Fix Guide - Registration & Email Issues

## Current Status
- ✅ All code is complete and correct
- ✅ Email configuration is correct in `.env`
- ⚠️ Docker containers need to reload configuration
- ⚠️ Need to verify services are running

---

## Step 1: Check Docker Services Status

```powershell
cd e:\gharsewa\backend
docker-compose ps
```

**Expected Output:**
```
NAME                  STATUS
gharsewa_app          Up
gharsewa_nginx        Up
gharsewa_db           Up (healthy)
gharsewa_redis        Up (healthy)
gharsewa_websocket    Up or Restarting
gharsewa_queue        Up
gharsewa_scheduler    Up
```

**If any service is not running:**
```powershell
docker-compose up -d
```

---

## Step 2: Clear Laravel Configuration Cache

The `.env` file was updated but Docker containers haven't reloaded it yet.

```powershell
cd e:\gharsewa\backend
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
```

**Expected Output:**
```
Configuration cache cleared successfully.
Application cache cleared successfully.
```

---

## Step 3: Restart App Container

```powershell
docker-compose restart app
```

Wait 5-10 seconds for the container to fully restart.

---

## Step 4: Test Email Sending

Run the test script inside Docker:

```powershell
docker-compose exec app php test-email-simple.php
```

**Expected Output:**
```
🧪 Testing Email Configuration
================================

📧 Sending test email to: anmolpal156@gmail.com
✅ Email sent successfully!
📬 Check your Gmail inbox: anmolpal156@gmail.com
```

**If you see errors:**
- Check the error message
- Verify Gmail credentials in `.env`
- Check Laravel logs (Step 5)

---

## Step 5: Check Laravel Logs

```powershell
docker-compose exec app tail -100 storage/logs/laravel.log
```

Look for:
- Email sending errors
- Registration errors
- Database connection errors

---

## Step 6: Test Registration API Directly

Test the registration endpoint using PowerShell:

```powershell
$body = @{
    name = "Test User"
    email = "test@example.com"
    password = "Test1234"
    role = "customer"
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/register" -Method Post -Body $body -Headers $headers
```

**Expected Success Response:**
```json
{
  "success": true,
  "message": "User registered successfully. Please check your email for the verification code.",
  "data": {
    "user_id": 1,
    "email": "test@example.com",
    "name": "Test User",
    "role": "customer",
    "otp_sent": true,
    "otp_expires_in": 600
  }
}
```

**If you see errors:**
- Note the error message
- Check if it's a database error, validation error, or email error

---

## Step 7: Hot Restart Flutter App

After backend is working:

1. In your Flutter terminal, press **`R`** (capital R) for hot restart
2. Or stop and restart the app completely

---

## Step 8: Test Registration in Flutter App

1. Open the app
2. Click "Don't have an account? Register"
3. Fill in:
   - **Name:** Test User
   - **Email:** your-email@gmail.com (use a real email you can access)
   - **Password:** Test1234 (must have uppercase, lowercase, digit)
4. Click "Create Account"

**Expected Behavior:**
- App navigates to OTP input screen
- You receive an email with 6-digit OTP code
- Enter OTP to verify email

**If registration fails:**
- Read the error message (it now shows the actual error)
- Share the error message

---

## Common Issues & Solutions

### Issue 1: "Connection refused" or "Network error"

**Cause:** Backend not running or wrong URL

**Solution:**
```powershell
# Check if nginx is running
docker-compose ps nginx

# Restart nginx
docker-compose restart nginx

# Test backend is accessible
curl http://localhost:8000/api/v1/health
```

### Issue 2: "Database connection error"

**Cause:** MySQL container not ready

**Solution:**
```powershell
# Check database health
docker-compose ps db

# Restart database
docker-compose restart db

# Wait 10 seconds, then restart app
Start-Sleep -Seconds 10
docker-compose restart app
```

### Issue 3: "Email not sending"

**Cause:** Gmail credentials incorrect or not loaded

**Solution:**
1. Verify `.env` has correct credentials:
   ```
   MAIL_USERNAME=anmolpal156@gmail.com
   MAIL_PASSWORD=zbpdaovlpjjppnxq
   MAIL_FROM_ADDRESS="anmolpal156@gmail.com"
   ```

2. Clear config and restart:
   ```powershell
   docker-compose exec app php artisan config:clear
   docker-compose restart app
   ```

3. Test email again:
   ```powershell
   docker-compose exec app php test-email-simple.php
   ```

### Issue 4: "Validation Error"

**Cause:** Password doesn't meet requirements

**Solution:**
Password must have:
- At least 8 characters
- At least 1 uppercase letter (A-Z)
- At least 1 lowercase letter (a-z)
- At least 1 digit (0-9)

Example valid passwords:
- `Test1234`
- `Password123`
- `MyPass99`

### Issue 5: "Email already registered"

**Cause:** Email already exists in database

**Solution:**
Use a different email or delete the existing user:

```powershell
docker-compose exec app php artisan tinker
```

If tinker is not available, use MySQL directly:
```powershell
docker-compose exec db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "DELETE FROM users WHERE email='test@example.com';"
```

---

## Troubleshooting Checklist

Run through this checklist:

- [ ] Docker Desktop is running
- [ ] All containers are up: `docker-compose ps`
- [ ] Config cache cleared: `docker-compose exec app php artisan config:clear`
- [ ] App container restarted: `docker-compose restart app`
- [ ] Test email works: `docker-compose exec app php test-email-simple.php`
- [ ] Backend accessible: Open http://localhost:8000 in browser
- [ ] Flutter app hot restarted
- [ ] Using valid password format (uppercase, lowercase, digit, 8+ chars)

---

## Quick Command Reference

```powershell
# Navigate to backend
cd e:\gharsewa\backend

# Check services
docker-compose ps

# Start all services
docker-compose up -d

# Clear config cache
docker-compose exec app php artisan config:clear

# Restart app
docker-compose restart app

# Test email
docker-compose exec app php test-email-simple.php

# View logs
docker-compose exec app tail -100 storage/logs/laravel.log

# Stop all services
docker-compose down

# Restart all services
docker-compose restart
```

---

## What to Share If Still Not Working

If you still have issues after following all steps, please share:

1. **Docker Status:**
   ```powershell
   docker-compose ps
   ```

2. **Email Test Output:**
   ```powershell
   docker-compose exec app php test-email-simple.php
   ```

3. **Laravel Logs:**
   ```powershell
   docker-compose exec app tail -100 storage/logs/laravel.log
   ```

4. **Registration Error:**
   - Screenshot of error in Flutter app
   - Or exact error message text

5. **API Test Result:**
   - Output from the PowerShell API test (Step 6)

---

## Next Steps After Everything Works

Once registration and email are working:

1. ✅ Test complete registration flow (register → receive OTP → verify)
2. ✅ Test login flow
3. ✅ Test forgot password flow
4. ✅ Test password reset with OTP
5. ✅ Verify JWT tokens work correctly
6. ✅ Test token refresh

---

*Last Updated: Now*
*Status: Ready for testing*
