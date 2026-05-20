# Multi-Panel Flutter Application - Folder Structure

## Complete Directory Structure

```
gharsewa/
├── .kiro/                          # Kiro spec files
│   └── specs/
│       └── multi-panel-flutter-app/
│           ├── design.md
│           ├── requirements.md
│           └── tasks.md
│
├── lib/                            # Main application code
│   ├── core/                       # Core functionality
│   │   ├── constants/              # App-wide constants
│   │   ├── utils/                  # Utility functions
│   │   ├── errors/                 # Error handling
│   │   ├── config/                 # App configuration
│   │   └── theme/                  # Theme definitions
│   │
│   ├── data/                       # Data layer
│   │   ├── models/                 # Data models (User, Service, Booking)
│   │   ├── repositories/           # Repository implementations
│   │   └── datasources/            # Data sources
│   │       ├── local/              # Local storage (Hive)
│   │       └── remote/             # API clients
│   │
│   ├── domain/                     # Business logic layer
│   │   ├── entities/               # Domain entities
│   │   ├── repositories/           # Repository interfaces
│   │   └── usecases/               # Business use cases
│   │
│   ├── presentation/               # UI layer
│   │   ├── panels/                 # Panel-specific code
│   │   │   ├── customer/           # Customer Panel (Mobile)
│   │   │   │   ├── screens/        # Customer screens
│   │   │   │   ├── widgets/        # Customer widgets
│   │   │   │   └── controllers/    # Customer controllers
│   │   │   │
│   │   │   ├── provider/           # Service Provider Panel (Mobile)
│   │   │   │   ├── screens/        # Provider screens
│   │   │   │   ├── widgets/        # Provider widgets
│   │   │   │   └── controllers/    # Provider controllers
│   │   │   │
│   │   │   └── admin/              # Admin Panel (Web)
│   │   │       ├── screens/        # Admin screens
│   │   │       ├── widgets/        # Admin widgets
│   │   │       └── controllers/    # Admin controllers
│   │   │
│   │   ├── shared/                 # Shared UI components
│   │   │   ├── widgets/            # Reusable widgets
│   │   │   └── layouts/            # Common layouts
│   │   │
│   │   └── router/                 # Navigation & routing
│   │
│   ├── services/                   # Application services
│   │   ├── auth/                   # Authentication service
│   │   ├── api/                    # API client
│   │   ├── storage/                # Local storage
│   │   ├── notification/           # Notifications
│   │   ├── websocket/              # Real-time features
│   │   ├── payment/                # Payment integration
│   │   └── ai/                     # AI services
│   │
│   └── main.dart                   # Application entry point
│
├── assets/                         # Static assets
│   ├── images/                     # Image files
│   ├── icons/                      # Icon files
│   └── fonts/                      # Custom fonts
│
├── test/                           # Test files
│   ├── unit/                       # Unit tests
│   ├── widget/                     # Widget tests
│   └── integration/                # Integration tests
│
├── android/                        # Android platform code
├── ios/                            # iOS platform code
├── web/                            # Web platform code
│
├── pubspec.yaml                    # Flutter dependencies
└── README.md                       # Project documentation
```

## Layer Responsibilities

### 1. Core Layer (`lib/core/`)
- Application-wide constants and configuration
- Utility functions and helpers
- Error handling and custom exceptions
- Theme and styling definitions

### 2. Data Layer (`lib/data/`)
- Data models with JSON serialization
- Repository implementations
- Local and remote data sources
- API communication logic

### 3. Domain Layer (`lib/domain/`)
- Business entities
- Repository contracts (interfaces)
- Use cases (business logic)
- Domain-specific rules

### 4. Presentation Layer (`lib/presentation/`)
- UI screens and widgets
- Panel-specific implementations
- State management (controllers/providers)
- Navigation and routing

### 5. Services Layer (`lib/services/`)
- Authentication and authorization
- API client and HTTP services
- Local storage management
- Third-party integrations (Payment, AI, WebSocket)

## Panel Structure

### Customer Panel (Mobile)
- Service browsing and search
- Booking management
- Profile management
- Payment processing

### Service Provider Panel (Mobile)
- Dashboard with analytics
- Booking request management
- Service management
- Earnings tracking

### Admin Panel (Web)
- Platform overview dashboard
- User management
- Booking oversight
- Reports and analytics

## Key Files to Create

### Core
- `lib/core/constants/api_constants.dart`
- `lib/core/constants/app_constants.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/utils/validators.dart`
- `lib/core/errors/exceptions.dart`

### Data Models
- `lib/data/models/user_model.dart`
- `lib/data/models/service_model.dart`
- `lib/data/models/booking_model.dart`
- `lib/data/models/auth_state_model.dart`

### Services
- `lib/services/auth/authentication_service.dart`
- `lib/services/api/api_client.dart`
- `lib/services/storage/local_storage_service.dart`

### Presentation
- `lib/presentation/router/app_router.dart`
- `lib/presentation/panels/customer/screens/home_screen.dart`
- `lib/presentation/panels/provider/screens/dashboard_screen.dart`
- `lib/presentation/panels/admin/screens/admin_dashboard_screen.dart`

## Next Steps

1. Initialize Flutter project: `flutter create .`
2. Update `pubspec.yaml` with dependencies
3. Create base files in each directory
4. Implement core services (Auth, API, Storage)
5. Build data models
6. Implement panel-specific features
