# Implementation Plan: Backend APIs, Testing, Epic 7 & 8

## Overview

This document outlines the implementation plan for:
1. Backend APIs (Service & Booking Management)
2. Testing (Unit, Integration, Widget)
3. Epic 7: Service Provider Panel
4. Epic 8: Admin Panel

---

## Phase 1: Backend APIs (Priority: CRITICAL)

### 1.1 Service Management APIs

**Controllers to Implement/Update:**
- `backend/app/Http/Controllers/API/V1/Provider/ServiceController.php`
- `backend/app/Http/Controllers/API/V1/Customer/CustomerController.php` (for browsing)

**Endpoints Needed:**

#### Provider Endpoints (Service Management)
```
POST   /api/v1/provider/services              - Create service
GET    /api/v1/provider/services              - List provider's services
GET    /api/v1/provider/services/{id}         - Get service details
PUT    /api/v1/provider/services/{id}         - Update service
DELETE /api/v1/provider/services/{id}         - Delete service
PATCH  /api/v1/provider/services/{id}/status  - Activate/deactivate service
POST   /api/v1/provider/services/{id}/images  - Upload service images
```

#### Customer Endpoints (Service Browsing)
```
GET    /api/v1/services                       - List all active services
GET    /api/v1/services/{id}                  - Get service details
GET    /api/v1/services/search                - Search services
GET    /api/v1/services/categories            - Get service categories
GET    /api/v1/services/featured              - Get featured services
```

**Database Schema (services table):**
```php
- id (bigint, primary key)
- provider_id (char(36), foreign key to users)
- name (string)
- description (text)
- category (string)
- price (decimal)
- currency (string, default 'NPR')
- duration_minutes (integer)
- status (enum: active, inactive)
- is_featured (boolean, default false)
- created_at, updated_at
```

**Validation Rules:**
- name: required, string, max:255
- description: required, string
- category: required, string
- price: required, numeric, min:0
- duration_minutes: required, integer, min:15
- status: in:active,inactive

---

### 1.2 Booking Management APIs

**Controllers to Implement/Update:**
- `backend/app/Http/Controllers/API/V1/Customer/BookingController.php`
- `backend/app/Http/Controllers/API/V1/Provider/BookingController.php`
- `backend/app/Http/Controllers/API/V1/Admin/BookingManagementController.php`

**Endpoints Needed:**

#### Customer Endpoints
```
POST   /api/v1/customer/bookings                    - Create booking
GET    /api/v1/customer/bookings                    - List customer bookings
GET    /api/v1/customer/bookings/{id}               - Get booking details
PUT    /api/v1/customer/bookings/{id}/cancel        - Cancel booking
GET    /api/v1/customer/bookings/availability       - Check time slot availability
```

#### Provider Endpoints
```
GET    /api/v1/provider/bookings                    - List provider bookings
GET    /api/v1/provider/bookings/{id}               - Get booking details
PUT    /api/v1/provider/bookings/{id}/accept        - Accept booking
PUT    /api/v1/provider/bookings/{id}/reject        - Reject booking
PUT    /api/v1/provider/bookings/{id}/complete      - Mark as completed
GET    /api/v1/provider/bookings/pending            - Get pending requests
GET    /api/v1/provider/bookings/stats              - Get booking statistics
```

#### Admin Endpoints
```
GET    /api/v1/admin/bookings                       - List all bookings
GET    /api/v1/admin/bookings/{id}                  - Get booking details
PUT    /api/v1/admin/bookings/{id}/cancel           - Admin cancel booking
GET    /api/v1/admin/bookings/stats                 - Platform-wide stats
```

**Database Schema (bookings table):**
```php
- id (bigint, primary key)
- customer_id (char(36), foreign key to users)
- service_id (bigint, foreign key to services)
- provider_id (char(36), foreign key to users)
- scheduled_at (datetime)
- status (enum: pending, confirmed, completed, cancelled, rejected)
- total_price (decimal)
- currency (string, default 'NPR')
- cancellation_reason (text, nullable)
- notes (text, nullable)
- created_at, updated_at
```

**Validation Rules:**
- service_id: required, exists:services,id
- scheduled_at: required, date, after:now
- notes: nullable, string, max:500

**Business Logic:**
- Booking status flow: pending → confirmed → completed
- Cancellation allowed only for pending/confirmed bookings
- Provider can accept/reject pending bookings
- Customer receives notification on status change

---

### 1.3 User Profile APIs

**Controller:** `backend/app/Http/Controllers/API/V1/Customer/CustomerController.php`

**Endpoints:**
```
GET    /api/v1/user/profile        - Get current user profile
PUT    /api/v1/user/profile        - Update profile
POST   /api/v1/user/profile/image  - Upload profile image
```

---

### 1.4 Provider Profile APIs

**Controller:** `backend/app/Http/Controllers/API/V1/Provider/ProviderController.php`

**Endpoints:**
```
GET    /api/v1/provider/profile           - Get provider profile
PUT    /api/v1/provider/profile           - Update provider profile
GET    /api/v1/provider/dashboard         - Get dashboard stats
GET    /api/v1/provider/earnings          - Get earnings summary
```

---

## Phase 2: Testing (Priority: HIGH)

### 2.1 Backend API Tests

**Location:** `backend/tests/Feature/`

**Test Files to Create:**

#### Service Management Tests
```
backend/tests/Feature/Services/ServiceManagementTest.php
- test_provider_can_create_service()
- test_provider_can_list_own_services()
- test_provider_can_update_service()
- test_provider_can_delete_service()
- test_provider_can_activate_deactivate_service()
- test_customer_can_browse_services()
- test_customer_can_search_services()
- test_service_validation_rules()
```

#### Booking Management Tests
```
backend/tests/Feature/Bookings/BookingManagementTest.php
- test_customer_can_create_booking()
- test_customer_can_list_bookings()
- test_customer_can_cancel_booking()
- test_provider_can_accept_booking()
- test_provider_can_reject_booking()
- test_provider_can_complete_booking()
- test_booking_status_transitions()
- test_booking_validation_rules()
- test_availability_check()
```

#### User Profile Tests
```
backend/tests/Feature/Profile/ProfileManagementTest.php
- test_user_can_get_profile()
- test_user_can_update_profile()
- test_user_can_upload_profile_image()
- test_profile_validation_rules()
```

---

### 2.2 Flutter Unit Tests

**Location:** `test/unit/`

**Test Files to Create:**

#### Model Tests
```
test/unit/models/user_model_test.dart
test/unit/models/service_model_test.dart
test/unit/models/booking_model_test.dart
- Test JSON serialization/deserialization
- Test model validation
- Test edge cases
```

#### Repository Tests
```
test/unit/repositories/service_repository_test.dart
test/unit/repositories/booking_repository_test.dart
test/unit/repositories/user_repository_test.dart
- Test API calls with mocked responses
- Test error handling
- Test data transformation
```

#### Service Tests
```
test/unit/services/jwt_auth_service_test.dart
test/unit/services/token_storage_test.dart
- Test authentication logic
- Test token management
- Test error scenarios
```

---

### 2.3 Flutter Widget Tests

**Location:** `test/widget/`

**Test Files to Create:**

#### Customer Panel Tests
```
test/widget/customer/customer_home_screen_test.dart
test/widget/customer/service_detail_screen_test.dart
test/widget/customer/booking_screen_test.dart
test/widget/customer/bookings_list_screen_test.dart
test/widget/customer/profile_screen_test.dart
- Test widget rendering
- Test user interactions
- Test navigation
- Test form validation
```

---

### 2.4 Flutter Integration Tests

**Location:** `integration_test/`

**Test Files to Create:**

```
integration_test/auth_flow_test.dart
- Test complete registration flow
- Test login flow
- Test logout flow

integration_test/booking_flow_test.dart
- Test service browsing
- Test booking creation
- Test booking cancellation

integration_test/provider_flow_test.dart
- Test service creation
- Test booking management
- Test dashboard
```

---

## Phase 3: Epic 7 - Service Provider Panel (Priority: HIGH)

### 7.1 Provider Panel Structure

**Files to Create/Update:**
- `lib/presentation/panels/provider/screens/provider_dashboard_screen.dart`
- `lib/presentation/router/app_router.dart` (add provider routes)

**Features:**
- Bottom navigation (Dashboard, Bookings, Services, Analytics, Profile)
- Role-based access control
- Provider-specific theme

---

### 7.2 Provider Dashboard

**Screen:** `provider_dashboard_screen.dart`

**Features:**
- Earnings summary (current month)
- Booking statistics (pending, confirmed, completed)
- Recent bookings list
- Quick actions (add service, view requests)
- Charts (bookings over time)

**Widgets:**
- MetricCard (earnings, bookings count)
- BookingsChart (using fl_chart package)
- RecentBookingsList
- QuickActionButtons

---

### 7.3 Booking Request Management

**Screen:** `provider_bookings_screen.dart`

**Features:**
- List of booking requests (pending, confirmed, completed)
- Accept/Reject actions
- Rejection reason dialog
- Mark as completed
- Booking details view
- Filter by status

---

### 7.4 Service Management

**Screens:**
- `provider_services_list_screen.dart`
- `add_service_screen.dart`
- `edit_service_screen.dart`

**Features:**
- List provider's services
- Add new service form
- Edit existing service
- Activate/deactivate service
- Upload service images
- Delete service

---

### 7.5 Provider Analytics

**Screen:** `provider_analytics_screen.dart`

**Features:**
- Date range selector
- Revenue breakdown by service
- Booking trends chart
- Customer demographics
- Performance metrics

---

### 7.6 Provider Profile

**Screen:** `provider_profile_screen.dart`

**Features:**
- Profile information display
- Edit profile
- Business information
- Service categories
- Availability settings

---

## Phase 4: Epic 8 - Admin Panel (Priority: MEDIUM)

### 8.1 Admin Panel Structure

**Files to Create/Update:**
- `lib/presentation/panels/admin/screens/admin_dashboard_screen.dart`
- `lib/presentation/router/app_router.dart` (add admin routes)

**Features:**
- Sidebar navigation (Dashboard, Users, Bookings, Services, Reports)
- Web-optimized layout
- Admin-specific theme

---

### 8.2 Admin Dashboard

**Screen:** `admin_dashboard_screen.dart`

**Features:**
- Platform statistics (total users, bookings, revenue)
- User growth chart
- Booking trends chart
- Recent activities feed
- Quick stats cards

---

### 8.3 User Management

**Screens:**
- `admin_users_list_screen.dart`
- `admin_user_detail_screen.dart`

**Features:**
- List all users (customers, providers)
- Search and filter users
- User details view
- Activate/deactivate users
- Password reset
- User statistics

---

### 8.4 Booking Oversight

**Screens:**
- `admin_bookings_screen.dart`
- `admin_booking_detail_screen.dart`

**Features:**
- List all bookings
- Search by ID, customer, provider
- Filter by status, date range
- Booking details modal
- Admin cancel booking
- Add notes to bookings

---

### 8.5 Service Oversight

**Screen:** `admin_services_screen.dart`

**Features:**
- List all services
- Search and filter
- Approve/reject services
- Feature services
- Service statistics

---

### 8.6 Reports Generation

**Screen:** `admin_reports_screen.dart`

**Features:**
- Report type selection
- Date range picker
- CSV export
- PDF export
- Revenue reports
- User activity reports
- Booking reports

---

## Implementation Order

### Week 1: Backend APIs
1. ✅ Day 1-2: Service Management APIs
2. ✅ Day 3-4: Booking Management APIs
3. ✅ Day 5: User/Provider Profile APIs

### Week 2: Testing
1. ✅ Day 1-2: Backend API Tests
2. ✅ Day 3-4: Flutter Unit Tests
3. ✅ Day 5: Flutter Widget Tests

### Week 3: Epic 7 - Provider Panel
1. ✅ Day 1: Provider Panel Structure
2. ✅ Day 2: Provider Dashboard
3. ✅ Day 3: Booking Request Management
4. ✅ Day 4: Service Management
5. ✅ Day 5: Provider Analytics & Profile

### Week 4: Epic 8 - Admin Panel
1. ✅ Day 1: Admin Panel Structure
2. ✅ Day 2: Admin Dashboard
3. ✅ Day 3: User Management
4. ✅ Day 4: Booking & Service Oversight
5. ✅ Day 5: Reports Generation

---

## Dependencies

### Backend
- Laravel 10.x
- tymon/jwt-auth
- spatie/laravel-permission (for role management)
- maatwebsite/excel (for CSV export)
- barryvdh/laravel-dompdf (for PDF export)

### Flutter
- flutter_riverpod (state management)
- go_router (navigation)
- dio (HTTP client)
- fl_chart (charts)
- file_picker (file selection)
- pdf (PDF generation)
- csv (CSV generation)

---

## Success Criteria

### Backend APIs
- ✅ All endpoints implemented and documented
- ✅ Proper validation and error handling
- ✅ Role-based access control
- ✅ API tests with >80% coverage

### Testing
- ✅ Backend: >80% code coverage
- ✅ Flutter: Unit tests for all models and services
- ✅ Flutter: Widget tests for all screens
- ✅ Integration tests for critical flows

### Epic 7 - Provider Panel
- ✅ All screens implemented and functional
- ✅ Service management working end-to-end
- ✅ Booking management working end-to-end
- ✅ Dashboard showing real data
- ✅ Analytics charts displaying correctly

### Epic 8 - Admin Panel
- ✅ All screens implemented and functional
- ✅ User management working
- ✅ Booking oversight working
- ✅ Reports generation working
- ✅ Web-optimized responsive layout

---

## Next Steps

1. **Start with Phase 1** - Backend APIs (most critical)
2. **Parallel work** - Testing can be done alongside API development
3. **Sequential** - Epic 7 and 8 depend on APIs being complete

Would you like me to start implementing Phase 1 (Backend APIs) now?
