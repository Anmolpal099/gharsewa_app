# Role Management System - Laravel Implementation

**Date:** 2026-05-21  
**Status:** ✅ **COMPLETE**

---

## Overview

This project uses **Laravel-based role management** instead of Firebase Cloud Functions. Roles are managed through Laravel API endpoints and synced with Firebase custom claims.

### Why Laravel Instead of Cloud Functions?

1. **Centralized Management**: All backend logic in one place
2. **Easier Debugging**: No need to deploy separate Cloud Functions
3. **Database Integration**: Roles stored in MySQL for querying and reporting
4. **Cost Effective**: No additional Firebase Cloud Functions costs
5. **Simpler Architecture**: One backend system instead of two

---

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Firebase Auth)│
└────────┬────────┘
         │ ID Token
         ▼
┌─────────────────┐
│  Laravel API    │
│  - Verify Token │
│  - Set Claims   │
│  - Store in DB  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│  MySQL Database │◄────┤ Firebase SDK │
│  (users table)  │     │ (Custom Claims)
└─────────────────┘     └──────────────┘
```

---

## Database Schema

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    role ENUM('customer', 'serviceProvider', 'admin') DEFAULT 'customer',
    phone_number VARCHAR(255) NULL,
    profile_image_url VARCHAR(255) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSON NULL,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    INDEX idx_role_active (role, is_active),
    INDEX idx_firebase_uid (firebase_uid)
);
```

---

## API Endpoints

### 1. Register User (Public)

**Endpoint:** `POST /api/v1/auth/register`

**Request:**
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
  "name": "John Doe",
  "role": "customer"  // Optional, defaults to "customer"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "id": "9d4e8f2a-1234-5678-90ab-cdef12345678",
    "uid": "firebase_uid_here",
    "email": "john@example.com",
    "name": "John Doe",
    "role": "customer"
  }
}
```

**What it does:**
1. Verifies Firebase ID token
2. Sets custom claims in Firebase (role)
3. Creates user record in MySQL database
4. Returns user data

---

### 2. Login (Public)

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": "9d4e8f2a-1234-5678-90ab-cdef12345678",
    "uid": "firebase_uid_here",
    "email": "john@example.com",
    "name": "John Doe",
    "role": "customer"
  }
}
```

**What it does:**
1. Verifies Firebase ID token
2. Updates last_login_at in database
3. Returns user data with role from Firebase claims

---

### 3. Get Current User (Protected)

**Endpoint:** `GET /api/v1/auth/me`

**Headers:**
```
Authorization: Bearer <firebase_id_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "9d4e8f2a-1234-5678-90ab-cdef12345678",
    "uid": "firebase_uid_here",
    "email": "john@example.com",
    "name": "John Doe",
    "role": "customer",
    "phone_number": "+1234567890",
    "profile_image_url": "https://...",
    "is_active": true,
    "last_login_at": "2026-05-21T08:30:00Z",
    "created_at": "2026-05-20T10:00:00Z"
  }
}
```

---

### 4. Update User Role (Admin Only)

**Endpoint:** `POST /api/v1/auth/update-role`

**Headers:**
```
Authorization: Bearer <admin_firebase_id_token>
```

**Request:**
```json
{
  "user_id": "9d4e8f2a-1234-5678-90ab-cdef12345678",
  "role": "serviceProvider"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User role updated successfully",
  "data": {
    "id": "9d4e8f2a-1234-5678-90ab-cdef12345678",
    "uid": "firebase_uid_here",
    "email": "john@example.com",
    "name": "John Doe",
    "role": "serviceProvider"
  }
}
```

**What it does:**
1. Verifies admin role (via RoleMiddleware)
2. Updates custom claims in Firebase
3. Updates role in MySQL database
4. User must refresh token to see new role

---

## Laravel Models

### User Model

**Location:** `backend/app/Models/User.php`

**Key Methods:**
```php
// Check user role
$user->isCustomer()         // Returns bool
$user->isServiceProvider()  // Returns bool
$user->isAdmin()            // Returns bool

// Query scopes
User::byRole('customer')->get()
User::active()->get()

// Relationships
$user->services()              // Services provided (if provider)
$user->customerBookings()      // Bookings made (if customer)
$user->providerBookings()      // Bookings received (if provider)
$user->reviewsGiven()          // Reviews written
$user->reviewsReceived()       // Reviews received (if provider)
```

---

## Middleware

### FirebaseAuthMiddleware

**Location:** `backend/app/Http/Middleware/FirebaseAuthMiddleware.php`

**Purpose:** Verifies Firebase ID token on every protected request

**How it works:**
1. Extracts Bearer token from Authorization header
2. Verifies token with Firebase Admin SDK
3. Extracts user UID, role, email, name from token claims
4. Attaches to request as `firebase_uid`, `firebase_role`, etc.
5. Returns 401 if token is invalid or expired

**Usage:**
```php
Route::middleware('firebase.auth')->group(function () {
    // Protected routes
});
```

---

### RoleMiddleware

**Location:** `backend/app/Http/Middleware/RoleMiddleware.php`

**Purpose:** Checks if user has required role

**How it works:**
1. Reads `firebase_role` from request (set by FirebaseAuthMiddleware)
2. Compares with required role(s)
3. Returns 403 if role doesn't match

**Usage:**
```php
// Single role
Route::middleware('role:admin')->group(function () {
    // Admin-only routes
});

// Multiple roles
Route::middleware('role:customer,serviceProvider')->group(function () {
    // Customer or Provider routes
});
```

---

## Flutter Integration

### Registration Flow

```dart
// 1. Create Firebase account
final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// 2. Get ID token
final idToken = await credential.user?.getIdToken();

// 3. Call Laravel API to set role and create DB record
await apiClient.post('/v1/auth/register', data: {
  'id_token': idToken,
  'name': name,
  'role': 'customer', // default role
});

// 4. Force token refresh to get new custom claims
await credential.user?.getIdToken(true);
```

### Login Flow

```dart
// 1. Sign in with Firebase
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// 2. Get ID token (automatically includes role from custom claims)
final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

// 3. Call Laravel API to update last login
await apiClient.post('/v1/auth/login', data: {
  'id_token': idToken,
});
```

### API Requests with Token

```dart
// Dio interceptor automatically attaches token
class _FirebaseTokenInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken(); // Auto-refreshes if expired
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

### Get User Role

```dart
final user = FirebaseAuth.instance.currentUser;
final idTokenResult = await user?.getIdTokenResult();
final role = idTokenResult?.claims?['role']; // 'customer', 'serviceProvider', or 'admin'
```

---

## Role Types

### 1. Customer
- **Default role** for new users
- Can browse services
- Can create bookings
- Can write reviews
- Can manage their profile

### 2. Service Provider
- Can create and manage services
- Can accept/reject booking requests
- Can view earnings and analytics
- Can receive reviews

### 3. Admin
- Can view platform dashboard
- Can manage all users
- Can change user roles
- Can view all bookings
- Can generate reports
- Full platform access

---

## Security

### Token Verification

Every protected request:
1. Extracts Bearer token from header
2. Verifies with Firebase Admin SDK
3. Checks token signature, expiry, and issuer
4. Extracts custom claims (role)
5. Attaches user info to request

### Role-Based Access Control

```php
// Example: Only admins can access
Route::middleware(['firebase.auth', 'role:admin'])->group(function () {
    Route::post('auth/update-role', [AuthController::class, 'updateRole']);
    Route::get('admin/dashboard', [AdminController::class, 'dashboard']);
});

// Example: Customers and providers can access
Route::middleware(['firebase.auth', 'role:customer,serviceProvider'])->group(function () {
    Route::get('services', [ServiceController::class, 'index']);
});
```

### Rate Limiting

```php
// Auth endpoints limited to 10 requests per minute
Route::prefix('auth')->middleware('api.limit:10')->group(function () {
    Route::post('login', [AuthController::class, 'login']);
    Route::post('register', [AuthController::class, 'register']);
});
```

---

## Testing

### Test User Registration

```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "YOUR_FIREBASE_ID_TOKEN",
    "name": "Test User",
    "role": "customer"
  }'
```

### Test Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "YOUR_FIREBASE_ID_TOKEN"
  }'
```

### Test Get Current User

```bash
curl -X GET http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN"
```

### Test Update Role (Admin Only)

```bash
curl -X POST http://localhost:8000/api/v1/auth/update-role \
  -H "Authorization: Bearer ADMIN_FIREBASE_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "9d4e8f2a-1234-5678-90ab-cdef12345678",
    "role": "serviceProvider"
  }'
```

---

## Creating the First Admin User

### Option 1: Direct Database Update

```sql
-- Update user role in database
UPDATE users 
SET role = 'admin' 
WHERE email = 'admin@example.com';
```

Then manually set Firebase custom claims using Firebase Admin SDK or Firebase Console.

### Option 2: Laravel Tinker

```bash
docker exec -it gharsewa_app php artisan tinker
```

```php
// Find user
$user = App\Models\User::where('email', 'admin@example.com')->first();

// Update role in database
$user->update(['role' => 'admin']);

// Set Firebase custom claims
$factory = (new Kreait\Firebase\Factory)->withServiceAccount(storage_path('app/firebase-credentials.json'));
$auth = $factory->createAuth();
$auth->setCustomUserClaims($user->firebase_uid, ['role' => 'admin']);
```

### Option 3: Seed File

Create `database/seeders/AdminUserSeeder.php`:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Kreait\Firebase\Factory;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        // Create admin user in database
        $admin = User::create([
            'firebase_uid' => 'FIREBASE_UID_HERE',
            'email' => 'admin@gharsewa.com',
            'name' => 'Admin User',
            'role' => 'admin',
            'is_active' => true,
        ]);

        // Set Firebase custom claims
        $factory = (new Factory)->withServiceAccount(storage_path('app/firebase-credentials.json'));
        $auth = $factory->createAuth();
        $auth->setCustomUserClaims($admin->firebase_uid, ['role' => 'admin']);
    }
}
```

---

## Troubleshooting

### Issue: Role not updating in Flutter app

**Solution:** Force token refresh after role change:
```dart
await FirebaseAuth.instance.currentUser?.getIdToken(true);
```

### Issue: 401 Unauthorized on protected routes

**Solution:** 
1. Check if token is being sent in Authorization header
2. Verify token is not expired
3. Check Firebase credentials file exists and is valid

### Issue: 403 Forbidden on role-protected routes

**Solution:**
1. Verify user has correct role in Firebase custom claims
2. Check RoleMiddleware is applied correctly
3. Force token refresh to get latest claims

### Issue: User not found in database

**Solution:**
1. Ensure `/auth/register` was called after Firebase signup
2. Check database connection
3. Verify migrations were run

---

## Best Practices

1. **Always call `/auth/register` after Firebase signup** to create database record
2. **Force token refresh after role changes** to get updated claims
3. **Use middleware for role checks** instead of manual verification
4. **Store sensitive data in database** not in Firebase custom claims
5. **Rate limit auth endpoints** to prevent abuse
6. **Log role changes** for audit trail
7. **Validate all inputs** before updating roles

---

## Summary

✅ **Epic 4: Authentication & Authorization - COMPLETE**

- ✅ Firebase Admin SDK installed in Laravel
- ✅ Firebase token verification middleware created
- ✅ Role-based authorization middleware created
- ✅ Laravel API endpoints for role management
- ✅ User model with role methods
- ✅ Database integration for user data
- ✅ Flutter authentication service
- ✅ Login UI with validation
- ✅ Token refresh interceptor

**No Firebase Cloud Functions needed!** All role management is handled through Laravel API.

---

**Last Updated:** 2026-05-21

