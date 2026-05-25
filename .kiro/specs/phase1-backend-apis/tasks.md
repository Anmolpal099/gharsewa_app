# Implementation Plan: Phase 1 Backend APIs

## Overview

This plan implements the Phase 1 Backend APIs for the Gharsewa application, including service management, booking management, user profiles, and provider dashboard functionality. The implementation follows Laravel best practices with JWT authentication and role-based authorization.

## Task Dependency Graph

```json
{
  "waves": [
    {"wave": 1, "tasks": [1]},
    {"wave": 2, "tasks": [2]},
    {"wave": 3, "tasks": [3]},
    {"wave": 4, "tasks": [4, 5]},
    {"wave": 5, "tasks": [6]},
    {"wave": 6, "tasks": [7, 8]},
    {"wave": 7, "tasks": [9]},
    {"wave": 8, "tasks": [10, 11]},
    {"wave": 9, "tasks": [12]},
    {"wave": 10, "tasks": [13, 16]},
    {"wave": 11, "tasks": [14, 17]},
    {"wave": 12, "tasks": [15, 18]},
    {"wave": 13, "tasks": [19]},
    {"wave": 14, "tasks": [20, 21]}
  ]
}
```

## Tasks

- [x] 1. Verify JWT Middleware Configuration (Requirement NFR1) - 30 minutes
  - Ensure jwt.auth middleware is properly configured and working before implementing endpoints

- [x] 2. Implement Role Middleware (Requirement NFR1) - 1 hour
  - Create or verify role-based middleware for customer, serviceProvider, admin roles

- [x] 3. Implement Provider Service Controller (Requirement FR1) - 3 hours
  - Create ServiceController with CRUD operations for service providers to manage their services
  - Implement index, store, show, update, destroy, and updateStatus methods

- [x] 4. Implement Customer Service Browsing (Requirement FR2) - 2 hours
  - Add public service browsing endpoints to CustomerController
  - Implement listServices, getService, searchServices, and getCategories methods

- [x] 5. Add Service Routes (Requirements FR1, FR2) - 30 minutes
  - Add all service-related routes to api.php with proper middleware for both public and provider endpoints

- [x] 6. Test Service APIs (Requirements FR1, FR2) - 1.5 hours
  - Manually test all service endpoints with Postman
  - Test CRUD operations, browsing, search, and authorization rules

- [x] 7. Implement Customer Booking Controller (Requirement FR3) - 2.5 hours
  - Create Customer\BookingController for customers to manage their bookings
  - Implement index, store, show, cancel, and checkAvailability methods

- [x] 8. Add Customer Booking Routes (Requirement FR3) - 20 minutes
  - Add customer booking routes to api.php with jwt.auth and role:customer middleware

- [x] 9. Test Customer Booking APIs (Requirement FR3) - 1 hour
  - Manually test all customer booking endpoints with Postman
  - Test creation, cancellation, and authorization rules

- [x] 10. Implement Provider Booking Controller (Requirement FR4) - 3 hours
  - Create Provider\BookingController for providers to manage booking requests
  - Implement index, show, accept, reject, complete, pending, and stats methods

- [x] 11. Add Provider Booking Routes (Requirement FR4) - 20 minutes
  - Add provider booking routes to api.php with jwt.auth and role:serviceProvider middleware

- [x] 12. Test Provider Booking APIs (Requirement FR4) - 1.5 hours
  - Manually test all provider booking endpoints with Postman
  - Test status transitions, statistics, and authorization rules

- [x] 13. Implement User Profile Methods (Requirement FR5) - 2 hours
  - Add profile management methods to CustomerController
  - Implement getProfile, updateProfile, and uploadProfileImage methods

- [x] 14. Add Profile Routes (Requirement FR5) - 15 minutes
  - Add user profile routes to api.php with jwt.auth middleware accessible to all authenticated users

- [x] 15. Test Profile APIs (Requirement FR5) - 45 minutes
  - Manually test all profile endpoints with Postman
  - Test retrieval, update, and image upload

- [x] 16. Implement Provider Dashboard Controller (Requirement FR6) - 2.5 hours
  - Create ProviderController with dashboard and analytics methods
  - Implement getProfile, updateProfile, getDashboard, and getEarnings methods

- [x] 17. Add Provider Dashboard Routes (Requirement FR6) - 15 minutes
  - Add provider dashboard routes to api.php with jwt.auth and role:serviceProvider middleware

- [x] 18. Test Provider Dashboard APIs (Requirement FR6) - 1 hour
  - Manually test all provider dashboard endpoints with Postman
  - Test statistics and earnings breakdown

- [ ] 19. Integration Testing (All FRs) - 2 hours
  - Test complete user flows across multiple endpoints
  - Test provider workflow (create service, receive booking, accept, complete)
  - Test customer workflow (browse services, create booking, cancel booking)

- [ ] 20. Create Postman Collection (All FRs) - 1.5 hours
  - Create comprehensive Postman collection with all endpoints organized by feature
  - Add example requests and environment variables

- [ ] 21. Create API Documentation (All FRs) - 2 hours
  - Document all endpoints with request/response examples
  - Include authentication guide and error handling


## Notes

**Total Estimated Time:** 31 hours

**Critical Path:**
JWT/Role Middleware → Service Management → Booking Management → Profile & Dashboard → Testing & Documentation

**Key Files:**
- Backend Controllers: `app/Http/Controllers/API/V1/`
- Middleware: `app/Http/Middleware/`
- Routes: `routes/api.php`
- Tests: `tests/Feature/`

**Testing Strategy:**
1. Test each endpoint with Postman/curl
2. Verify authentication and authorization
3. Test complete user workflows
4. Verify error handling and validation

**Progress:**
- Tasks 1-12: ✅ Complete (JWT, Services, Bookings)
- Tasks 13-18: 🚧 In Progress (Profile, Dashboard)
- Tasks 19-21: ⏳ Pending (Testing, Documentation)
