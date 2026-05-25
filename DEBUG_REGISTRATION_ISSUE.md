# Debug Registration Issue

## Problem
Registration shows "Something went wrong. Please try again" instead of navigating to OTP screen.

## Changes Made

### 1. Improved Error Handling
**File:** `lib/presentation/shared/screens/login_screen.dart`
- Changed from catching only `Exception` to catching all errors
- Now shows the actual error message instead of generic "Something went wrong"
- Increased error message duration to 5 seconds

### 2. Better Error Propagation
**File:** `lib/services/auth/auth_service.dart`
- Added try-catch in register method
- Re-throws errors with better context

### 3. Fixed CORS Configuration
**File:** `backend/config/cors.php`
- Added `http://localhost` (without port)
- Added `http://127.0.0.1`
- Added patterns to match localhost with any port

## How to Debug

### Step 1: Check Backend Server
Make sure Laravel backend is running:
```bash
cd e:\gharsewa\backend
php artisan serve
```

You should see:
```
Starting Laravel development server: http://127.0.0.1:8000
```

### Step 2: Check Laravel Logs
Open a new terminal and tail the Laravel logs:
```bash
cd e:\gharsewa\backend
tail -f storage/logs/laravel.log
```

Or on Windows:
```powershell
Get-Content e:\gharsewa\backend\storage\logs\laravel.log -Wait -Tail 50
```

### Step 3: Test Registration Again
1. Run the Flutter app
2. Try to register with:
   - Name: Test User
   - Email: test@example.com
   - Password: Test1234 (must have uppercase, lowercase, and digit)

3. Watch for the error message - it should now show the actual error instead of generic message

### Step 4: Check Browser Console (if using Flutter Web)
If running on web:
1. Open browser DevTools (F12)
2. Go to Console tab
3. Try registration again
4. Look for any CORS errors or network errors

### Step 5: Test Backend Directly
Use curl or Postman to test the endpoint directly:

```bash
curl -X POST http://localhost:8000/api/v1/auth/jwt/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Test1234",
    "role": "customer"
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "User registered successfully. Please check your email for the verification code.",
  "data": {
    "user_id": 1,
    "email": "test@example.com",
    "name": "Test User",
    "role": "customer",
    "otp_sent": true,
    "otp_expires_in": 600
  }
}
```

## Common Issues

### Issue 1: Backend Not Running
**Symptom:** Connection refused error
**Solution:** Start Laravel server with `php artisan serve`

### Issue 2: CORS Error
**Symptom:** "Access to XMLHttpRequest has been blocked by CORS policy"
**Solution:** 
- Backend CORS config updated (already done)
- Restart Laravel server after config change

### Issue 3: Database Connection Error
**Symptom:** "SQLSTATE[HY000] [2002] Connection refused"
**Solution:** 
- Check if MySQL/PostgreSQL is running
- Verify `.env` database credentials

### Issue 4: Validation Error
**Symptom:** 422 Unprocessable Entity
**Solution:** Check password requirements:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit

### Issue 5: Email Already Exists
**Symptom:** "Email already registered"
**Solution:** Use a different email or delete the existing user from database

## Next Steps After Fixing

Once registration works:
1. ✅ User should be redirected to OTP input screen
2. ✅ Check Gmail inbox for OTP email
3. ✅ Enter OTP to verify email
4. ✅ User should be logged in and redirected to dashboard

## Files Modified

1. `lib/presentation/shared/screens/login_screen.dart` - Better error handling
2. `lib/services/auth/auth_service.dart` - Better error propagation
3. `backend/config/cors.php` - Fixed CORS for localhost

## Test the Fix

After making these changes:
1. Hot restart the Flutter app (press 'R' in terminal or click restart button)
2. Try registration again
3. You should now see the actual error message if something fails
4. Check Laravel logs for backend errors

---

*If you still see errors, please share:*
1. The exact error message shown in the app
2. Laravel log output
3. Browser console errors (if using web)
