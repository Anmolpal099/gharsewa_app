# Manual Integration Testing Guide

## Quick Reference for Testing Complete User Workflows

This guide provides step-by-step instructions for manually testing the complete user workflows described in Task 19.

---

## Prerequisites

1. **Backend Running:**
   ```powershell
   cd e:\gharsewa\backend
   docker-compose up -d
   ```

2. **Test Users Created:**
   - Provider: `provider@test.com` / `Test1234`
   - Customer: `customer@test.com` / `Test1234`

3. **Tool:** Use Postman, Insomnia, or curl

---

## Test 1: Complete Provider Workflow

### Step 1: Login as Provider

**Request:**
```http
POST http://localhost:8000/api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "provider@test.com",
  "password": "Test1234"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600
  }
}
```

**Action:** Save the `access_token` for subsequent requests.

---

### Step 2: Create a Service

**Request:**
```http
POST http://localhost:8000/api/v1/provider/services
Authorization: Bearer {provider_token}
Content-Type: application/json

{
  "name": "House Cleaning Service",
  "description": "Professional house cleaning service with experienced staff",
  "category": "Cleaning",
  "price": 1500,
  "duration_minutes": 120,
  "currency": "NPR"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Service created successfully",
  "data": {
    "id": "uuid-here",
    "name": "House Cleaning Service",
    "description": "Professional house cleaning service with experienced staff",
    "category": "Cleaning",
    "price": 1500,
    "duration_minutes": 120,
    "currency": "NPR",
    "status": "active",
    "provider_id": "provider-uuid",
    "created_at": "2026-05-26T12:00:00.000000Z"
  }
}
```

**Action:** Save the service `id` for booking creation.

---

### Step 3: Customer Creates Booking

**Request:**
```http
POST http://localhost:8000/api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "customer@test.com",
  "password": "Test1234"
}
```

**Then:**
```http
POST http://localhost:8000/api/v1/customer/bookings
Authorization: Bearer {customer_token}
Content-Type: application/json

{
  "service_id": "{service_id_from_step_2}",
  "scheduled_at": "2026-06-01 10:00:00",
  "notes": "Please bring cleaning supplies"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "id": "booking-uuid",
    "customer_id": "customer-uuid",
    "service_id": "service-uuid",
    "provider_id": "provider-uuid",
    "status": "pending",
    "total_price": 1500,
    "currency": "NPR",
    "scheduled_at": "2026-06-01 10:00:00",
    "notes": "Please bring cleaning supplies"
  }
}
```

**Verify:**
- ✅ Status is "pending"
- ✅ Total price matches service price (1500)
- ✅ Provider ID is automatically set

**Action:** Save the booking `id`.

---

### Step 4: Provider Views Booking

**Request:**
```http
GET http://localhost:8000/api/v1/provider/bookings/{booking_id}
Authorization: Bearer {provider_token}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking retrieved successfully",
  "data": {
    "id": "booking-uuid",
    "status": "pending",
    "total_price": 1500,
    "customer": {
      "id": "customer-uuid",
      "name": "Test Customer",
      "email": "customer@test.com"
    },
    "service": {
      "id": "service-uuid",
      "name": "House Cleaning Service"
    }
  }
}
```

**Verify:**
- ✅ Provider can see booking details
- ✅ Customer information is included
- ✅ Service information is included

---

### Step 5: Provider Accepts Booking

**Request:**
```http
POST http://localhost:8000/api/v1/provider/bookings/{booking_id}/accept
Authorization: Bearer {provider_token}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking accepted successfully",
  "data": {
    "id": "booking-uuid",
    "status": "confirmed"
  }
}
```

**Verify:**
- ✅ Status changed from "pending" to "confirmed"

---

### Step 6: Provider Completes Booking

**Request:**
```http
POST http://localhost:8000/api/v1/provider/bookings/{booking_id}/complete
Authorization: Bearer {provider_token}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking marked as completed successfully",
  "data": {
    "id": "booking-uuid",
    "status": "completed"
  }
}
```

**Verify:**
- ✅ Status changed from "confirmed" to "completed"

---

### Step 7: Provider Views Dashboard

**Request:**
```http
GET http://localhost:8000/api/v1/provider/dashboard
Authorization: Bearer {provider_token}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Dashboard data retrieved successfully",
  "data": {
    "total_services": 1,
    "active_services": 1,
    "total_bookings": 1,
    "pending_bookings": 0,
    "this_month_earnings": 1500,
    "this_month_bookings": 1,
    "average_rating": 0
  }
}
```

**Verify:**
- ✅ Total services = 1
- ✅ Total bookings = 1
- ✅ Pending bookings = 0 (completed)
- ✅ This month earnings = 1500

---

## Test 2: Complete Customer Workflow

### Step 1: Browse Services (No Auth Required)

**Request:**
```http
GET http://localhost:8000/api/v1/services
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Services retrieved successfully",
  "data": [
    {
      "id": "service-uuid",
      "name": "House Cleaning Service",
      "category": "Cleaning",
      "price": 1500,
      "status": "active",
      "provider": {
        "id": "provider-uuid",
        "name": "Test Provider"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 1
  }
}
```

**Verify:**
- ✅ No authentication required
- ✅ Only active services shown
- ✅ Provider information included

---

### Step 2: View Service Details

**Request:**
```http
GET http://localhost:8000/api/v1/services/{service_id}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Service retrieved successfully",
  "data": {
    "id": "service-uuid",
    "name": "House Cleaning Service",
    "description": "Professional house cleaning service with experienced staff",
    "category": "Cleaning",
    "price": 1500,
    "duration_minutes": 120,
    "currency": "NPR",
    "status": "active",
    "provider": {
      "id": "provider-uuid",
      "name": "Test Provider",
      "email": "provider@test.com"
    }
  }
}
```

**Verify:**
- ✅ Full service details shown
- ✅ Provider details included

---

### Step 3: Login as Customer

**Request:**
```http
POST http://localhost:8000/api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "customer@test.com",
  "password": "Test1234"
}
```

**Action:** Save the `access_token`.

---

### Step 4: Create Booking

**Request:**
```http
POST http://localhost:8000/api/v1/customer/bookings
Authorization: Bearer {customer_token}
Content-Type: application/json

{
  "service_id": "{service_id}",
  "scheduled_at": "2026-06-05 14:00:00",
  "notes": "Kitchen sink is leaking"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "id": "booking-uuid",
    "status": "pending",
    "total_price": 1500
  }
}
```

**Verify:**
- ✅ Booking created successfully
- ✅ Status is "pending"

**Action:** Save the booking `id`.

---

### Step 5: View My Bookings

**Request:**
```http
GET http://localhost:8000/api/v1/customer/bookings
Authorization: Bearer {customer_token}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Bookings retrieved successfully",
  "data": [
    {
      "id": "booking-uuid",
      "status": "pending",
      "total_price": 1500,
      "scheduled_at": "2026-06-05 14:00:00",
      "service": {
        "name": "House Cleaning Service"
      },
      "provider": {
        "name": "Test Provider"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 1
  }
}
```

**Verify:**
- ✅ Customer sees their booking
- ✅ Service and provider info included

---

### Step 6: Cancel Booking

**Request:**
```http
PUT http://localhost:8000/api/v1/customer/bookings/{booking_id}/cancel
Authorization: Bearer {customer_token}
Content-Type: application/json

{
  "cancellation_reason": "Found another service provider"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking cancelled successfully",
  "data": {
    "id": "booking-uuid",
    "status": "cancelled",
    "cancellation_reason": "Found another service provider"
  }
}
```

**Verify:**
- ✅ Status changed to "cancelled"
- ✅ Cancellation reason saved

---

## Test 3: Authentication & Authorization

### Test 3.1: Unauthenticated Access (Should Fail)

**Request:**
```http
GET http://localhost:8000/api/v1/customer/bookings
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

**Status Code:** 401

**Verify:**
- ✅ Protected endpoints require authentication

---

### Test 3.2: Wrong Role Access (Should Fail)

**Request:**
```http
GET http://localhost:8000/api/v1/provider/services
Authorization: Bearer {customer_token}
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

**Status Code:** 403

**Verify:**
- ✅ Customers cannot access provider endpoints

---

### Test 3.3: Cross-User Access (Should Fail)

Create a second customer, then try to access first customer's booking:

**Request:**
```http
GET http://localhost:8000/api/v1/customer/bookings/{other_customer_booking_id}
Authorization: Bearer {customer2_token}
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Unauthorized access to booking"
}
```

**Status Code:** 403

**Verify:**
- ✅ Users cannot access other users' resources

---

## Test 4: Error Handling & Validation

### Test 4.1: Invalid Service Data

**Request:**
```http
POST http://localhost:8000/api/v1/provider/services
Authorization: Bearer {provider_token}
Content-Type: application/json

{
  "name": "",
  "price": -100,
  "duration_minutes": 5
}
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "name": ["The name field is required."],
    "description": ["The description field is required."],
    "category": ["The category field is required."],
    "price": ["The price must be at least 0."],
    "duration_minutes": ["The duration minutes must be at least 15."]
  }
}
```

**Status Code:** 422

**Verify:**
- ✅ Validation errors returned
- ✅ All invalid fields listed

---

### Test 4.2: Book Inactive Service

First, deactivate a service:

**Request:**
```http
PATCH http://localhost:8000/api/v1/provider/services/{service_id}/status
Authorization: Bearer {provider_token}
Content-Type: application/json

{
  "status": "inactive"
}
```

Then try to book it:

**Request:**
```http
POST http://localhost:8000/api/v1/customer/bookings
Authorization: Bearer {customer_token}
Content-Type: application/json

{
  "service_id": "{inactive_service_id}",
  "scheduled_at": "2026-06-10 10:00:00"
}
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Service is not available for booking"
}
```

**Status Code:** 400

**Verify:**
- ✅ Cannot book inactive services

---

### Test 4.3: Invalid Status Transition

Try to complete a pending booking (should be confirmed first):

**Request:**
```http
POST http://localhost:8000/api/v1/provider/bookings/{pending_booking_id}/complete
Authorization: Bearer {provider_token}
```

**Expected Response:**
```json
{
  "success": false,
  "message": "Only confirmed bookings can be marked as completed"
}
```

**Status Code:** 400

**Verify:**
- ✅ Status transitions are enforced

---

## Test 5: Service Search & Filtering

### Test 5.1: Filter by Category

**Request:**
```http
GET http://localhost:8000/api/v1/services?category=Cleaning
```

**Verify:**
- ✅ Only services in "Cleaning" category returned

---

### Test 5.2: Filter by Price Range

**Request:**
```http
GET http://localhost:8000/api/v1/services?min_price=1000&max_price=2000
```

**Verify:**
- ✅ Only services within price range returned

---

### Test 5.3: Search by Name

**Request:**
```http
GET http://localhost:8000/api/v1/services?search=cleaning
```

**Verify:**
- ✅ Services matching search term returned
- ✅ Search is case-insensitive

---

### Test 5.4: Get Categories

**Request:**
```http
GET http://localhost:8000/api/v1/services/categories
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Categories retrieved successfully",
  "data": [
    {
      "category": "Cleaning",
      "count": 2
    },
    {
      "category": "Plumbing",
      "count": 1
    }
  ]
}
```

**Verify:**
- ✅ All categories listed
- ✅ Counts are accurate

---

## Test 6: Provider Statistics

### Test 6.1: View Dashboard

**Request:**
```http
GET http://localhost:8000/api/v1/provider/dashboard
Authorization: Bearer {provider_token}
```

**Verify:**
- ✅ Total services count
- ✅ Active services count
- ✅ Total bookings count
- ✅ Pending bookings count
- ✅ This month earnings
- ✅ This month bookings count

---

### Test 6.2: View Booking Statistics

**Request:**
```http
GET http://localhost:8000/api/v1/provider/bookings/stats
Authorization: Bearer {provider_token}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Booking statistics retrieved successfully",
  "data": {
    "total_bookings": 5,
    "pending_count": 1,
    "confirmed_count": 2,
    "completed_count": 2,
    "cancelled_count": 0,
    "rejected_count": 0,
    "total_revenue": 3000,
    "date_from": "2026-05-01",
    "date_to": "2026-05-31"
  }
}
```

**Verify:**
- ✅ Counts by status are accurate
- ✅ Revenue includes only completed bookings
- ✅ Date range is correct

---

### Test 6.3: Statistics with Date Range

**Request:**
```http
GET http://localhost:8000/api/v1/provider/bookings/stats?date_from=2026-05-01&date_to=2026-05-15
Authorization: Bearer {provider_token}
```

**Verify:**
- ✅ Only bookings within date range counted

---

## Test Checklist

Use this checklist to track your manual testing progress:

### Provider Workflow
- [ ] Provider can create service
- [ ] Provider can view their services
- [ ] Provider can update service
- [ ] Provider can activate/deactivate service
- [ ] Provider can view booking requests
- [ ] Provider can accept booking
- [ ] Provider can reject booking with reason
- [ ] Provider can complete booking
- [ ] Provider can view dashboard statistics
- [ ] Provider cannot delete service with active bookings

### Customer Workflow
- [ ] Anyone can browse services (no auth)
- [ ] Anyone can view service details
- [ ] Customer can create booking
- [ ] Customer can view their bookings
- [ ] Customer can cancel booking
- [ ] Customer cannot book inactive service
- [ ] Customer cannot cancel completed booking

### Authentication & Authorization
- [ ] Unauthenticated requests are rejected (401)
- [ ] Wrong role requests are rejected (403)
- [ ] Cross-user access is blocked (403)
- [ ] Users can access their own resources (200)

### Validation & Error Handling
- [ ] Invalid service data returns validation errors
- [ ] Invalid booking data returns validation errors
- [ ] Business logic violations return 400 errors
- [ ] Invalid status transitions are blocked

### Search & Filtering
- [ ] Filter by category works
- [ ] Filter by price range works
- [ ] Search by name works
- [ ] Categories list is accurate

### Statistics
- [ ] Dashboard shows correct counts
- [ ] Booking stats are accurate
- [ ] Revenue calculation is correct
- [ ] Date range filtering works

---

## Summary

**Total Test Scenarios:** 6 major workflows  
**Total Test Cases:** 30+ individual tests  
**Estimated Testing Time:** 45-60 minutes

**Coverage:**
- ✅ All functional requirements (FR1-FR6)
- ✅ Authentication and authorization (NFR1)
- ✅ Validation rules
- ✅ Business logic constraints
- ✅ Error handling
- ✅ Complete user workflows

This manual testing guide ensures comprehensive validation of all Phase 1 Backend API endpoints and workflows.
