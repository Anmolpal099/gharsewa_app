# Requirements: Laravel JWT + Nodemailer Authentication Migration

## Introduction

This document specifies the requirements for migrating the authentication system from Firebase to a Laravel-based JWT authentication with Nodemailer for real-time OTP email delivery. The system will handle user registration, login, email verification, and password reset entirely through the Laravel backend, eliminating dependency on Firebase Authentication.

## Glossary

- **JWT**: JSON Web Token - Used for stateless authentication
- **Nodemailer**: Node.js library for sending emails (used in Laravel via npm)
- **OTP**: One-Time Password - 6-digit code for email verification and password reset
- **Laravel Passport/Sanctum**: Laravel authentication packages (we'll use JWT instead)
- **Access Token**: Short-lived JWT token for API authentication
- **Refresh Token**: Long-lived token for obtaining new access tokens
- **SMTP**: Simple Mail Transfer Protocol - For sending emails

## Requirements

### Requirement 1: Remove Firebase Authentication Dependencies

**User Story:** As a developer, I want to remove all Firebase authentication dependencies from the project, so that the system uses only Laravel for authentication.

#### Acceptance Criteria

1. WHEN Firebase packages are removed from Flutter, THE System SHALL compile without Firebase dependencies
2. WHEN Firebase Admin SDK is removed from Laravel, THE System SHALL not reference any Firebase authentication methods
3. THE System SHALL remove all Firebase configuration files (firebase-credentials.json, google-services.json, GoogleService-Info.plist)
4. THE System SHALL remove Firebase initialization code from Flutter main.dart
5. THE System SHALL remove Firebase custom claims logic from Laravel
6. THE System SHALL remove all Firebase-related environment variables
7. WHEN the migration is complete, THE System SHALL function without any Firebase services

### Requirement 2: Laravel JWT Authentication Implementation

**User Story:** As a user, I want to authenticate using email and password with JWT tokens, so that I can securely access the application.

#### Acceptance Criteria

1. WHEN a user registers with valid credentials, THE System SHALL create a user account in the Laravel database and return JWT access and refresh tokens
2. WHEN a user logs in with valid credentials, THE System SHALL verify the credentials against the database and return JWT tokens
3. THE System SHALL generate access tokens with 1-hour expiration
4. THE System SHALL generate refresh tokens with 30-day expiration
5. WHEN an access token expires, THE System SHALL allow token refresh using the refresh token
6. THE System SHALL store hashed passwords using bcrypt with cost factor 12
7. THE System SHALL validate JWT tokens on all protected API endpoints
8. WHEN a user logs out, THE System SHALL invalidate the refresh token
9. THE System SHALL store user roles (customer, serviceProvider, admin) in the database
10. THE System SHALL include user role in JWT token claims

### Requirement 3: Nodemailer Email Service Integration

**User Story:** As a system administrator, I want to send real emails using Nodemailer, so that users receive actual OTP codes in their inbox.

#### Acceptance Criteria

1. THE System SHALL integrate Nodemailer for sending emails from Laravel
2. THE System SHALL support SMTP configuration via environment variables (host, port, username, password)
3. WHEN an OTP is generated, THE System SHALL send a real email to the user's email address within 5 seconds
4. THE System SHALL use HTML email templates with branding and styling
5. THE System SHALL handle email sending failures gracefully and log errors
6. THE System SHALL support multiple SMTP providers (Gmail, SendGrid, Mailtrap, custom SMTP)
7. THE System SHALL include unsubscribe links in non-critical emails
8. WHEN email sending fails, THE System SHALL retry up to 3 times with exponential backoff
9. THE System SHALL log all email sending attempts with status (sent, failed, queued)

### Requirement 4: OTP Email Verification System

**User Story:** As a new user, I want to verify my email address using an OTP sent to my inbox, so that I can activate my account.

#### Acceptance Criteria

1. WHEN a user registers, THE System SHALL generate a 6-digit OTP and send it via Nodemailer
2. THE OTP SHALL expire after 10 minutes
3. THE System SHALL allow maximum 5 verification attempts per OTP
4. WHEN a user enters a valid OTP, THE System SHALL mark the email as verified in the database
5. WHEN a user enters an invalid OTP, THE System SHALL return an error and decrement remaining attempts
6. THE System SHALL allow OTP resend with 60-second cooldown
7. WHEN OTP is resent, THE System SHALL invalidate the previous OTP
8. THE System SHALL prevent login for unverified users (optional based on business rules)
9. THE System SHALL send a welcome email after successful verification

### Requirement 5: Password Reset with OTP

**User Story:** As a user, I want to reset my password using an OTP sent to my email, so that I can regain access to my account.

#### Acceptance Criteria

1. WHEN a user requests password reset, THE System SHALL verify the email exists in the database
2. THE System SHALL generate a 6-digit OTP and send it via Nodemailer
3. THE OTP SHALL expire after 10 minutes
4. WHEN a user enters a valid OTP, THE System SHALL allow password reset
5. WHEN a user sets a new password, THE System SHALL hash it with bcrypt and update the database
6. THE System SHALL invalidate all existing refresh tokens after password reset
7. THE System SHALL send a password reset confirmation email
8. THE System SHALL enforce password strength requirements (min 8 chars, uppercase, lowercase, number)

### Requirement 6: Flutter Authentication Service Refactor

**User Story:** As a developer, I want a Flutter authentication service that works with Laravel JWT, so that the frontend can authenticate users.

#### Acceptance Criteria

1. THE Flutter app SHALL remove all Firebase authentication code
2. THE System SHALL implement a new AuthService that communicates with Laravel API
3. WHEN a user logs in, THE System SHALL store JWT tokens in secure storage
4. THE System SHALL automatically attach access tokens to all API requests
5. WHEN an access token expires, THE System SHALL automatically refresh it using the refresh token
6. WHEN token refresh fails, THE System SHALL log out the user and redirect to login
7. THE System SHALL provide authentication state stream for UI updates
8. THE System SHALL handle network errors gracefully with retry logic

### Requirement 7: User Registration Flow

**User Story:** As a new user, I want to register with email and password, so that I can create an account.

#### Acceptance Criteria

1. WHEN a user submits registration form, THE System SHALL validate email format and password strength
2. THE System SHALL check if email already exists in the database
3. WHEN email is unique, THE System SHALL create user account with hashed password
4. THE System SHALL send OTP email for verification
5. THE System SHALL navigate user to OTP verification screen
6. WHEN OTP is verified, THE System SHALL mark email as verified
7. THE System SHALL return JWT tokens after verification
8. THE System SHALL navigate user to dashboard after successful registration

### Requirement 8: User Login Flow

**User Story:** As a registered user, I want to log in with my email and password, so that I can access my account.

#### Acceptance Criteria

1. WHEN a user submits login credentials, THE System SHALL verify email and password against the database
2. WHEN credentials are valid, THE System SHALL return JWT access and refresh tokens
3. WHEN credentials are invalid, THE System SHALL return appropriate error message
4. THE System SHALL implement rate limiting (5 failed attempts per 15 minutes)
5. WHEN rate limit is exceeded, THE System SHALL temporarily block login attempts
6. THE System SHALL update last_login_at timestamp in the database
7. THE System SHALL navigate user to role-specific dashboard after login

### Requirement 9: Token Management

**User Story:** As a developer, I want robust token management, so that authentication is secure and seamless.

#### Acceptance Criteria

1. THE System SHALL store access tokens in memory (not persistent storage)
2. THE System SHALL store refresh tokens in secure storage (Keychain/Keystore)
3. WHEN app restarts, THE System SHALL use refresh token to obtain new access token
4. THE System SHALL implement token refresh interceptor for API calls
5. WHEN access token is about to expire (within 5 minutes), THE System SHALL proactively refresh it
6. THE System SHALL handle concurrent token refresh requests (prevent multiple refreshes)
7. WHEN refresh token expires, THE System SHALL log out user and clear all tokens
8. THE System SHALL provide logout functionality that invalidates tokens on backend

### Requirement 10: Email Templates

**User Story:** As a user, I want to receive professional-looking emails, so that I trust the communication.

#### Acceptance Criteria

1. THE System SHALL use HTML email templates with responsive design
2. THE System SHALL include company logo and branding in emails
3. THE System SHALL provide templates for: OTP verification, welcome, password reset, password changed
4. THE System SHALL include clear call-to-action buttons in emails
5. THE System SHALL include OTP code prominently in verification emails
6. THE System SHALL include expiry time in OTP emails
7. THE System SHALL include support contact information in all emails
8. THE System SHALL support email template customization via configuration

### Requirement 11: Security Requirements

**User Story:** As a security-conscious user, I want my authentication data to be secure, so that my account is protected.

#### Acceptance Criteria

1. THE System SHALL use HTTPS for all API communications
2. THE System SHALL hash passwords with bcrypt (cost factor 12)
3. THE System SHALL use cryptographically secure random number generator for OTPs
4. THE System SHALL implement rate limiting on authentication endpoints
5. THE System SHALL log all authentication events (login, logout, failed attempts)
6. THE System SHALL implement CORS properly to prevent unauthorized access
7. THE System SHALL validate and sanitize all user inputs
8. THE System SHALL use secure JWT signing algorithm (RS256 or HS256)
9. THE System SHALL rotate JWT secret keys periodically (manual process)
10. THE System SHALL implement account lockout after 10 failed login attempts

### Requirement 12: Migration Strategy

**User Story:** As a developer, I want a clear migration path, so that existing users are not affected.

#### Acceptance Criteria

1. THE System SHALL provide a migration plan document
2. THE System SHALL backup existing Firebase user data before migration
3. THE System SHALL migrate existing users to Laravel database (if any)
4. THE System SHALL handle users who are mid-session during migration
5. THE System SHALL provide rollback plan in case of migration failure
6. THE System SHALL test migration in staging environment before production
7. THE System SHALL communicate migration timeline to users
8. THE System SHALL provide support for users experiencing issues post-migration

## Non-Functional Requirements

### Performance
- Email sending SHALL complete within 5 seconds
- JWT token generation SHALL complete within 100ms
- Authentication API endpoints SHALL respond within 200ms for 95% of requests

### Scalability
- System SHALL support 10,000 concurrent users
- Email queue SHALL handle 1,000 emails per minute

### Reliability
- Email delivery success rate SHALL be at least 99%
- Authentication service uptime SHALL be at least 99.9%

### Maintainability
- Code SHALL follow Laravel and Flutter best practices
- All authentication logic SHALL be well-documented
- Email templates SHALL be easily customizable

## Out of Scope

- Social authentication (Google, Facebook, Apple)
- Two-factor authentication (2FA) beyond email OTP
- Biometric authentication
- Magic link authentication
- SMS OTP (only email OTP)
