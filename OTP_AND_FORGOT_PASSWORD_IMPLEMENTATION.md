# ✅ OTP & Forgot Password Implementation

**Date:** 2026-05-21  
**Status:** 🚧 **PARTIALLY COMPLETE** - Backend Ready, Frontend Pending

---

## 🎯 What Was Implemented

### Backend (Laravel) - ✅ COMPLETE

1. **OTP Database Table** ✅
   - Migration created and run
   - Stores 6-digit OTPs with expiry
   - Tracks usage and attempts
   - Supports email verification and password reset

2. **OTP Model** ✅
   - Generate 6-digit OTP
   - Create OTP for email verification
   - Create OTP for password reset
   - Verify OTP with expiry check
   - Track attempts (max 5)

3. **OTP Controller** ✅
   - Send email verification OTP
   - Verify email OTP
   - Send password reset OTP
   - Verify password reset OTP
   - Reset password

4. **API Endpoints** ✅
   - `POST /api/v1/auth/otp/send-email-verification`
   - `POST /api/v1/auth/otp/verify-email`
   - `POST /api/v1/auth/otp/send-password-reset`
   - `POST /api/v1/auth/otp/verify-password-reset`
   - `POST /api/v1/auth/otp/reset-password`

### Frontend (Flutter) - ⏳ PENDING

**Still needs to be implemented:**
- Forgot Password link on login screen
- Forgot Password screen (enter email)
- OTP Input screen (6-digit code)
- New Password screen
- Integration with backend OTP APIs

---

## 📊 Current Status

### ✅ What's Working

**Backend:**
- OTP generation (6-digit random codes)
- OTP storage in database
- OTP expiry (10 minutes)
- OTP verification
- Email sending (logs OTP for now)
- Rate limiting (10 requests/minute)

**Frontend:**
- Email verification with Firebase links (existing)
- Login/Register screens (existing)

### ⏳ What's Pending

**Frontend Implementation Needed:**
1. Add "Forgot Password?" link to login screen
2. Create Forgot Password screen
3. Create OTP Input screen
4. Create New Password screen
5. Integrate with backend OTP APIs
6. Replace Firebase email verification with OTP system

---

## 🔄 Planned OTP Flow

### Email Verification with OTP

```
1. User registers → Backend generates 6-digit OTP
2. Backend sends OTP to email
3. User sees OTP input screen
4. User enters 6-digit code
5. Frontend calls verify-email API
6. If valid → User verified
7. If invalid → Show error, allow retry
```

### Forgot Password with OTP

```
1. User clicks "Forgot Password?" on login
2. User enters email address
3. Backend generates 6-digit OTP
4. Backend sends OTP to email
5. User sees OTP input screen
6. User enters 6-digit code
7. Frontend calls verify-password-reset API
8. If valid → Show new password screen
9. User enters new password
10. Frontend calls reset-password API
11. Password reset in Firebase
12. User can login with new password
```

---

## 📧 OTP Email Format

**Subject:** Your [Purpose] OTP - Gharsewa

**Body:**
```
Your OTP for [Purpose] is: 123456

This OTP will expire in 10 minutes.

If you didn't request this, please ignore this email.
```

**Current Status:** OTPs are logged to Laravel logs for development. In production, configure Laravel Mail to send actual emails.

---

## 🔧 Backend API Documentation

### 1. Send Email Verification OTP

**Endpoint:** `POST /api/v1/auth/otp/send-email-verification`

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent to your email",
  "expires_in": 600
}
```

### 2. Verify Email OTP

**Endpoint:** `POST /api/v1/auth/otp/verify-email`

**Request:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

### 3. Send Password Reset OTP

**Endpoint:** `POST /api/v1/auth/otp/send-password-reset`

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent to your email",
  "expires_in": 600
}
```

### 4. Verify Password Reset OTP

**Endpoint:** `POST /api/v1/auth/otp/verify-password-reset`

**Request:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "email": "user@example.com",
    "can_reset_password": true
  }
}
```

### 5. Reset Password

**Endpoint:** `POST /api/v1/auth/otp/reset-password`

**Request:**
```json
{
  "email": "user@example.com",
  "otp": "123456",
  "new_password": "NewPassword123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password reset successful. Please login with your new password."
}
```

---

## 🧪 Testing the Backend

### Test OTP Generation

```powershell
curl -X POST http://localhost:8000/api/v1/auth/otp/send-email-verification `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com"}'
```

**Check Laravel logs for OTP:**
```powershell
docker exec gharsewa_app tail -f storage/logs/laravel.log
```

### Test OTP Verification

```powershell
curl -X POST http://localhost:8000/api/v1/auth/otp/verify-email `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com","otp":"123456"}'
```

### Test Password Reset OTP

```powershell
curl -X POST http://localhost:8000/api/v1/auth/otp/send-password-reset `
  -H "Content-Type: application/json" `
  -d '{"email":"customer@test.com"}'
```

### Check OTP in Database

```powershell
docker exec -it gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SELECT email, otp, type, expires_at, is_used FROM otp_verifications ORDER BY created_at DESC LIMIT 5;"
```

---

## 📱 Frontend Implementation Guide

### Step 1: Add Forgot Password Link

**File:** `lib/presentation/shared/screens/login_screen.dart`

Add after password field:
```dart
// Forgot password link
if (!_isRegisterMode)
  Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: () => context.push('/forgot-password'),
      child: const Text('Forgot Password?'),
    ),
  ),
```

### Step 2: Create Forgot Password Screen

**File:** `lib/presentation/shared/screens/forgot_password_screen.dart`

Features:
- Email input field
- "Send OTP" button
- Navigate to OTP input screen

### Step 3: Create OTP Input Screen

**File:** `lib/presentation/shared/screens/otp_input_screen.dart`

Features:
- 6 input boxes for OTP digits
- Auto-focus next box
- Resend OTP button (60s cooldown)
- Verify button
- Timer showing expiry (10 minutes)

### Step 4: Create New Password Screen

**File:** `lib/presentation/shared/screens/new_password_screen.dart`

Features:
- New password input
- Confirm password input
- Password strength indicator
- Submit button

### Step 5: Add Routes

**File:** `lib/presentation/router/app_router.dart`

```dart
GoRoute(
  path: '/forgot-password',
  builder: (context, state) => const ForgotPasswordScreen(),
),
GoRoute(
  path: '/otp-input',
  builder: (context, state) => OtpInputScreen(
    email: state.extra as String,
    type: state.queryParameters['type'] ?? 'email_verification',
  ),
),
GoRoute(
  path: '/new-password',
  builder: (context, state) => NewPasswordScreen(
    email: state.extra as String,
  ),
),
```

---

## 🔐 Security Features

### OTP Security

1. **Expiry:** 10 minutes
2. **Single Use:** OTP invalidated after use
3. **Max Attempts:** 5 attempts per OTP
4. **Rate Limiting:** 10 requests/minute
5. **Random Generation:** Cryptographically secure random
6. **Database Storage:** Hashed in production (recommended)

### Password Reset Security

1. **Email Verification:** Must verify email first
2. **OTP Required:** Can't reset without valid OTP
3. **Time-Limited:** OTP expires in 10 minutes
4. **Audit Trail:** All attempts logged
5. **Firebase Integration:** Password actually reset in Firebase

---

## 📊 Database Schema

### otp_verifications Table

```sql
CREATE TABLE otp_verifications (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    type ENUM('email_verification', 'password_reset'),
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP NULL,
    attempts INT DEFAULT 0,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    
    INDEX idx_email_type_used (email, type, is_used),
    INDEX idx_expires_at (expires_at)
);
```

---

## 🚀 Next Steps

### Immediate (To Complete Feature)

1. **Create Frontend Screens:**
   - Forgot Password screen
   - OTP Input screen
   - New Password screen

2. **Add Forgot Password Link:**
   - Update login screen
   - Add navigation

3. **Integrate APIs:**
   - Call OTP endpoints from Flutter
   - Handle responses
   - Show error messages

4. **Test End-to-End:**
   - Register with OTP
   - Forgot password flow
   - Verify all scenarios

### Optional Enhancements

5. **Configure Email Service:**
   - Set up Laravel Mail
   - Use Mailtrap for testing
   - Use SendGrid/SES for production

6. **Improve OTP UI:**
   - Add animations
   - Better error messages
   - Loading states

7. **Add Analytics:**
   - Track OTP success rate
   - Monitor failed attempts
   - Alert on suspicious activity

---

## 📝 Important Notes

### Firebase vs Custom OTP

**Current Implementation:**
- Email verification: Firebase links (existing)
- Password reset: Not yet implemented
- Custom OTP: Backend ready, frontend pending

**Recommendation:**
- Keep Firebase for authentication
- Use custom OTP for email verification
- Use custom OTP for password reset
- Provides better UX (6-digit code vs clicking link)

### Email Configuration

**Development:**
- OTPs logged to Laravel logs
- Check logs: `docker exec gharsewa_app tail -f storage/logs/laravel.log`

**Production:**
- Configure Laravel Mail in `.env`
- Use SendGrid, SES, or Mailgun
- Set up email templates

---

## ✅ Summary

### What's Done ✅

- ✅ Backend OTP system complete
- ✅ Database table created
- ✅ API endpoints working
- ✅ OTP generation and verification
- ✅ Email sending (logs for now)

### What's Pending ⏳

- ⏳ Forgot Password link on login
- ⏳ Forgot Password screen
- ⏳ OTP Input screen
- ⏳ New Password screen
- ⏳ Frontend API integration
- ⏳ Replace Firebase email verification with OTP

### Estimated Time to Complete

- Frontend screens: 4-6 hours
- API integration: 2-3 hours
- Testing: 1-2 hours
- **Total: 7-11 hours**

---

**Backend is ready! Frontend implementation needed to complete the feature.** 🚀

Would you like me to implement the Flutter screens now?

