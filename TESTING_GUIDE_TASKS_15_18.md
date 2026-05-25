# Testing Guide: Tasks 15 & 18

## Overview
This guide provides step-by-step instructions for manually testing the Profile Management and Provider Dashboard APIs (Tasks 15 & 18).

---

## Prerequisites

### 1. Ensure Backend is Running
```bash
cd backend
php artisan serve
# Backend should be running at http://localhost:8000
```

### 2. Configure Storage
```bash
# Create symbolic link for public storage
php artisan storage:link

# Verify storage directory exists
mkdir -p storage/app/public/profile-images
```

### 3. Get JWT Tokens
You'll need JWT tokens for testing. Use the login endpoint:

```bash
# Login as Customer
POST http://localhost:8000/api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "customer@example.com",
  "password": "password"
}

# Login as Service Provider
POST http://localhost:8000/api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "provider@example.com",
  "password": "password"
}
```

Save the `access_token` from the response for use in subsequent requests.

---

## Task 15: Test Profile APIs (45 minutes)

### Test 1: Get Profile (All Roles)
**Endpoint**: `GET /api/v1/profile`  
**Auth**: JWT (any role)

```bash
GET http://localhost:8000/api/v1/profile
Authorization: Bearer {your_jwt_token}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "uuid",
    "name": "User Name",
    "email": "user@example.com",
    "role": "customer",
    "phone_number": "+1234567890",
    "profile_image_url": null,
    "is_active": true,
    "email_verified_at": "2024-01-01T00:00:00.000000Z",
    "last_login_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**Test Cases**:
- ✅ Valid JWT token returns profile
- ✅ Invalid JWT token returns 401
- ✅ Missing JWT token returns 401
- ✅ Profile includes all required fields

---

### Test 2: Update Profile (All Roles)
**Endpoint**: `PUT /api/v1/profile`  
**Auth**: JWT (any role)

```bash
PUT http://localhost:8000/api/v1/profile
Authorization: Bearer {your_jwt_token}
Content-Type: application/json

{
  "name": "Updated Name",
  "phone_number": "+9876543210",
  "address": "123 Main Street, City, Country"
}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "uuid",
    "name": "Updated Name",
    "email": "user@example.com",
    "role": "customer",
    "phone_number": "+9876543210",
    "profile_image_url": null,
    "is_active": true,
    "email_verified_at": "2024-01-01T00:00:00.000000Z",
    "last_login_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

**Test Cases**:
- ✅ Update name only
- ✅ Update phone_number only
- ✅ Update address only
- ✅ Update all fields together
- ✅ Update with empty body (no changes)
- ✅ Invalid data returns 422 validation error
- ✅ Name exceeding 255 characters returns 422
- ✅ Phone number exceeding 20 characters returns 422

**Validation Test**:
```bash
PUT http://localhost:8000/api/v1/profile
Authorization: Bearer {your_jwt_token}
Content-Type: application/json

{
  "name": "A very long name that exceeds the maximum allowed length of 255 characters... (repeat until > 255 chars)",
  "phone_number": "123456789012345678901234567890"
}
```

**Expected Response** (422 Unprocessable Entity):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "name": ["The name must not be greater than 255 characters."],
    "phone_number": ["The phone number must not be greater than 20 characters."]
  }
}
```

---

### Test 3: Upload Profile Image (All Roles)
**Endpoint**: `POST /api/v1/profile/image`  
**Auth**: JWT (any role)

```bash
POST http://localhost:8000/api/v1/profile/image
Authorization: Bearer {your_jwt_token}
Content-Type: multipart/form-data

image: [select a JPEG/PNG/JPG file < 2MB]
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Profile image uploaded successfully",
  "data": {
    "image_url": "/storage/profile-images/1234567890_uuid.jpg",
    "path": "profile-images/1234567890_uuid.jpg"
  }
}
```

**Test Cases**:
- ✅ Upload valid JPEG image
- ✅ Upload valid PNG image
- ✅ Upload valid JPG image
- ✅ Upload replaces old image (verify old image deleted)
- ✅ Image > 2MB returns 422 validation error
- ✅ Non-image file returns 422 validation error
- ✅ Invalid file type (e.g., PDF) returns 422 validation error
- ✅ Missing image field returns 422 validation error

**Validation Test (File Too Large)**:
```bash
POST http://localhost:8000/api/v1/profile/image
Authorization: Bearer {your_jwt_token}
Content-Type: multipart/form-data

image: [select a file > 2MB]
```

**Expected Response** (422 Unprocessable Entity):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "image": ["The image must not be greater than 2048 kilobytes."]
  }
}
```

**Validation Test (Invalid File Type)**:
```bash
POST http://localhost:8000/api/v1/profile/image
Authorization: Bearer {your_jwt_token}
Content-Type: multipart/form-data

image: [select a PDF or TXT file]
```

**Expected Response** (422 Unprocessable Entity):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "image": ["The image must be a file of type: jpeg, png, jpg."]
  }
}
```

---

## Task 18: Test Provider Dashboard APIs (1 hour)

### Test 1: Get Provider Profile
**Endpoint**: `GET /api/v1/provider/profile`  
**Auth**: JWT (serviceProvider role only)

```bash
GET http://localhost:8000/api/v1/provider/profile
Authorization: Bearer {provider_jwt_token}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Provider profile retrieved successfully",
  "data": {
    "id": "uuid",
    "name": "Provider Name",
    "email": "provider@example.com",
    "role": "serviceProvider",
    "phone_number": "+1234567890",
    "profile_image_url": null,
    "is_active": true,
    "email_verified_at": "2024-01-01T00:00:00.000000Z",
    "last_login_at": "2024-01-01T00:00:00.000000Z",
    "services_count": 5
  }
}
```

**Test Cases**:
- ✅ Valid provider JWT token returns profile with services_count
- ✅ Customer JWT token returns 403 (role check)
- ✅ Invalid JWT token returns 401
- ✅ Services count is accurate

---

### Test 2: Update Provider Profile
**Endpoint**: `PUT /api/v1/provider/profile`  
**Auth**: JWT (serviceProvider role only)

```bash
PUT http://localhost:8000/api/v1/provider/profile
Authorization: Bearer {provider_jwt_token}
Content-Type: application/json

{
  "name": "Updated Provider Name",
  "phone_number": "+9876543210",
  "business_name": "My Awesome Business",
  "business_description": "We provide the best services in town",
  "address": "456 Business Avenue, City, Country"
}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Provider profile updated successfully",
  "data": {
    "id": "uuid",
    "name": "Updated Provider Name",
    "email": "provider@example.com",
    "role": "serviceProvider",
    "phone_number": "+9876543210",
    "profile_image_url": null,
    "is_active": true,
    "email_verified_at": "2024-01-01T00:00:00.000000Z",
    "last_login_at": "2024-01-01T00:00:00.000000Z",
    "services_count": 5
  }
}
```

**Test Cases**:
- ✅ Update name and phone_number
- ✅ Update business_name and business_description
- ✅ Update address
- ✅ Update all fields together
- ✅ Business fields stored in metadata
- ✅ Validation errors for invalid data (422)

---

### Test 3: Get Dashboard Statistics
**Endpoint**: `GET /api/v1/provider/dashboard`  
**Auth**: JWT (serviceProvider role only)

```bash
GET http://localhost:8000/api/v1/provider/dashboard
Authorization: Bearer {provider_jwt_token}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Dashboard statistics retrieved successfully",
  "data": {
    "total_services": 5,
    "active_services": 3,
    "total_bookings": 42,
    "pending_bookings": 3,
    "this_month_earnings": 1250.50,
    "this_month_bookings": 12,
    "average_rating": 0
  }
}
```

**Test Cases**:
- ✅ All statistics are calculated correctly
- ✅ total_services includes all services (active + inactive)
- ✅ active_services only includes status='active'
- ✅ total_bookings includes all bookings
- ✅ pending_bookings only includes status='pending'
- ✅ this_month_earnings only includes completed bookings
- ✅ this_month_earnings is for current month only
- ✅ this_month_bookings is for current month only
- ✅ average_rating is 0 (placeholder)
- ✅ Customer JWT token returns 403

**Verification Steps**:
1. Create some services for the provider
2. Create some bookings for those services
3. Mark some bookings as completed
4. Verify the statistics match the actual data

---

### Test 4: Get Earnings Breakdown
**Endpoint**: `GET /api/v1/provider/earnings`  
**Auth**: JWT (serviceProvider role only)

#### Test 4a: Daily Grouping (Default)
```bash
GET http://localhost:8000/api/v1/provider/earnings?date_from=2024-01-01&date_to=2024-01-31&group_by=day
Authorization: Bearer {provider_jwt_token}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Earnings breakdown retrieved successfully",
  "data": {
    "date_from": "2024-01-01",
    "date_to": "2024-01-31",
    "group_by": "day",
    "total_earnings": 1250.50,
    "total_bookings": 12,
    "breakdown": [
      {
        "period": "2024-01-15",
        "date": "2024-01-15",
        "earnings": 150.00,
        "bookings": 2
      },
      {
        "period": "2024-01-16",
        "date": "2024-01-16",
        "earnings": 200.00,
        "bookings": 3
      }
    ]
  }
}
```

#### Test 4b: Weekly Grouping
```bash
GET http://localhost:8000/api/v1/provider/earnings?date_from=2024-01-01&date_to=2024-01-31&group_by=week
Authorization: Bearer {provider_jwt_token}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Earnings breakdown retrieved successfully",
  "data": {
    "date_from": "2024-01-01",
    "date_to": "2024-01-31",
    "group_by": "week",
    "total_earnings": 1250.50,
    "total_bookings": 12,
    "breakdown": [
      {
        "period": "202401",
        "date": "2024-01-01",
        "earnings": 450.00,
        "bookings": 5
      },
      {
        "period": "202402",
        "date": "2024-01-08",
        "earnings": 800.50,
        "bookings": 7
      }
    ]
  }
}
```

#### Test 4c: Monthly Grouping
```bash
GET http://localhost:8000/api/v1/provider/earnings?date_from=2024-01-01&date_to=2024-12-31&group_by=month
Authorization: Bearer {provider_jwt_token}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Earnings breakdown retrieved successfully",
  "data": {
    "date_from": "2024-01-01",
    "date_to": "2024-12-31",
    "group_by": "month",
    "total_earnings": 15000.00,
    "total_bookings": 120,
    "breakdown": [
      {
        "period": "2024-01",
        "date": null,
        "earnings": 1250.50,
        "bookings": 12
      },
      {
        "period": "2024-02",
        "date": null,
        "earnings": 1500.00,
        "bookings": 15
      }
    ]
  }
}
```

#### Test 4d: Default Parameters (Current Month, Daily)
```bash
GET http://localhost:8000/api/v1/provider/earnings
Authorization: Bearer {provider_jwt_token}
```

**Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Earnings breakdown retrieved successfully",
  "data": {
    "date_from": "2024-01-01",
    "date_to": "2024-01-31",
    "group_by": "day",
    "total_earnings": 1250.50,
    "total_bookings": 12,
    "breakdown": [...]
  }
}
```

**Test Cases**:
- ✅ Daily grouping works correctly
- ✅ Weekly grouping works correctly
- ✅ Monthly grouping works correctly
- ✅ Default parameters use current month and daily grouping
- ✅ Only completed bookings are included
- ✅ Date range filtering works correctly
- ✅ Total earnings and bookings are accurate
- ✅ Breakdown array is sorted by period
- ✅ Invalid group_by returns 422 validation error
- ✅ Invalid date format returns 422 validation error
- ✅ date_to before date_from returns 422 validation error
- ✅ Customer JWT token returns 403

**Validation Test (Invalid group_by)**:
```bash
GET http://localhost:8000/api/v1/provider/earnings?group_by=invalid
Authorization: Bearer {provider_jwt_token}
```

**Expected Response** (422 Unprocessable Entity):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "group_by": ["The selected group by is invalid."]
  }
}
```

**Validation Test (Invalid date range)**:
```bash
GET http://localhost:8000/api/v1/provider/earnings?date_from=2024-01-31&date_to=2024-01-01
Authorization: Bearer {provider_jwt_token}
```

**Expected Response** (422 Unprocessable Entity):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "date_to": ["The date to must be a date after or equal to date from."]
  }
}
```

---

## Testing Checklist

### Task 15: Profile APIs
- [ ] Get profile with valid JWT token
- [ ] Get profile with invalid JWT token (401)
- [ ] Get profile without JWT token (401)
- [ ] Update profile with valid data
- [ ] Update profile with invalid data (422)
- [ ] Update profile with partial data
- [ ] Upload valid image (JPEG)
- [ ] Upload valid image (PNG)
- [ ] Upload valid image (JPG)
- [ ] Upload image > 2MB (422)
- [ ] Upload non-image file (422)
- [ ] Upload replaces old image
- [ ] Verify old image is deleted from storage

### Task 18: Provider Dashboard APIs
- [ ] Get provider profile with provider JWT token
- [ ] Get provider profile with customer JWT token (403)
- [ ] Update provider profile with valid data
- [ ] Update provider profile with business fields
- [ ] Get dashboard statistics
- [ ] Verify all statistics are accurate
- [ ] Get earnings with daily grouping
- [ ] Get earnings with weekly grouping
- [ ] Get earnings with monthly grouping
- [ ] Get earnings with default parameters
- [ ] Get earnings with custom date range
- [ ] Get earnings with invalid group_by (422)
- [ ] Get earnings with invalid date range (422)
- [ ] Verify only completed bookings are included
- [ ] Verify customer JWT token returns 403

---

## Common Issues & Solutions

### Issue 1: 401 Unauthorized
**Cause**: Invalid or expired JWT token  
**Solution**: Get a new JWT token by logging in again

### Issue 2: 403 Forbidden
**Cause**: User role doesn't match required role  
**Solution**: Use a JWT token with the correct role (e.g., serviceProvider for provider endpoints)

### Issue 3: 422 Validation Error
**Cause**: Invalid input data  
**Solution**: Check the error response for specific validation failures and correct the input

### Issue 4: 500 Internal Server Error
**Cause**: Server-side error  
**Solution**: Check Laravel logs at `backend/storage/logs/laravel.log`

### Issue 5: Image Upload Fails
**Cause**: Storage not configured  
**Solution**: Run `php artisan storage:link` and verify `storage/app/public/profile-images` exists

### Issue 6: Statistics Don't Match
**Cause**: Test data not set up correctly  
**Solution**: Create test services and bookings, mark some as completed, then verify statistics

---

## Success Criteria

### Task 15 Complete When:
- ✅ All profile endpoints return correct responses
- ✅ Validation works correctly
- ✅ Image upload works and old images are deleted
- ✅ Authorization checks work (401 for invalid tokens)

### Task 18 Complete When:
- ✅ All provider dashboard endpoints return correct responses
- ✅ Statistics are calculated accurately
- ✅ Earnings breakdown works for all grouping options
- ✅ Date range filtering works correctly
- ✅ Validation works correctly
- ✅ Authorization checks work (403 for non-providers)

---

## Next Steps After Testing

1. ✅ Mark Tasks 15 & 18 as complete in tasks.md
2. ✅ Document any issues found and their resolutions
3. ✅ Proceed to Task 19: Integration Testing
4. ✅ Create Postman collection (Task 20)
5. ✅ Create API documentation (Task 21)

---

**Happy Testing! 🚀**
