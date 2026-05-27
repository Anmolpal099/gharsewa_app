# Postman Collection Setup Guide

## Quick Import (Recommended)

Due to the large size of the collection, we provide a structured guide to create it manually or use the provided curl scripts for testing.

## Option 1: Manual Creation in Postman

### Step 1: Create New Collection

1. Open Postman
2. Click **New** → **Collection**
3. Name: `Phase 1 Backend APIs - Gharsewa`
4. Description: `Complete API collection for Gharsewa Phase 1 Backend APIs`

### Step 2: Configure Collection Variables

In Collection → Variables tab, add:

| Variable | Initial Value | Type |
|----------|---------------|------|
| base_url | http://localhost:8000/api/v1 | default |
| access_token | (empty) | secret |
| provider_token | (empty) | secret |
| customer_token | (empty) | secret |
| service_id | (empty) | default |
| booking_id | (empty) | default |

### Step 3: Configure Collection Authorization

1. Go to Collection → Authorization tab
2. Type: **Bearer Token**
3. Token: `{{access_token}}`

### Step 4: Create Folders and Requests

Follow the structure below to create each folder and request.


## Folder 1: Authentication (7 requests)

### 1.1 Register (Customer)
- **Method:** POST
- **URL:** `{{base_url}}/auth/jwt/register`
- **Auth:** No Auth
- **Body (raw JSON):**
```json
{
  "name": "Test Customer",
  "email": "customer@test.com",
  "password": "Test1234",
  "password_confirmation": "Test1234",
  "role": "customer"
}
```
- **Tests:**
```javascript
pm.test("Status code is 201", () => pm.response.to.have.status(201));
if (pm.response.code === 201) {
    const response = pm.response.json();
    pm.environment.set("customer_token", response.data.access_token);
    pm.environment.set("access_token", response.data.access_token);
}
```

### 1.2 Register (Provider)
- **Method:** POST
- **URL:** `{{base_url}}/auth/jwt/register`
- **Auth:** No Auth
- **Body (raw JSON):**
```json
{
  "name": "Test Provider",
  "email": "provider@test.com",
  "password": "Test1234",
  "password_confirmation": "Test1234",
  "role": "serviceProvider"
}
```
- **Tests:**
```javascript
pm.test("Status code is 201", () => pm.response.to.have.status(201));
if (pm.response.code === 201) {
    const response = pm.response.json();
    pm.environment.set("provider_token", response.data.access_token);
}
```

### 1.3 Login (Customer)
- **Method:** POST
- **URL:** `{{base_url}}/auth/jwt/login`
- **Auth:** No Auth
- **Body (raw JSON):**
```json
{
  "email": "customer@test.com",
  "password": "Test1234"
}
```
- **Tests:**
```javascript
pm.test("Status code is 200", () => pm.response.to.have.status(200));
if (pm.response.code === 200) {
    const response = pm.response.json();
    pm.environment.set("customer_token", response.data.access_token);
    pm.environment.set("access_token", response.data.access_token);
}
```

### 1.4 Login (Provider)
- **Method:** POST
- **URL:** `{{base_url}}/auth/jwt/login`
- **Auth:** No Auth
- **Body (raw JSON):**
```json
{
  "email": "provider@test.com",
  "password": "Test1234"
}
```
- **Tests:**
```javascript
pm.test("Status code is 200", () => pm.response.to.have.status(200));
if (pm.response.code === 200) {
    const response = pm.response.json();
    pm.environment.set("provider_token", response.data.access_token);
    pm.environment.set("access_token", response.data.access_token);
}
```

### 1.5 Get Current User
- **Method:** GET
- **URL:** `{{base_url}}/auth/jwt/me`
- **Auth:** Inherit from parent

### 1.6 Refresh Token
- **Method:** POST
- **URL:** `{{base_url}}/auth/jwt/refresh`
- **Auth:** Inherit from parent

### 1.7 Logout
- **Method:** POST
- **URL:** `{{base_url}}/auth/jwt/logout`
- **Auth:** Inherit from parent

