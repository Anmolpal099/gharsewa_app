# Forgot Password Flow Fix

## Issue
When entering a registered user's email in the forgot password section, the system was showing "No account found with this email" error instead of navigating to the OTP verification and new password screens.

## Root Cause
The password reset OTP endpoint was checking only the Laravel database for user existence. However, there was a potential sync issue where:
1. Users register through Firebase (frontend)
2. Registration endpoint is called to sync to Laravel database
3. If the sync failed or was delayed, the user wouldn't be found in Laravel database
4. Password reset would fail with "No account found" error

## Solution

### 1. Enhanced User Lookup in OTP Controller
**File:** `backend/app/Http/Controllers/API/V1/Auth/OtpController.php`

**Changes:**
- Modified `sendPasswordResetOtp()` method to check both Laravel database AND Firebase
- If user exists in Firebase but not in Laravel, automatically sync them to the database
- This ensures password reset works even if initial registration sync failed

```php
// Check Laravel database first
$user = User::where('email', $request->email)->first();

if (!$user) {
    // Fallback: Check Firebase and sync to Laravel
    try {
        $auth = app('firebase.auth');
        $firebaseUser = $auth->getUserByEmail($request->email);
        
        // Create user in Laravel database
        $user = User::create([
            'firebase_uid' => $firebaseUser->uid,
            'email' => $request->email,
            'name' => $firebaseUser->displayName ?? 'User',
            'role' => 'customer',
            'is_active' => true,
        ]);
    } catch (\Kreait\Firebase\Exception\Auth\UserNotFound $e) {
        return response()->json([
            'success' => false,
            'message' => 'No account found with this email',
        ], 404);
    }
}
```

### 2. Firebase Password Update in Backend
**File:** `backend/app/Http/Controllers/API/V1/Auth/OtpController.php`

**Changes:**
- Modified `resetPassword()` method to actually update the password in Firebase
- Previously it was just a placeholder - now it calls Firebase Admin SDK to update the password

```php
// Update password in Firebase
$auth = app('firebase.auth');
$firebaseUser = $auth->getUserByEmail($request->email);

$auth->updateUser($firebaseUser->uid, [
    'password' => $request->new_password,
]);
```

### 3. Simplified Flutter Password Reset
**File:** `lib/presentation/shared/screens/new_password_screen.dart`

**Changes:**
- Removed duplicate Firebase password update attempt from Flutter
- Backend now handles all password updates
- Removed unused `firebase_auth` import

## Complete Forgot Password Flow (After Fix)

### Step 1: Enter Email
1. User clicks "Forgot Password?" on login screen
2. Navigates to `ForgotPasswordScreen`
3. User enters their registered email
4. Clicks "Send OTP"

### Step 2: Backend Processing
1. Backend checks Laravel database for user
2. If not found, checks Firebase and syncs to Laravel
3. If user exists, generates 6-digit OTP
4. Sends OTP via email (logged in Laravel logs)
5. Returns success response

### Step 3: OTP Verification
1. User navigates to `OtpInputScreen`
2. Enters 6-digit OTP from email/logs
3. Backend verifies OTP
4. If valid, returns success

### Step 4: New Password
1. User navigates to `NewPasswordScreen`
2. Enters new password (with strength indicator)
3. Re-enters password for confirmation
4. Clicks "Reset Password"

### Step 5: Backend Password Update
1. Backend verifies OTP again
2. Updates password in Firebase using Admin SDK
3. Updates metadata in Laravel database
4. Returns success response

### Step 6: Login
1. Success message shown
2. User navigates back to login screen
3. Can now login with new password

## Password Requirements

The new password must contain:
- ✅ At least 8 characters
- ✅ One uppercase letter (A-Z)
- ✅ One lowercase letter (a-z)
- ✅ One number (0-9)

**Password Strength Indicator:**
- **Weak** (Red): 0-2 criteria met
- **Medium** (Orange): 3 criteria met
- **Strong** (Green): 4+ criteria met (includes special characters)

## Files Modified

### Backend
1. **`backend/app/Http/Controllers/API/V1/Auth/OtpController.php`**
   - Enhanced `sendPasswordResetOtp()` - checks Laravel DB + Firebase fallback
   - Enhanced `resetPassword()` - actually updates Firebase password

### Frontend
2. **`lib/presentation/shared/screens/new_password_screen.dart`**
   - Removed duplicate Firebase password update
   - Removed unused import

## Testing

### Test Case 1: Registered User Password Reset

**Steps:**
1. Register a new user (e.g., test@example.com)
2. Logout
3. Click "Forgot Password?"
4. Enter: test@example.com
5. Click "Send OTP"

**Expected:**
- ✅ Success message: "OTP sent to your email"
- ✅ Navigates to OTP input screen
- ✅ Check Laravel logs for OTP: `docker exec gharsewa_app tail -f storage/logs/laravel.log`

6. Enter the 6-digit OTP
7. Click "Verify OTP"

**Expected:**
- ✅ Success message: "OTP verified successfully"
- ✅ Navigates to new password screen

8. Enter new password: `NewPass123`
9. Re-enter password: `NewPass123`
10. Click "Reset Password"

**Expected:**
- ✅ Success message: "Password reset successful! Please login with your new password."
- ✅ Navigates to login screen

11. Login with new password

**Expected:**
- ✅ Login successful
- ✅ Navigates to dashboard

### Test Case 2: User in Firebase but Not in Laravel

**Scenario:** User registered but Laravel sync failed

**Steps:**
1. Create user in Firebase only (manually or through failed registration)
2. Try forgot password flow

**Expected:**
- ✅ Backend checks Laravel DB (not found)
- ✅ Backend checks Firebase (found)
- ✅ Backend syncs user to Laravel DB
- ✅ OTP sent successfully
- ✅ Rest of flow works normally

### Test Case 3: Non-Existent User

**Steps:**
1. Click "Forgot Password?"
2. Enter: nonexistent@example.com
3. Click "Send OTP"

**Expected:**
- ✅ Error message: "No account found with this email"
- ✅ User remains on forgot password screen

## API Endpoints

### 1. Send Password Reset OTP
```
POST http://localhost:8000/api/v1/auth/otp/send-password-reset
Body: {"email": "test@example.com"}

Response (Success):
{
  "success": true,
  "message": "OTP sent to your email",
  "expires_in": 600
}

Response (User Not Found):
{
  "success": false,
  "message": "No account found with this email"
}
```

### 2. Verify Password Reset OTP
```
POST http://localhost:8000/api/v1/auth/otp/verify-password-reset
Body: {"email": "test@example.com", "otp": "123456"}

Response (Success):
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "email": "test@example.com",
    "can_reset_password": true
  }
}
```

### 3. Reset Password
```
POST http://localhost:8000/api/v1/auth/otp/reset-password
Body: {
  "email": "test@example.com",
  "otp": "123456",
  "new_password": "NewPass123"
}

Response (Success):
{
  "success": true,
  "message": "Password reset successful. Please login with your new password."
}
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    role ENUM('customer', 'serviceProvider', 'admin') DEFAULT 'customer',
    phone_number VARCHAR(20),
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSON,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);
```

### OTP Verifications Table
```sql
CREATE TABLE otp_verifications (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    purpose ENUM('email_verification', 'password_reset') NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    attempts INT DEFAULT 0,
    verified_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Security Features

1. **OTP Expiry:** 10 minutes
2. **Max Attempts:** 5 attempts per OTP
3. **Rate Limiting:** 10 requests per minute per user
4. **Single Use:** OTP is marked as used after successful verification
5. **Password Strength:** Enforced on frontend and backend
6. **Firebase Admin SDK:** Secure password updates using server-side SDK

## Common Issues

### Issue: "No account found with this email"
**Cause:** User doesn't exist in Firebase
**Solution:** User needs to register first

### Issue: OTP not received
**Cause:** Email service not configured (development mode)
**Solution:** Check Laravel logs for OTP: `docker exec gharsewa_app tail -f storage/logs/laravel.log`

### Issue: "Invalid or expired OTP"
**Cause:** OTP expired (10 minutes) or wrong code
**Solution:** Click "Resend" to get a new OTP

### Issue: Password reset fails after OTP verification
**Cause:** Firebase Admin SDK not configured
**Solution:** Ensure `firebase-credentials.json` exists in `backend/storage/app/`

## Notes

- Users are stored in BOTH Firebase (authentication) and Laravel (application data)
- Firebase is the source of truth for authentication
- Laravel database stores user profile and application data
- Password reset updates Firebase password using Admin SDK
- OTP codes are logged in development for testing
