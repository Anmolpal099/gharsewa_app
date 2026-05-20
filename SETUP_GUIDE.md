# Setup Guide - Gharsewa Multi-Panel Application

## Quick Start

### 1. Install Dependencies

```bash
cd e:\gharsewa
flutter pub get
```

### 2. Verify Flutter Installation

```bash
flutter doctor
```

Ensure all checks pass for your target platforms (Android, iOS, Web).

### 3. Run Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the Application

**For Mobile (Android):**
```bash
flutter run -d android
```

**For Mobile (iOS):**
```bash
flutter run -d ios
```

**For Web:**
```bash
flutter run -d chrome
```

## Project Structure Overview

```
gharsewa/
├── lib/
│   ├── core/           # Core utilities and constants
│   ├── data/           # Data models and repositories
│   ├── domain/         # Business logic
│   ├── presentation/   # UI (Customer, Provider, Admin panels)
│   └── services/       # API, Auth, Storage, etc.
├── assets/             # Images, icons, fonts
├── test/               # Unit, widget, integration tests
└── pubspec.yaml        # Dependencies
```

## Next Steps

### Phase 1: Core Setup (Week 1)
1. ✅ Create folder structure
2. ✅ Update pubspec.yaml
3. ⏳ Initialize Firebase project
4. ⏳ Set up Laravel backend with Docker
5. ⏳ Create core constants and utilities
6. ⏳ Implement authentication service

### Phase 2: Data Layer (Week 2)
1. Create data models (User, Service, Booking)
2. Implement repositories
3. Set up API client with Dio
4. Configure local storage with Hive

### Phase 3: UI Implementation (Weeks 3-6)
1. Implement Customer Panel (Mobile)
2. Implement Service Provider Panel (Mobile)
3. Implement Admin Panel (Web)
4. Add shared widgets and layouts

### Phase 4: Advanced Features (Weeks 7-9)
1. Integrate AI services
2. Implement real-time features (WebSocket)
3. Add payment integration (Stripe)
4. Set up notification systems

### Phase 5: Testing & Deployment (Weeks 10-12)
1. Write unit and widget tests
2. Perform integration testing
3. Set up CI/CD pipeline
4. Deploy to production

## Development Workflow

### 1. Create a New Feature

```bash
# Create feature branch
git checkout -b feature/feature-name

# Make changes
# ...

# Run tests
flutter test

# Format code
dart format .

# Analyze code
flutter analyze

# Commit changes
git add .
git commit -m "feat: add feature description"
git push origin feature/feature-name
```

### 2. Code Generation

When you add new models or providers:

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generates on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/auth_service_test.dart

# Run with coverage
flutter test --coverage
```

## Environment Configuration

### Development Environment

Create `.env.dev`:
```env
API_BASE_URL=http://localhost:8000/api
ENVIRONMENT=development
```

### Production Environment

Create `.env.prod`:
```env
API_BASE_URL=https://api.gharsewa.com/api
ENVIRONMENT=production
```

## Firebase Setup Steps

1. Go to https://console.firebase.google.com
2. Create new project "Gharsewa"
3. Add Android app:
   - Package name: `com.gharsewa.app`
   - Download `google-services.json` → `android/app/`
4. Add iOS app:
   - Bundle ID: `com.gharsewa.app`
   - Download `GoogleService-Info.plist` → `ios/Runner/`
5. Add Web app:
   - Copy Firebase config to `web/index.html`
6. Enable services:
   - Authentication
   - Cloud Messaging
   - Analytics
   - Crashlytics
   - Performance Monitoring

## Backend Setup (Laravel + Docker)

### 1. Navigate to Backend Directory

```bash
cd e:\gharsewa\backend
```

### 2. Start Docker Containers

```bash
docker-compose up -d
```

### 3. Install Laravel Dependencies

```bash
docker-compose exec app composer install
```

### 4. Run Migrations

```bash
docker-compose exec app php artisan migrate
```

### 5. Seed Database

```bash
docker-compose exec app php artisan db:seed
```

## Useful Commands

### Flutter

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check outdated packages
flutter pub outdated

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release

# Build Web
flutter build web --release
```

### Git

```bash
# Check status
git status

# Create branch
git checkout -b feature/branch-name

# Commit changes
git add .
git commit -m "commit message"

# Push changes
git push origin branch-name

# Pull latest changes
git pull origin main
```

## Troubleshooting

### Issue: "Gradle build failed"
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Issue: "CocoaPods not installed"
**Solution:**
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

### Issue: "Build runner conflicts"
**Solution:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: "Firebase not initialized"
**Solution:**
Ensure `Firebase.initializeApp()` is called in `main()` before `runApp()`.

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Stripe Flutter Integration](https://stripe.com/docs/payments/accept-a-payment?platform=flutter)

## Support

For issues or questions:
1. Check the documentation in `/docs`
2. Review the task list in `.kiro/specs/multi-panel-flutter-app/tasks.md`
3. Contact the development team

---

**Last Updated:** 2026-05-20
**Version:** 1.0.0
