# Phase 1 Backend APIs - Postman Collection Summary

## Overview

This document provides a complete summary of the Postman collection for Phase 1 Backend APIs, including all 35 endpoints organized by feature.

## Collection Files

1. **Gharsewa-Local.postman_environment.json** - Environment variables for local development
2. **README.md** - Comprehensive documentation and usage guide
3. **COLLECTION_GUIDE.md** - Step-by-step guide to manually create the collection
4. **test-apis.ps1** - PowerShell script to test all endpoints
5. **POSTMAN_COLLECTION_SUMMARY.md** - This file

## Quick Start

### Option 1: Use PowerShell Test Script (Fastest)

```powershell
cd e:\gharsewa\backend\postman
.\test-apis.ps1
```

This script will:
- Test all 35 endpoints automatically
- Create test users (customer and provider)
- Create a test service
- Create a test booking
- Test the complete workflow
- Display results with color-coded output

### Option 2: Import Environment and Create Collection Manually

1. Import `Gharsewa-Local.postman_environment.json` into Postman
2. Follow `COLLECTION_GUIDE.md` to create requests manually
3. Use `README.md` for detailed documentation

## Complete Endpoint List

### 1. Authentication (7 endpoints)

| # | Name | Method | Endpoint | Auth |
|---|------|--------|----------|------|
| 1.1 | Register (Customer) | POST | `/auth/jwt/register` | None |
| 1.2 | Register (Provider) | POST | `/auth/jwt/register` | None |
| 1.3 | Login (Customer) | POST | `/auth/jwt/login` | None |
| 1.4 | Login (Provider) | POST | `/auth/jwt/login` | None |
| 1.5 | Get Current User | GET | `/auth/jwt/me` | Bearer |
| 1.6 | Refresh Token | POST | `/auth/jwt/refresh` | Bearer |
| 1.7 | Logout | POST | `/auth/jwt/logout` | Bearer |

### 2. Services - Public (4 endpoints)

| # | Name | Method | Endpoint | Auth |
|---|------|--------|----------|------|
| 2.1 | Browse Services | GET | `/services` | None |
| 2.2 | Get Service Details | GET | `/services/{id}` | None |
| 2.3 | Search Services | GET | `/services/search` | None |
| 2.4 | Get Categories | GET | `/services/categories` | None |

### 3. Services - Provider (6 endpoints)

| # | Name | Method | Endpoint | Auth |
|---|------|--------|----------|------|
| 3.1 | List My Services | GET | `/provider/services` | Provider |
| 3.2 | Create Service | POST | `/provider/services` | Provider |
| 3.3 | Get Service Details | GET | `/provider/services/{id}` | Provider |
| 3.4 | Update Service | PUT | `/provider/services/{id}` | Provider |
| 3.5 | Update Service Status | PATCH | `/provider/services/{id}/status` | Provider |
| 3.6 | Delete Service | DELETE | `/provider/services/{id}` | Provider |

### 4. Bookings - Customer (5 endpoints)

| # | Name | Method | Endpoint | Auth |
|---|------|--------|----------|------|
| 4.1 | List My Bookings | GET | `/customer/bookings` | Customer |
| 4.2 | Create Booking | POST | `/customer/bookings` | Customer |
| 4.3 | Get Booking Details | GET | `/customer/bookings/{id}` | Customer |
| 4.4 | Cancel Booking | POST | `/customer/bookings/{id}/cancel` | Customer |
| 4.5 | Check Availability | GET | `/customer/bookings/check-availability` | Customer |

### 5. Bookings - Provider (7 endpoints)

| # | Name | Method | Endpoint | Auth |
|---|------|--------|----------|------|
| 5.1 | List Bookings | GET | `/provider/bookings` | Provider |
| 5.2 | Get Booking Details | GET | `/provider/bookings/{id}` | Provider |
| 5.3 | Accept Booking | POST | `/provider/bookings/{id}/accept` | Provider |
| 5.4 | Reject Booking | POST | `/provider/bookings/{id}/reject` | Provider |
| 5.5 | Complete Booking | POST | `/provider/bookings/{id}/complete` | Provider |
| 5.6 | Get Pending Bookings | GET | `/provider/bookings/pending` | Provider |
| 5.7 | Get Booking Statistics | GET | `/provider/bookings/stats` | Provider |

### 6. Profile (3 endpoints)

| # | Name | Method | Endpoint | Auth |
|---|------|--------|----------|------|
| 6.1 | Get Profile | GET | `/profile` | Any |
| 6.2 | Update Profile | PUT | `/profile` | Any |
| 6.3 | Upload Profile Image | POST | `/profile/image` | Any |

### 7. Provider Dashboard (4 endpoints)

| # | Name | Method | Endpoint | Auth |
|---|------|--------|----------|------|
| 7.1 | Get Provider Profile | GET | `/provider/profile` | Provider |
| 7.2 | Update Provider Profile | PUT | `/provider/profile` | Provider |
| 7.3 | Get Dashboard | GET | `/provider/dashboard` | Provider |
| 7.4 | Get Earnings | GET | `/provider/earnings` | Provider |

**Total: 36 endpoints**

