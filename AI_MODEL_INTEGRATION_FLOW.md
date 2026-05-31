# Qwen 3.5 VL 2B Model Integration Flow

## Overview
The Qwen 3.5 VL 2B (Vision-Language) model is integrated into your Gharsewa project to analyze images and provide AI-powered home service diagnostics.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CUSTOMER PANEL                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐              │
│  │ Image        │      │ Annotation   │      │ Analysis     │              │
│  │ Capture      │─────▶│ Editor       │─────▶│ Results      │              │
│  │ Screen       │      │ (Markers)    │      │ Screen       │              │
│  └──────────────┘      └──────────────┘      └──────────────┘              │
│         │                      │                      │                     │
│         │                      ▼                      │                     │
│         │              ┌──────────────┐               │                     │
│         │              │ Defect       │               │                     │
│         │              │ Marker       │               │                     │
│         │              │ Models       │               │                     │
│         │              └──────────────┘               │                     │
│         │                      │                      │                     │
│         └──────────────────────┴──────────────────────┘                     │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ CurrentConsultation │                                 │
│                    │ Notifier            │                                 │
│                    │ (State Management)  │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ AIConsultationApi    │                                 │
│                    │ Service              │                                 │
│                    └──────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ HTTP POST /v1/customer/ai/consultations
                                       │ Payload: { image (base64), markers }
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND (Laravel)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                    ┌──────────────────────┐                                 │
│                    │ API Endpoint        │                                 │
│                    │ /v1/customer/ai/    │                                 │
│                    │ consultations       │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ Image Processing     │                                 │
│                    │ - Convert to tensor  │                                 │
│                    │ - Preprocess         │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ QWEN 3.5 VL 2B       │                                 │
│                    │ Model Inference      │                                 │
│                    │ - Vision Encoder     │                                 │
│                    │ - Language Decoder   │                                 │
│                    │ - Multi-modal Fusion  │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ Response Generation   │                                 │
│                    │ - Diagnosis          │                                 │
│                    │ - Service Type       │                                 │
│                    │ - Cost Estimate      │                                 │
│                    │ - Provider Recs      │                                 │
│                    └──────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ JSON Response
                                       │ { diagnosis, serviceType, costMin, costMax, providers }
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CUSTOMER PANEL (CONTINUED)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                    ┌──────────────────────┐                                 │
│                    │ AIConsultationModel │                                 │
│                    │ (Data Model)         │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ Analysis Results     │                                 │
│                    │ Screen Display       │                                 │
│                    │ - Diagnosis Card     │                                 │
│                    │ - Service Type       │                                 │
│                    │ - Cost Estimate      │                                 │
│                    │ - Provider List      │                                 │
│                    └──────────────────────┘                                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ Booking created with aiConsultationId
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BOOKING SYSTEM                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                    ┌──────────────────────┐                                 │
│                    │ BookingModel         │                                 │
│                    │ - id                 │                                 │
│                    │ - customerId         │                                 │
│                    │ - providerId         │                                 │
│                    │ - aiConsultationId ◄─┼── LINK TO AI CONSULTATION         │
│                    │ - status             │                                 │
│                    │ - totalPrice         │                                 │
│                    └──────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PROVIDER PANEL                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                    ┌──────────────────────┐                                 │
│                    │ Provider Bookings    │                                 │
│                    │ Screen              │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ Booking Cards        │                                 │
│                    │ - AI Indicator Badge │◄── Shows if booking has AI     │
│                    │ - AI Details Widget  │    consultation linked          │
│                    │ - Diagnosis Display  │                                 │
│                    │ - Cost Estimate      │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ AIConsultationById   │                                 │
│                    │ Provider             │                                 │
│                    │ (Fetches details)    │                                 │
│                    └──────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                               ADMIN PANEL                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                    ┌──────────────────────┐                                 │
│                    │ Admin Dashboard      │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ AI Analytics Section │                                 │
│                    │ - Total Consultations│                                 │
│                    │ - Success Rate       │                                 │
│                    │ - Avg Processing     │                                 │
│                    │ - Conversion Rate    │                                 │
│                    │ - Top Service Types  │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ AI Consultation      │                                 │
│                    │ Analytics Provider   │                                 │
│                    │ (30-day stats)       │                                 │
│                    └──────────────────────┘                                 │
│                                │                                             │
│                                ▼                                             │
│                    ┌──────────────────────┐                                 │
│                    │ AIConsultationApi    │                                 │
│                    │ Service              │                                 │
│                    │ getAnalytics()       │                                 │
│                    └──────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Detailed Flow Explanation

### 1. Customer Initiates AI Consultation

**Step 1: Image Capture**
- Customer opens AI Visual Assistant
- Captures photo of home issue (e.g., leaking pipe, broken window)
- Image stored as `PlatformImage` (cross-platform abstraction)

**Step 2: Annotation**
- Customer draws on image to mark problem areas
- Creates `DefectMarkerModel` objects with coordinates and descriptions
- Markers sent along with image to AI

**Step 3: Submission**
- `CurrentConsultationNotifier.submitConsultation()` called
- Converts `PlatformImage` to base64 string
- Sends HTTP POST to `/v1/customer/ai/consultations`
- Payload:
  ```json
  {
    "image": "base64_encoded_image",
    "markers": [
      {
        "id": "marker_1",
        "x": 100,
        "y": 200,
        "description": "Leaking pipe joint"
      }
    ]
  }
  ```

### 2. Backend AI Processing

**Step 4: Image Preprocessing**
- Backend receives base64 image
- Converts to tensor format for Qwen model
- Applies normalization and resizing

**Step 5: Qwen 3.5 VL 2B Inference**
- **Vision Encoder**: Processes image to extract visual features
- **Language Decoder**: Processes marker descriptions
- **Multi-modal Fusion**: Combines visual and textual information
- **Generation**: Produces structured output

**Step 6: Response Generation**
- Diagnosis: "Pipe joint leak requiring replacement"
- Service Type: "Plumbing Repair"
- Cost Estimate: NPR 2,000 - 5,000
- Recommended Providers: List of top-rated plumbers

**Step 7: Database Storage**
- Consultation saved with all AI results
- Unique consultation ID generated
- Image URL stored (cloud storage)

### 3. Customer Views Results

**Step 8: Display Analysis**
- `AnalysisResultsScreen` shows:
  - Annotated image with markers overlay
  - Diagnosis card with prominent styling
  - Service type with icon
  - Cost estimate range
  - Provider recommendations with booking buttons

**Step 9: Booking Creation**
- Customer selects provider and books service
- `BookingModel` created with `aiConsultationId` field
- Links booking to original AI consultation

### 4. Provider Views AI Diagnosis

**Step 10: Provider Receives Booking**
- Provider sees booking in dashboard
- **AI Indicator Badge** shows if booking originated from AI consultation
- Badge displays "AI" icon in purple

**Step 11: View AI Details**
- Provider taps booking to see AI consultation details
- `AIConsultationDetailsWidget` displays:
  - AI diagnosis text
  - Service type recommended
  - Cost estimate
  - Defect markers count
  - Original image (if available)

**Step 12: Informed Decision**
- Provider uses AI diagnosis to:
  - Prepare appropriate tools
  - Estimate accurate pricing
  - Understand problem severity

### 5. Admin Monitors AI Performance

**Step 13: Dashboard Analytics**
- Admin views AI consultation analytics
- Displays 30-day statistics:
  - Total consultations: 100
  - Successful: 85
  - Failed: 15
  - Avg processing time: 25.5s
  - Conversion rate: 65%

**Step 14: Service Type Insights**
- Top service types displayed:
  - Plumbing Repair: 30 (30%)
  - Electrical Work: 25 (25%)
  - Carpentry: 20 (20%)

**Step 15: Performance Monitoring**
- Admin can track:
  - AI model accuracy
  - Processing time trends
  - User satisfaction
  - Booking conversion rates

## Key Components

### Frontend (Flutter)

**Models:**
- `AIConsultationModel` - Stores AI consultation data
- `BookingModel` - Stores booking data with `aiConsultationId` link
- `DefectMarkerModel` - Stores annotation markers

**Services:**
- `AIConsultationApiService` - Handles API communication
- `ImageService` - Cross-platform image handling

**Providers:**
- `CurrentConsultationNotifier` - Manages current consultation state
- `ConsultationHistoryNotifier` - Manages consultation history
- `aiConsultationByIdProvider` - Fetches consultation by ID
- `aiConsultationAnalyticsProvider` - Fetches analytics for admin

**Widgets:**
- `AnnotationCanvas` - Freehand drawing on images
- `AIConsultationDetailsWidget` - Displays AI diagnosis
- `AIConsultationAnalyticsWidget` - Displays admin analytics

### Backend (Laravel)

**API Endpoints:**
- `POST /v1/customer/ai/consultations` - Create consultation
- `GET /v1/customer/ai/consultations` - Get history
- `GET /v1/customer/ai/consultations/{id}` - Get details
- `DELETE /v1/customer/ai/consultations/{id}` - Delete consultation
- `GET /v1/admin/ai/consultations/analytics` - Get analytics
- `GET /v1/admin/ai/consultations/statistics` - Get statistics

**AI Integration:**
- Qwen 3.5 VL 2B model hosted on backend
- Image preprocessing pipeline
- Response post-processing
- Database storage

## Data Flow Summary

```
Customer Image → Annotation → API Request → Qwen Model → AI Response → 
Customer Display → Booking Creation → Provider View → Admin Analytics
```

## Benefits of Integration

1. **Customer**: Quick, accurate diagnosis before booking
2. **Provider**: Informed decisions with AI insights
3. **Admin**: Data-driven insights into AI performance
4. **Business**: Higher conversion rates from AI consultations
