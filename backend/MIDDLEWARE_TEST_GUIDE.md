# JWT and Role Middleware Testing Guide

## Overview
This guide helps you test the JWT authentication and role-based authorization middleware.

## Prerequisites
- Laravel backend server running (`php artisan serve`)
- API client (Postman, Insomnia, or curl)
- At least one registered user account

## Middleware Configuration

### 1. JWT Middleware (`jwt.auth`)
**Location:** `app/Http/Middleware/JwtMiddleware.php`

**Features:**
- Validates JWT token from Authorization header
- Checks if user exists and is active
- Returns appropriate error messages for expired/invalid tokens

**Registration:** Already registered in `bootstrap/app.php` as `jwt.auth`

### 2. Role Middleware (`role`)
**Location:** `app/Http/Middleware/RoleMiddleware.php`

**Features:**
- Checks if authenticated user has required role(s)
- Supports multiple roles: `role:customer,serviceProvider`
- Returns 401 if not authenticated, 403 if wrong role

**Registration:** Already registered in `bootstrap/app.php` as `role`

## Test Endpoints

The following test endpoints have been added to `routes/api.php`:

### 1. Test JWT Authentication Only
```
GET /api/v1/test/authenticated
Middleware: jwt.auth
```

### 2. Test Customer Role
```
GET /api/v1/test/customer-only
Middleware: jwt.auth, role:customer
```

### 3. Test Service Provider Role
```
GET /api/v1/test/provider-only
Middleware: jwt.auth, role:serviceProvider
```

### 4. Test Admin Role
```
GET /api/v1/test/admin-only
Middleware: jwt.auth, role:admin
```

### 5. Test Multiple Roles
```
GET /api/v1/test/customer-or-provider
Middleware: jwt.auth, role:customer,serviceProvider
```

## Testing Steps

### Step 1: Register a User
```bash
curl -X POST http://localhost:8000/api/v1/auth/jwt/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Customer",
    "email": "customer@test.com",
    "password": "Password123",
    "role": "customer"
  }'
```

### Step 2: Verify Email (if required)
Check your email for OTP and verify:
```bash
curl -X POST http://localhost:8000/api/v1/auth/otp/verify-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "customer@test.com",
    "otp": "123456"
  }'
```

### Step 3: Login to Get JWT Token
```bash
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "customer@test.com",
    "password": "Password123"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "...",
      "name": "Test Customer",
      "email": "customer@test.com",
      "role": "customer"
    }
  }
}
```

### Step 4: Test JWT Authentication
```bash
curl -X GET http://localhost:8000/api/v1/test/authenticated \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response (Success):**
```json
{
  "success": true,
  "message": "JWT authentication working",
  "user": {
    "id": "...",
    "name": "Test Customer",
    "email": "customer@test.com",
    "role": "customer"
  }
}
```

**Expected Response (No Token):**
```json
{
  "success": false,
  "message": "Token not provided",
  "error": "token_absent"
}
```

### Step 5: Test Role Middleware (Correct Role)
```bash
curl -X GET http://localhost:8000/api/v1/test/customer-only \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response (Customer accessing customer-only):**
```json
{
  "success": true,
  "message": "Customer role middleware working",
  "user": {
    "id": "...",
    "name": "Test Customer",
    "email": "customer@test.com",
    "role": "customer"
  }
}
```

### Step 6: Test Role Middleware (Wrong Role)
```bash
curl -X GET http://localhost:8000/api/v1/test/admin-only \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response (Customer accessing admin-only):**
```json
{
  "success": false,
  "message": "You do not have permission to access this resource",
  "required_roles": ["admin"],
  "your_role": "customer"
}
```

### Step 7: Test Multiple Roles
```bash
curl -X GET http://localhost:8000/api/v1/test/customer-or-provider \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response (Customer or Provider):**
```json
{
  "success": true,
  "message": "Multiple role middleware working",
  "user": {
    "id": "...",
    "name": "Test Customer",
    "email": "customer@test.com",
    "role": "customer"
  }
}
```

## Test Matrix

| Endpoint | No Token | Customer Token | Provider Token | Admin Token |
|----------|----------|----------------|----------------|-------------|
| `/test/authenticated` | 401 ❌ | 200 ✅ | 200 ✅ | 200 ✅ |
| `/test/customer-only` | 401 ❌ | 200 ✅ | 403 ❌ | 403 ❌ |
| `/test/provider-only` | 401 ❌ | 403 ❌ | 200 ✅ | 403 ❌ |
| `/test/admin-only` | 401 ❌ | 403 ❌ | 403 ❌ | 200 ✅ |
| `/test/customer-or-provider` | 401 ❌ | 200 ✅ | 200 ✅ | 403 ❌ |

## Error Codes Reference

### JWT Middleware Errors
- **401 - Token not provided:** No Authorization header
- **401 - Token has expired:** JWT token expired (default: 60 minutes)
- **401 - Token is invalid:** Malformed or tampered token
- **403 - User account is inactive:** User's `is_active` flag is false
- **404 - User not found:** User ID in token doesn't exist

### Role Middleware Errors
- **401 - Unauthenticated:** No authenticated user (jwt.auth should run first)
- **403 - Permission denied:** User doesn't have required role

## Automated Test Script

Create a file `test-middleware.sh` in the backend directory:

```bash
#!/bin/bash

BASE_URL="http://localhost:8000/api/v1"

echo "=== Testing JWT and Role Middleware ==="
echo ""

# Register a customer
echo "1. Registering customer..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/jwt/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Customer",
    "email": "test-customer-'$(date +%s)'@test.com",
    "password": "Password123",
    "role": "customer"
  }')
echo "$REGISTER_RESPONSE" | jq .

# Extract email
EMAIL=$(echo "$REGISTER_RESPONSE" | jq -r '.data.email')
echo "Email: $EMAIL"
echo ""

# Login
echo "2. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/jwt/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"Password123\"
  }")
echo "$LOGIN_RESPONSE" | jq .

# Extract token
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.access_token')
echo "Token: ${TOKEN:0:50}..."
echo ""

# Test authenticated endpoint
echo "3. Testing authenticated endpoint..."
curl -s -X GET "$BASE_URL/test/authenticated" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# Test customer-only endpoint (should succeed)
echo "4. Testing customer-only endpoint (should succeed)..."
curl -s -X GET "$BASE_URL/test/customer-only" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# Test admin-only endpoint (should fail with 403)
echo "5. Testing admin-only endpoint (should fail with 403)..."
curl -s -X GET "$BASE_URL/test/admin-only" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# Test without token (should fail with 401)
echo "6. Testing without token (should fail with 401)..."
curl -s -X GET "$BASE_URL/test/authenticated" | jq .
echo ""

echo "=== Tests Complete ==="
```

Make it executable:
```bash
chmod +x test-middleware.sh
./test-middleware.sh
```

## Cleanup

After testing, you can remove the test routes from `routes/api.php` if desired, or keep them for future testing.

## Conclusion

✅ **JWT Middleware (`jwt.auth`)** - Properly configured and working
✅ **Role Middleware (`role`)** - Fixed and ready to use
✅ **Middleware Registration** - Both registered in `bootstrap/app.php`
✅ **Test Endpoints** - Added for verification

The middleware infrastructure is now ready for Phase 1 Backend API implementation!
