# Registration API Documentation

## Overview

The Registration API allows new users to create accounts in the Gharsewa platform. Upon successful registration, users receive an OTP (One-Time Password) via email for email verification.

---

## Endpoint

**URL:** `POST /api/v1/auth/jwt/register`

**Authentication:** Not required (public endpoint)

**Rate Limit:** 10 requests per minute

---

## Request

### Headers

```http
Content-Type: application/json
Accept: application/json
```

### Body Parameters

| Parameter | Type | Required | Description | Validation Rules |
|-----------|------|----------|-------------|------------------|
| `name` | string | Yes | User's full name | Max 255 characters |
| `email` | string | Yes | User's email address | Valid email format, unique, max 255 characters |
| `password` | string | Yes | User's password | Min 8 characters, must contain uppercase, lowercase, and number |
| `role` | string | Yes | User's role | Must be either `customer` or `serviceProvider` |

### Example Request

```json
{
  "name": "John Doe",
  "email": "john.doe@example.com",
  "password": "Password123",
  "role": "customer"
}
```

---

## Response

### Success Response (200 OK)

```json
{
  "success": true,
  "message": "User registered successfully. Please check your email for the verification code.",
  "data": {
    "user_id": "9d4e8c2a-1234-5678-9abc-def012345678",
    "email": "john.doe@example.com",
    "name": "John Doe",
    "role": "customer",
    "otp_sent": true,
    "otp_expires_in": 600
  }
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Always `true` for successful requests |
| `message` | string | Success message |
| `data.user_id` | string (UUID) | Unique identifier for the created user |
| `data.email` | string | User's email address |
| `data.name` | string | User's full name |
| `data.role` | string | User's role (customer or serviceProvider) |
| `data.otp_sent` | boolean | Indicates if OTP email was sent |
| `data.otp_expires_in` | integer | OTP expiration time in seconds (600 = 10 minutes) |

---

### Error Responses

#### Validation Error (422 Unprocessable Entity)

**Scenario:** Invalid or missing required fields

```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "email": [
      "The email has already been taken."
    ],
    "password": [
      "The password must be at least 8 characters.",
      "The password format is invalid."
    ]
  }
}
```

**Common Validation Errors:**

| Field | Error Message | Cause |
|-------|---------------|-------|
| `name` | "The name field is required." | Missing name |
| `email` | "The email field is required." | Missing email |
| `email` | "The email must be a valid email address." | Invalid email format |
| `email` | "The email has already been taken." | Email already exists |
| `password` | "The password field is required." | Missing password |
| `password` | "The password must be at least 8 characters." | Password too short |
| `password` | "The password format is invalid." | Missing uppercase, lowercase, or number |
| `role` | "The role field is required." | Missing role |
| `role` | "The selected role is invalid." | Role not in [customer, serviceProvider] |

---

#### Server Error (500 Internal Server Error)

**Scenario:** Unexpected server error during registration

```json
{
  "success": false,
  "message": "Registration failed. Please try again.",
  "errors": null
}
```

---

## Password Requirements

Passwords must meet the following criteria:

- ✅ Minimum 8 characters
- ✅ At least one uppercase letter (A-Z)
- ✅ At least one lowercase letter (a-z)
- ✅ At least one number (0-9)

**Valid Examples:**
- `Password123`
- `SecurePass456`
- `MyP@ssw0rd`

**Invalid Examples:**
- `password` (no uppercase, no number)
- `PASSWORD123` (no lowercase)
- `PasswordOnly` (no number)
- `Pass1` (too short)

---

## User Roles

### Customer
- Can browse and book services
- Can view service providers
- Can manage bookings
- Can leave reviews

### Service Provider
- Can offer services
- Can manage service listings
- Can accept/reject bookings
- Can view earnings and analytics

**Note:** Admin role cannot be assigned during registration. Admin accounts must be created manually by existing administrators.

---

## Email Verification Flow

### 1. Registration
User submits registration form → Account created → OTP generated → Email sent

### 2. OTP Email
User receives email with:
- 6-digit OTP code
- 10-minute expiration notice
- Security warning

### 3. Verification
User enters OTP → Email verified → Account activated → JWT tokens issued

### 4. Resend OTP (if needed)
User can request new OTP → Previous OTP invalidated → New OTP sent

---

## OTP Details

| Property | Value |
|----------|-------|
| **Format** | 6-digit numeric code |
| **Expiration** | 10 minutes |
| **Max Attempts** | 5 verification attempts |
| **Resend Cooldown** | 60 seconds |
| **Type** | `email_verification` |

**Example OTP:** `123456`

---

## Email Template

Users receive a professionally designed HTML email with:

- **Header:** Gharsewa branding with gradient background
- **Greeting:** Personalized with user's name
- **OTP Code:** Large, prominent display with dashed border
- **Expiry Notice:** Clear indication of 10-minute expiration
- **Security Warning:** Notice about unauthorized requests
- **Footer:** Support contact, help center, privacy policy links

**Email Subject:** "Verify Your Email - Gharsewa"

**From Address:** `noreply@gharsewa.com`

---

## Testing

### Manual Testing with cURL

```bash
curl -X POST http://localhost:8000/api/v1/auth/jwt/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john.doe@example.com",
    "password": "Password123",
    "role": "customer"
  }'
```

### Manual Testing with PowerShell

```powershell
$body = @{
    name = "John Doe"
    email = "john.doe@example.com"
    password = "Password123"
    role = "customer"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/register" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"
```

### Automated Testing

Run the provided test scripts:

**Bash (Linux/Mac):**
```bash
chmod +x test-registration.sh
./test-registration.sh
```

**PowerShell (Windows):**
```powershell
.\test-registration.ps1
```

### PHPUnit Tests

Run the comprehensive test suite:

```bash
php artisan test --filter JwtAuthControllerTest
```

**Test Coverage:**
- ✅ Successful registration (customer)
- ✅ Successful registration (service provider)
- ✅ Validation errors (missing fields, invalid email, weak password)
- ✅ Duplicate email detection
- ✅ Password complexity validation
- ✅ Invalid role rejection
- ✅ Email sending failure handling

---

## Security Considerations

### Password Security
- ✅ Passwords are hashed using bcrypt (cost factor 12)
- ✅ Passwords are never stored in plain text
- ✅ Passwords are never returned in API responses
- ✅ Password strength is enforced

### Email Security
- ✅ OTPs are cryptographically secure random numbers
- ✅ OTPs expire after 10 minutes
- ✅ OTPs are single-use (marked as used after verification)
- ✅ Previous OTPs are invalidated when new ones are generated
- ✅ Maximum 5 verification attempts per OTP

### API Security
- ✅ Rate limiting (10 requests per minute)
- ✅ Input validation and sanitization
- ✅ Unique email constraint
- ✅ CORS protection
- ✅ Comprehensive error logging

### Data Privacy
- ✅ Sensitive data is not logged
- ✅ Email addresses are validated before storage
- ✅ User data is protected by database constraints
- ✅ GDPR-compliant data handling

---

## Error Handling

### Graceful Degradation

If email sending fails:
- ✅ Registration still succeeds
- ✅ User account is created
- ✅ OTP is stored in database
- ✅ User can request OTP resend
- ✅ Error is logged for debugging

**Rationale:** Email delivery issues should not prevent account creation. Users can always resend the OTP.

### Logging

All registration attempts are logged with:
- User email (for successful registrations)
- Validation errors (for failed registrations)
- Email sending status (success/failure)
- Exception details (for server errors)

**Log Levels:**
- `INFO`: Successful registrations, email sent
- `WARNING`: Registration succeeded but email failed
- `ERROR`: Email sending failures, server errors

---

## Integration with Frontend

### Flutter Integration

```dart
// Registration request
final response = await http.post(
  Uri.parse('$baseUrl/api/v1/auth/jwt/register'),
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  body: jsonEncode({
    'name': nameController.text,
    'email': emailController.text,
    'password': passwordController.text,
    'role': selectedRole,
  }),
);

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  final userId = data['data']['user_id'];
  final email = data['data']['email'];
  
  // Navigate to OTP verification screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OtpVerificationScreen(
        userId: userId,
        email: email,
      ),
    ),
  );
} else {
  // Handle validation errors
  final errors = jsonDecode(response.body)['errors'];
  // Display errors to user
}
```

### React Integration

```javascript
// Registration request
const response = await fetch(`${baseUrl}/api/v1/auth/jwt/register`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  body: JSON.stringify({
    name: formData.name,
    email: formData.email,
    password: formData.password,
    role: formData.role,
  }),
});

const data = await response.json();

if (data.success) {
  const { user_id, email } = data.data;
  
  // Navigate to OTP verification page
  navigate('/verify-otp', { 
    state: { userId: user_id, email } 
  });
} else {
  // Handle validation errors
  setErrors(data.errors);
}
```

---

## Troubleshooting

### Issue: Email not received

**Possible Causes:**
1. SMTP credentials not configured
2. Email in spam folder
3. Invalid email address
4. SMTP server issues

**Solutions:**
1. Check `.env` file for correct SMTP settings
2. Check spam/junk folder
3. Verify email address is valid
4. Check Laravel logs for email sending errors
5. Test SMTP connection manually

### Issue: Validation errors

**Possible Causes:**
1. Missing required fields
2. Invalid email format
3. Weak password
4. Duplicate email
5. Invalid role

**Solutions:**
1. Ensure all required fields are provided
2. Use valid email format
3. Meet password requirements (8+ chars, uppercase, lowercase, number)
4. Use unique email address
5. Use valid role (customer or serviceProvider)

### Issue: Server error (500)

**Possible Causes:**
1. Database connection issues
2. Missing environment variables
3. Code errors

**Solutions:**
1. Check database connection in `.env`
2. Verify all required environment variables are set
3. Check Laravel logs (`storage/logs/laravel.log`)
4. Enable debug mode (`APP_DEBUG=true`) for detailed errors

---

## Related Endpoints

### OTP Verification
**URL:** `POST /api/v1/auth/otp/verify-email`

Verify the OTP sent during registration.

### Resend OTP
**URL:** `POST /api/v1/auth/otp/send-email-verification`

Request a new OTP if the previous one expired.

### Login
**URL:** `POST /api/v1/auth/jwt/login`

Login with verified credentials to receive JWT tokens.

---

## Support

For issues or questions:

- **Email:** support@gharsewa.com
- **Documentation:** [API Documentation](http://localhost:8000/api/documentation)
- **GitHub Issues:** [Report a bug](https://github.com/gharsewa/backend/issues)

---

## Changelog

### Version 1.0.0 (Current)
- ✅ Initial implementation
- ✅ Email verification with OTP
- ✅ Password strength validation
- ✅ Role-based registration
- ✅ Comprehensive test coverage
- ✅ Professional email templates
- ✅ Graceful error handling

---

**Last Updated:** 2025-01-XX  
**API Version:** v1  
**Status:** Production Ready
