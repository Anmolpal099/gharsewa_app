# Design: Phase 1 Backend APIs

## Architecture Overview

### System Context
The Phase 1 Backend APIs provide RESTful endpoints for the Gharsewa multi-panel Flutter application. The APIs handle service management, booking operations, and user profiles with JWT-based authentication and role-based authorization.

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Customer   │  │   Provider   │  │    Admin     │      │
│  │    Panel     │  │    Panel     │  │    Panel     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/JSON + JWT
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Laravel Backend API                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              JWT Auth Middleware                     │   │
│  │         (tymon/jwt-auth + Role Checking)             │   │
│  └──────────────────────────────────────────────────────┘   │
│                            │                                 │
│  ┌─────────────────────────┴──────────────────────────┐     │
│  │                   Controllers                       │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │     │
│  │  │   Service    │  │   Booking    │  │  Profile │ │     │
│  │  │  Controller  │  │  Controller  │  │Controller│ │     │
│  │  └──────────────┘  └──────────────┘  └──────────┘ │     │
│  └─────────────────────────┬──────────────────────────┘     │
│                            │                                 │
│  ┌─────────────────────────┴──────────────────────────┐     │
│  │              Eloquent Models                        │     │
│  │    ┌──────┐    ┌─────────┐    ┌─────────┐         │     │
│  │    │ User │    │ Service │    │ Booking │         │     │
│  │    └──────┘    └─────────┘    └─────────┘         │     │
│  └─────────────────────────┬──────────────────────────┘     │
└────────────────────────────┼────────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  MySQL Database │
                    └─────────────────┘
```

## Component Design

### 1. Controller Architecture

All controllers extend `BaseController` which provides standardized response methods:
- `success($data, $message, $code)` - Success responses
- `error($message, $code, $errors)` - Error responses
- `paginated($data, $message)` - Paginated responses with meta

#### Controller Hierarchy
```
BaseController (abstract)
├── Provider\ServiceController
├── Provider\BookingController
├── Provider\ProviderController
├── Customer\CustomerController
└── Customer\BookingController
```

### 2. Service Management Design

#### Provider\ServiceController
**Responsibility:** Manage service CRUD operations for providers

**Methods:**
```php
class ServiceController extends BaseController
{
    // GET /api/v1/provider/services
    public function index(Request $request): JsonResponse
    // List provider's services with filtering and pagination
    
    // POST /api/v1/provider/services
    public function store(Request $request): JsonResponse
    // Create new service
    
    // GET /api/v1/provider/services/{id}
    public function show(string $id): JsonResponse
    // Get service details with bookings count
    
    // PUT /api/v1/provider/services/{id}
    public function update(Request $request, string $id): JsonResponse
    // Update service information
    
    // DELETE /api/v1/provider/services/{id}
    public function destroy(string $id): JsonResponse
    // Soft delete service (check for active bookings)
    
    // PATCH /api/v1/provider/services/{id}/status
    public function updateStatus(Request $request, string $id): JsonResponse
    // Activate/deactivate service
}
```

**Authorization Strategy:**
- Middleware: `jwt.auth` + `role:serviceProvider`
- Policy: Verify `auth()->user()->id === service->provider_id`

**Query Optimization:**
- Use `withCount('bookings')` for booking counts
- Eager load `provider` relationship when needed
- Apply pagination (15 per page default)

#### Customer Service Browsing (CustomerController)
**Responsibility:** Public service browsing and search

**Methods:**
```php
class CustomerController extends BaseController
{
    // GET /api/v1/services
    public function listServices(Request $request): JsonResponse
    // Browse active services with filtering
    
    // GET /api/v1/services/{id}
    public function getService(string $id): JsonResponse
    // Get service details with provider info
    
    // GET /api/v1/services/search
    public function searchServices(Request $request): JsonResponse
    // Search services by name, description, tags
    
    // GET /api/v1/services/categories
    public function getCategories(): JsonResponse
    // List unique categories with counts
    
    // GET /api/v1/user/profile
    public function getProfile(): JsonResponse
    // Get current user profile
    
    // PUT /api/v1/user/profile
    public function updateProfile(Request $request): JsonResponse
    // Update user profile
    
    // POST /api/v1/user/profile/image
    public function uploadProfileImage(Request $request): JsonResponse
    // Upload profile image
}
```

**Authorization Strategy:**
- Service browsing: No auth required (public)
- Profile operations: `jwt.auth` (any role)

**Query Optimization:**
- Only show `status = 'active'` services
- Eager load `provider` for service listings
- Use `select()` to limit fields in listings

### 3. Booking Management Design

#### Customer\BookingController
**Responsibility:** Customer booking operations

**Methods:**
```php
class BookingController extends BaseController
{
    // GET /api/v1/customer/bookings
    public function index(Request $request): JsonResponse
    // List customer's bookings with filtering
    
    // POST /api/v1/customer/bookings
    public function store(Request $request): JsonResponse
    // Create new booking
    
    // GET /api/v1/customer/bookings/{id}
    public function show(string $id): JsonResponse
    // Get booking details
    
    // PUT /api/v1/customer/bookings/{id}/cancel
    public function cancel(Request $request, string $id): JsonResponse
    // Cancel booking with optional reason
    
    // GET /api/v1/customer/bookings/availability
    public function checkAvailability(Request $request): JsonResponse
    // Check service availability for date
}
```

**Business Logic:**
```php
// store() method logic:
1. Validate: service_id, scheduled_at, notes
2. Load service and verify it's active
3. Create booking:
   - customer_id = auth()->user()->id
   - provider_id = service->provider_id
   - total_price = service->price
   - currency = service->currency
   - status = 'pending'
4. Return created booking with relationships

// cancel() method logic:
1. Load booking and verify ownership
2. Check status is 'pending' or 'confirmed'
3. Update status to 'cancelled'
4. Save cancellation_reason if provided
5. Return updated booking
```

**Authorization Strategy:**
- Middleware: `jwt.auth` + `role:customer`
- Policy: Verify `auth()->user()->id === booking->customer_id`

#### Provider\BookingController
**Responsibility:** Provider booking management

**Methods:**
```php
class BookingController extends BaseController
{
    // GET /api/v1/provider/bookings
    public function index(Request $request): JsonResponse
    // List provider's bookings with filtering
    
    // GET /api/v1/provider/bookings/{id}
    public function show(string $id): JsonResponse
    // Get booking details
    
    // PUT /api/v1/provider/bookings/{id}/accept
    public function accept(string $id): JsonResponse
    // Accept pending booking
    
    // PUT /api/v1/provider/bookings/{id}/reject
    public function reject(Request $request, string $id): JsonResponse
    // Reject pending booking with reason
    
    // PUT /api/v1/provider/bookings/{id}/complete
    public function complete(string $id): JsonResponse
    // Mark confirmed booking as completed
    
    // GET /api/v1/provider/bookings/pending
    public function pending(): JsonResponse
    // Get pending bookings only
    
    // GET /api/v1/provider/bookings/stats
    public function stats(Request $request): JsonResponse
    // Get booking statistics
}
```

**Business Logic:**
```php
// accept() method logic:
1. Load booking and verify provider ownership
2. Check status is 'pending'
3. Update status to 'confirmed'
4. Return updated booking

// reject() method logic:
1. Load booking and verify provider ownership
2. Check status is 'pending'
3. Validate rejection_reason is provided
4. Update status to 'rejected'
5. Save cancellation_reason (reuse field)
6. Return updated booking

// complete() method logic:
1. Load booking and verify provider ownership
2. Check status is 'confirmed'
3. Update status to 'completed'
4. Return updated booking

// stats() method logic:
1. Get date range from query params (default: current month)
2. Query bookings where provider_id = auth()->user()->id
3. Calculate:
   - total_bookings
   - pending_count
   - confirmed_count
   - completed_count
   - cancelled_count
   - rejected_count
   - total_revenue (sum of completed bookings)
4. Return statistics object
```

**Authorization Strategy:**
- Middleware: `jwt.auth` + `role:serviceProvider`
- Policy: Verify `auth()->user()->id === booking->provider_id`

### 4. Profile & Dashboard Design

#### Provider\ProviderController
**Responsibility:** Provider profile and dashboard

**Methods:**
```php
class ProviderController extends BaseController
{
    // GET /api/v1/provider/profile
    public function getProfile(): JsonResponse
    // Get provider profile with services count
    
    // PUT /api/v1/provider/profile
    public function updateProfile(Request $request): JsonResponse
    // Update provider profile
    
    // GET /api/v1/provider/dashboard
    public function getDashboard(): JsonResponse
    // Get dashboard statistics
    
    // GET /api/v1/provider/earnings
    public function getEarnings(Request $request): JsonResponse
    // Get earnings breakdown
}
```

**Dashboard Statistics:**
```php
[
    'total_services' => Service::where('provider_id', $userId)->count(),
    'active_services' => Service::where('provider_id', $userId)->active()->count(),
    'total_bookings' => Booking::where('provider_id', $userId)->count(),
    'pending_bookings' => Booking::where('provider_id', $userId)->pending()->count(),
    'this_month_earnings' => Booking::where('provider_id', $userId)
        ->where('status', 'completed')
        ->whereMonth('created_at', now()->month)
        ->sum('total_price'),
    'this_month_bookings' => Booking::where('provider_id', $userId)
        ->whereMonth('created_at', now()->month)
        ->count(),
    'average_rating' => 0, // Placeholder for future review system
]
```

**Earnings Breakdown:**
```php
// Query based on group_by parameter (day, week, month)
// Example for 'day' grouping:
Booking::where('provider_id', $userId)
    ->where('status', 'completed')
    ->whereBetween('created_at', [$dateFrom, $dateTo])
    ->selectRaw('DATE(created_at) as date, SUM(total_price) as earnings, COUNT(*) as bookings')
    ->groupBy('date')
    ->orderBy('date')
    ->get();
```

## Data Flow

### Service Creation Flow
```
1. Provider submits POST /api/v1/provider/services
   ↓
2. JWT middleware validates token and extracts user
   ↓
3. Role middleware checks user.role === 'serviceProvider'
   ↓
4. ServiceController::store() validates request data
   ↓
5. Create Service model with provider_id = auth()->user()->id
   ↓
6. Save to database
   ↓
7. Return success response with created service
```

### Booking Creation Flow
```
1. Customer submits POST /api/v1/customer/bookings
   ↓
2. JWT middleware validates token and extracts user
   ↓
3. Role middleware checks user.role === 'customer'
   ↓
4. BookingController::store() validates request data
   ↓
5. Load Service model and verify status === 'active'
   ↓
6. Create Booking model:
   - customer_id = auth()->user()->id
   - provider_id = service->provider_id
   - total_price = service->price
   - currency = service->currency
   - status = 'pending'
   ↓
7. Save to database
   ↓
8. Return success response with created booking
```

### Booking Status Transition Flow
```
pending → confirmed (provider accepts)
pending → rejected (provider rejects)
confirmed → completed (provider completes)
pending/confirmed → cancelled (customer cancels)
```

## API Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* resource data */ }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "errors": { /* validation errors or null */ }
}
```

### Paginated Response
```json
{
  "success": true,
  "message": "Data retrieved successfully",
  "data": [ /* array of items */ ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 73
  }
}
```

## Route Organization

### Public Routes (No Auth)
```php
Route::prefix('v1')->group(function () {
    Route::get('services', [CustomerController::class, 'listServices']);
    Route::get('services/{id}', [CustomerController::class, 'getService']);
    Route::get('services/search', [CustomerController::class, 'searchServices']);
    Route::get('services/categories', [CustomerController::class, 'getCategories']);
});
```

### Authenticated Routes (JWT Required)
```php
Route::prefix('v1')->middleware(['jwt.auth'])->group(function () {
    
    // User profile (all roles)
    Route::prefix('user')->group(function () {
        Route::get('profile', [CustomerController::class, 'getProfile']);
        Route::put('profile', [CustomerController::class, 'updateProfile']);
        Route::post('profile/image', [CustomerController::class, 'uploadProfileImage']);
    });
    
    // Customer routes
    Route::prefix('customer')->middleware('role:customer')->group(function () {
        Route::get('bookings', [CustomerBookingController::class, 'index']);
        Route::post('bookings', [CustomerBookingController::class, 'store']);
        Route::get('bookings/{id}', [CustomerBookingController::class, 'show']);
        Route::put('bookings/{id}/cancel', [CustomerBookingController::class, 'cancel']);
        Route::get('bookings/availability', [CustomerBookingController::class, 'checkAvailability']);
    });
    
    // Provider routes
    Route::prefix('provider')->middleware('role:serviceProvider')->group(function () {
        // Services
        Route::get('services', [ServiceController::class, 'index']);
        Route::post('services', [ServiceController::class, 'store']);
        Route::get('services/{id}', [ServiceController::class, 'show']);
        Route::put('services/{id}', [ServiceController::class, 'update']);
        Route::delete('services/{id}', [ServiceController::class, 'destroy']);
        Route::patch('services/{id}/status', [ServiceController::class, 'updateStatus']);
        
        // Bookings
        Route::get('bookings', [ProviderBookingController::class, 'index']);
        Route::get('bookings/pending', [ProviderBookingController::class, 'pending']);
        Route::get('bookings/stats', [ProviderBookingController::class, 'stats']);
        Route::get('bookings/{id}', [ProviderBookingController::class, 'show']);
        Route::put('bookings/{id}/accept', [ProviderBookingController::class, 'accept']);
        Route::put('bookings/{id}/reject', [ProviderBookingController::class, 'reject']);
        Route::put('bookings/{id}/complete', [ProviderBookingController::class, 'complete']);
        
        // Profile & Dashboard
        Route::get('profile', [ProviderController::class, 'getProfile']);
        Route::put('profile', [ProviderController::class, 'updateProfile']);
        Route::get('dashboard', [ProviderController::class, 'getDashboard']);
        Route::get('earnings', [ProviderController::class, 'getEarnings']);
    });
});
```

## Security Design

### Authentication Flow
```
1. Client includes JWT token in Authorization header
   Authorization: Bearer {access_token}
   ↓
2. jwt.auth middleware validates token
   - Verify signature
   - Check expiration
   - Extract user from token
   ↓
3. Set auth()->user() for request
   ↓
4. Continue to role middleware or controller
```

### Authorization Checks

#### Ownership Verification Pattern
```php
// In controller methods:
$service = Service::findOrFail($id);

if ($service->provider_id !== auth()->user()->id) {
    return $this->error('Unauthorized', 403);
}

// Proceed with operation
```

#### Role-Based Access
```php
// Middleware checks user role before reaching controller
Route::middleware('role:serviceProvider')->group(function () {
    // Only service providers can access these routes
});
```

### Input Validation

#### Validation Rules Pattern
```php
$validator = Validator::make($request->all(), [
    'name' => 'required|string|max:255',
    'description' => 'required|string',
    'category' => 'required|string',
    'price' => 'required|numeric|min:0',
    'duration_minutes' => 'required|integer|min:15',
    'currency' => 'string|in:NPR,USD',
]);

if ($validator->fails()) {
    return $this->error('Validation Error', 422, $validator->errors());
}
```

## Error Handling

### Error Response Strategy
```php
try {
    // Operation logic
    return $this->success($data, 'Success message');
    
} catch (ModelNotFoundException $e) {
    return $this->error('Resource not found', 404);
    
} catch (ValidationException $e) {
    return $this->error('Validation failed', 422, $e->errors());
    
} catch (\Exception $e) {
    Log::error('Operation failed', [
        'user_id' => auth()->user()->id,
        'exception' => $e->getMessage(),
    ]);
    
    return $this->error(
        'Operation failed. Please try again.',
        500,
        config('app.debug') ? ['exception' => $e->getMessage()] : null
    );
}
```

## Database Query Optimization

### Eager Loading Strategy
```php
// Avoid N+1 queries
$services = Service::with('provider')
    ->where('status', 'active')
    ->paginate(15);

$bookings = Booking::with(['customer', 'service', 'provider'])
    ->where('provider_id', $providerId)
    ->paginate(15);
```

### Counting Relationships
```php
// Use withCount instead of loading all relationships
$service = Service::withCount('bookings')->findOrFail($id);
// Access via $service->bookings_count
```

### Selective Field Loading
```php
// Only load needed fields for listings
$services = Service::select(['id', 'name', 'category', 'price', 'status'])
    ->active()
    ->paginate(15);
```

## File Upload Design

### Profile Image Upload
```php
public function uploadProfileImage(Request $request): JsonResponse
{
    $validator = Validator::make($request->all(), [
        'image' => 'required|image|mimes:jpeg,png,jpg|max:2048',
    ]);
    
    if ($validator->fails()) {
        return $this->error('Validation Error', 422, $validator->errors());
    }
    
    try {
        $user = auth()->user();
        
        // Delete old image if exists
        if ($user->profile_image_url) {
            Storage::disk('public')->delete($user->profile_image_url);
        }
        
        // Store new image
        $path = $request->file('image')->store('profile-images', 'public');
        
        // Update user
        $user->update(['profile_image_url' => $path]);
        
        return $this->success([
            'profile_image_url' => Storage::url($path),
        ], 'Profile image uploaded successfully');
        
    } catch (\Exception $e) {
        Log::error('Profile image upload failed', [
            'user_id' => auth()->user()->id,
            'exception' => $e->getMessage(),
        ]);
        
        return $this->error('Upload failed. Please try again.', 500);
    }
}
```

## Testing Strategy

### Manual Testing Checklist
1. **Authentication Testing**
   - Valid JWT token accepted
   - Invalid JWT token rejected
   - Expired JWT token rejected
   - Missing JWT token rejected

2. **Authorization Testing**
   - Provider can only access own services
   - Provider can only manage own bookings
   - Customer can only access own bookings
   - Role-based access enforced

3. **Validation Testing**
   - Required fields enforced
   - Data type validation works
   - Min/max constraints enforced
   - Enum values validated

4. **Business Logic Testing**
   - Service deletion blocked with active bookings
   - Booking status transitions work correctly
   - Price automatically set from service
   - Provider ID automatically set

5. **Error Handling Testing**
   - 404 for non-existent resources
   - 403 for unauthorized access
   - 422 for validation errors
   - 500 for server errors

### Postman Collection Structure
```
Phase 1 Backend APIs
├── Auth
│   ├── Register
│   ├── Login
│   └── Get Profile
├── Services (Provider)
│   ├── List Services
│   ├── Create Service
│   ├── Get Service
│   ├── Update Service
│   ├── Delete Service
│   └── Update Status
├── Services (Public)
│   ├── Browse Services
│   ├── Get Service Details
│   ├── Search Services
│   └── Get Categories
├── Bookings (Customer)
│   ├── List Bookings
│   ├── Create Booking
│   ├── Get Booking
│   ├── Cancel Booking
│   └── Check Availability
├── Bookings (Provider)
│   ├── List Bookings
│   ├── Get Booking
│   ├── Accept Booking
│   ├── Reject Booking
│   ├── Complete Booking
│   ├── Get Pending
│   └── Get Stats
└── Profile & Dashboard
    ├── Get Profile
    ├── Update Profile
    ├── Upload Image
    ├── Get Dashboard
    └── Get Earnings
```

## Implementation Order

### Phase 1: Core Service Management
1. Implement Provider\ServiceController
2. Add service routes
3. Test service CRUD operations

### Phase 2: Service Browsing
1. Implement public service endpoints in CustomerController
2. Add public routes
3. Test browsing and search

### Phase 3: Customer Booking
1. Implement Customer\BookingController
2. Add customer booking routes
3. Test booking creation and cancellation

### Phase 4: Provider Booking Management
1. Implement Provider\BookingController
2. Add provider booking routes
3. Test booking status transitions

### Phase 5: Profile & Dashboard
1. Implement profile methods in CustomerController
2. Implement Provider\ProviderController
3. Add profile and dashboard routes
4. Test profile updates and statistics

### Phase 6: Integration Testing
1. Test complete user flows
2. Verify authorization rules
3. Test error scenarios
4. Performance testing

## Deployment Considerations

### Environment Configuration
```env
JWT_SECRET=your-secret-key
JWT_TTL=60  # 1 hour in minutes
JWT_REFRESH_TTL=43200  # 30 days in minutes

FILESYSTEM_DISK=public
```

### Database Indexes
```php
// Ensure these indexes exist for performance:
- services: provider_id, status, category
- bookings: customer_id, provider_id, service_id, status, scheduled_at
- users: email, role
```

### Storage Configuration
```php
// config/filesystems.php
'public' => [
    'driver' => 'local',
    'root' => storage_path('app/public'),
    'url' => env('APP_URL').'/storage',
    'visibility' => 'public',
],
```

Run: `php artisan storage:link` to create symbolic link

## Monitoring & Logging

### Log Important Events
```php
// Service creation
Log::info('Service created', [
    'service_id' => $service->id,
    'provider_id' => $service->provider_id,
]);

// Booking status changes
Log::info('Booking status changed', [
    'booking_id' => $booking->id,
    'old_status' => $oldStatus,
    'new_status' => $booking->status,
    'changed_by' => auth()->user()->id,
]);

// Failed operations
Log::error('Operation failed', [
    'operation' => 'service_deletion',
    'service_id' => $id,
    'reason' => 'Active bookings exist',
]);
```

## Future Enhancements

### Phase 2 Additions
- Implement Laravel Policies for authorization
- Add automated feature tests
- Implement API rate limiting per user
- Add request/response logging middleware
- Implement soft delete restoration endpoints

### Phase 3 Additions
- Add review and rating system
- Implement real-time notifications
- Add webhook support for booking events
- Implement advanced search with filters
- Add caching layer for frequently accessed data
