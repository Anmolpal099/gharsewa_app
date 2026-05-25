# Registration OTP Flow Fix

## Issue
After filling credentials in the registration section, the app was navigating directly to the dashboard instead of showing the OTP verification screen.

## Root Cause
The problem was caused by an auth state listener in `login_screen.dart` that automatically navigated users to the dashboard whenever they became authenticated. During registration:

1. User fills registration form
2. Firebase creates account (user becomes authenticated)
3. Auth state changes to authenticated
4. The `ref.listen` callback fires and navigates to dashboard
5. This happened BEFORE the manual navigation to OTP screen could complete

## Solution

### 1. Fixed Login Screen Auto-Navigation (login_screen.dart)
**File:** `lib/presentation/shared/screens/login_screen.dart`

**Change:** Modified the auth state listener to NOT auto-navigate during registration mode:

```dart
// OLD CODE:
ref.listen(authServiceProvider, (_, next) {
  next.whenData((auth) {
    if (auth.isAuthenticated) _navigateByRole(auth.role);
  });
});

// NEW CODE:
ref.listen(authServiceProvider, (_, next) {
  next.whenData((auth) {
    // Only auto-navigate if authenticated AND not in registration mode
    if (auth.isAuthenticated && !_isRegisterMode && !_isLoading) {
      _navigateByRole(auth.role);
    }
  });
});
```

**Why:** This prevents the auto-navigation from interfering with the manual OTP flow navigation during registration.

### 2. Fixed OTP Screen Post-Verification Navigation (otp_input_screen.dart)
**File:** `lib/presentation/shared/screens/otp_input_screen.dart`

**Change:** After successful email verification, navigate to dashboard instead of login:

```dart
// OLD CODE:
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Email verified successfully! Please login.'),
    backgroundColor: Colors.green,
  ),
);
await Future.delayed(const Duration(seconds: 1));
if (mounted) {
  context.go('/login');
}

// NEW CODE:
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Email verified successfully!'),
    backgroundColor: Colors.green,
  ),
);
await Future.delayed(const Duration(seconds: 1));
if (mounted) {
  context.go('/customer/home');
}
```

**Why:** The user is already authenticated after registration, so they should go directly to the dashboard after verifying their email, not back to the login screen.

## Registration Flow (After Fix)

1. **User fills registration form** → Enters name, email, password
2. **Clicks "Create Account"** → Firebase creates account, user is authenticated
3. **Navigates to OTP screen** → Shows 6-digit OTP input (no auto-redirect interference)
4. **User enters OTP** → Backend verifies the OTP
5. **Verification success** → Navigates to customer dashboard
6. **User is logged in** → Can use the app normally

## Testing

To test the fix:

1. Open the app
2. Click "Don't have an account? Register"
3. Fill in name, email, and password
4. Click "Create Account"
5. **Expected:** OTP input screen appears
6. Enter the 6-digit OTP (check Laravel logs: `docker exec gharsewa_app tail -f storage/logs/laravel.log`)
7. **Expected:** Success message and navigation to customer dashboard

## Files Modified

1. `lib/presentation/shared/screens/login_screen.dart`
   - Modified auth state listener to skip auto-navigation during registration

2. `lib/presentation/shared/screens/otp_input_screen.dart`
   - Changed post-verification navigation from `/login` to `/customer/home`

3. `lib/presentation/router/app_router.dart`
   - No changes needed (router already allows authenticated users on auth routes)

## Related Files

- `lib/services/auth/auth_service.dart` - Handles registration and OTP sending
- `backend/app/Http/Controllers/API/V1/Auth/OtpController.php` - Backend OTP logic
- `lib/core/constants/route_constants.dart` - Route definitions

## Notes

- The router's redirect logic already allows authenticated users to access OTP routes
- Firebase creates the account immediately, so the user is authenticated during OTP verification
- The backend stores the email verification status separately from Firebase
- OTP codes expire after 10 minutes and have a 60-second resend cooldown
