# 🔧 Login 401 Error - Complete Solution Guide

## Problem Summary

You're getting a **401 Unauthorized** error when trying to sign in with registered credentials.

## Root Cause

The most common cause is that the user either:
1. **Doesn't exist** in the database
2. **Email not verified** after registration
3. **Wrong password** being entered

## Solution Steps

### Step 1: Check if Backend is Running

```powershell
# Check Docker containers
docker ps
```

**Expected output:** You should see 4 containers running:
- `gharsewa-app` (Laravel)
- `gharsewa-db` (MySQL)
- `gharsewa-redis` (Redis)
- `gharsewa-nginx` (Nginx)

If containers are not running:
```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

### Step 2: Create a Test User

Since PHP is not installed on your system, use Docker to run commands:

```powershell
# Access MySQL database through Docker
docker exec -it gharsewa-db mysql -u root -proot_password gharsewa
```

Then run this SQL:
```sql
-- Delete existing test user if exists
DELETE FROM users WHERE email = 'test@example.com';

-- Create test user with verified email
INSERT INTO users (
    name, 
    email, 
    password, 
    role, 
    is_active, 
    email_verified_at, 
    created_at, 
    updated_at
)
VALUES (
    'Test User',
    'test@example.com',
    '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYfujPn7Twu',
    'customer',
    1,
    NOW(),
    NOW(),
    NOW()
);

-- Verify the user was created
SELECT id, name, email, role, email_verified_at FROM users WHERE email = 'test@example.com';

-- Exit MySQL
EXIT;
```

**Test Credentials:**
- **Email:** `test@example.com`
- **Password:** `Password123`

### Step 3: Test Login in Flutter App

1. Open your Flutter app
2. Enter credentials:
   - Email: `test@example.com`
   - Password: `Password123`
3. Click "Sign In"
4. You should be logged in successfully!

### Step 4: If You Want to Use Your Own Account

If you already registered but can't log in, verify your email:

```powershell
# Access MySQL
docker exec -it gharsewa-db mysql -u root -proot_password gharsewa
```

```sql
-- Check if your user exists
SELECT id, name, email, email_verified_at FROM users WHERE email = 'your-email@example.com';

-- If email_verified_at is NULL, verify it manually
UPDATE users 
SET email_verified_at = NOW() 
WHERE email = 'your-email@example.com';

-- Verify it worked
SELECT id, name, email, email_verified_at FROM users WHERE email = 'your-email@example.com';

EXIT;
```

## Alternative: Complete Registration Flow

If you want to test the full registration flow:

1. **Register a new account:**
   - Click "Don't have an account? Register"
   - Fill in Name, Email, Password
   - Click "Create Account"

2. **Check email for OTP:**
   - Check your email inbox
   - Look for "Verify Your Email - Gharsewa"
   - Copy the 6-digit OTP code

3. **Verify email:**
   - Enter OTP in the app
   - Click "Verify"

4. **Login:**
   - You'll be automatically logged in after verification
   - Or go back to login screen and sign in

## Quick Commands Reference

### Check Docker Containers
```powershell
docker ps
```

### Start Backend
```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

### Stop Backend
```powershell
cd e:\gharsewa\backend
docker-compose down
```

### Access MySQL Database
```powershell
docker exec -it gharsewa-db mysql -u root -proot_password gharsewa
```

### View Laravel Logs
```powershell
docker logs gharsewa-app --tail=50
```

### Run Laravel Commands
```powershell
# Example: Run migrations
docker exec -it gharsewa-app php artisan migrate

# Example: Clear cache
docker exec -it gharsewa-app php artisan cache:clear
```

## Test API Directly (Optional)

You can test the login API using PowerShell:

```powershell
$body = @{
    email = "test@example.com"
    password = "Password123"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/login" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

**Expected response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "abc123...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "1",
      "name": "Test User",
      "email": "test@example.com",
      "role": "customer",
      "email_verified_at": "2024-01-01T00:00:00.000000Z"
    }
  }
}
```

## Troubleshooting

### Error: "Cannot connect to Docker daemon"
**Solution:** Start Docker Desktop

### Error: "Container not found"
**Solution:** 
```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

### Error: "Access denied for user"
**Solution:** Check MySQL password in `.env` file (should be `root_password`)

### Error: Still getting 401 after creating test user
**Solution:** 
1. Check if backend is running: `docker ps`
2. Check Laravel logs: `docker logs gharsewa-app --tail=50`
3. Verify user exists in database
4. Try restarting Flutter app (press 'R')

## Summary

**Quick Fix:**
1. Make sure Docker containers are running
2. Create test user with SQL script above
3. Login with `test@example.com` / `Password123`

**For Your Own Account:**
1. Register through the app
2. Verify email with OTP
3. Login with your credentials

---

**Most Common Issue:** Email not verified after registration.

**Quick Solution:** Manually verify email in database using SQL UPDATE command.

