# Gharsewa API Documentation - Phase 1 Backend APIs

## Overview

This document provides comprehensive documentation for all Phase 1 Backend API endpoints for the Gharsewa application. The APIs support customer, provider, and admin functionalities with JWT authentication.

**Base URL:** `http://localhost:8000/api/v1`

**Authentication:** JWT Bearer Token (except public endpoints)

**Response Format:** JSON

---

## Table of Contents

1. [Authentication](#authentication)
2. [Public Service Browsing](#public-service-browsing)
3. [User Profile](#user-profile)
4. [Customer APIs](#customer-apis)
5. [Provider APIs](#provider-apis)
6. [Admin APIs](#admin-apis)
7. [Error Handling](#error-handling)
8. [Status Codes](#status-codes)

---

## Authentication

### Register

**Endpoint:** `POST /auth/jwt/register`

**Authentication:** None (Public)

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123",
  "password_confirmation": "SecurePass123",
  "role": "customer"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer"
    },
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600
  }
}
```


### Login

**Endpoint:** `POST /auth/jwt/login`

**Authentication:** None (Public)

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer"
    }
  }
}
```

### Logout

**Endpoint:** `POST /auth/jwt/logout`

**Authentication:** Required (Bearer Token)

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Successfully logged out"
}
```

### Get Current User

**Endpoint:** `GET /auth/jwt/me`

**Authentication:** Required

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer",
    "email_verified_at": "2026-05-26T12:00:00.000000Z"
  }
}
```


### Refresh Token

**Endpoint:** `POST /auth/jwt/refresh`

**Authentication:** Required (Refresh Token)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "access_token": "new_token_here",
    "token_type": "bearer",
    "expires_in": 3600
  }
}
```

---

## Public Service Browsing

### List All Services

**Endpoint:** `GET /services`

**Authentication:** None (Public)

**Query Parameters:**
- `category` (optional): Filter by category
- `min_price` (optional): Minimum price filter
- `max_price` (optional): Maximum price filter
- `search` (optional): Search term for name/description
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 15)

**Example:** `GET /services?category=Cleaning&min_price=1000&max_price=3000`

**Response (200):**
```json
{
  "success": true,
  "message": "Services retrieved successfully",
  "data": [
    {
      "id": "uuid",
      "name": "House Cleaning Service",
      "description": "Professional house cleaning",
      "category": "Cleaning",
      "price": 1500,
      "duration_minutes": 120,
      "currency": "NPR",
      "status": "active",
      "provider": {
        "id": "provider-uuid",
        "name": "Provider Name",
        "email": "provider@example.com"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 15,
    "total": 42
  }
}
```


### Get Service Details

**Endpoint:** `GET /services/{id}`

**Authentication:** None (Public)

**Response (200):**
```json
{
  "success": true,
  "message": "Service retrieved successfully",
  "data": {
    "id": "uuid",
    "name": "House Cleaning Service",
    "description": "Professional house cleaning with experienced staff",
    "category": "Cleaning",
    "price": 1500,
    "duration_minutes": 120,
    "currency": "NPR",
    "status": "active",
    "provider": {
      "id": "provider-uuid",
      "name": "Provider Name",
      "email": "provider@example.com",
      "phone_number": "+977-9841234567"
    },
    "booking_count": 25,
    "created_at": "2026-01-15T10:00:00.000000Z"
  }
}
```

### Search Services

**Endpoint:** `GET /services/search`

**Authentication:** None (Public)

**Query Parameters:**
- `q` (required): Search query

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "House Cleaning Service",
      "category": "Cleaning",
      "price": 1500
    }
  ]
}
```

### Get Categories

**Endpoint:** `GET /services/categories`

**Authentication:** None (Public)

**Response (200):**
```json
{
  "success": true,
  "message": "Categories retrieved successfully",
  "data": [
    {
      "category": "Cleaning",
      "count": 15
    },
    {
      "category": "Plumbing",
      "count": 8
    }
  ]
}
```


---

## User Profile

### Get Profile

**Endpoint:** `GET /profile`

**Authentication:** Required (Any Role)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer",
    "phone_number": "+977-9841234567",
    "address": "Kathmandu, Nepal",
    "profile_image": "https://example.com/images/profile.jpg",
    "email_verified_at": "2026-05-26T12:00:00.000000Z"
  }
}
```

### Update Profile

**Endpoint:** `PUT /profile`

**Authentication:** Required (Any Role)

**Request Body:**
```json
{
  "name": "John Updated",
  "phone_number": "+977-9841234567",
  "address": "Pokhara, Nepal"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "uuid",
    "name": "John Updated",
    "phone_number": "+977-9841234567",
    "address": "Pokhara, Nepal"
  }
}
```

### Upload Profile Image

**Endpoint:** `POST /profile/image`

**Authentication:** Required (Any Role)

**Request:** Multipart form-data
- `image`: Image file (JPEG, PNG, JPG, max 2MB)

**Response (200):**
```json
{
  "success": true,
  "message": "Profile image uploaded successfully",
  "data": {
    "profile_image": "https://example.com/storage/profiles/uuid.jpg"
  }
}
```


---

## Customer APIs

### List Customer Bookings

**Endpoint:** `GET /customer/bookings`

**Authentication:** Required (Role: customer)

**Query Parameters:**
- `status` (optional): Filter by status (pending, confirmed, completed, cancelled, rejected)
- `page` (optional): Page number

**Response (200):**
```json
{
  "success": true,
  "message": "Bookings retrieved successfully",
  "data": [
    {
      "id": "uuid",
      "service_id": "service-uuid",
      "provider_id": "provider-uuid",
      "status": "pending",
      "total_price": 1500,
      "currency": "NPR",
      "scheduled_at": "2026-06-01 10:00:00",
      "notes": "Please bring cleaning supplies",
      "service": {
        "name": "House Cleaning Service",
        "category": "Cleaning"
      },
      "provider": {
        "name": "Provider Name",
        "phone_number": "+977-9841234567"
      },
      "created_at": "2026-05-26T12:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 5
  }
}
```

### Create Booking

**Endpoint:** `POST /customer/bookings`

**Authentication:** Required (Role: customer)

**Request Body:**
```json
{
  "service_id": "service-uuid",
  "scheduled_at": "2026-06-01 10:00:00",
  "notes": "Please bring cleaning supplies"
}
```

**Validation Rules:**
- `service_id`: required, must exist, service must be active
- `scheduled_at`: required, must be future date/time
- `notes`: optional, max 500 characters

**Response (201):**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "id": "uuid",
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


### Get Booking Details

**Endpoint:** `GET /customer/bookings/{id}`

**Authentication:** Required (Role: customer)

**Response (200):**
```json
{
  "success": true,
  "message": "Booking retrieved successfully",
  "data": {
    "id": "uuid",
    "status": "confirmed",
    "total_price": 1500,
    "scheduled_at": "2026-06-01 10:00:00",
    "notes": "Please bring cleaning supplies",
    "cancellation_reason": null,
    "service": {
      "id": "service-uuid",
      "name": "House Cleaning Service",
      "description": "Professional cleaning",
      "duration_minutes": 120
    },
    "provider": {
      "id": "provider-uuid",
      "name": "Provider Name",
      "email": "provider@example.com",
      "phone_number": "+977-9841234567"
    }
  }
}
```

### Cancel Booking

**Endpoint:** `PUT /customer/bookings/{id}/cancel`

**Authentication:** Required (Role: customer)

**Request Body:**
```json
{
  "cancellation_reason": "Found another service provider"
}
```

**Business Rules:**
- Only bookings with status "pending" or "confirmed" can be cancelled

**Response (200):**
```json
{
  "success": true,
  "message": "Booking cancelled successfully",
  "data": {
    "id": "uuid",
    "status": "cancelled",
    "cancellation_reason": "Found another service provider"
  }
}
```

### Check Service Availability

**Endpoint:** `GET /customer/bookings/check-availability`

**Authentication:** Required (Role: customer)

**Query Parameters:**
- `service_id` (required): Service UUID
- `date` (required): Date in YYYY-MM-DD format

**Response (200):**
```json
{
  "success": true,
  "data": {
    "available": true,
    "date": "2026-06-01",
    "existing_bookings": 2
  }
}
```


---

## Provider APIs

### Provider Dashboard

**Endpoint:** `GET /provider/dashboard`

**Authentication:** Required (Role: serviceProvider)

**Response (200):**
```json
{
  "success": true,
  "message": "Dashboard data retrieved successfully",
  "data": {
    "total_services": 5,
    "active_services": 4,
    "total_bookings": 25,
    "pending_bookings": 3,
    "this_month_earnings": 45000,
    "this_month_bookings": 12,
    "average_rating": 4.5
  }
}
```

### Get Provider Earnings

**Endpoint:** `GET /provider/earnings`

**Authentication:** Required (Role: serviceProvider)

**Query Parameters:**
- `date_from` (optional): Start date (YYYY-MM-DD)
- `date_to` (optional): End date (YYYY-MM-DD)
- `group_by` (optional): day, week, month (default: day)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "total_earnings": 45000,
    "breakdown": [
      {
        "period": "2026-05-01",
        "earnings": 3000,
        "bookings_count": 2
      },
      {
        "period": "2026-05-02",
        "earnings": 4500,
        "bookings_count": 3
      }
    ]
  }
}
```

### List Provider Services

**Endpoint:** `GET /provider/services`

**Authentication:** Required (Role: serviceProvider)

**Query Parameters:**
- `status` (optional): Filter by status (active, inactive, pending)
- `category` (optional): Filter by category

**Response (200):**
```json
{
  "success": true,
  "message": "Services retrieved successfully",
  "data": [
    {
      "id": "uuid",
      "name": "House Cleaning Service",
      "category": "Cleaning",
      "price": 1500,
      "status": "active",
      "booking_count": 25
    }
  ]
}
```


### Create Service

**Endpoint:** `POST /provider/services`

**Authentication:** Required (Role: serviceProvider)

**Request Body:**
```json
{
  "name": "House Cleaning Service",
  "description": "Professional house cleaning with experienced staff",
  "category": "Cleaning",
  "price": 1500,
  "duration_minutes": 120,
  "currency": "NPR"
}
```

**Validation Rules:**
- `name`: required, max 255 characters
- `description`: required
- `category`: required
- `price`: required, numeric, minimum 0
- `duration_minutes`: required, integer, minimum 15
- `currency`: NPR or USD (default: NPR)

**Response (201):**
```json
{
  "success": true,
  "message": "Service created successfully",
  "data": {
    "id": "uuid",
    "name": "House Cleaning Service",
    "description": "Professional house cleaning with experienced staff",
    "category": "Cleaning",
    "price": 1500,
    "duration_minutes": 120,
    "currency": "NPR",
    "status": "active",
    "provider_id": "provider-uuid"
  }
}
```

### Update Service

**Endpoint:** `PUT /provider/services/{id}`

**Authentication:** Required (Role: serviceProvider)

**Request Body:** Same as Create Service

**Response (200):**
```json
{
  "success": true,
  "message": "Service updated successfully",
  "data": {
    "id": "uuid",
    "name": "Updated Service Name",
    "price": 1800
  }
}
```

### Delete Service

**Endpoint:** `DELETE /provider/services/{id}`

**Authentication:** Required (Role: serviceProvider)

**Business Rules:**
- Cannot delete service with active bookings (pending or confirmed)

**Response (200):**
```json
{
  "success": true,
  "message": "Service deleted successfully"
}
```


### Update Service Status

**Endpoint:** `PATCH /provider/services/{id}/status`

**Authentication:** Required (Role: serviceProvider)

**Request Body:**
```json
{
  "status": "inactive"
}
```

**Valid Status Values:** active, inactive, pending

**Response (200):**
```json
{
  "success": true,
  "message": "Service status updated successfully",
  "data": {
    "id": "uuid",
    "status": "inactive"
  }
}
```

### List Provider Bookings

**Endpoint:** `GET /provider/bookings`

**Authentication:** Required (Role: serviceProvider)

**Query Parameters:**
- `status` (optional): Filter by status
- `page` (optional): Page number

**Response (200):**
```json
{
  "success": true,
  "message": "Bookings retrieved successfully",
  "data": [
    {
      "id": "uuid",
      "status": "pending",
      "total_price": 1500,
      "scheduled_at": "2026-06-01 10:00:00",
      "customer": {
        "name": "Customer Name",
        "phone_number": "+977-9841234567"
      },
      "service": {
        "name": "House Cleaning Service"
      }
    }
  ]
}
```

### Get Pending Bookings

**Endpoint:** `GET /provider/bookings/pending`

**Authentication:** Required (Role: serviceProvider)

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "status": "pending",
      "scheduled_at": "2026-06-01 10:00:00",
      "customer": {
        "name": "Customer Name"
      }
    }
  ]
}
```


### Accept Booking

**Endpoint:** `POST /provider/bookings/{id}/accept`

**Authentication:** Required (Role: serviceProvider)

**Business Rules:**
- Only bookings with status "pending" can be accepted
- Changes status to "confirmed"

**Response (200):**
```json
{
  "success": true,
  "message": "Booking accepted successfully",
  "data": {
    "id": "uuid",
    "status": "confirmed"
  }
}
```

### Reject Booking

**Endpoint:** `POST /provider/bookings/{id}/reject`

**Authentication:** Required (Role: serviceProvider)

**Request Body:**
```json
{
  "rejection_reason": "Not available on that date"
}
```

**Business Rules:**
- Only bookings with status "pending" can be rejected
- Rejection reason is required
- Changes status to "rejected"

**Response (200):**
```json
{
  "success": true,
  "message": "Booking rejected successfully",
  "data": {
    "id": "uuid",
    "status": "rejected",
    "cancellation_reason": "Not available on that date"
  }
}
```

### Complete Booking

**Endpoint:** `POST /provider/bookings/{id}/complete`

**Authentication:** Required (Role: serviceProvider)

**Business Rules:**
- Only bookings with status "confirmed" can be completed
- Changes status to "completed"

**Response (200):**
```json
{
  "success": true,
  "message": "Booking marked as completed successfully",
  "data": {
    "id": "uuid",
    "status": "completed"
  }
}
```


### Get Booking Statistics

**Endpoint:** `GET /provider/bookings/stats`

**Authentication:** Required (Role: serviceProvider)

**Query Parameters:**
- `date_from` (optional): Start date (YYYY-MM-DD)
- `date_to` (optional): End date (YYYY-MM-DD)

**Response (200):**
```json
{
  "success": true,
  "message": "Booking statistics retrieved successfully",
  "data": {
    "total_bookings": 25,
    "pending_count": 3,
    "confirmed_count": 5,
    "completed_count": 15,
    "cancelled_count": 1,
    "rejected_count": 1,
    "total_revenue": 22500,
    "date_from": "2026-05-01",
    "date_to": "2026-05-31"
  }
}
```

---

## Admin APIs

### Admin Dashboard

**Endpoint:** `GET /admin/dashboard`

**Authentication:** Required (Role: admin)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "total_users": 150,
    "total_customers": 100,
    "total_providers": 45,
    "total_services": 75,
    "total_bookings": 250,
    "pending_bookings": 15,
    "total_revenue": 375000,
    "this_month_revenue": 45000
  }
}
```

### Admin Analytics

**Endpoint:** `GET /admin/analytics`

**Authentication:** Required (Role: admin)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user_growth": [
      {"month": "2026-01", "count": 20},
      {"month": "2026-02", "count": 35}
    ],
    "booking_trends": [
      {"month": "2026-01", "count": 45},
      {"month": "2026-02", "count": 68}
    ],
    "revenue_trends": [
      {"month": "2026-01", "amount": 67500},
      {"month": "2026-02", "amount": 102000}
    ]
  }
}
```


### List Users

**Endpoint:** `GET /admin/users`

**Authentication:** Required (Role: admin)

**Query Parameters:**
- `search` (optional): Search by name or email
- `role` (optional): Filter by role (customer, serviceProvider, admin)
- `status` (optional): Filter by status

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer",
      "email_verified_at": "2026-05-26T12:00:00.000000Z",
      "created_at": "2026-01-15T10:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 150
  }
}
```

### Get User Details

**Endpoint:** `GET /admin/users/{id}`

**Authentication:** Required (Role: admin)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer",
    "phone_number": "+977-9841234567",
    "address": "Kathmandu, Nepal",
    "email_verified_at": "2026-05-26T12:00:00.000000Z",
    "bookings_count": 5,
    "services_count": 0
  }
}
```

### Activate User

**Endpoint:** `POST /admin/users/{id}/activate`

**Authentication:** Required (Role: admin)

**Response (200):**
```json
{
  "success": true,
  "message": "User activated successfully"
}
```

### Deactivate User

**Endpoint:** `POST /admin/users/{id}/deactivate`

**Authentication:** Required (Role: admin)

**Request Body:**
```json
{
  "reason": "Violation of terms of service"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "User deactivated successfully"
}
```


### Reset User Password

**Endpoint:** `POST /admin/users/{id}/password-reset`

**Authentication:** Required (Role: admin)

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset successfully",
  "data": {
    "temporary_password": "TempPass123"
  }
}
```

### Delete User

**Endpoint:** `DELETE /admin/users/{id}`

**Authentication:** Required (Role: admin)

**Query Parameters:**
- `reason` (required): Reason for deletion

**Response (200):**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

### List Admin Bookings

**Endpoint:** `GET /admin/bookings`

**Authentication:** Required (Role: admin)

**Query Parameters:**
- `search` (optional): Search by customer/provider name
- `status` (optional): Filter by status

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "status": "confirmed",
      "total_price": 1500,
      "scheduled_at": "2026-06-01 10:00:00",
      "customer": {
        "name": "Customer Name"
      },
      "provider": {
        "name": "Provider Name"
      },
      "service": {
        "name": "Service Name"
      }
    }
  ]
}
```

### Cancel Booking (Admin)

**Endpoint:** `POST /admin/bookings/{id}/cancel`

**Authentication:** Required (Role: admin)

**Request Body:**
```json
{
  "reason": "Service provider unavailable",
  "refund": true
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Booking cancelled successfully"
}
```


### Add Booking Note (Admin)

**Endpoint:** `POST /admin/bookings/{id}/note`

**Authentication:** Required (Role: admin)

**Request Body:**
```json
{
  "note": "Customer requested rescheduling"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Note added successfully"
}
```

### Generate Report

**Endpoint:** `GET /admin/reports`

**Authentication:** Required (Role: admin)

**Query Parameters:**
- `type` (required): bookings, revenue, users
- `format` (required): json, csv, pdf
- `start_date` (required): YYYY-MM-DD
- `end_date` (required): YYYY-MM-DD

**Response (200):**
```json
{
  "success": true,
  "data": {
    "report_type": "bookings",
    "period": {
      "start": "2026-05-01",
      "end": "2026-05-31"
    },
    "summary": {
      "total_bookings": 125,
      "total_revenue": 187500
    },
    "download_url": "https://example.com/reports/bookings-2026-05.pdf"
  }
}
```

---

## Error Handling

### Standard Error Response

All error responses follow this format:

```json
{
  "success": false,
  "message": "Error message here",
  "errors": {
    "field_name": [
      "Validation error message"
    ]
  }
}
```

### Validation Error Example (422)

```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "name": ["The name field is required."],
    "price": ["The price must be at least 0."],
    "duration_minutes": ["The duration minutes must be at least 15."]
  }
}
```


### Authentication Error (401)

```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

### Authorization Error (403)

```json
{
  "success": false,
  "message": "Unauthorized access to this resource"
}
```

### Not Found Error (404)

```json
{
  "success": false,
  "message": "Resource not found"
}
```

### Business Logic Error (400)

```json
{
  "success": false,
  "message": "Service is not available for booking"
}
```

---

## Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET, PUT, PATCH, DELETE |
| 201 | Created | Successful POST (resource created) |
| 400 | Bad Request | Business logic violation |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 422 | Unprocessable Entity | Validation errors |
| 500 | Internal Server Error | Server error |

---

## Common Patterns

### Pagination

All list endpoints support pagination:

**Query Parameters:**
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 15, max: 100)

**Response Meta:**
```json
{
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 72,
    "from": 1,
    "to": 15
  }
}
```

### Filtering

Most list endpoints support filtering:

**Common Filters:**
- `search`: Text search across relevant fields
- `status`: Filter by status
- `category`: Filter by category
- `date_from` / `date_to`: Date range filtering


### Authentication Header

All protected endpoints require JWT token:

```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Content Type

All POST/PUT/PATCH requests should include:

```
Content-Type: application/json
```

For file uploads:

```
Content-Type: multipart/form-data
```

---

## Testing with Postman

### Environment Variables

Create a Postman environment with these variables:

```json
{
  "base_url": "http://localhost:8000/api/v1",
  "access_token": "",
  "customer_token": "",
  "provider_token": "",
  "admin_token": ""
}
```

### Pre-request Script for Authentication

Add this to collection-level pre-request scripts:

```javascript
if (pm.environment.get("access_token")) {
    pm.request.headers.add({
        key: "Authorization",
        value: "Bearer " + pm.environment.get("access_token")
    });
}
```

### Test Script to Save Token

Add this to login request tests:

```javascript
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set("access_token", jsonData.data.access_token);
}
```

---

## Workflow Examples

### Complete Provider Workflow

1. **Register as Provider**
   ```
   POST /auth/jwt/register
   Body: { "role": "serviceProvider", ... }
   ```

2. **Login**
   ```
   POST /auth/jwt/login
   Save access_token
   ```

3. **Create Service**
   ```
   POST /provider/services
   Headers: Authorization: Bearer {token}
   ```

4. **View Dashboard**
   ```
   GET /provider/dashboard
   ```

5. **Accept Booking**
   ```
   POST /provider/bookings/{id}/accept
   ```

6. **Complete Booking**
   ```
   POST /provider/bookings/{id}/complete
   ```


### Complete Customer Workflow

1. **Register as Customer**
   ```
   POST /auth/jwt/register
   Body: { "role": "customer", ... }
   ```

2. **Login**
   ```
   POST /auth/jwt/login
   Save access_token
   ```

3. **Browse Services (No Auth)**
   ```
   GET /services
   ```

4. **View Service Details**
   ```
   GET /services/{id}
   ```

5. **Create Booking**
   ```
   POST /customer/bookings
   Headers: Authorization: Bearer {token}
   ```

6. **View My Bookings**
   ```
   GET /customer/bookings
   ```

7. **Cancel Booking**
   ```
   PUT /customer/bookings/{id}/cancel
   ```

---

## Rate Limiting

### Authentication Endpoints

- **General Auth:** 10 requests per minute
- **Login:** 5 requests per minute

### Other Endpoints

- No rate limiting currently implemented
- Future: 60 requests per minute per user

---

## Versioning

Current API version: **v1**

All endpoints are prefixed with `/api/v1/`

Future versions will use `/api/v2/`, `/api/v3/`, etc.

---

## Support

For API support or questions:
- **Email:** support@gharsewa.com
- **Documentation:** https://docs.gharsewa.com
- **GitHub Issues:** https://github.com/gharsewa/api/issues

---

## Changelog

### Version 1.0.0 (2026-05-26)

**Initial Release:**
- Authentication (JWT)
- Service Management (Provider)
- Service Browsing (Public/Customer)
- Booking Management (Customer & Provider)
- User Profile Management
- Provider Dashboard & Analytics
- Admin User Management
- Admin Booking Management
- Admin Analytics & Reports

---

**Last Updated:** May 26, 2026  
**API Version:** 1.0.0  
**Document Version:** 1.0.0
