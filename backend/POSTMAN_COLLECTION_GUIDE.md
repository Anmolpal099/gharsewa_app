# Gharsewa API - Postman Collection Guide

## Overview

This guide explains how to use the Postman collection to test all Phase 1 Backend APIs for the Gharsewa application.

**Files:**
- `Gharsewa_API_Collection.postman_collection.json` - Complete API collection
- `Gharsewa_Environment.postman_environment.json` - Environment variables

---

## Quick Start

### 1. Import Collection and Environment

1. Open Postman
2. Click **Import** button
3. Select both files:
   - `Gharsewa_API_Collection.postman_collection.json`
   - `Gharsewa_Environment.postman_environment.json`
4. Click **Import**

### 2. Select Environment

1. Click the environment dropdown (top right)
2. Select **Gharsewa - Local**

### 3. Start Backend Server

```bash
cd e:\gharsewa\backend
docker-compose up -d
```

### 4. Test the Collection

Start with the **Authentication** folder to get your access token.

---

## Collection Structure

The collection is organized into 6 main folders:

### 1. Authentication (4 requests)
- Register
- Login
- Get Current User
- Logout

### 2. Public Services (3 requests)
- List All Services
- Get Service Details
- Get Categories

### 3. User Profile (3 requests)
- Get Profile
- Update Profile
- Upload Profile Image

### 4. Customer (4 requests)
- List My Bookings
- Create Booking
- Get Booking Details
- Cancel Booking

### 5. Provider (13 requests)
- Dashboard
- Get Earnings
- List My Services
- Create Service
- Update Service
- Delete Service
- Update Service Status
- List Provider Bookings
- Get Pending Bookings
- Get Booking Details
- Accept Booking
- Reject Booking
- Complete Booking
- Get Booking Statistics

### 6. Admin (11 requests)
- Dashboard
- Analytics
- List Users
- Get User Details
- Activate User
- Deactivate User
- Reset User Password
- Delete User
- List Bookings
- Cancel Booking
- Add Booking Note
- Generate Report

**Total Requests:** 38

---

## Environment Variables

The environment includes these variables:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `base_url` | API base URL | `http://localhost:8000/api/v1` |
| `access_token` | Current user's JWT token | Auto-set on login |
| `customer_token` | Customer JWT token | Auto-set on customer login |
| `provider_token` | Provider JWT token | Auto-set on provider login |
| `admin_token` | Admin JWT token | Auto-set on admin login |
| `customer_email` | Test customer email | `customer@test.com` |
| `provider_email` | Test provider email | `provider@test.com` |
| `admin_email` | Test admin email | `admin@test.com` |
| `test_password` | Test password | `Test1234` |

---

## Authentication Flow

### Step 1: Register a User

**Request:** `Authentication > Register`

**Body:**
```json
{
  "name": "Test Customer",
  "email": "customer@test.com",
  "password": "Test1234",
  "password_confirmation": "Test1234",
  "role": "customer"
}
```

**Result:** Token is automatically saved to `access_token` variable

### Step 2: Login

**Request:** `Authentication > Login`

**Body:**
```json
{
  "email": "customer@test.com",
  "password": "Test1234"
}
```

**Result:** Token is automatically saved to `access_token` variable

### Step 3: Use Protected Endpoints

All requests in Customer, Provider, Admin, and User Profile folders will automatically use the `access_token` from the environment.

---

## Testing Workflows

### Complete Customer Workflow

1. **Register as Customer**
   - Request: `Authentication > Register`
   - Set role to "customer"

2. **Browse Services (No Auth)**
   - Request: `Public Services > List All Services`

3. **View Service Details**
   - Request: `Public Services > Get Service Details`
   - Replace `:id` with actual service UUID

4. **Create Booking**
   - Request: `Customer > Create Booking`
   - Update `service_id` in body

5. **View My Bookings**
   - Request: `Customer > List My Bookings`

6. **Cancel Booking**
   - Request: `Customer > Cancel Booking`
   - Replace `:id` with booking UUID

### Complete Provider Workflow

1. **Register as Provider**
   - Request: `Authentication > Register`
   - Set role to "serviceProvider"

2. **View Dashboard**
   - Request: `Provider > Dashboard`

3. **Create Service**
   - Request: `Provider > Create Service`

4. **View Pending Bookings**
   - Request: `Provider > Get Pending Bookings`

5. **Accept Booking**
   - Request: `Provider > Accept Booking`
   - Replace `:id` with booking UUID

6. **Complete Booking**
   - Request: `Provider > Complete Booking`

7. **View Statistics**
   - Request: `Provider > Get Booking Statistics`

### Admin Workflow

1. **Register/Login as Admin**
   - Request: `Authentication > Register`
   - Set role to "admin"

2. **View Dashboard**
   - Request: `Admin > Dashboard`

3. **List Users**
   - Request: `Admin > List Users`

4. **Manage Users**
   - Activate: `Admin > Activate User`
   - Deactivate: `Admin > Deactivate User`
   - Reset Password: `Admin > Reset User Password`

5. **View Bookings**
   - Request: `Admin > List Bookings`

6. **Generate Report**
   - Request: `Admin > Generate Report`

---

## Using Multiple Roles

To test with multiple roles simultaneously:

### Method 1: Use Different Tokens

1. Login as customer, save token to `customer_token`
2. Login as provider, save token to `provider_token`
3. Login as admin, save token to `admin_token`
4. Manually switch `access_token` value when testing different roles

### Method 2: Use Multiple Environments

1. Duplicate the environment (right-click > Duplicate)
2. Rename to "Gharsewa - Customer", "Gharsewa - Provider", etc.
3. Login with each role in its respective environment
4. Switch environments when testing different roles

---

## Request Variables

Many requests use path variables that need to be replaced:

### Service ID
- Replace `:id` in service endpoints with actual service UUID
- Example: `{{base_url}}/services/123e4567-e89b-12d3-a456-426614174000`

### Booking ID
- Replace `:id` in booking endpoints with actual booking UUID
- Example: `{{base_url}}/customer/bookings/123e4567-e89b-12d3-a456-426614174000`

### User ID
- Replace `:id` in admin user endpoints with actual user UUID
- Example: `{{base_url}}/admin/users/123e4567-e89b-12d3-a456-426614174000`

---

## Query Parameters

Many requests have optional query parameters that are disabled by default. Enable them as needed:

### Filtering
- `status`: Filter by status (pending, confirmed, completed, cancelled, rejected)
- `category`: Filter by service category
- `role`: Filter users by role

### Pagination
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 15)

### Date Range
- `date_from`: Start date (YYYY-MM-DD)
- `date_to`: End date (YYYY-MM-DD)

### Search
- `search`: Search term for name/email/description

---

## Automated Tests

The collection includes automated tests for key requests:

### Register Request
```javascript
if (pm.response.code === 201) {
    var jsonData = pm.response.json();
    pm.environment.set('access_token', jsonData.data.access_token);
    pm.test('Registration successful', function () {
        pm.expect(jsonData.success).to.be.true;
    });
}
```

### Login Request
```javascript
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set('access_token', jsonData.data.access_token);
    pm.test('Login successful', function () {
        pm.expect(jsonData.success).to.be.true;
    });
}
```

These tests automatically:
- Save the JWT token to environment
- Verify successful response
- Check response structure

---

## Common Issues

### Issue 1: 401 Unauthorized

**Cause:** Missing or expired JWT token

**Solution:**
1. Login again using `Authentication > Login`
2. Verify `access_token` is set in environment
3. Check token hasn't expired (1 hour expiry)

### Issue 2: 403 Forbidden

**Cause:** Wrong role for endpoint

**Solution:**
1. Verify you're using correct role token
2. Customer endpoints require customer role
3. Provider endpoints require serviceProvider role
4. Admin endpoints require admin role

### Issue 3: 422 Validation Error

**Cause:** Invalid request data

**Solution:**
1. Check request body matches required format
2. Verify all required fields are present
3. Check data types (numbers, strings, dates)
4. Review validation rules in API documentation

### Issue 4: 404 Not Found

**Cause:** Invalid UUID or resource doesn't exist

**Solution:**
1. Verify UUID is correct format
2. Check resource exists (create it first if needed)
3. Ensure you're using correct endpoint path

---

## Tips and Best Practices

### 1. Use Collection Runner

Run entire workflows automatically:
1. Click **Runner** button
2. Select collection or folder
3. Select environment
4. Click **Run**

### 2. Save Responses

Save successful responses as examples:
1. Send request
2. Click **Save Response**
3. Click **Save as Example**

### 3. Use Pre-request Scripts

Add collection-level pre-request script for automatic token refresh:

```javascript
// Check if token is about to expire
const tokenExpiry = pm.environment.get('token_expiry');
if (tokenExpiry && Date.now() > tokenExpiry - 300000) {
    // Refresh token 5 minutes before expiry
    pm.sendRequest({
        url: pm.environment.get('base_url') + '/auth/jwt/refresh',
        method: 'POST',
        header: {
            'Authorization': 'Bearer ' + pm.environment.get('access_token')
        }
    }, function (err, res) {
        if (!err) {
            const newToken = res.json().data.access_token;
            pm.environment.set('access_token', newToken);
        }
    });
}
```

### 4. Export Results

Export test results for documentation:
1. Run collection
2. Click **Export Results**
3. Save as JSON or HTML

---

## Advanced Usage

### Testing Error Cases

Modify requests to test error handling:

**Invalid Data:**
```json
{
  "name": "",
  "price": -100
}
```

**Past Date:**
```json
{
  "scheduled_at": "2020-01-01 10:00:00"
}
```

**Non-existent ID:**
```
{{base_url}}/services/invalid-uuid
```

### Performance Testing

Use Collection Runner with iterations:
1. Set iterations to 100
2. Set delay to 100ms
3. Monitor response times

### Load Testing

Use Newman (Postman CLI) for load testing:

```bash
npm install -g newman
newman run Gharsewa_API_Collection.postman_collection.json \
  -e Gharsewa_Environment.postman_environment.json \
  -n 100 \
  --delay-request 100
```

---

## Support

For issues or questions:
- **API Documentation:** `API_DOCUMENTATION.md`
- **Manual Testing Guide:** `MANUAL_INTEGRATION_TEST_GUIDE.md`
- **Integration Tests:** `INTEGRATION_TEST_DOCUMENTATION.md`

---

**Last Updated:** May 26, 2026  
**Collection Version:** 1.0.0  
**Total Requests:** 38
