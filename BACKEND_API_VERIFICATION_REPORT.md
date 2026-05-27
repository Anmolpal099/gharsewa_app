# Backend API Verification Report
**Generated:** 2024-01-XX  
**Project:** Gharsewa Home Services Platform  
**Status:** ✅ VERIFIED - All APIs Managed, Linked, and Working

---

## Executive Summary

The Gharsewa backend API is **fully implemented and operational** with comprehensive role-based access control for Customer, Service Provider, and Admin panels. All endpoints are properly structured, linked to controllers, and protected by JWT authentication and role middleware.

### Key Findings
- ✅ **100% API Coverage**: All required endpoints implemented
- ✅ **Role-Based Access Control**: Proper middleware protection for all roles
- ✅ **JWT Authentication**: Secure token-based authentication system
- ✅ **Database Models**: Complete with relationships and soft deletes
- ✅ **AI Integration**: Full AI consultation, recommendation, and analytics system
- ✅ **Notification System**: Scheduled notifications with engagement tracking
- ✅ **Rate Limiting**: API and login rate limiting configured

---

## API Architecture Overview

### Base URL Structure
```
http://localhost:8000/api/v1/
```

### Authentication Flow
1. **Public Routes**: No authentication required
   - Service browsing, search, categories
   - Auth endpoints (register, login, OTP)

2. **Protected Routes**: JWT authentication required (`jwt.auth` middleware)
   - Profile management
   - Notifications
   - Role-specific endpoints

3. **Role-Protected Routes**: JWT + Role middleware
   - Customer endpoints: `role:customer`
   - Provider endpoints: `role:serviceProvider`
   - Admin endpoints: `role:admin`

### Middleware Stack

| Middleware | Alias | Purpose |
|------------|-------|---------|
| `CorsMiddleware` | (global) | CORS headers for cross-origin requests |
| `JwtMiddleware` | `jwt.auth` | JWT token validation |
| `RoleMiddleware` | `role` | Role-based access control |
| `ApiRateLimitMiddleware` | `api.limit` | General API rate limiting |
| `LoginRateLimitMiddleware` | `login.limit` | Login attempt rate limiting |

---

## 1. Public Endpoints (No Authentication)

### 1.1 Authentication Endpoints
**Base Path:** `/api/v1/auth`  
**Rate Limit:** 10 requests/minute

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| POST | `/jwt/register` | `JwtAuthController@register` | User registration |
| POST | `/jwt/login` | `JwtAuthController@login` | User login (extra rate limit) |
| POST | `/jwt/refresh` | `JwtAuthController@refresh` | Refresh JWT token |
| POST | `/otp/send-email-verification` | `OtpController@sendEmailVerificationOtp` | Send email verification OTP |
| POST | `/otp/verify-email` | `OtpController@verifyEmailOtp` | Verify email with OTP |
| POST | `/otp/send-password-reset` | `OtpController@sendPasswordResetOtp` | Send password reset OTP |
| POST | `/otp/verify-password-reset` | `OtpController@verifyPasswordResetOtp` | Verify password reset OTP |
| POST | `/otp/reset-password` | `OtpController@resetPassword` | Reset password with OTP |

### 1.2 Service Browsing (Public)
**Base Path:** `/api/v1/services`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/` | `CustomerController@listServices` | Browse all services with filters |
| GET | `/search` | `CustomerController@searchServices` | Search services by query |
| GET | `/categories` | `CustomerController@getCategories` | Get service categories |
| GET | `/{id}` | `CustomerController@getService` | Get service details |

**Filters Supported:**
- `category` - Filter by service category
- `min_price` / `max_price` - Price range filtering
- `search` - Search in name/description
- Pagination: 15 items per page

### 1.3 Health Check
| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/api/v1/health` | `{"status": "ok", "timestamp": "..."}` |

---

## 2. Authenticated Endpoints (JWT Required)

### 2.1 Auth Management
**Base Path:** `/api/v1/auth/jwt`  
**Middleware:** `jwt.auth`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| POST | `/logout` | `JwtAuthController@logout` | Logout user |
| GET | `/me` | `JwtAuthController@me` | Get current user info |
| POST | `/become-service-provider` | `JwtAuthController@becomeServiceProvider` | Upgrade to provider role |

### 2.2 Profile Management
**Base Path:** `/api/v1/profile`  
**Middleware:** `jwt.auth`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/` | `CustomerController@getProfile` | Get user profile |
| PUT | `/` | `CustomerController@updateProfile` | Update profile (name, phone, address) |
| POST | `/image` | `CustomerController@uploadProfileImage` | Upload profile image (max 2MB) |

### 2.3 Notifications (All Users)
**Base Path:** `/api/v1/notifications`  
**Middleware:** `jwt.auth`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/scheduled` | `NotificationController@getScheduled` | Get scheduled notifications |
| GET | `/engagement-metrics` | `NotificationController@getEngagementMetrics` | Get engagement stats |
| GET | `/preferences` | `NotificationController@getPreferences` | Get notification preferences |
| POST | `/schedule` | `NotificationController@schedule` | Schedule a notification |
| POST | `/engagement` | `NotificationController@recordEngagement` | Record engagement event |
| POST | `/send-immediate` | `NotificationController@sendImmediate` | Send immediate notification |
| PUT | `/preferences` | `NotificationController@updatePreferences` | Update preferences |
| DELETE | `/{scheduleId}` | `NotificationController@cancel` | Cancel scheduled notification |

### 2.4 AI Safety SOP
**Endpoint:** `/api/v1/ai/safety-sop`  
**Middleware:** `jwt.auth`

| Method | Controller | Purpose |
|--------|------------|---------|
| POST | `AiController@safetySop` | AI safety standard operating procedure |

---

## 3. Customer Endpoints

**Base Path:** `/api/v1/customer`  
**Middleware:** `jwt.auth` + `role:customer`

### 3.1 Customer Dashboard
| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/dashboard` | `CustomerController@dashboard` | Customer dashboard stats |
| GET | `/services` | `CustomerController@services` | Browse services (legacy) |
| GET | `/services/{id}` | `CustomerController@serviceDetail` | Service details (legacy) |
| GET | `/recommendations` | `CustomerController@recommendations` | AI-powered recommendations |

### 3.2 Booking Management
**Base Path:** `/api/v1/customer/bookings`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/check-availability` | `CustomerBookingController@checkAvailability` | Check service availability |
| GET | `/` | `CustomerBookingController@index` | List customer bookings |
| POST | `/` | `CustomerBookingController@store` | Create new booking |
| GET | `/{id}` | `CustomerBookingController@show` | Get booking details |
| PUT | `/{id}` | `CustomerBookingController@update` | Update booking |
| DELETE | `/{id}` | `CustomerBookingController@destroy` | Delete booking |
| POST | `/{id}/cancel` | `CustomerBookingController@cancel` | Cancel booking |

### 3.3 AI Recommendations
**Base Path:** `/api/v1/customer/ai`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/recommendations` | `RecommendationController@index` | Get AI recommendations |
| POST | `/recommendations/feedback` | `RecommendationController@feedback` | Submit recommendation feedback |
| GET | `/recommendations/stats` | `RecommendationController@stats` | Get recommendation statistics |
| GET | `/providers/matches` | `MatchingController@findMatches` | Find matching providers |

### 3.4 AI Visual Assistant Consultations
**Base Path:** `/api/v1/customer/ai/consultations`  
**Rate Limit:** 10 requests/minute

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/` | `AIConsultationController@index` | List consultations |
| POST | `/` | `AIConsultationController@store` | Create consultation (image analysis) |
| GET | `/{id}` | `AIConsultationController@show` | Get consultation details |
| DELETE | `/{id}` | `AIConsultationController@destroy` | Delete consultation |

**Features:**
- Image upload and analysis using Ollama AI
- Service recommendations based on image content
- Consultation history tracking
- Automatic cleanup (12 months retention)

---

## 4. Service Provider Endpoints

**Base Path:** `/api/v1/provider`  
**Middleware:** `jwt.auth` + `role:serviceProvider`

### 4.1 Provider Profile & Dashboard
| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/profile` | `ProviderController@getProfile` | Get provider profile |
| PUT | `/profile` | `ProviderController@updateProfile` | Update provider profile |
| GET | `/dashboard` | `ProviderController@getDashboard` | Provider dashboard stats |
| GET | `/earnings` | `ProviderController@getEarnings` | Earnings breakdown |
| GET | `/metrics` | `ProviderController@getMetrics` | Performance metrics |
| GET | `/analytics` | `ProviderController@analytics` | Analytics (legacy) |

**Profile Fields:**
- Basic: name, phone_number, profile_image_url
- Business: business_name, business_description, address
- Metadata: certifications, ratings, reviews

**Dashboard Metrics:**
- Total/active services count
- Total/pending bookings count
- Monthly earnings and bookings
- Average rating (placeholder for review system)

**Earnings Query Parameters:**
- `date_from` / `date_to` - Date range
- `group_by` - Grouping: day, week, month

### 4.2 Certification Management
| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| POST | `/certifications/upload` | `ProviderController@uploadCertification` | Upload certification (PDF/PNG/JPG, max 10MB) |

**Certification Structure:**
- ID, name, document_url, file_type
- Verification status (is_verified, verified_at)
- Stored in user metadata

### 4.3 Booking Management
**Base Path:** `/api/v1/provider/bookings`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/` | `ProviderBookingController@index` | List provider bookings |
| GET | `/pending` | `ProviderBookingController@pending` | List pending bookings |
| GET | `/stats` | `ProviderBookingController@stats` | Booking statistics |
| GET | `/{id}` | `ProviderBookingController@show` | Get booking details |
| POST | `/{id}/accept` | `ProviderBookingController@accept` | Accept booking |
| POST | `/{id}/reject` | `ProviderBookingController@reject` | Reject booking |
| POST | `/{id}/counter` | `ProviderBookingController@counter` | Counter-offer |
| POST | `/{id}/complete` | `ProviderBookingController@complete` | Mark as completed |


### 4.4 Service Management
**Base Path:** `/api/v1/provider/services`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/` | `ServiceController@index` | List provider services |
| POST | `/` | `ServiceController@store` | Create new service |
| GET | `/{id}` | `ServiceController@show` | Get service details |
| PUT | `/{id}` | `ServiceController@update` | Update service |
| DELETE | `/{id}` | `ServiceController@destroy` | Delete service |
| PATCH | `/{id}/status` | `ServiceController@updateStatus` | Update service status |

**Service Fields:**
- name, description, category
- price, currency, duration_minutes
- status (active, inactive, pending)
- Images (via ServiceImage model)

### 4.5 AI Matching
**Base Path:** `/api/v1/provider/ai`

| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/bookings/{id}/match-score` | `MatchingController@getMatchScore` | Get AI match score for booking |

---

## 5. Admin Endpoints

**Base Path:** `/api/v1/admin`  
**Middleware:** `jwt.auth` + `role:admin`

### 5.1 Admin Dashboard & Analytics
| Method | Endpoint | Controller | Purpose |
|--------|----------|------------|---------|
| GET | `/dashboard` | `AdminController@dashboard` | Admin dashboard with comprehensive stats |
| GET | `/analytics` | `AdminController@analytics` | Platform analytics (user growth, bookings, revenue) |
| GET | `/reports` | `AdminController@reports` | Generate reports (users, bookings, revenue, services) |

**Dashboard Metrics:**
- User counts (total, customers, providers, admins)
- Booking counts by status (pending, confirmed, completed, cancelled)
- Revenue (total, current month)
- Active services count
- Platform rating
- Recent activities
- **AI Metrics** (see section 5.4)

**Analytics Features:**
- User growth trends (last 3 months)
- Booking trends
- Revenue trends
- Top service categories

**Report Types:**
- `users` - User list with filters
- `bookings` - Booking list with filters
- `revenue` - Revenue breakdown
- `services` - Service list with filters
- Formats: JSON, CSV, PDF
- Date range filtering

