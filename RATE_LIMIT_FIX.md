# Rate Limit Fix for Authentication

## Problem
API rate limit exceeded when trying to authenticate as a service provider. The error occurred because the login endpoint had a strict rate limit of **5 attempts per 15 minutes**.

## Root Cause
The `JwtAuthController` had hardcoded rate limiting:
- **Max attempts**: 5
- **Lockout duration**: 15 minutes (900 seconds)
- **Key**: Based on IP address (`login:{ip}`)

After 5 failed login attempts (or even successful attempts during testing), the IP was blocked for 15 minutes.

## Solution Applied

### 1. Cleared Rate Limiter Cache
Ran `php artisan cache:clear` to immediately reset all rate limiters.

### 2. Made Rate Limits Configurable
Updated `JwtAuthController.php` to use environment variables:

```php
$maxAttempts = env('LOGIN_MAX_ATTEMPTS', 100); // Default 100 for development
$decayMinutes = env('LOGIN_DECAY_MINUTES', 1); // Default 1 minute
```

### 3. Added Environment Variables
Added to `.env` file:
```env
# Login Rate Limiting
LOGIN_MAX_ATTEMPTS=100
LOGIN_DECAY_MINUTES=1
```

### 4. Restarted Backend
Restarted Laravel Sail to apply changes.

## New Rate Limit Settings

### Development (Current)
- **Max attempts**: 100 per minute
- **Lockout duration**: 1 minute
- **Purpose**: Allow extensive testing without hitting limits

### Production (Recommended)
Update `.env` for production:
```env
LOGIN_MAX_ATTEMPTS=10
LOGIN_DECAY_MINUTES=15
```

## How It Works

### Rate Limiting Flow:
1. User attempts to login
2. System checks: `login:{ip_address}` key in cache
3. If attempts < `LOGIN_MAX_ATTEMPTS`: Allow login
4. If attempts ≥ `LOGIN_MAX_ATTEMPTS`: Block for `LOGIN_DECAY_MINUTES`
5. On failed login: Increment counter
6. On successful login: Clear counter

### Key Format:
```
login:127.0.0.1
login:192.168.1.100
```

## Testing

You can now:
✅ Login multiple times without being blocked
✅ Test authentication flows extensively
✅ Switch between customer and provider accounts freely
✅ Retry failed logins without waiting 15 minutes

## Manual Rate Limiter Reset

If you ever hit the rate limit again, run:

```bash
# Clear all cache (including rate limiter)
./vendor/bin/sail artisan cache:clear

# Or clear specific rate limiter key
./vendor/bin/sail artisan tinker
>>> Illuminate\Support\Facades\RateLimiter::clear('login:127.0.0.1');
```

## Configuration Options

### Disable Rate Limiting Completely (Not Recommended)
Set very high values:
```env
LOGIN_MAX_ATTEMPTS=999999
LOGIN_DECAY_MINUTES=1
```

### Strict Rate Limiting (Production)
```env
LOGIN_MAX_ATTEMPTS=5
LOGIN_DECAY_MINUTES=30
```

### Moderate Rate Limiting (Staging)
```env
LOGIN_MAX_ATTEMPTS=20
LOGIN_DECAY_MINUTES=5
```

## Files Modified
1. `backend/app/Http/Controllers/API/V1/Auth/JwtAuthController.php`
2. `backend/.env`

## Security Considerations

### Development
- High limits are acceptable for local development
- No security risk as it's not exposed to internet

### Production
- **Must use strict limits** to prevent brute force attacks
- Recommended: 5-10 attempts per 15-30 minutes
- Consider implementing:
  - CAPTCHA after 3 failed attempts
  - Account lockout after 10 failed attempts
  - Email notifications for suspicious activity
  - IP-based blocking for repeated offenders

## Additional Rate Limiters in the System

### AI Consultations
- **Endpoint**: `/api/v1/customer/ai/consultations`
- **Limit**: 10 requests per minute
- **Location**: `routes/api.php` (line 102)

### AI Recommendations
- **Endpoint**: `/api/v1/recommendations`
- **Limit**: 10 requests per minute
- **Location**: `app/Http/Controllers/API/V1/Ai/RecommendationController.php`

### General API
- **Middleware**: `ApiRateLimitMiddleware`
- **Default**: 60 requests per minute
- **Location**: `app/Http/Middleware/ApiRateLimitMiddleware.php`

## Monitoring Rate Limits

### Check Current Attempts
```php
use Illuminate\Support\Facades\RateLimiter;

$key = 'login:127.0.0.1';
$attempts = RateLimiter::attempts($key);
$remaining = RateLimiter::remaining($key, 100);
$availableIn = RateLimiter::availableIn($key); // seconds until reset
```

### Response Headers
Rate limit info is included in response headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
```

## Troubleshooting

### Still Getting Rate Limited?
1. Clear cache: `./vendor/bin/sail artisan cache:clear`
2. Restart backend: `./vendor/bin/sail restart`
3. Check `.env` file has the new variables
4. Verify you're using the correct IP address

### Rate Limiter Not Working?
1. Check cache driver in `.env`: `CACHE_DRIVER=redis` or `file`
2. Ensure Redis is running (if using Redis)
3. Check Laravel logs: `backend/storage/logs/laravel.log`

### Different IP Address?
If using Docker/Sail, your IP might be different:
```bash
# Check your IP
curl ifconfig.me

# Or check in Laravel
./vendor/bin/sail artisan tinker
>>> request()->ip();
```

## Best Practices

### Development
- Use high limits (100+ attempts)
- Short decay time (1-5 minutes)
- Clear cache frequently

### Staging
- Use moderate limits (20-50 attempts)
- Medium decay time (5-10 minutes)
- Monitor for issues

### Production
- Use strict limits (5-10 attempts)
- Long decay time (15-30 minutes)
- Implement additional security measures
- Monitor and alert on suspicious activity
- Consider per-user rate limiting (not just IP)

## Future Improvements

1. **Per-User Rate Limiting**: Track by user ID instead of IP
2. **Progressive Delays**: Increase delay after each failed attempt
3. **CAPTCHA Integration**: Require CAPTCHA after N failed attempts
4. **Account Lockout**: Temporarily lock account after too many failures
5. **Notification System**: Alert users of suspicious login attempts
6. **Whitelist IPs**: Allow unlimited attempts from trusted IPs
7. **Blacklist IPs**: Permanently block known attackers
