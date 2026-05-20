# Dependencies Documentation

## Production Dependencies

### UI & Icons
- **cupertino_icons** (^1.0.6) - iOS style icons
- **flutter_svg** (^2.0.9) - SVG rendering support
- **cached_network_image** (^3.3.0) - Image caching and loading

### Routing & Navigation
- **go_router** (^13.0.0) - Declarative routing with deep linking support

### State Management
- **flutter_riverpod** (^2.4.0) - Reactive state management
- **riverpod_annotation** (^2.3.3) - Code generation for Riverpod

### Network & API
- **dio** (^5.4.0) - HTTP client for API calls
- **retrofit** (^4.0.0) - Type-safe REST client
- **pretty_dio_logger** (^1.3.1) - HTTP request/response logging

### Local Storage
- **hive** (^2.2.3) - Fast NoSQL database
- **hive_flutter** (^1.1.0) - Hive Flutter integration
- **flutter_secure_storage** (^9.0.0) - Secure storage for sensitive data
- **shared_preferences** (^2.2.2) - Simple key-value storage
- **path_provider** (^2.1.2) - File system path access

### Authentication
- **jwt_decoder** (^2.0.1) - JWT token decoding and validation

### Firebase Services
- **firebase_core** (^2.24.0) - Firebase core functionality
- **firebase_messaging** (^14.7.0) - Push notifications
- **firebase_analytics** (^10.8.0) - Analytics tracking
- **firebase_crashlytics** (^3.4.8) - Crash reporting
- **firebase_performance** (^0.9.3+8) - Performance monitoring

### Payment Integration
- **flutter_stripe** (^10.1.0) - Stripe payment gateway integration

### Real-time Communication
- **web_socket_channel** (^2.4.0) - WebSocket client
- **pusher_channels_flutter** (^2.2.1) - Pusher real-time events

### Charts & Visualization
- **fl_chart** (^0.66.0) - Beautiful charts and graphs

### Image Handling
- **image_picker** (^1.0.7) - Pick images from gallery or camera

### Utilities
- **intl** (^0.19.0) - Internationalization and localization
- **uuid** (^4.3.3) - UUID generation
- **equatable** (^2.0.5) - Value equality for objects
- **freezed_annotation** (^2.4.1) - Immutable classes annotation
- **json_annotation** (^4.8.1) - JSON serialization annotation
- **logger** (^2.0.2+1) - Logging utility

### Permissions
- **permission_handler** (^11.2.0) - Runtime permissions handling

### URL & File Handling
- **url_launcher** (^6.2.4) - Launch URLs and external apps
- **file_picker** (^6.1.1) - File selection from device

### PDF Generation
- **pdf** (^3.10.7) - PDF document generation
- **printing** (^5.12.0) - PDF printing and sharing

### Device Information
- **connectivity_plus** (^5.0.2) - Network connectivity status
- **device_info_plus** (^9.1.1) - Device information
- **package_info_plus** (^5.0.1) - App package information

## Development Dependencies

### Code Generation
- **build_runner** (^2.4.7) - Code generation runner
- **freezed** (^2.4.6) - Code generation for immutable classes
- **json_serializable** (^6.7.1) - JSON serialization code generation
- **retrofit_generator** (^8.0.0) - Retrofit code generation
- **riverpod_generator** (^2.3.9) - Riverpod code generation
- **hive_generator** (^2.0.1) - Hive type adapter generation

### Testing
- **mockito** (^5.4.4) - Mocking framework for tests
- **integration_test** (SDK) - Integration testing framework

### Tools
- **flutter_lints** (^3.0.0) - Recommended linting rules
- **flutter_launcher_icons** (^0.13.1) - App icon generation

## Installation

Run the following command to install all dependencies:

```bash
flutter pub get
```

## Code Generation

After adding models or providers, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For continuous code generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Platform-Specific Setup

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Required permissions in AndroidManifest.xml:
  - INTERNET
  - ACCESS_NETWORK_STATE
  - CAMERA (for image picker)
  - READ_EXTERNAL_STORAGE
  - WRITE_EXTERNAL_STORAGE

### iOS
- Minimum iOS version: 12.0
- Required Info.plist entries:
  - NSCameraUsageDescription
  - NSPhotoLibraryUsageDescription
  - NSLocationWhenInUseUsageDescription

### Web
- Ensure CORS is properly configured on the backend
- Firebase configuration in index.html

## Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Add Android, iOS, and Web apps to the project
3. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Web: Add Firebase config to `web/index.html`

## Stripe Setup

1. Get API keys from https://dashboard.stripe.com
2. Add publishable key to environment configuration
3. Configure webhook endpoints for payment events

## Environment Variables

Create `.env` file in the project root:

```env
API_BASE_URL=https://api.gharsewa.com
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
FIREBASE_API_KEY=xxxxx
PUSHER_APP_KEY=xxxxx
PUSHER_CLUSTER=xxxxx
```

## Troubleshooting

### Common Issues

1. **Build runner conflicts**: Run with `--delete-conflicting-outputs` flag
2. **Firebase initialization**: Ensure `firebase_core` is initialized before other Firebase services
3. **iOS build issues**: Run `pod install` in the `ios/` directory
4. **Android build issues**: Ensure Gradle version is compatible

### Useful Commands

```bash
# Clean build
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Analyze code
flutter analyze

# Format code
dart format .
```
