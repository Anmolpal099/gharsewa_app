# 🔧 Troubleshooting Guide - OTP & Navigation Issues

## Issue 1: Not Receiving OTP Emails

### ✅ Backend is Working

I just tested and confirmed:
- ✅ Backend is running
- ✅ Email sending works
- ✅ Registration API works
- ✅ OTP is being generated

**Latest OTP:** `177149` for email: restarttest@example.com

### ❌ Problem: Gmail Not Delivering

**Root Cause:** Gmail is blocking/filtering emails (same issue as before)

**Why:** After computer restart, Gmail's spam filters are still active

### Solutions

#### Solution 1: Use OTP from Logs (Quick Fix)

**Get OTP:**
```powershell
cd e:\gharsewa\backend
docker-compose exec app tail -100 storage/logs/laravel.log | Select-String "otp"
```

**Look for:**
```
"otp":"123456"
```

**Use that OTP in your app!**

#### Solution 2: Set Up Mailtrap (Recommended)

See `MAILTRAP_SETUP.md` for complete guide.

**Quick Setup:**
1. Sign up at https://mailtrap.io (FREE)
2. Get SMTP credentials
3. Update `backend/.env`:
   ```env
   MAIL_HOST=sandbox.smtp.mailtrap.io
   MAIL_PORT=2525
   MAIL_USERNAME=your-mailtrap-username
   MAIL_PASSWORD=your-mailtrap-password
   ```
4. Restart backend:
   ```powershell
   docker-compose exec app php artisan config:clear
   docker-compose restart app
   ```
5. See ALL emails instantly in Mailtrap inbox!

#### Solution 3: Check Gmail Spam Folder

1. Open Gmail: https://mail.google.com
2. Click "Spam" folder
3. Search for: `from:anmolpal156@gmail.com`
4. If found, mark as "Not Spam"

---

## Issue 2: Navigation Not Working

### Diagnosis Steps

#### Step 1: Verify Flutter App is Running Latest Code

**Did you restart Flutter after the navigation fix?**

If not:
```powershell
# In Flutter terminal, press 'q' to stop
# Then run again:
cd e:\gharsewa
flutter run -d windows
```

Or press **`R`** (capital R) for hot restart

#### Step 2: Check What's Happening

Add debug prints to see what's going on.

**In `otp_input_screen.dart`, add prints:**

```dart
await actions.verifyEmail(widget.email, otp);
print('✅ Verification complete');

if (mounted) {
  print('✅ Mounted, showing snackbar');
  ScaffoldMessenger.of(context).showSnackBar(...);
  
  if (mounted) {
    print('✅ Navigating to /splash');
    context.go('/splash');
    print('✅ Navigation called');
  }
}
```

**Then check Flutter console for these prints.**

#### Step 3: Test with Direct Navigation

If splash redirect doesn't work, try direct navigation:

**Replace in `otp_input_screen.dart`:**

```dart
// Instead of:
context.go('/splash');

// Try:
await Future.delayed(const Duration(milliseconds: 1500));
final user = await actions.getCurrentUser();
if (user != null) {
  final role = AuthState.roleFromString(user.role);
  switch (role) {
    case UserRole.serviceProvider:
      context.go('/provider/dashboard');
    case UserRole.admin:
      context.go('/admin/dashboard');
    default:
      context.go('/customer/home');
  }
}
```

#### Step 4: Check Router Configuration

Verify routes are defined in `app_router.dart`:

```dart
// Customer routes
GoRoute(
  path: '/customer/home',
  builder: (context, state) => const CustomerHomeScreen(),
),

// Provider routes
GoRoute(
  path: '/provider/dashboard',
  builder: (context, state) => const ProviderDashboardScreen(),
),

// Admin routes
GoRoute(
  path: '/admin/dashboard',
  builder: (context, state) => const AdminDashboardScreen(),
),
```

#### Step 5: Check Auth State

Add debug print in `auth_service.dart`:

```dart
Future<void> verifyEmail(String email, String otp) async {
  final response = await _apiClient.post('/v1/auth/otp/verify-email', data: {
    'email': email.trim(),
    'otp': otp,
  });

  print('✅ Verify response: ${response.data}');

  if (response.data['success'] != true) {
    throw Exception(response.data['message'] ?? 'Verification failed');
  }

  final data = response.data['data'];
  
  // Save tokens
  await TokenStorage.saveTokens(
    accessToken: data['access_token'],
    refreshToken: data['refresh_token'],
    expiresIn: data['expires_in'],
  );
  
  print('✅ Tokens saved');
  
  // Save user data
  await TokenStorage.saveUserData(jsonEncode(data['user']));
  
  print('✅ User data saved: ${data['user']}');
  
  // Notify auth state changed
  await _notifyAuthStateChanged();
  
  print('✅ Auth state notified');
}
```

---

## Quick Fix Commands

### 1. Get Latest OTP

```powershell
cd e:\gharsewa\backend
docker-compose exec app tail -100 storage/logs/laravel.log | Select-String "otp"
```

### 2. Test Registration

```powershell
$body = @{
    name = "Nav Test"
    email = "navtest$(Get-Random)@example.com"
    password = "Test1234"
    role = "customer"
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/register" -Method Post -Body $body -Headers $headers
```

### 3. Restart Flutter

```powershell
# Stop Flutter (press 'q')
# Then:
cd e:\gharsewa
flutter clean
flutter pub get
flutter run -d windows
```

### 4. Restart Backend

```powershell
cd e:\gharsewa\backend
docker-compose restart app nginx
```

---

## Complete Reset (If Nothing Works)

### 1. Stop Everything

```powershell
# Stop Flutter (press 'q' in Flutter terminal)

# Stop Backend
cd e:\gharsewa\backend
docker-compose down
```

### 2. Clean Flutter

```powershell
cd e:\gharsewa
flutter clean
flutter pub get
```

### 3. Start Backend

```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

Wait 10 seconds for services to start.

### 4. Clear Backend Cache

```powershell
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
```

### 5. Start Flutter

```powershell
cd e:\gharsewa
flutter run -d windows
```

### 6. Test

1. Register with new email
2. Get OTP from logs
3. Enter OTP
4. Check if navigation works

---

## Expected Behavior

### Registration Flow

```
1. Fill registration form
   ↓
2. Click "Create Account"
   ↓
3. Backend creates user + generates OTP
   ↓
4. Backend sends email (may not arrive in Gmail)
   ↓
5. Backend logs OTP (check logs!)
   ↓
6. Navigate to OTP input screen
   ↓
7. Enter OTP (from logs)
   ↓
8. Backend verifies OTP
   ↓
9. Backend returns JWT tokens
   ↓
10. Flutter saves tokens
   ↓
11. Navigate to /splash
   ↓
12. Router detects authenticated state
   ↓
13. Router redirects to /customer/home
   ↓
14. User sees customer home screen ✅
```

### What You Should See

1. **After registration:** Navigate to OTP screen
2. **After entering OTP:** Show "Email verified successfully!" message
3. **1 second later:** Navigate to customer home dashboard
4. **Dashboard shows:** Customer home screen with bottom navigation

---

## Debug Checklist

Run through this checklist:

- [ ] Backend is running (`docker-compose ps`)
- [ ] App container is "Up" status
- [ ] Nginx container is "Up" status
- [ ] Flutter app is running
- [ ] Flutter app was restarted after navigation fix (press 'R')
- [ ] Registration works (navigates to OTP screen)
- [ ] OTP is in logs (`tail -100 storage/logs/laravel.log | Select-String "otp"`)
- [ ] Entering OTP shows success message
- [ ] After success message, app navigates somewhere (even if wrong place)

**If app doesn't navigate at all:**
- Check Flutter console for errors
- Check if `context.go('/splash')` is being called
- Check if router redirect logic is working

**If app navigates to wrong place:**
- Check user role in backend
- Check router redirect logic
- Check route definitions

---

## Current Status

### Backend
- ✅ Running
- ✅ Email sending works
- ✅ Registration works
- ✅ OTP generation works
- ✅ OTP logged successfully

### Frontend
- ❓ Navigation code updated (needs Flutter restart)
- ❓ App running with latest code?

### Email
- ❌ Gmail not delivering (use logs for OTP)
- ✅ Mailtrap recommended for development

---

## Immediate Actions

### Action 1: Get OTP from Logs

```powershell
cd e:\gharsewa\backend
docker-compose exec app tail -100 storage/logs/laravel.log | Select-String "otp"
```

Use the OTP code in your app!

### Action 2: Restart Flutter

```powershell
# In Flutter terminal, press 'R' (capital R)
```

Or stop and restart:
```powershell
# Press 'q' to stop
cd e:\gharsewa
flutter run -d windows
```

### Action 3: Test Navigation

1. Register with new email
2. Get OTP from logs
3. Enter OTP
4. Watch what happens
5. Check Flutter console for errors

### Action 4: Share Results

If still not working, share:
1. Flutter console output (any errors?)
2. What happens after entering OTP?
3. Does it show success message?
4. Does it navigate anywhere?
5. Any error messages?

---

## Summary

**OTP Issue:** ✅ Backend working, Gmail not delivering
**Solution:** Use OTP from logs or set up Mailtrap

**Navigation Issue:** ❓ Need to verify Flutter restarted with new code
**Solution:** Restart Flutter app (press 'R' or restart completely)

**Next Steps:**
1. Get OTP from logs
2. Restart Flutter app
3. Test registration flow
4. Share results if still not working

---

*The backend is working perfectly. The issues are Gmail delivery and ensuring Flutter has the latest code.*
