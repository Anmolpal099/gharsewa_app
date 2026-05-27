# Manual Fix Guide: Provider Profile & Certificate Upload Issues

## Problem Summary

You're experiencing two issues:
1. **Provider Profile Photo Upload**: "Unsupported operation: _Namespace" error on Flutter Web
2. **Provider Certificate Upload**: "Unsupported operation: _Namespace" error on Flutter Web

## Root Cause

The backend is expecting **file uploads** but the frontend is now sending **base64 encoded images** (after implementing cross-platform image handling). The backend needs to be updated to accept base64 images, similar to how the customer profile upload was fixed.

---

## Fix 1: Update Provider Profile Photo Upload Backend

### File: `backend/app/Http/Controllers/API/V1/Provider/ProviderController.php`

**Add a new method** for profile photo upload (currently missing):

```php
/**
 * Upload profile image
 * POST /api/v1/provider/profile/image
 * Requires authentication with serviceProvider role
 */
public function uploadProfileImage(Request $request): JsonResponse
{
    try {
        $user = auth()->user();

        if (!$user) {
            return $this->error('User not authenticated', 401);
        }

        // Validate image - accept base64
        $validator = Validator::make($request->all(), [
            'image' => ['required', new \App\Rules\Base64Image(51200)], // Max 50MB
        ]);

        if ($validator->fails()) {
            return $this->error('Validation failed', 422, $validator->errors());
        }

        // Delete old image if exists
        if ($user->profile_image_url) {
            $oldPath = $user->profile_image_url;
            
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
                Log::info('Old profile image deleted', [
                    'user_id' => $user->id,
                    'old_path' => $oldPath,
                ]);
            }
        }

        // Handle base64 image
        $base64Image = $request->input('image');
        
        // Remove data URI scheme if present
        if (preg_match('/^data:image\/(\w+);base64,/', $base64Image, $matches)) {
            $base64Image = substr($base64Image, strpos($base64Image, ',') + 1);
        }
        
        // Decode base64
        $imageData = base64_decode($base64Image);
        
        // Generate filename
        $filename = time() . '_' . $user->id . '.jpg';
        $path = 'profile-images/' . $filename;
        
        // Store image
        Storage::disk('public')->put($path, $imageData);

        // Update user's profile_image_url
        $user->update([
            'profile_image_url' => $path,
        ]);

        // Generate full URL
        $imageUrl = Storage::url($path);

        Log::info('Provider profile image uploaded', [
            'user_id' => $user->id,
            'path' => $path,
            'url' => $imageUrl,
        ]);

        return $this->success([
            'image_url' => $imageUrl,
            'path' => $path,
        ], 'Profile image uploaded successfully');

    } catch (\Exception $e) {
        Log::error('Failed to upload provider profile image', [
            'exception' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
        ]);

        return $this->error('Failed to upload profile image. Please try again.', 500);
    }
}
```

---

## Fix 2: Update Provider Certificate Upload Backend

### File: `backend/app/Http/Controllers/API/V1/Provider/ProviderController.php`

**Replace the existing `uploadCertification` method** (around line 420):

**OLD CODE:**
```php
$validator = Validator::make($request->all(), [
    'name' => 'required|string|max:255',
    'document' => 'required|file|max:51200', // 50MB max, all file types
]);

if ($validator->fails()) {
    return $this->error('Validation failed', 422, $validator->errors());
}

$file = $request->file('document');
$ext = strtolower($file->getClientOriginalExtension());
$filename = time() . '_' . Str::uuid() . '.' . $ext;
$path = $file->storeAs('certifications/' . $user->id, $filename, 'public');
$documentUrl = Storage::disk('public')->url($path);
```

**NEW CODE:**
```php
$validator = Validator::make($request->all(), [
    'name' => 'required|string|max:255',
    'document' => ['required', new \App\Rules\Base64Image(51200)], // Max 50MB, base64
]);

if ($validator->fails()) {
    return $this->error('Validation failed', 422, $validator->errors());
}

// Handle base64 image
$base64Image = $request->input('document');

// Remove data URI scheme if present
if (preg_match('/^data:image\/(\w+);base64,/', $base64Image, $matches)) {
    $ext = strtolower($matches[1]);
    $base64Image = substr($base64Image, strpos($base64Image, ',') + 1);
} else {
    // Default to jpg if no mime type detected
    $ext = 'jpg';
}

// Decode base64
$imageData = base64_decode($base64Image);

// Generate filename
$filename = time() . '_' . Str::uuid() . '.' . $ext;
$path = 'certifications/' . $user->id . '/' . $filename;

// Store image
Storage::disk('public')->put($path, $imageData);
$documentUrl = Storage::disk('public')->url($path);
```

---

## Fix 3: Add Route for Provider Profile Image Upload

### File: `backend/routes/api.php`

Find the provider routes section and add:

```php
// Provider profile image upload
Route::post('/provider/profile/image', [ProviderController::class, 'uploadProfileImage']);
```

This should be added near the other provider routes (around line 80-100).

---

## Fix 4: Update Frontend Upload Service Endpoint

### File: `lib/features/provider_panel/data/services/provider_upload_service.dart`

**Update the `uploadProfilePhoto` method** to use the correct endpoint:

**CHANGE:**
```dart
final response = await _dio.post(
  '/v1/profile/image',  // ❌ This is the customer endpoint
```

**TO:**
```dart
final response = await _dio.post(
  '/v1/provider/profile/image',  // ✅ Use provider-specific endpoint
```

---

## Step-by-Step Implementation

### Step 1: Update Backend Controller
1. Open `backend/app/Http/Controllers/API/V1/Provider/ProviderController.php`
2. Add the `uploadProfileImage` method (from Fix 1)
3. Update the `uploadCertification` method (from Fix 2)
4. Save the file

### Step 2: Update Backend Routes
1. Open `backend/routes/api.php`
2. Add the route for provider profile image upload (from Fix 3)
3. Save the file

### Step 3: Update Frontend Service
1. Open `lib/features/provider_panel/data/services/provider_upload_service.dart`
2. Change the endpoint from `/v1/profile/image` to `/v1/provider/profile/image` (from Fix 4)
3. Save the file

### Step 4: Restart Backend
```bash
cd backend
./vendor/bin/sail down
./vendor/bin/sail up -d
```

### Step 5: Restart Frontend
```bash
# Stop the current Flutter web server (Ctrl+C)
flutter clean
flutter pub get
flutter run -d chrome
```

---

## Testing Checklist

After implementing the fixes, test the following:

### ✅ Provider Profile Photo Upload
1. Login as a provider
2. Go to provider profile section
3. Click on profile photo upload
4. Select an image
5. Verify upload succeeds without "_Namespace" error
6. Verify image displays correctly

### ✅ Provider Certificate Upload
1. Login as a provider
2. Go to certifications section
3. Click to upload a certificate
4. Enter certificate name
5. Select an image/document
6. Verify upload succeeds without "_Namespace" error
7. Verify certificate appears in the list

### ✅ Customer Profile Photo Upload (Already Fixed)
1. Login as a customer
2. Go to profile section
3. Upload profile photo
4. Verify it still works correctly

---

## Why These Changes Work

1. **Base64 Encoding**: The frontend now uses `PlatformImage` which works on both web and desktop by converting images to base64 strings.

2. **Backend Compatibility**: The backend needs to accept base64 strings instead of file uploads. The `Base64Image` validation rule handles:
   - Validating base64 format
   - Checking file size
   - Verifying image format (JPEG, PNG, HEIC)
   - No minimum size requirement

3. **Separate Endpoints**: Provider and customer endpoints are separate to maintain proper authorization and role-based access control.

---

## Common Issues & Solutions

### Issue: "Validation failed" error
**Solution**: Make sure the `Base64Image` rule is imported at the top of the controller:
```php
use App\Rules\Base64Image;
```

### Issue: Images not displaying after upload
**Solution**: Check that the storage link is created:
```bash
cd backend
./vendor/bin/sail artisan storage:link
```

### Issue: Still getting "_Namespace" error
**Solution**: 
1. Make sure you did a full restart (not hot reload)
2. Clear browser cache
3. Check that the frontend is using the correct endpoint

### Issue: "File too large" error
**Solution**: The max size is set to 50MB (51200 KB). If you need larger files, increase the value in the `Base64Image` constructor.

---

## Summary

The fixes involve:
1. ✅ Adding a new `uploadProfileImage` method for providers
2. ✅ Updating `uploadCertification` to accept base64 instead of file uploads
3. ✅ Adding the route for provider profile image upload
4. ✅ Fixing the frontend endpoint to use `/v1/provider/profile/image`

All changes follow the same pattern used for the customer profile upload fix, ensuring consistency across the application.
