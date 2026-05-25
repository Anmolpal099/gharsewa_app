# Provider Panel Data Models

This directory contains all data models for the Provider Panel Modernization feature.

## Models

### Core Models
- **ProviderProfile**: Provider profile with photo, bio, skills, certifications, and completeness calculation
- **Certification**: Certification document with verification status
- **PerformanceMetrics**: Provider performance metrics (rating, jobs completed, response time)

### Earnings Models
- **EarningsData**: Earnings data with trend analysis and percentage change
- **EarningsDataPoint**: Single data point for earnings chart
- **DateRange**: Date range for earnings queries

### Booking Models
- **BookingRequest**: Customer booking request with urgency detection
- **CounterOffer**: Provider counter-offer with price difference calculation

### AI & Safety Models
- **Suggestion**: AI-generated suggestion for provider optimization
- **SafetySOP**: Safety Standard Operating Procedure for job types

### Configuration Models
- **ChartConfig**: Configuration for chart rendering with Material Design 3 colors

### Enums
- **BookingRequestStatus**: pending, accepted, declined, counterOffered, expired
- **SuggestionType**: profileImprovement, performanceOptimization, availabilityAdjustment, pricingStrategy
- **SuggestionPriority**: high, medium, low
- **CounterOfferStatus**: pending, accepted, rejected
- **EarningsViewType**: daily, weekly

## Usage

Import all models using the barrel file:

```dart
import 'package:gharsewa/features/provider_panel/data/models/models.dart';
```

## Features

### Profile Completeness Calculation
The `ProviderProfile` model automatically calculates completeness percentage:
- 25% for having a photo
- 25% for having a bio with at least 50 characters
- 25% for having at least 3 skills
- 25% for having at least 1 certification

### Earnings Trend Analysis
The `EarningsData` model provides:
- Percentage change calculation from previous period
- Positive/negative/no change detection
- Support for daily and weekly views

### Urgency Detection
The `BookingRequest` model automatically detects urgent requests (scheduled within 24 hours).

### Counter-Offer Analysis
The `CounterOffer` model calculates:
- Price difference
- Percentage difference
- Higher/lower comparison

## Dependencies

All required dependencies are already in `pubspec.yaml`:
- `flutter_riverpod` - State management
- `fl_chart` - Charts and visualization
- `hive` & `hive_flutter` - Local storage
- `image_picker` - Image selection
- `intl` - Internationalization

## Next Steps

The following components need to be implemented:
1. Data layer services (API client, Document Uploader, Cache Manager)
2. Business logic layer managers (Profile Manager, Skill Manager, etc.)
3. Presentation layer (screens and widgets)
4. Navigation and integration
