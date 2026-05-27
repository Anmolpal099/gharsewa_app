# Gharsewa Phase 1 Backend APIs - Postman Collection

## Overview

This directory contains the complete Postman collection and environment for testing all Phase 1 Backend APIs of the Gharsewa application.

## Files

- `Phase1-Backend-APIs.postman_collection.json` - Complete API collection with 30+ endpoints
- `Gharsewa-Local.postman_environment.json` - Environment variables for local development
- `README.md` - This file

## Setup Instructions

### 1. Import Collection and Environment

1. Open Postman
2. Click **Import** button
3. Select both JSON files:
   - `Phase1-Backend-APIs.postman_collection.json`
   - `Gharsewa-Local.postman_environment.json`
4. Click **Import**

### 2. Select Environment

1. In Postman, click the environment dropdown (top right)
2. Select **Gharsewa - Local**

### 3. Start Backend Server

```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

## Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `base_url` | API base URL | `http://localhost:8000/api/v1` |
| `access_token` | Current user's JWT token | Auto-set by login requests |
| `provider_token` | Provider's JWT token | Auto-set by provider login |
| `customer_token` | Customer's JWT token | Auto-set by customer login |
| `service_id` | Service ID for testing | Auto-set by service creation |
| `booking_id` | Booking ID for testing | Auto-set by booking creation |
| `provider_email` | Provider test email | `provider@test.com` |
| `provider_password` | Provider test password | `Test1234` |
| `customer_email` | Customer test email | `customer@test.com` |
| `customer_password` | Customer test password | `Test1234` |


## API Endpoints Overview

### 1. Authentication (6 endpoints)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/jwt/register` | Register new user | No |
| POST | `/auth/jwt/login` | Login and get JWT token | No |
| POST | `/auth/jwt/refresh` | Refresh JWT token | No |
| POST | `/auth/jwt/logout` | Logout user | Yes |
| GET | `/auth/jwt/me` | Get current user info | Yes |
| POST | `/auth/jwt/become-service-provider` | Upgrade to provider | Yes |

### 2. Services - Public (4 endpoints)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/services` | Browse all active services | No |
| GET | `/services/{id}` | Get service details | No |
| GET | `/services/search` | Search services | No |
| GET | `/services/categories` | Get service categories | No |

### 3. Services - Provider (6 endpoints)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/provider/services` | List provider's services | Provider |
| POST | `/provider/services` | Create new service | Provider |
| GET | `/provider/services/{id}` | Get service details | Provider |
| PUT | `/provider/services/{id}` | Update service | Provider |
| DELETE | `/provider/services/{id}` | Delete service | Provider |
| PATCH | `/provider/services/{id}/status` | Update service status | Provider |

### 4. Bookings - Customer (5 endpoints)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/customer/bookings` | List customer's bookings | Customer |
| POST | `/customer/bookings` | Create new booking | Customer |
| GET | `/customer/bookings/{id}` | Get booking details | Customer |
| POST | `/customer/bookings/{id}/cancel` | Cancel booking | Customer |
| GET | `/customer/bookings/check-availability` | Check service availability | Customer |

### 5. Bookings - Provider (7 endpoints)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/provider/bookings` | List provider's bookings | Provider |
| GET | `/provider/bookings/{id}` | Get booking details | Provider |
| POST | `/provider/bookings/{id}/accept` | Accept booking | Provider |
| POST | `/provider/bookings/{id}/reject` | Reject booking | Provider |
| POST | `/provider/bookings/{id}/complete` | Complete booking | Provider |
| GET | `/provider/bookings/pending` | Get pending bookings | Provider |
| GET | `/provider/bookings/stats` | Get booking statistics | Provider |

### 6. Profile (3 endpoints)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/profile` | Get user profile | Yes (Any) |
| PUT | `/profile` | Update user profile | Yes (Any) |
| POST | `/profile/image` | Upload profile image | Yes (Any) |

### 7. Provider Dashboard (4 endpoints)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/provider/profile` | Get provider profile | Provider |
| PUT | `/provider/profile` | Update provider profile | Provider |
| GET | `/provider/dashboard` | Get dashboard statistics | Provider |
| GET | `/provider/earnings` | Get earnings breakdown | Provider |

**Total: 35 endpoints**


## Testing Workflows

### Workflow 1: Complete Provider Journey

1. **Register as Provider**
   - Use: `1. Authentication > Register (Provider)`
   - Token auto-saved to `provider_token`

2. **Create a Service**
   - Use: `3. Services - Provider > Create Service`
   - Service ID auto-saved to `service_id`

3. **View Your Services**
   - Use: `3. Services - Provider > List My Services`

4. **Wait for Customer Booking** (see Workflow 2)

5. **View Pending Bookings**
   - Use: `5. Bookings - Provider > Get Pending Bookings`

6. **Accept Booking**
   - Use: `5. Bookings - Provider > Accept Booking`

7. **Complete Booking**
   - Use: `5. Bookings - Provider > Complete Booking`

8. **View Dashboard**
   - Use: `7. Provider Dashboard > Get Dashboard`

### Workflow 2: Complete Customer Journey

1. **Register as Customer**
   - Use: `1. Authentication > Register (Customer)`
   - Token auto-saved to `customer_token`

2. **Browse Services**
   - Use: `2. Services - Public > Browse Services`

3. **View Service Details**
   - Use: `2. Services - Public > Get Service Details`
   - Copy a service ID to `service_id` variable

4. **Create Booking**
   - Use: `4. Bookings - Customer > Create Booking`
   - Booking ID auto-saved to `booking_id`

5. **View My Bookings**
   - Use: `4. Bookings - Customer > List My Bookings`

6. **Cancel Booking** (optional)
   - Use: `4. Bookings - Customer > Cancel Booking`

### Workflow 3: Testing Authorization

1. **Login as Customer**
   - Use: `1. Authentication > Login (Customer)`

2. **Try to Access Provider Endpoint** (should fail with 403)
   - Use: `3. Services - Provider > List My Services`
   - Expected: `403 Unauthorized`

3. **Login as Provider**
   - Use: `1. Authentication > Login (Provider)`

4. **Try to Access Customer Endpoint** (should fail with 403)
   - Use: `4. Bookings - Customer > List My Bookings`
   - Expected: `403 Unauthorized`


## Request Examples

### Authentication

#### Register
```json
POST /auth/jwt/register
{
  "name": "Test Provider",
  "email": "provider@test.com",
  "password": "Test1234",
  "password_confirmation": "Test1234",
  "role": "serviceProvider"
}
```

#### Login
```json
POST /auth/jwt/login
{
  "email": "provider@test.com",
  "password": "Test1234"
}
```

### Services

#### Create Service
```json
POST /provider/services
Authorization: Bearer {{provider_token}}
{
  "name": "House Cleaning Service",
  "description": "Professional house cleaning with experienced staff",
  "category": "Cleaning",
  "price": 1500,
  "duration_minutes": 120,
  "currency": "NPR"
}
```

#### Browse Services (Public)
```
GET /services?category=Cleaning&min_price=1000&max_price=2000
```

### Bookings

#### Create Booking
```json
POST /customer/bookings
Authorization: Bearer {{customer_token}}
{
  "service_id": "{{service_id}}",
  "scheduled_at": "2026-06-01 10:00:00",
  "notes": "Please bring cleaning supplies"
}
```

#### Accept Booking
```json
POST /provider/bookings/{{booking_id}}/accept
Authorization: Bearer {{provider_token}}
```

#### Reject Booking
```json
POST /provider/bookings/{{booking_id}}/reject
Authorization: Bearer {{provider_token}}
{
  "cancellation_reason": "Not available at that time"
}
```

### Profile

#### Update Profile
```json
PUT /profile
Authorization: Bearer {{access_token}}
{
  "name": "Updated Name",
  "phone_number": "+977-9841234567",
  "address": "Kathmandu, Nepal"
}
```


## Response Validation Tests

Each request in the collection includes automated tests that:

1. **Validate Status Code**
   ```javascript
   pm.test("Status code is 200", function () {
       pm.response.to.have.status(200);
   });
   ```

2. **Validate Response Structure**
   ```javascript
   pm.test("Response has success field", function () {
       const response = pm.response.json();
       pm.expect(response).to.have.property('success');
       pm.expect(response).to.have.property('message');
       pm.expect(response).to.have.property('data');
   });
   ```

3. **Auto-Save Variables**
   ```javascript
   // Auto-save access token from login
   if (pm.response.code === 200) {
       const response = pm.response.json();
       if (response.data && response.data.access_token) {
           pm.environment.set('access_token', response.data.access_token);
       }
   }
   ```

4. **Validate Data Types**
   ```javascript
   pm.test("Service has required fields", function () {
       const service = pm.response.json().data;
       pm.expect(service).to.have.property('id');
       pm.expect(service).to.have.property('name');
       pm.expect(service.price).to.be.a('number');
   });
   ```

## Common HTTP Status Codes

| Code | Meaning | When It Occurs |
|------|---------|----------------|
| 200 | OK | Successful GET, PUT, PATCH requests |
| 201 | Created | Successful POST requests (resource created) |
| 400 | Bad Request | Business logic violation |
| 401 | Unauthorized | Missing or invalid JWT token |
| 403 | Forbidden | Insufficient permissions (wrong role) |
| 404 | Not Found | Resource doesn't exist |
| 422 | Unprocessable Entity | Validation errors |
| 500 | Internal Server Error | Server-side error |

## Troubleshooting

### Issue: "Unauthenticated" Error (401)

**Solution:**
1. Make sure you've logged in first
2. Check that `access_token` variable is set
3. Verify token hasn't expired (1 hour expiry)
4. Use refresh token endpoint if needed

### Issue: "Unauthorized" Error (403)

**Solution:**
1. Check you're using the correct role token
2. Provider endpoints need `provider_token`
3. Customer endpoints need `customer_token`
4. Verify you own the resource you're accessing

### Issue: Validation Errors (422)

**Solution:**
1. Check all required fields are provided
2. Verify data types match requirements
3. Check min/max constraints
4. Review error response for specific field errors

### Issue: "Resource not found" (404)

**Solution:**
1. Verify the ID exists in database
2. Check you're using correct variable (e.g., `{{service_id}}`)
3. Ensure resource wasn't soft-deleted


## Advanced Features

### Query Parameters

#### Filtering Services
```
GET /services?category=Cleaning&status=active
GET /services?min_price=1000&max_price=5000
GET /services/search?q=cleaning
```

#### Filtering Bookings
```
GET /customer/bookings?status=pending
GET /provider/bookings?status=confirmed&date_from=2026-05-01
```

#### Pagination
```
GET /services?page=2&per_page=20
GET /customer/bookings?page=1&per_page=10
```

### Date Range Queries

#### Provider Earnings
```
GET /provider/earnings?date_from=2026-05-01&date_to=2026-05-31&group_by=day
GET /provider/earnings?date_from=2026-01-01&date_to=2026-12-31&group_by=month
```

#### Booking Statistics
```
GET /provider/bookings/stats?date_from=2026-05-01&date_to=2026-05-31
```

### File Upload

#### Profile Image Upload
```
POST /profile/image
Authorization: Bearer {{access_token}}
Content-Type: multipart/form-data

image: [Select File - JPEG/PNG, max 2MB]
```

## Collection Organization

```
Phase 1 Backend APIs
├── 1. Authentication (6 requests)
│   ├── Register (Customer)
│   ├── Register (Provider)
│   ├── Login (Customer)
│   ├── Login (Provider)
│   ├── Refresh Token
│   ├── Logout
│   ├── Get Current User
│   └── Become Service Provider
│
├── 2. Services - Public (4 requests)
│   ├── Browse Services
│   ├── Get Service Details
│   ├── Search Services
│   └── Get Categories
│
├── 3. Services - Provider (6 requests)
│   ├── List My Services
│   ├── Create Service
│   ├── Get Service Details
│   ├── Update Service
│   ├── Delete Service
│   └── Update Service Status
│
├── 4. Bookings - Customer (5 requests)
│   ├── List My Bookings
│   ├── Create Booking
│   ├── Get Booking Details
│   ├── Cancel Booking
│   └── Check Availability
│
├── 5. Bookings - Provider (7 requests)
│   ├── List Bookings
│   ├── Get Booking Details
│   ├── Accept Booking
│   ├── Reject Booking
│   ├── Complete Booking
│   ├── Get Pending Bookings
│   └── Get Booking Statistics
│
├── 6. Profile (3 requests)
│   ├── Get Profile
│   ├── Update Profile
│   └── Upload Profile Image
│
└── 7. Provider Dashboard (4 requests)
    ├── Get Provider Profile
    ├── Update Provider Profile
    ├── Get Dashboard
    └── Get Earnings
```

## Testing Checklist

### Functional Testing
- [ ] All authentication endpoints work
- [ ] Public service browsing works without auth
- [ ] Provider can CRUD their services
- [ ] Customer can create and cancel bookings
- [ ] Provider can manage booking status
- [ ] Profile updates work for all roles
- [ ] Dashboard shows correct statistics

### Authorization Testing
- [ ] Unauthenticated requests are rejected (401)
- [ ] Wrong role requests are rejected (403)
- [ ] Users can only access their own resources
- [ ] Cross-user access is blocked

### Validation Testing
- [ ] Required fields are enforced
- [ ] Data type validation works
- [ ] Min/max constraints are enforced
- [ ] Enum values are validated

### Business Logic Testing
- [ ] Service deletion blocked with active bookings
- [ ] Booking status transitions work correctly
- [ ] Price automatically set from service
- [ ] Provider ID automatically set
- [ ] Only pending bookings can be accepted/rejected
- [ ] Only confirmed bookings can be completed

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the manual testing guide: `backend/MANUAL_INTEGRATION_TEST_GUIDE.md`
3. Check API documentation in the spec folder

## Version History

- **v1.0.0** (2026-05-26) - Initial release with 35 endpoints
  - Authentication (6 endpoints)
  - Services - Public (4 endpoints)
  - Services - Provider (6 endpoints)
  - Bookings - Customer (5 endpoints)
  - Bookings - Provider (7 endpoints)
  - Profile (3 endpoints)
  - Provider Dashboard (4 endpoints)
