# WebSocket Authentication Middleware

## Overview

The `WebSocketAuthMiddleware` provides JWT-based authentication for WebSocket connections in the Gharsewa platform. This middleware ensures that only authenticated users can establish WebSocket connections.

## Implementation Details

### File Location
- **Middleware**: `app/Http/Middleware/WebSocketAuthMiddleware.php`
- **Registration**: `bootstrap/app.php` (alias: `ws.auth`)

### Features

1. **Token Extraction**
   - Supports token from query parameter: `?token=YOUR_JWT_TOKEN`
   - Supports token from Authorization header: `Authorization: Bearer YOUR_JWT_TOKEN`
   - Query parameter is checked first, then Authorization header

2. **JWT Validation**
   - Uses the same JWTAuth facade as REST API endpoints
   - Validates token signature using the application's JWT secret
   - Extracts user identity from the 'sub' claim in the JWT payload

3. **User Verification**
   - Verifies user exists in the database
   - Checks if user account is active (`is_active` flag)
   - Sets authenticated user in Laravel's Auth facade

4. **Error Handling**
   - **Missing Token**: Returns 401 with error code `token_absent`
   - **Expired Token**: Returns 401 with error code `token_expired`
   - **Invalid Token**: Returns 401 with error code `token_invalid`
   - **User Not Found**: Returns 401 with error code `user_not_found`
   - **Inactive User**: Returns 401 with error code `user_inactive`
   - **General JWT Error**: Returns 401 with error code `token_error`

## Usage

### In Channel Authorization (routes/channels.php)

```php
use Illuminate\Support\Facades\Broadcast;

// Apply middleware to broadcast routes
Broadcast::routes(['middleware' => ['ws.auth']]);

// Define channel authorization
Broadcast::channel('user.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});
```

### Client Connection Examples

#### Using Query Parameter
```javascript
const wsUrl = 'ws://localhost:6001/app/YOUR_APP_KEY?token=YOUR_JWT_TOKEN';
const socket = new WebSocket(wsUrl);
```

#### Using Authorization Header
```javascript
const wsUrl = 'ws://localhost:6001/app/YOUR_APP_KEY';
const socket = new WebSocket(wsUrl, {
    headers: {
        'Authorization': 'Bearer YOUR_JWT_TOKEN'
    }
});
```

## Error Response Format

All authentication errors return a JSON response with the following structure:

```json
{
    "success": false,
    "message": "Human-readable error message",
    "error": "error_code"
}
```

### Error Codes

| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `token_absent` | No JWT token provided | 401 |
| `token_expired` | JWT token has expired | 401 |
| `token_invalid` | JWT token is invalid or malformed | 401 |
| `user_not_found` | User ID from token not found in database | 401 |
| `user_inactive` | User account is inactive | 401 |
| `token_error` | General JWT authentication error | 401 |

## Requirements Satisfied

This middleware implementation satisfies the following requirements from the spec:

- **Requirement 2.1**: WebSocket connections require a valid JWT token
- **Requirement 2.2**: Invalid JWT tokens are rejected with authentication error
- **Requirement 2.3**: Expired JWT tokens close the connection
- **Requirement 2.4**: JWT signature validation uses the same secret as REST API
- **Requirement 2.5**: User identity is extracted from JWT payload for channel authorization

## Testing

To test the middleware, you can:

1. **Valid Token Test**: Connect with a valid JWT token and verify connection succeeds
2. **Missing Token Test**: Connect without a token and verify 401 response
3. **Expired Token Test**: Connect with an expired token and verify 401 response with `token_expired` error
4. **Invalid Token Test**: Connect with a malformed token and verify 401 response with `token_invalid` error
5. **Inactive User Test**: Connect with a token for an inactive user and verify 401 response with `user_inactive` error

## Next Steps

After implementing this middleware, the next tasks are:

1. **Task 2.1**: Configure channel authorization in `routes/channels.php`
2. **Task 2.3**: Create `BookingStatusChanged` event class
3. **Task 2.4**: Create `NotificationCreated` event class

The middleware is now ready to be used for authenticating WebSocket connections in the Reverb server.
