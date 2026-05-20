# Environment Configuration Guide

## Overview

This project uses environment-specific configuration files to manage different deployment environments (development, staging, production).

## Environment Files

### Available Files:
- `.env.dev` - Development environment
- `.env.staging` - Staging environment
- `.env.prod` - Production environment
- `.env.example` - Template file (committed to Git)

### Security:
⚠️ **IMPORTANT:** Never commit `.env.dev`, `.env.staging`, or `.env.prod` files with real credentials to version control. These files are already added to `.gitignore`.

## Setup Instructions

### 1. Copy Example File

```bash
# For development
cp .env.example .env.dev

# For staging
cp .env.example .env.staging

# For production
cp .env.example .env.prod
```

### 2. Fill in Your Credentials

Edit each file and replace placeholder values with your actual credentials:

```env
# Example: Update API URL
API_BASE_URL=https://your-actual-api-url.com/api

# Example: Update Firebase keys
FIREBASE_API_KEY=your_actual_firebase_key
FIREBASE_PROJECT_ID=your_actual_project_id

# Example: Update Stripe keys
STRIPE_PUBLISHABLE_KEY=pk_test_your_actual_key
```

## Running with Different Environments

### Development

```bash
flutter run --dart-define-from-file=.env.dev
```

### Staging

```bash
flutter run --dart-define-from-file=.env.staging
```

### Production

```bash
flutter run --dart-define-from-file=.env.prod --release
```

## Building with Environments

### Android

```bash
# Development
flutter build apk --dart-define-from-file=.env.dev

# Staging
flutter build apk --dart-define-from-file=.env.staging

# Production
flutter build apk --dart-define-from-file=.env.prod --release
```

### iOS

```bash
# Development
flutter build ios --dart-define-from-file=.env.dev

# Production
flutter build ios --dart-define-from-file=.env.prod --release
```

### Web

```bash
# Development
flutter build web --dart-define-from-file=.env.dev

# Production
flutter build web --dart-define-from-file=.env.prod --release
```

## Using Environment Variables in Code

### Import the Config

```dart
import 'package:gharsewa/core/config/env_config.dart';
```

### Access Variables

```dart
// Get API base URL
final apiUrl = EnvConfig.apiBaseUrl;

// Check environment
if (EnvConfig.isDevelopment) {
  print('Running in development mode');
}

// Get Firebase config
final firebaseKey = EnvConfig.firebaseApiKey;

// Print all config (debug only)
EnvConfig.printConfig();
```

## Environment Variables Reference

### API Configuration
- `API_BASE_URL` - Backend API base URL
- `API_TIMEOUT` - API request timeout in milliseconds

### Environment
- `ENVIRONMENT` - Current environment (development/staging/production)
- `DEBUG_MODE` - Enable/disable debug features

### Firebase
- `FIREBASE_API_KEY` - Firebase API key
- `FIREBASE_APP_ID` - Firebase app ID
- `FIREBASE_MESSAGING_SENDER_ID` - FCM sender ID
- `FIREBASE_PROJECT_ID` - Firebase project ID

### Stripe
- `STRIPE_PUBLISHABLE_KEY` - Stripe publishable key
- `STRIPE_SECRET_KEY` - Stripe secret key (backend only)

### Pusher
- `PUSHER_APP_KEY` - Pusher app key
- `PUSHER_CLUSTER` - Pusher cluster region
- `PUSHER_APP_ID` - Pusher app ID

### AI Service
- `AI_API_KEY` - AI service API key
- `AI_MODEL` - AI model to use

### SMS (Twilio)
- `TWILIO_ACCOUNT_SID` - Twilio account SID
- `TWILIO_AUTH_TOKEN` - Twilio auth token
- `TWILIO_PHONE_NUMBER` - Twilio phone number

### Email
- `MAIL_HOST` - SMTP host
- `MAIL_PORT` - SMTP port
- `MAIL_USERNAME` - SMTP username
- `MAIL_PASSWORD` - SMTP password

### App
- `APP_NAME` - Application name
- `APP_VERSION` - Application version

## Best Practices

### 1. Never Hardcode Credentials
❌ **Bad:**
```dart
const apiUrl = 'https://api.example.com';
```

✅ **Good:**
```dart
final apiUrl = EnvConfig.apiBaseUrl;
```

### 2. Use Different Keys for Different Environments
- Development: Use test/sandbox keys
- Staging: Use test keys with staging data
- Production: Use live/production keys

### 3. Rotate Credentials Regularly
- Change API keys periodically
- Update credentials after team member changes
- Use different credentials for each environment

### 4. Document Required Variables
- Keep `.env.example` updated
- Document what each variable does
- Provide example values

## Troubleshooting

### Issue: Environment variables not loading

**Solution:** Ensure you're using the `--dart-define-from-file` flag:
```bash
flutter run --dart-define-from-file=.env.dev
```

### Issue: Getting default values

**Solution:** Check that:
1. The `.env` file exists
2. Variable names match exactly (case-sensitive)
3. No extra spaces around `=` sign

### Issue: Build fails with environment file

**Solution:** Ensure the environment file path is correct and the file is not corrupted.

## Security Checklist

- [ ] `.env.dev`, `.env.staging`, `.env.prod` are in `.gitignore`
- [ ] Only `.env.example` is committed to Git
- [ ] Production credentials are stored securely
- [ ] Team members have their own local `.env` files
- [ ] Credentials are rotated regularly
- [ ] No credentials in code comments or logs

## Getting Credentials

### Firebase
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings
4. Copy the configuration values

### Stripe
1. Go to [Stripe Dashboard](https://dashboard.stripe.com/)
2. Go to Developers → API keys
3. Copy publishable and secret keys

### Pusher
1. Go to [Pusher Dashboard](https://dashboard.pusher.com/)
2. Select your app
3. Go to App Keys
4. Copy the credentials

### Twilio
1. Go to [Twilio Console](https://console.twilio.com/)
2. Go to Account → API keys & tokens
3. Copy Account SID and Auth Token

---

**Last Updated:** 2026-05-20
