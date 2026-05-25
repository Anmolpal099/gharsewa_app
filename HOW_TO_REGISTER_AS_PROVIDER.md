# How to Register as a Service Provider

## Method 1: Using the Flutter App (Recommended)

### Step 1: Start the Application

1. **Start Backend**:
```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

2. **Start Flutter App**:
```powershell
cd e:\gharsewa
flutter run
```

### Step 2: Register on Login Screen

1. Open the app
2. On the login screen, tap **"Sign Up"** or **"Register"**
3. Fill in the registration form:
   - **Name**: Your full name (e.g., "John Provider")
   - **Email**: Your email address (e.g., "john@provider.com")
   - **Password**: Strong password (min 8 characters)
   - **Confirm Password**: Same password
   - **Role**: Select **"Service Provider"** from dropdown
4. Tap **"Register"** button

### Step 3: Verify Email

1. Check your email for the OTP (One-Time Password)
   - If using local development, check backend logs:
   ```powershell
   docker-compose logs -f app | grep OTP
   ```
2. Enter the 6-digit OTP in the verification screen
3. Tap **"Verify"**

### Step 4: Login

1. After verification, you'll be redirected to login
2. Enter your email and password
3. Tap **"Login"**
4. You'll be automatically redirected to the **Provider Dashboard**

---

## Method 2: Using API (For Testing/Development)

### Step 1: Register via API

```bash
POST http://localhost:8000/api/v1/auth/jwt/register
Content-Type: application/json

{
  "name": "Test Provider",
  "email": "provider@test.com",
  "password": "Test1234",
  "password_confirmation": "Test1234",
  "role": "serviceProvider"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Registration successful. Please verify your email.",
  "data": {
    "user": {
      "id": "uuid-here",
      "name": "Test Provider",
      "email": "provider@test.com",
      "role": "serviceProvider",
      "email_verified_at": null
    }
  }
}
```

### Step 2: Get OTP from Logs

```powershell
# Check backend logs for OTP
docker-compose logs -f app | grep OTP

# You'll see something like:
# OTP for provider@test.com: 123456
```

### Step 3: Verify Email

```bash
POST http://localhost:8000/api/v1/auth/otp/verify-email
Content-Type: application/json

{
  "email": "provider@test.com",
  "otp": "123456"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Email verified successfully",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid-here",
      "name": "Test Provider",
      "email": "provider@test.com",
      "role": "serviceProvider",
      "email_verified_at": "2025-01-XX 10:30:00"
    }
  }
}
```

### Step 4: Login (if needed)

```bash
POST http://localhost:8000/api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "provider@test.com",
  "password": "Test1234"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid-here",
      "name": "Test Provider",
      "email": "provider@test.com",
      "role": "serviceProvider"
    }
  }
}
```

---

## Method 3: Using Postman/Insomnia

### Import this collection:

```json
{
  "name": "Provider Registration",
  "requests": [
    {
      "name": "1. Register Provider",
      "method": "POST",
      "url": "http://localhost:8000/api/v1/auth/jwt/register",
      "headers": {
        "Content-Type": "application/json"
      },
      "body": {
        "name": "{{provider_name}}",
        "email": "{{provider_email}}",
        "password": "{{provider_password}}",
        "password_confirmation": "{{provider_password}}",
        "role": "serviceProvider"
      }
    },
    {
      "name": "2. Verify Email",
      "method": "POST",
      "url": "http://localhost:8000/api/v1/auth/otp/verify-email",
      "headers": {
        "Content-Type": "application/json"
      },
      "body": {
        "email": "{{provider_email}}",
        "otp": "{{otp_from_logs}}"
      }
    },
    {
      "name": "3. Login",
      "method": "POST",
      "url": "http://localhost:8000/api/v1/auth/jwt/login",
      "headers": {
        "Content-Type": "application/json"
      },
      "body": {
        "email": "{{provider_email}}",
        "password": "{{provider_password}}"
      }
    }
  ]
}
```

**Environment Variables**:
```json
{
  "provider_name": "Test Provider",
  "provider_email": "provider@test.com",
  "provider_password": "Test1234",
  "otp_from_logs": "123456"
}
```

---

## What Happens After Registration?

### 1. Email Verification
- An OTP is sent to your email
- In development, check backend logs for the OTP
- In production, check your email inbox

### 2. Account Activation
- After email verification, your account is activated
- You receive JWT tokens (access_token and refresh_token)

### 3. Automatic Login
- The app automatically logs you in after verification
- You're redirected to the Provider Dashboard

### 4. Provider Dashboard Access
You'll see:
- Welcome card with your name
- Earnings card (initially NPR 0)
- Services overview (0 services)
- Booking statistics (0 bookings)
- Empty state prompts to add your first service

---

## First Steps After Registration

### 1. Add Your First Service

1. Navigate to **"Services"** tab
2. Tap the **"Add Service"** button
3. Fill in the form:
   - **Service Name**: e.g., "House Cleaning"
   - **Description**: e.g., "Professional house cleaning service"
   - **Category**: Select from dropdown (Cleaning, Plumbing, etc.)
   - **Price**: e.g., "2000" (NPR)
   - **Duration**: e.g., "120" (minutes)
4. Tap **"Add Service"**

### 2. Wait for Booking Requests

- Customers can now see your service
- You'll receive booking requests in the **"Bookings"** tab
- Accept or reject requests as they come in

### 3. Manage Your Business

- **Dashboard**: Monitor earnings and statistics
- **Bookings**: Accept/reject/complete bookings
- **Services**: Add, edit, or deactivate services
- **Analytics**: View earnings breakdown and trends

---

## Troubleshooting

### Issue 1: OTP Not Received

**Solution**:
```powershell
# Check backend logs
cd e:\gharsewa\backend
docker-compose logs -f app | grep OTP

# You'll see: OTP for your-email@example.com: 123456
```

### Issue 2: Email Already Registered

**Solution**:
- Use a different email address
- Or reset password if you forgot it

### Issue 3: Registration Fails

**Check**:
1. Backend is running: `docker-compose ps`
2. Database is accessible
3. Password meets requirements (min 8 characters)
4. Email format is valid

**View Logs**:
```powershell
docker-compose logs -f app
```

### Issue 4: Can't Login After Registration

**Solution**:
1. Make sure you verified your email first
2. Check if you're using the correct password
3. Try password reset if needed

---

## Testing Multiple Provider Accounts

### Quick Setup Script (PowerShell):

```powershell
# Provider 1
$provider1 = @{
    name = "John's Cleaning Service"
    email = "john@cleaning.com"
    password = "Test1234"
    role = "serviceProvider"
}

# Provider 2
$provider2 = @{
    name = "Jane's Plumbing"
    email = "jane@plumbing.com"
    password = "Test1234"
    role = "serviceProvider"
}

# Register Provider 1
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/register" `
    -Method POST `
    -ContentType "application/json" `
    -Body ($provider1 | ConvertTo-Json)

# Register Provider 2
Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/register" `
    -Method POST `
    -ContentType "application/json" `
    -Body ($provider2 | ConvertTo-Json)

# Check logs for OTPs
docker-compose logs -f app | Select-String "OTP"
```

---

## Role Differences

### Customer vs Service Provider

| Feature | Customer | Service Provider |
|---------|----------|------------------|
| Browse Services | ✅ Yes | ❌ No |
| Book Services | ✅ Yes | ❌ No |
| Manage Services | ❌ No | ✅ Yes |
| Accept Bookings | ❌ No | ✅ Yes |
| View Dashboard | ✅ Basic | ✅ Advanced |
| View Analytics | ❌ No | ✅ Yes |
| Earnings Tracking | ❌ No | ✅ Yes |

### Switching Roles

**Note**: You cannot switch roles after registration. Each account is tied to one role:
- To be both a customer and provider, create two separate accounts
- Use different email addresses for each role

---

## Security Best Practices

### For Production:

1. **Strong Passwords**:
   - Minimum 8 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Don't reuse passwords

2. **Email Verification**:
   - Always verify your email
   - Don't share OTP codes

3. **Token Security**:
   - Tokens are stored securely in the app
   - Don't share your access tokens
   - Tokens expire after 1 hour (auto-refresh)

4. **Account Security**:
   - Use a valid email you have access to
   - Enable two-factor authentication (future feature)
   - Log out from shared devices

---

## Quick Reference

### Registration Endpoint:
```
POST /api/v1/auth/jwt/register
```

### Required Fields:
- `name` (string, 2-100 chars)
- `email` (valid email format)
- `password` (min 8 chars)
- `password_confirmation` (must match password)
- `role` (must be "serviceProvider")

### Verification Endpoint:
```
POST /api/v1/auth/otp/verify-email
```

### Login Endpoint:
```
POST /api/v1/auth/jwt/login
```

---

## Need Help?

### Check Documentation:
- `PROVIDER_PANEL_TESTING_GUIDE.md` - Testing guide
- `EPIC_7_PROVIDER_PANEL_COMPLETE.md` - Feature documentation
- `PHASE_1_COMPLETE_SUMMARY.md` - Backend API documentation

### Check Logs:
```powershell
# Backend logs
docker-compose logs -f app

# Flutter logs
flutter run --verbose
```

### Common Commands:
```powershell
# Restart backend
docker-compose restart

# Clear backend cache
docker-compose exec app php artisan cache:clear

# Run migrations
docker-compose exec app php artisan migrate

# Check database
docker-compose exec db mysql -u root -p gharsewa
```

---

**Happy Providing! 🎉**

