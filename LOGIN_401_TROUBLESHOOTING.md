# 🔍 Login 401 Error Troubleshooting Guide

## Problem

Getting **401 Unauthorized** error when trying to sign in with registered credentials.

**Error Message:**
```
DioException [bad response]: This exception was thrown because the response 
has a status code of 401 and RequestOptions.validateStatus was configured 
to throw for this status code.

The status code of 401 has the following meaning: "Client error - the request 
contains bad syntax or cannot be fulfilled"
```

## Possible Causes

### 1. **Invalid Credentials** ❌
- Email or password is incorrect
- User doesn't exist in database
- Password doesn't match

### 2. **Email Not Verified** ⚠️
- User registered but hasn't verified email with OTP
- `email_verified_at` is NULL in database

### 3. **Backend Not Running** ❌
- Laravel backend is not running
- Docker containers are down

### 4. **Wrong API Endpoint** ❌
- Flutter app is calling wrong URL
- API route doesn't exist

## Diagnostic Steps

### Step 1: Check Backend is Running

```bash
# Check if Docker containers are running
docker ps

# Should see:
# - gharsewa-app (Laravel)
# - gharsewa-db (MySQL)
# - gharsewa-redis (Redis)
# - gharsewa-nginx (Nginx)
```

**Expected Output:**
```
CONTAINER ID   IMAGE          STATUS         PORTS
xxxxx          gharsewa-app   Up 5 minutes   9000/tcp
xxxxx          mysql:8.0      Up 5 minutes   3306/tcp, 33060/tcp
xxxxx          redis:7        Up 5 minutes   6379/tcp
xxxxx          nginx:latest   Up 5 minutes   0.0.0.0:8000->80/tcp
```

### Step 2: Check User Exists in Database

```bash
# Access MySQL container
docker exec -it gharsewa-db mysql -u root -p

# Enter password: root_password

# Check users table
USE gharsewa;
SELECT id, name, email, role, email_verified_at, created_at FROM users;
```

**What to Look For:**
- Does your email exist in the users table?
- Is `email_verified_at` NULL or has a timestamp?
- What is the `role` value?

### Step 3: Test Login API Directly

```bash
# Test login endpoint with curl
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'
```

**Expected Responses:**

**Success (200):**
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
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer",
      "email_verified_at": "2024-01-01T00:00:00.000000Z"
    }
  }
}
```

**Failure (401):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

### Step 4: Check Laravel Logs

```bash
# View Laravel logs
docker exec -it gharsewa-app tail -f storage/logs/laravel.log

# Or check all logs
docker logs gharsewa-app --tail=50
```

**Look for:**
- Authentication errors
- Database connection errors
- JWT token errors

## Common Solutions

### Solution 1: User Doesn't Exist - Register First

If the user doesn't exist in the database, you need to register:

1. **In Flutter App:**
   - Click "Don't have an account? Register"
   - Fill in Name, Email, Password
   - Click "Create Account"
   - Enter OTP from email
   - Now try logging in

2. **Check Email for OTP:**
   - Check your email inbox
   - Look for "Verify Your Email - Gharsewa"
   - Copy the 6-digit OTP code
   - Enter it in the app

### Solution 2: Email Not Verified - Verify Email

If `email_verified_at` is NULL, the user needs to verify their email:

**Option A: Resend OTP (if implemented)**
- Click "Resend OTP" on verification screen

**Option B: Manually verify in database (for testing)**
```sql
-- Access MySQL
docker exec -it gharsewa-db mysql -u root -p

USE gharsewa;

-- Verify email manually
UPDATE users 
SET email_verified_at = NOW() 
WHERE email = 'your-email@example.com';

-- Check it worked
SELECT email, email_verified_at FROM users WHERE email = 'your-email@example.com';
```

### Solution 3: Wrong Password - Reset Password

If you forgot your password:

1. **In Flutter App:**
   - Click "Forgot Password?"
   - Enter your email
   - Click "Send OTP"
   - Enter OTP from email
   - Set new password

2. **Or manually reset in database (for testing)**
```sql
-- Access MySQL
docker exec -it gharsewa-db mysql -u root -p

USE gharsewa;

-- Reset password to "Password123"
UPDATE users 
SET password = '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYfujPn7Twu' 
WHERE email = 'your-email@example.com';
```

### Solution 4: Create Test User

Create a test user with verified email:

```sql
-- Access MySQL
docker exec -it gharsewa-db mysql -u root -p

USE gharsewa;

-- Create test user
INSERT INTO users (name, email, password, role, is_active, email_verified_at, created_at, updated_at)
VALUES (
  'Test User',
  'test@example.com',
  '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYfujPn7Twu', -- Password123
  'customer',
  1,
  NOW(),
  NOW(),
  NOW()
);

-- Verify it was created
SELECT * FROM users WHERE email = 'test@example.com';
```

**Test Credentials:**
- Email: `test@example.com`
- Password: `Password123`

### Solution 5: Check API URL in Flutter

Verify the Flutter app is using the correct API URL:

**File:** `lib/core/constants/api_constants.dart`

```dart
class ApiConstants {
  static String get baseUrl {
    if (PlatformDetector.isWeb) {
      return 'http://localhost:8000/api';
    } else if (PlatformDetector.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://localhost:8000/api'; // iOS, Desktop
    }
  }
}
```

**For Windows Desktop:** Should be `http://localhost:8000/api` ✅

## Quick Test Script

Save this as `test-login.sh` and run it:

```bash
#!/bin/bash

echo "Testing Login API..."
echo ""

# Test with test user
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123"
  }' | jq '.'

echo ""
echo "If you see 'Invalid credentials', the user doesn't exist or password is wrong."
echo "If you see 'access_token', login is working!"
```

## Debugging Checklist

- [ ] Backend Docker containers are running
- [ ] Can access http://localhost:8000 in browser
- [ ] User exists in database (check with SQL query)
- [ ] Email is verified (`email_verified_at` is not NULL)
- [ ] Password is correct
- [ ] API URL in Flutter app is correct
- [ ] No errors in Laravel logs
- [ ] Can login with curl/Postman

## Still Not Working?

### Enable Debug Mode

1. **Check Laravel logs in real-time:**
```bash
docker exec -it gharsewa-app tail -f storage/logs/laravel.log
```

2. **Try logging in from Flutter app**

3. **Look for errors in logs:**
   - Database connection errors
   - JWT configuration errors
   - Authentication errors

### Check JWT Configuration

```bash
# Access Laravel container
docker exec -it gharsewa-app bash

# Check JWT secret is set
php artisan tinker
>>> config('jwt.secret')
# Should return a long string, not null

# If null, generate JWT secret
php artisan jwt:secret
```

### Check Database Connection

```bash
# Access Laravel container
docker exec -it gharsewa-app bash

# Test database connection
php artisan tinker
>>> DB::connection()->getPdo()
# Should return PDO object, not error
```

## Expected Behavior

### Successful Login Flow

```
1. User enters email and password
2. Flutter app sends POST to /api/v1/auth/jwt/login
3. Backend validates credentials
4. Backend generates JWT tokens
5. Backend returns tokens + user data
6. Flutter app saves tokens
7. Flutter app navigates to dashboard
```

### Failed Login Flow

```
1. User enters email and password
2. Flutter app sends POST to /api/v1/auth/jwt/login
3. Backend validates credentials
4. Credentials are invalid
5. Backend returns 401 error
6. Flutter app shows error message
7. User stays on login screen
```

## Contact Support

If none of these solutions work:

1. **Check backend logs:** `docker logs gharsewa-app`
2. **Check database:** Verify user exists and email is verified
3. **Test API directly:** Use curl or Postman
4. **Check network:** Ensure backend is accessible

---

**Most Common Issue:** User hasn't verified their email with OTP after registration.

**Quick Fix:** Manually verify email in database or complete OTP verification flow.

