# Phase 1: Backend APIs - Ready to Implement

## Status: Specifications Complete ✅

All models and migrations are in place. The following controllers need to be implemented with the specified endpoints.

---

## 1. Service Management APIs

### Provider Service Controller
**File:** `backend/app/Http/Controllers/API/V1/Provider/ServiceController.php`

**Existing Model:** ✅ `App\Models\Service`
**Migration:** ✅ `2024_01_01_000002_create_services_table.php`

**Schema:**
- id (UUID)
- provider_id (UUID, foreign key to users)
- name (string)
- description (text)
- category (string)
- price (decimal 10,2)
- currency (string, default 'NPR')
- duration_minutes (integer)
- status (enum: active, inactive, pending)
- image_urls (json, nullable)
- tags (json, nullable)
- metadata (json, nullable)
- timestamps, soft deletes

**Endpoints to Implement:**

```php
// List provider's services
GET /api/v1/provider/services
- Auth: Required (JWT, role: serviceProvider)
- Query params: status, category, page, per_page
- Returns: Paginated list of provider's services

// Create new service
POST /api/v1/provider/services
- Auth: Required (JWT, role: serviceProvider)
- Body: name, description, category, price, duration_minutes, currency
- Validation:
  * name: required|string|max:255
  * description: required|string
  * category: required|string
  * price: required|numeric|min:0
  * duration_minutes: required|integer|min:15
  * currency: string|in:NPR,USD
- Returns: Created service

// Get service details
GET /api/v1/provider/services/{id}
- Auth: Required (JWT, role: serviceProvider)
- Authorization: Must own the service
- Returns: Service details with bookings count

// Update service
PUT /api/v1/provider/services/{id}
- Auth: Required (JWT, role: serviceProvider)
- Authorization: Must own the service
- Body: name, description, category, price, duration_minutes
- Returns: Updated service

// Delete service
DELETE /api/v1/provider/services/{id}
- Auth: Required (JWT, role: serviceProvider)
- Authorization: Must own the service
- Business rule: Cannot delete if active bookings exist
- Returns: Success message

// Update service status
PATCH /api/v1/provider/services/{id}/status
- Auth: Required (JWT, role: serviceProvider)
- Authorization: Must own the service
- Body: status (active|inactive)
- Returns: Updated service
```

### Customer Service Browsing
**File:** `backend/app/Http/Controllers/API/V1/Customer/CustomerController.php`

**Endpoints to Implement:**

```php
// Browse all active services
GET /api/v1/services
- Auth: Optional (public endpoint)
- Query params: category, min_price, max_price, search, page, per_page
- Returns: Paginated list of active services with provider info

// Get service details
GET /api/v1/services/{id}
- Auth: Optional (public endpoint)
- Returns: Service details with provider info and reviews

// Search services
GET /api/v1/services/search
- Auth: Optional (public endpoint)
- Query params: q (search term), category, page, per_page
- Search in: name, description, tags
- Returns: Paginated search results

// Get service categories
GET /api/v1/services/categories
- Auth: Optional (public endpoint)
- Returns: List of unique categories with service counts
```

---

## 2. Booking Management APIs

### Customer Booking Controller
**File:** `backend/app/Http/Controllers/API/V1/Customer/BookingController.php`

**Existing Model:** ✅ `App\Models\Booking`
**Migration:** ✅ `2024_01_01_000003_create_bookings_table.php`

**Schema:**
- id (UUID)
- customer_id (UUID, foreign key to users)
- service_id (UUID, foreign key to services)
- provider_id (UUID, foreign key to users)
- scheduled_at (datetime)
- status (enum: pending, confirmed, completed, cancelled, rejected)
- total_price (decimal 10,2)
- currency (string, default 'NPR')
- cancellation_reason (text, nullable)
- timestamps, soft deletes

**Endpoints to Implement:**

```php
// Create booking
POST /api/v1/customer/bookings
- Auth: Required (JWT, role: customer)
- Body: service_id, scheduled_at, notes
- Validation:
  * service_id: required|exists:services,id
  * scheduled_at: required|date|after:now
  * notes: nullable|string|max:500
- Business logic:
  * Get service and provider_id
  * Set total_price from service price
  * Set status to 'pending'
  * Check provider availability (optional)
- Returns: Created booking

// List customer bookings
GET /api/v1/customer/bookings
- Auth: Required (JWT, role: customer)
- Query params: status, page, per_page
- Returns: Paginated list of customer's bookings with service and provider info

// Get booking details
GET /api/v1/customer/bookings/{id}
- Auth: Required (JWT, role: customer)
- Authorization: Must own the booking
- Returns: Booking details with service, provider, and payment info

// Cancel booking
PUT /api/v1/customer/bookings/{id}/cancel
- Auth: Required (JWT, role: customer)
- Authorization: Must own the booking
- Body: cancellation_reason (optional)
- Business rule: Can only cancel pending or confirmed bookings
- Returns: Updated booking

// Check availability
GET /api/v1/customer/bookings/availability
- Auth: Required (JWT, role: customer)
- Query params: service_id, date
- Returns: Available time slots for the service on the given date
```

### Provider Booking Controller
**File:** `backend/app/Http/Controllers/API/V1/Provider/BookingController.php`

**Endpoints to Implement:**

```php
// List provider bookings
GET /api/v1/provider/bookings
- Auth: Required (JWT, role: serviceProvider)
- Query params: status, date_from, date_to, page, per_page
- Returns: Paginated list of provider's bookings

// Get booking details
GET /api/v1/provider/bookings/{id}
- Auth: Required (JWT, role: serviceProvider)
- Authorization: Must be the provider for this booking
- Returns: Booking details with customer and service info

// Accept booking
PUT /api/v1/provider/bookings/{id}/accept
- Auth: Required (JWT, role: serviceProvider)
- Authorization: Must be the provider for this booking
- Business rule: Can only accept pending bookings
- Updates status to 'confirmed'
- Returns: Updated booking

// Reject booking
PUT /api/v1/provider/bookings/{id}/reject
- Auth: Required (JWT, role: serviceProvider)
- Authorization: Must be the provider for this booking
- Body: rejection_reason (required)
- Business rule: Can only reject pending bookings
- Updates status to 'rejected'
- Returns: Updated booking

// Complete booking
PUT /api/v1/provider/bookings/{id}/complete
- Auth: Required (JWT, role: serviceProvider)
- Authorization: Must be the provider for this booking
- Business rule: Can only complete confirmed bookings
- Updates status to 'completed'
- Returns: Updated booking

// Get pending bookings
GET /api/v1/provider/bookings/pending
- Auth: Required (JWT, role: serviceProvider)
- Returns: List of pending booking requests

// Get booking statistics
GET /api/v1/provider/bookings/stats
- Auth: Required (JWT, role: serviceProvider)
- Query params: date_from, date_to
- Returns: Statistics (total, pending, confirmed, completed, cancelled, revenue)
```

---

## 3. User/Provider Profile APIs

### Customer Profile Controller
**File:** `backend/app/Http/Controllers/API/V1/Customer/CustomerController.php`

**Endpoints to Implement:**

```php
// Get current user profile
GET /api/v1/user/profile
- Auth: Required (JWT)
- Returns: Current user profile data

// Update profile
PUT /api/v1/user/profile
- Auth: Required (JWT)
- Body: name, phone_number, address (optional fields)
- Validation:
  * name: string|max:255
  * phone_number: string|max:20
  * address: string|max:500
- Returns: Updated user profile

// Upload profile image
POST /api/v1/user/profile/image
- Auth: Required (JWT)
- Body: image (file)
- Validation:
  * image: required|image|mimes:jpeg,png,jpg|max:2048
- Stores image and updates profile_image_url
- Returns: Updated user with new image URL
```

### Provider Profile Controller
**File:** `backend/app/Http/Controllers/API/V1/Provider/ProviderController.php`

**Endpoints to Implement:**

```php
// Get provider profile
GET /api/v1/provider/profile
- Auth: Required (JWT, role: serviceProvider)
- Returns: Provider profile with services count and ratings

// Update provider profile
PUT /api/v1/provider/profile
- Auth: Required (JWT, role: serviceProvider)
- Body: name, phone_number, business_name, business_description, address
- Returns: Updated provider profile

// Get provider dashboard stats
GET /api/v1/provider/dashboard
- Auth: Required (JWT, role: serviceProvider)
- Returns: Dashboard statistics
  * Total services
  * Active services
  * Total bookings
  * Pending bookings
  * This month earnings
  * This month bookings
  * Average rating

// Get provider earnings
GET /api/v1/provider/earnings
- Auth: Required (JWT, role: serviceProvider)
- Query params: date_from, date_to, group_by (day|week|month)
- Returns: Earnings breakdown by time period
```

---

## Implementation Checklist

### Service Management
- [ ] Implement Provider ServiceController methods
- [ ] Implement Customer service browsing methods
- [ ] Add service validation rules
- [ ] Add authorization policies (provider owns service)
- [ ] Add service search functionality
- [ ] Add category listing
- [ ] Test all service endpoints

### Booking Management
- [ ] Implement Customer BookingController methods
- [ ] Implement Provider BookingController methods
- [ ] Add booking validation rules
- [ ] Add authorization policies (customer/provider owns booking)
- [ ] Implement booking status transitions
- [ ] Add availability checking logic
- [ ] Add booking statistics calculation
- [ ] Test all booking endpoints

### Profile Management
- [ ] Implement Customer profile methods
- [ ] Implement Provider profile methods
- [ ] Add profile validation rules
- [ ] Implement image upload functionality
- [ ] Add dashboard statistics calculation
- [ ] Add earnings calculation
- [ ] Test all profile endpoints

### Routes
- [ ] Add all routes to `routes/api.php`
- [ ] Apply JWT auth middleware
- [ ] Apply role-based middleware
- [ ] Add rate limiting

### Testing
- [ ] Write feature tests for services
- [ ] Write feature tests for bookings
- [ ] Write feature tests for profiles
- [ ] Test authorization rules
- [ ] Test validation rules
- [ ] Test business logic

---

## Routes File Structure

Add to `backend/routes/api.php`:

```php
// Public service browsing
Route::prefix('v1')->group(function () {
    Route::get('services', [CustomerController::class, 'listServices']);
    Route::get('services/{id}', [CustomerController::class, 'getService']);
    Route::get('services/search', [CustomerController::class, 'searchServices']);
    Route::get('services/categories', [CustomerController::class, 'getCategories']);
});

// Authenticated routes
Route::prefix('v1')->middleware(['auth:api'])->group(function () {
    
    // User profile (all roles)
    Route::prefix('user')->group(function () {
        Route::get('profile', [CustomerController::class, 'getProfile']);
        Route::put('profile', [CustomerController::class, 'updateProfile']);
        Route::post('profile/image', [CustomerController::class, 'uploadProfileImage']);
    });
    
    // Customer routes
    Route::prefix('customer')->middleware('role:customer')->group(function () {
        Route::apiResource('bookings', BookingController::class)->only(['index', 'store', 'show']);
        Route::put('bookings/{id}/cancel', [BookingController::class, 'cancel']);
        Route::get('bookings/availability', [BookingController::class, 'checkAvailability']);
    });
    
    // Provider routes
    Route::prefix('provider')->middleware('role:serviceProvider')->group(function () {
        // Services
        Route::apiResource('services', ServiceController::class);
        Route::patch('services/{id}/status', [ServiceController::class, 'updateStatus']);
        
        // Bookings
        Route::get('bookings', [BookingController::class, 'index']);
        Route::get('bookings/pending', [BookingController::class, 'pending']);
        Route::get('bookings/stats', [BookingController::class, 'stats']);
        Route::get('bookings/{id}', [BookingController::class, 'show']);
        Route::put('bookings/{id}/accept', [BookingController::class, 'accept']);
        Route::put('bookings/{id}/reject', [BookingController::class, 'reject']);
        Route::put('bookings/{id}/complete', [BookingController::class, 'complete']);
        
        // Profile & Dashboard
        Route::get('profile', [ProviderController::class, 'getProfile']);
        Route::put('profile', [ProviderController::class, 'updateProfile']);
        Route::get('dashboard', [ProviderController::class, 'getDashboard']);
        Route::get('earnings', [ProviderController::class, 'getEarnings']);
    });
});
```

---

## Next Steps

1. **Implement Controllers** - Start with ServiceController, then BookingController
2. **Add Routes** - Update routes/api.php with all endpoints
3. **Create Policies** - Add authorization policies for services and bookings
4. **Add Middleware** - Create role-based middleware if not exists
5. **Test Endpoints** - Use Postman or write feature tests
6. **Document APIs** - Create API documentation

Would you like me to start implementing these controllers now?
