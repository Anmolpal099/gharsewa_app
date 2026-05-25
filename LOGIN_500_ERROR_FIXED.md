# Login 500 Error - FIXED ✅

## Problem
User was getting 500 Internal Server Error when trying to log in with registered credentials (`test@example.com` / `Password123`).

## Root Causes Identified and Fixed

### 1. JWT Configuration Error
**Error**: `Class "Tymon\JWTAuth\Providers\JWT\Provider" not found at /var/www/config/jwt.php:134`

**Cause**: The JWT config file was referencing a non-existent class constant:
```php
'algo' => env('JWT_ALGO', Tymon\JWTAuth\Providers\JWT\Provider::ALGO_HS256),
```

**Fix**: Changed to use the string value directly:
```php
'algo' => env('JWT_ALGO', 'HS256'),
```

**File**: `backend/config/jwt.php` (line 134)

### 2. Password Hash Incompatibility
**Error**: `This password does not use the Bcrypt algorithm`

**Cause**: The test user's password was hashed using PHP's `password_hash()` function, but Laravel's Hash facade uses a slightly different bcrypt implementation that wasn't compatible.

**Fix**: Generated a new password hash using Laravel's Hash facade and updated the database:
```php
// Generated hash using Laravel
$2y$12$tX214Us4pf74lEUaaWzz8OvDlImQMRy7X5lkzj5DVgKVt.NvCgNIq
```

**Command used**:
```bash
docker exec -it gharsewa_app php generate_hash.php
```

**Database update**:
```sql
UPDATE users 
SET password = '$2y$12$tX214Us4pf74lEUaaWzz8OvDlImQMRy7X5lkzj5DVgKVt.NvCgNIq' 
WHERE email = 'test@example.com';
```

## Test User Credentials
- **Email**: `test@example.com`
- **Password**: `Password123`
- **Role**: customer
- **Email Verified**: YES
- **UUID**: `f730a221-5757-11f1-a8c5-3ed475fbdcab`

## Verification
Login endpoint tested successfully:
```bash
POST http://localhost:8000/api/v1/auth/jwt/login
{
  "email": "test@example.com",
  "password": "Password123"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "me6O2o0Xfbxxu2BjQqLLE9Y2bUUYTDQZi7tJziPDmTiuI5IaL8Dfc40wrFFr9Ixg",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "f730a221-5757-11f1-a8c5-3ed475fbdcab",
      "name": "Test User",
      "email": "test@example.com",
      "role": "customer",
      "email_verified_at": "2026-05-24T10:04:34.000000Z"
    }
  }
}
```

## Files Modified
1. `backend/config/jwt.php` - Fixed JWT algorithm configuration
2. `backend/generate_hash.php` - Created helper script to generate Laravel-compatible password hashes
3. `backend/update_password.sql` - SQL script to update test user password

## Next Steps
1. ✅ Login is now working
2. Test login from Flutter app
3. Verify user can access customer dashboard after login
4. Test token refresh functionality
5. Test logout functionality

## Important Notes
- Always use Laravel's `Hash::make()` to generate password hashes for Laravel applications
- PHP's `password_hash()` and Laravel's `Hash::make()` both use bcrypt but have subtle differences
- The JWT library requires proper configuration - avoid using class constants that don't exist
- Docker containers need config files copied or volumes mounted to reflect host changes
