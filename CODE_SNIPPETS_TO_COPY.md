# Ready-to-Copy Code Snippets

## 📋 Snippet 1: Add to ProviderController.php (after line 420)

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

## 📋 Snippet 2: Replace in ProviderController.php uploadCertification() method

**FIND THIS CODE** (around line 430-440):
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

**REPLACE WITH THIS CODE**:
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

## 📋 Snippet 3: Add to routes/api.php (in provider section)

**FIND THIS SECTION** (around line 80-100):
```php
// Provider routes
Route::middleware(['auth:api', 'role:serviceProvider'])->prefix('provider')->group(function () {
    Route::get('/profile', [ProviderController::class, 'getProfile']);
    Route::put('/profile', [ProviderController::class, 'updateProfile']);
    // ... other routes
});
```

**ADD THIS LINE**:
```php
Route::post('/profile/image', [ProviderController::class, 'uploadProfileImage']);
```

**FULL EXAMPLE**:
```php
// Provider routes
Route::middleware(['auth:api', 'role:serviceProvider'])->prefix('provider')->group(function () {
    Route::get('/profile', [ProviderController::class, 'getProfile']);
    Route::put('/profile', [ProviderController::class, 'updateProfile']);
    Route::post('/profile/image', [ProviderController::class, 'uploadProfileImage']); // ← ADD THIS
    Route::post('/certifications/upload', [ProviderController::class, 'uploadCertification']);
    // ... other routes
});
```

---

## 📋 Snippet 4: Update provider_upload_service.dart

**FIND THIS CODE** (around line 20):
```dart
final response = await _dio.post(
  '/v1/profile/image',
```

**CHANGE TO**:
```dart
final response = await _dio.post(
  '/v1/provider/profile/image',
```

**FULL METHOD**:
```dart
Future<String> uploadProfilePhoto(
  PlatformImage image, {
  void Function(double progress)? onProgress,
}) async {
  // Convert PlatformImage to base64
  final base64String = await _imageService.imageToBase64(image);

  // Upload with progress tracking
  final response = await _dio.post(
    '/v1/provider/profile/image',  // ← CHANGED THIS LINE
    data: FormData.fromMap({
      'image': base64String,
    }),
    onSendProgress: (sent, total) {
      if (onProgress != null && total > 0) {
        onProgress(sent / total);
      }
    },
  );

  final body = response.data;
  if (body is Map<String, dynamic> && body['success'] == true) {
    final imageUrl = body['data']['image_url'] ?? body['data']['url'];
    if (imageUrl != null) {
      return imageUrl as String;
    }
  }
  throw Exception(
    body is Map ? (body['message'] ?? 'Upload failed') : 'Upload failed',
  );
}
```

---

## 🔄 Restart Commands

### Backend:
```bash
cd backend
./vendor/bin/sail down
./vendor/bin/sail up -d
```

### Frontend:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

---

## ✅ Done!

After applying all 4 snippets and restarting:
- Provider profile photo upload will work on web ✅
- Provider certificate upload will work on web ✅
- No more "_Namespace" errors ✅
