# Testing Guide: Forgot Password Flow

## Prerequisites

1. **Backend running:**
   ```bash
   cd backend
   docker-compose up -d
   ```

2. **Check backend logs:**
   ```bash
   docker exec gharsewa_app tail -f storage/logs/laravel.log
   ```

3. **Flutter app running:**
   ```bash
   flutter run
   ```

## Complete Test Flow

### Step 1: Register a Test User (if not already registered)

1. Open the app
2. Click **"Don't have an account? Register"**
3. Fill in:
   - Name: Test User
   - Email: testuser@example.com
   - Password: OldPass123
4. Click **"Create Account"**
5. Enter OTP from logs
6. Verify email
7. You should be logged in to dashboard

### Step 2: Logout

1. Navigate to Profile
2. Click Logout (or restart the app)

### Step 3: Start Forgot Password Flow

1. On login screen, click **"Forgot Password?"**
2. You should see the "Reset Your Password" screen

### Step 4: Enter Email

1. Enter: **testuser@example.com**
2. Click **"Send OTP"**

**Expected Results:**
- ✅ Loading indicator appears
- ✅ Success message: "OTP sent to your email"
- ✅ Navigates to OTP Input Screen
- ✅ Screen shows: "We sent a 6-digit code to testuser@example.com"

**Backend Verification:**
Check the Laravel logs terminal - you should see:
```
OTP Email - To: testuser@example.com, OTP: 123456, Purpose: Password Reset
```

### Step 5: Enter OTP

1. Enter the 6-digit OTP from the logs
2. Click **"Verify OTP"** (or it auto-verifies after 6th digit)

**Expected Results:**
- ✅ Loading indicator appears
- ✅ Success message: "OTP verified successfully"
- ✅ Navigates to New Password Screen
- ✅ Screen shows: "Create New Password"

### Step 6: Create New Password

1. Enter new password: **NewPass123**
   - Should show password strength indicator
   - Should turn green (Strong)
2. Re-enter password: **NewPass123**
3. Click **"Reset Password"**

**Expected Results:**
- ✅ Loading indicator appears
- ✅ Success message: "Password reset successful! Please login with your new password."
- ✅ Navigates to Login Screen

### Step 7: Login with New Password

1. Enter email: **testuser@example.com**
2. Enter password: **NewPass123** (the new password)
3. Click **"Sign In"**

**Expected Results:**
- ✅ Login successful
- ✅ Navigates to Customer Dashboard
- ✅ User is logged in

### Step 8: Verify Old Password Doesn't Work

1. Logout
2. Try to login with old password: **OldPass123**

**Expected Results:**
- ✅ Error message: "Incorrect password"
- ✅ User remains on login screen

## Edge Case Tests

### Test 1: Non-Existent Email

**Steps:**
1. Click "Forgot Password?"
2. Enter: **nonexistent@example.com**
3. Click "Send OTP"

**Expected:**
- ✅ Error message: "No account found with this email"
- ✅ User remains on forgot password screen

### Test 2: Invalid OTP

**Steps:**
1. Complete steps 1-4 from main flow
2. Enter wrong OTP: **000000**
3. Click "Verify OTP"

**Expected:**
- ✅ Error message: "Invalid or expired OTP"
- ✅ User remains on OTP screen
- ✅ Can try again with correct OTP

### Test 3: Expired OTP

**Steps:**
1. Complete steps 1-4 from main flow
2. Wait 10 minutes (or modify expiry time in code for faster testing)

**Expected:**
- ✅ Timer shows 00:00
- ✅ Error message: "OTP has expired. Please request a new one."
- ✅ Must click "Resend" to get new OTP

### Test 4: Password Mismatch

**Steps:**
1. Complete steps 1-5 from main flow
2. Enter password: **NewPass123**
3. Re-enter different password: **NewPass456**
4. Click "Reset Password"

**Expected:**
- ✅ Validation error: "Passwords do not match"
- ✅ Cannot submit form

### Test 5: Weak Password

**Steps:**
1. Complete steps 1-5 from main flow
2. Enter password: **weak** (too short, no uppercase, no numbers)

**Expected:**
- ✅ Validation errors shown:
  - "Password must be at least 8 characters"
  - "Password must contain at least one uppercase letter"
  - "Password must contain at least one number"
- ✅ Password strength shows "Weak" in red
- ✅ Cannot submit form

### Test 6: Resend OTP

**Steps:**
1. Complete steps 1-4 from main flow
2. Wait 60 seconds for resend button to enable
3. Click **"Resend"**

**Expected:**
- ✅ Success message: "OTP sent successfully!"
- ✅ New OTP appears in Laravel logs
- ✅ Timer resets to 10:00
- ✅ Resend button disabled again for 60 seconds
- ✅ Previous OTP input cleared

### Test 7: Back Button Navigation

**Steps:**
1. Complete steps 1-4 from main flow
2. Press back button (or click back arrow)

**Expected:**
- ✅ Returns to forgot password screen
- ✅ Can start flow again

## Password Strength Indicator Test

Test different passwords and verify strength indicator:

| Password | Expected Strength | Color |
|----------|------------------|-------|
| weak | Weak | Red |
| Weak123 | Medium | Orange |
| StrongPass123 | Strong | Green |
| StrongPass123! | Strong | Green |

## API Testing (Optional)

You can also test the API directly using curl or Postman:

### 1. Send OTP
```bash
curl -X POST http://localhost:8000/api/v1/auth/otp/send-password-reset \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com"}'
```

### 2. Verify OTP
```bash
curl -X POST http://localhost:8000/api/v1/auth/otp/verify-password-reset \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","otp":"123456"}'
```

### 3. Reset Password
```bash
curl -X POST http://localhost:8000/api/v1/auth/otp/reset-password \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","otp":"123456","new_password":"NewPass123"}'
```

## Troubleshooting

### Issue: "No account found with this email" for registered user

**Possible Causes:**
1. User not synced to Laravel database during registration
2. Email mismatch (case-sensitive)

**Solution:**
- Check if user exists in Firebase: Firebase Console → Authentication
- Check if user exists in Laravel: `docker exec gharsewa_db mysql -u root -proot gharsewa -e "SELECT * FROM users WHERE email='testuser@example.com';"`
- The fix now automatically syncs Firebase users to Laravel database

### Issue: OTP not appearing in logs

**Solution:**
- Ensure backend is running: `docker ps`
- Check container logs: `docker logs gharsewa_app`
- Verify log file exists: `docker exec gharsewa_app ls -la storage/logs/`

### Issue: "Failed to send OTP"

**Possible Causes:**
1. Database connection issue
2. OTP table doesn't exist

**Solution:**
- Run migrations: `docker exec gharsewa_app php artisan migrate`
- Check database: `docker exec gharsewa_db mysql -u root -proot gharsewa -e "SHOW TABLES;"`

### Issue: Password reset fails after OTP verification

**Possible Causes:**
1. Firebase Admin SDK not configured
2. firebase-credentials.json missing

**Solution:**
- Check if file exists: `docker exec gharsewa_app ls -la storage/app/firebase-credentials.json`
- Verify Firebase config in Laravel

## Success Criteria

✅ All main flow steps complete successfully
✅ All edge case tests pass
✅ User can login with new password
✅ Old password no longer works
✅ Password strength indicator works correctly
✅ OTP expiry and resend work as expected

## Notes

- OTP codes are valid for 10 minutes
- Resend button is disabled for 60 seconds after sending
- Maximum 5 attempts per OTP
- Password must meet all strength requirements
- Backend logs OTP codes in development mode
