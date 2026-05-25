# Requirements: Phase 1 Backend APIs

## Overview
Implement RESTful API endpoints for service management, booking management, and user profiles to support the multi-panel Flutter application.

## Functional Requirements

### FR1: Service Management (Provider)
**Priority:** High  
**Description:** Service providers must be able to create, read, update, delete, and manage their service offerings.

**Acceptance Criteria:**
- Provider can create a new service with name, description, category, price, duration, and currency
- Provider can list all their services with filtering by status and category
- Provider can view details of a specific service including booking count
- Provider can update service information
- Provider can delete a service (only if no active bookings exist)
- Provider can activate/deactivate a service
- All operations require JWT authentication with serviceProvider role
- Provider can only manage their own services (authorization check)

**Validation Rules:**
- name: required, string, max 255 characters
- description: required, string
- category: required, string
- price: required, numeric, minimum 0
- duration_minutes: required, integer, minimum 15
- currency: string, must be NPR or USD (default: NPR)
- status: enum (active, inactive, pending)

### FR2: Service Browsing (Customer/Public)
**Priority:** High  
**Description:** Customers and public users must be able to browse, search, and view service offerings.

**Acceptance Criteria:**
- Anyone can browse all active services (no authentication required)
- Services can be filtered by category, price range, and search term
- Service details include provider information
- Service categories can be listed with service counts
- Search functionality works across service name, description, and tags
- Results are paginated for performance

### FR3: Booking Management (Customer)
**Priority:** High  
**Description:** Customers must be able to create, view, and cancel bookings for services.

**Acceptance Criteria:**
- Customer can create a booking for any active service
- Customer can list all their bookings with status filtering
- Customer can view detailed information about a specific booking
- Customer can cancel a booking (only pending or confirmed status)
- Customer can optionally provide cancellation reason
- Customer can check service availability for a specific date
- All operations require JWT authentication with customer role
- Customer can only manage their own bookings

**Validation Rules:**
- service_id: required, must exist in services table
- scheduled_at: required, must be a future date/time
- notes: optional, string, max 500 characters
- cancellation_reason: optional, string

**Business Logic:**
- Booking status starts as 'pending'
- Total price is automatically set from service price
- Provider ID is automatically set from service
- Only pending or confirmed bookings can be cancelled

### FR4: Booking Management (Provider)
**Priority:** High  
**Description:** Service providers must be able to view, accept, reject, and complete bookings for their services.

**Acceptance Criteria:**
- Provider can list all bookings for their services with filtering
- Provider can view detailed information about a specific booking
- Provider can accept a pending booking (changes status to confirmed)
- Provider can reject a pending booking with a required reason
- Provider can mark a confirmed booking as completed
- Provider can view only pending bookings
- Provider can view booking statistics (total, by status, revenue)
- All operations require JWT authentication with serviceProvider role
- Provider can only manage bookings for their own services

**Business Logic:**
- Only pending bookings can be accepted or rejected
- Only confirmed bookings can be completed
- Rejection requires a reason
- Statistics include date range filtering

### FR5: User Profile Management
**Priority:** Medium  
**Description:** All authenticated users must be able to view and update their profile information.

**Acceptance Criteria:**
- User can view their own profile
- User can update name, phone number, and address
- User can upload a profile image (JPEG, PNG, JPG, max 2MB)
- Profile image is stored and URL is returned
- All operations require JWT authentication (any role)

**Validation Rules:**
- name: string, max 255 characters
- phone_number: string, max 20 characters
- address: optional, string, max 500 characters
- image: required for upload, must be image file, max 2MB

### FR6: Provider Dashboard & Analytics
**Priority:** Medium  
**Description:** Service providers must be able to view dashboard statistics and earnings information.

**Acceptance Criteria:**
- Provider can view dashboard with key metrics:
  - Total services count
  - Active services count
  - Total bookings count
  - Pending bookings count
  - Current month earnings
  - Current month bookings count
  - Average rating (if reviews exist)
- Provider can view earnings breakdown by time period
- Earnings can be filtered by date range
- Earnings can be grouped by day, week, or month
- All operations require JWT authentication with serviceProvider role

## Non-Functional Requirements

### NFR1: Security
**Priority:** Critical  
**Description:** All API endpoints must be properly secured and authorized.

**Acceptance Criteria:**
- JWT authentication using tymon/jwt-auth package
- Role-based authorization (customer, serviceProvider, admin)
- Users can only access their own resources
- Sensitive operations require ownership verification
- Rate limiting on authentication endpoints
- Input validation on all endpoints
- SQL injection prevention through Eloquent ORM
- XSS prevention through proper output encoding

### NFR2: Performance
**Priority:** High  
**Description:** API endpoints must respond quickly and handle concurrent requests.

**Acceptance Criteria:**
- List endpoints use pagination (default 15 items per page)
- Database queries use proper indexing
- Eager loading for relationships to prevent N+1 queries
- Response time under 200ms for simple queries
- Response time under 500ms for complex queries with joins

### NFR3: Data Integrity
**Priority:** High  
**Description:** Data must remain consistent and valid across all operations.

**Acceptance Criteria:**
- Foreign key constraints enforced at database level
- Soft deletes for User, Service, and Booking models
- UUID primary keys for all models
- Timestamps (created_at, updated_at) on all models
- Proper transaction handling for multi-step operations
- Validation before database operations

### NFR4: API Standards
**Priority:** High  
**Description:** APIs must follow RESTful conventions and return consistent responses.

**Acceptance Criteria:**
- RESTful URL structure (/api/v1/resource)
- Proper HTTP methods (GET, POST, PUT, PATCH, DELETE)
- Consistent JSON response format using BaseController
- Proper HTTP status codes (200, 201, 400, 401, 403, 404, 422, 500)
- Error responses include validation details
- Success responses include data and message
- Paginated responses include meta information

### NFR5: Maintainability
**Priority:** Medium  
**Description:** Code must be clean, documented, and follow Laravel best practices.

**Acceptance Criteria:**
- Controllers extend BaseController
- Use Eloquent ORM for database operations
- Use Laravel validation
- Use Laravel authorization policies
- Proper error handling and logging
- Code comments for complex business logic
- Consistent naming conventions

## Technical Requirements

### TR1: Technology Stack
- Laravel 10.x
- PHP 8.1+
- MySQL 8.0+
- tymon/jwt-auth for JWT authentication
- Laravel Eloquent ORM
- Laravel Validation

### TR2: Existing Infrastructure
- User model with JWT authentication implemented
- Service model with relationships
- Booking model with relationships
- BaseController with response helpers
- JWT middleware configured
- Database migrations complete

### TR3: API Versioning
- All endpoints under /api/v1/ prefix
- Version included in URL path

### TR4: Authentication
- JWT access token: 1 hour expiry
- JWT refresh token: 30 days expiry
- Token passed in Authorization header: `Bearer {token}`

### TR5: Database Schema
- Users table with UUID, role, soft deletes
- Services table with UUID, provider_id, status, soft deletes
- Bookings table with UUID, customer_id, service_id, provider_id, status, soft deletes

## Constraints

### C1: Authorization
- Providers can only manage their own services
- Providers can only manage bookings for their services
- Customers can only manage their own bookings
- Users can only view/update their own profile

### C2: Business Rules
- Services cannot be deleted if active bookings exist
- Bookings can only be cancelled if status is pending or confirmed
- Only pending bookings can be accepted or rejected by provider
- Only confirmed bookings can be marked as completed
- Booking price is set from service price at creation time

### C3: Data Validation
- All monetary values use decimal(10,2) precision
- Dates must be in ISO 8601 format
- UUIDs must be valid v4 format
- Enum values must match defined constants

## Dependencies

### D1: Existing Components
- JWT authentication system (JwtAuthController)
- User model with role-based methods
- Service model with relationships
- Booking model with relationships
- BaseController with response methods
- Database migrations

### D2: External Services
- None (all functionality is self-contained)

## Success Metrics

### SM1: Functionality
- All 30+ endpoints implemented and working
- All validation rules enforced
- All authorization checks in place
- All business rules implemented

### SM2: Quality
- Zero security vulnerabilities
- All endpoints return proper status codes
- All error cases handled gracefully
- Consistent response format across all endpoints

### SM3: Testing
- All endpoints manually tested with Postman
- Authorization rules verified
- Validation rules verified
- Business logic verified

## Out of Scope

### OS1: Not Included in Phase 1
- Payment processing
- Review and rating system
- Real-time notifications
- File storage service integration
- Email notifications for booking status changes
- SMS notifications
- Advanced search with Elasticsearch
- Caching layer
- API documentation generation
- Automated testing (unit/feature tests)

### OS2: Future Phases
- Admin panel APIs (Phase 4)
- Advanced analytics and reporting
- Multi-language support
- API rate limiting per user
- Webhook support
- GraphQL API
