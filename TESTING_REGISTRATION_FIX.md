# Testing Guide: Registration OTP Flow Fix

## Prerequisites

1. **Backend running:**
   ```bash
   cd backend
   docker-compose up -d
   ```

2. **Check backend logs in a separate terminal:**
   ```bash
   docker exec gharsewa_app tail -f storage/logs/laravel.log
   ```

3. **Flutter app running:**
   ```bash
   flutter run
   ```

## Test Case 1: New User Registration with OTP

### Steps:
1. Launch the app
2. On the login screen, click **"Don't have an account? Register"**
3. Fill in the registration form:
   - **Name:** Test User
   - **Email:** test@example.com (or any valid email)
   - **Password:** password123 (at least 8 characters)
4. Click **"Create Account"**

### Expected Results:
- ✅ Loading indicator appears briefly
- ✅ App navigates to **OTP Input Screen** (NOT dashboard)
- ✅ OTP screen shows:
  - "Enter OTP" title
  - "We sent a 6-digit code to test@example.com"
  - 6 input boxes for OTP digits
  - Countdown timer (10:00 minutes)
  - Resend button (disabled for 60 seconds)

### Backend Verification:
Check the Laravel logs terminal - you should see:
```
OTP Email - To: test@example.com, OTP: 123456, Purpose: Email Verification
```

5. Enter the 6-digit OTP from the logs
6. Click **"Verify OTP"** (or it auto-verifies after entering 6th digit)

### Expected Results:
- ✅ Success message: "Email verified successfully!"
- ✅ App navigates to **Customer Dashboard** (NOT login screen)
- ✅ User is logged in and can use the app

## Test Case 2: OTP Resend

### Steps:
1. Follow Test Case 1 steps 1-4 to reach OTP screen
2. Wait 60 seconds for resend button to enable
3. Click **"Resend"**

### Expected Results:
- ✅ Success message: "OTP sent successfully!"
- ✅ New OTP appears in Laravel logs
- ✅ Timer resets to 10:00
- ✅ Resend button disabled again for 60 seconds
- ✅ Previous OTP input cleared

## Test Case 3: Invalid OTP

### Steps:
1. Follow Test Case 1 steps 1-4 to reach OTP screen
2. Enter an incorrect 6-digit code (e.g., 000000)
3. Click **"Verify OTP"**

### Expected Results:
- ✅ Error message: "Invalid OTP. Please try again."
- ✅ User remains on OTP screen
- ✅ Can try again with correct OTP

## Test Case 4: Expired OTP

### Steps:
1. Follow Test Case 1 steps 1-4 to reach OTP screen
2. Wait 10 minutes (or modify the expiry time in code for faster testing)

### Expected Results:
- ✅ Timer counts down to 00:00
- ✅ Error message: "OTP has expired. Please request a new one."
- ✅ User must click "Resend" to get a new OTP

## Test Case 5: Existing User Login (No OTP)

### Steps:
1. On the login screen, enter credentials for an existing user
2. Click **"Sign In"**

### Expected Results:
- ✅ User logs in successfully
- ✅ Navigates directly to dashboard (based on role)
- ✅ NO OTP screen shown (OTP is only for registration and password reset)

## Test Case 6: Back Button During OTP

### Steps:
1. Follow Test Case 1 steps 1-4 to reach OTP screen
2. Press the back button (or click back arrow in app bar)

### Expected Results:
- ✅ Returns to login/registration screen
- ✅ User account is created in Firebase but not verified
- ✅ User can login later and verify email separately (if needed)

## Common Issues and Solutions

### Issue: OTP not appearing in logs
**Solution:** 
- Check if backend is running: `docker ps`
- Check if Laravel app container is healthy: `docker logs gharsewa_app`
- Verify API endpoint is accessible: `curl http://localhost:8000/api/v1/auth/otp/send-email-verification -X POST -H "Content-Type: application/json" -d '{"email":"test@example.com"}'`

### Issue: App navigates to dashboard instead of OTP screen
**Solution:**
- This was the bug we just fixed!
- Make sure you have the latest code changes
- Restart the Flutter app: `flutter run`

### Issue: "Invalid OTP" even with correct code
**Solution:**
- Check if OTP has expired (10-minute limit)
- Verify the email matches exactly (case-sensitive)
- Check backend logs for any errors

### Issue: Network error when verifying OTP
**Solution:**
- Ensure backend is running and accessible
- Check if API client base URL is correct in Flutter app
- Verify CORS is configured in Laravel backend

## API Endpoints Used

1. **Send Email Verification OTP:**
   - POST `http://localhost:8000/api/v1/auth/otp/send-email-verification`
   - Body: `{"email": "test@example.com"}`

2. **Verify Email OTP:**
   - POST `http://localhost:8000/api/v1/auth/otp/verify-email`
   - Body: `{"email": "test@example.com", "otp": "123456"}`

3. **Register User:**
   - POST `http://localhost:8000/api/v1/auth/register`
   - Body: `{"id_token": "...", "name": "Test User", "role": "customer"}`

## Success Criteria

All test cases should pass with expected results. The registration flow should be:
1. Fill form → 2. OTP screen → 3. Verify → 4. Dashboard

No automatic redirects should interrupt the OTP verification flow.
