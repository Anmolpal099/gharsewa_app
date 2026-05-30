# Test Image Upload & Display

## Quick Test Steps

### 1. Test Profile Photo Upload (Provider)

**Upload**:
1. Login as provider
2. Go to Profile screen
3. Click "Change photo"
4. Select an image
5. Watch for "Profile photo updated" message

**Verify Upload**:
- Check browser console for any errors
- Check network tab for the upload request
- Response should contain `image_url` with `data:image/...` format

**Verify Display**:
- Image should appear immediately in profile header
- Refresh the page - image should still be there
- Check browser console for any image loading errors

### 2. Test Profile Photo Upload (Customer)

Same steps as provider but in customer panel.

### 3. Test Certificate Upload (Provider)

**Upload**:
1. Login as provider
2. Go to Profile screen
3. Scroll to "Certifications" section
4. Click upload icon
5. Enter certificate name
6. Select image
7. Watch for "Certification uploaded" message

**Verify**:
- Certificate should appear in list with "Pending" status
- Click on certificate - should open/display (not 404)
- Refresh page - certificate should still be there

## Debug Checklist

### Backend Issues

**Check if migration ran**:
```bash
cd backend
./vendor/bin/sail artisan migrate:status
```
Look for: `2026_05_30_163622_add_profile_image_data_to_users_table`

**Check database columns**:
```bash
./vendor/bin/sail mysql -e "DESCRIBE users;" | grep profile_image
```
Should show:
- `profile_image_url`
- `profile_image_data`
- `profile_image_mime_type`

**Check if data is being saved**:
```bash
./vendor/bin/sail mysql -e "SELECT id, name, LENGTH(profile_image_data) as data_length, profile_image_mime_type FROM users WHERE profile_image_data IS NOT NULL LIMIT 3;"
```

**Check Laravel logs**:
```bash
tail -f backend/storage/logs/laravel.log
```
Look for: "Profile image uploaded to database"

### Frontend Issues

**Check browser console**:
- Open DevTools (F12)
- Go to Console tab
- Look for errors related to images

**Check network requests**:
- Open DevTools (F12)
- Go to Network tab
- Upload an image
- Look for the POST request to `/api/v1/provider/profile/image` or `/api/v1/profile/image`
- Check the response - should contain `image_url` with `data:image/jpeg;base64,...`

**Check state refresh**:
- After upload, check if `fetchProfile(forceRefresh: true)` is called
- Look in network tab for GET request to `/api/v1/provider/profile` or `/api/v1/profile`
- Response should contain `profile_image_url` with data URL

### Common Issues

**Issue 1: "Profile photo updated" but image not showing**
- **Cause**: State not refreshing after upload
- **Fix**: Check if `fetchProfile(forceRefresh: true)` is called in `profile_manager.dart`
- **Verify**: Look at network tab - should see GET request after POST

**Issue 2: Image shows broken/blank**
- **Cause**: Data URL format incorrect or too large
- **Fix**: Check response format - should be `data:image/jpeg;base64,{base64_string}`
- **Verify**: Copy `image_url` from response and paste in browser address bar - should display image

**Issue 3: 404 error on certificates**
- **Cause**: Certificate URL not being converted to data URL
- **Fix**: Check `processCertificationUrls()` method in ProviderController
- **Verify**: Check GET `/api/v1/provider/profile` response - certificates should have `document_url` with data URL

**Issue 4: Upload fails silently**
- **Cause**: Validation error or database error
- **Fix**: Check Laravel logs for errors
- **Verify**: Look at network tab response - should have `success: true`

**Issue 5: Image too large error**
- **Cause**: Image exceeds 50MB limit
- **Fix**: Compress image before upload or increase limit
- **Verify**: Check file size before upload

## Manual API Test

### Test Upload Endpoint

```bash
# Get auth token first
TOKEN="your_jwt_token_here"

# Create a small test image (1x1 pixel red PNG)
BASE64_IMAGE="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

# Test provider upload
curl -X POST http://localhost:8000/api/v1/provider/profile/image \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"image\": \"$BASE64_IMAGE\"}"

# Test customer upload
curl -X POST http://localhost:8000/api/v1/profile/image \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"image\": \"$BASE64_IMAGE\"}"
```

### Test Retrieval Endpoint

```bash
# Get provider profile
curl -X GET http://localhost:8000/api/v1/provider/profile \
  -H "Authorization: Bearer $TOKEN"

# Get customer profile
curl -X GET http://localhost:8000/api/v1/profile \
  -H "Authorization: Bearer $TOKEN"
```

Expected response:
```json
{
  "success": true,
  "data": {
    "id": "...",
    "name": "...",
    "profile_image_url": "data:image/png;base64,iVBORw0KG..."
  }
}
```

## Frontend State Check

### Check Profile Manager State

Add debug logging to `profile_manager.dart`:

```dart
Future<void> updateProfilePhoto(
  PlatformImage image, {
  void Function(double progress)? onProgress,
}) async {
  print('DEBUG: Starting profile photo upload');
  await _uploads.uploadProfilePhoto(image, onProgress: onProgress);
  print('DEBUG: Upload complete, refreshing profile');
  await fetchProfile(forceRefresh: true);
  print('DEBUG: Profile refreshed, new state: ${state.value?.photoUrl}');
}
```

### Check Upload Service Response

Add debug logging to `provider_upload_service.dart`:

```dart
Future<String> uploadProfilePhoto(
  PlatformImage image, {
  void Function(double progress)? onProgress,
}) async {
  final base64String = await _imageService.imageToBase64(image);
  print('DEBUG: Uploading image, size: ${base64String.length}');
  
  final response = await _dio.post(...);
  print('DEBUG: Upload response: ${response.data}');
  
  final imageUrl = body['data']['image_url'];
  print('DEBUG: Image URL: ${imageUrl?.substring(0, 50)}...');
  return imageUrl;
}
```

## Success Criteria

✅ Upload shows "Profile photo updated" message
✅ Image displays immediately after upload
✅ Image persists after page refresh
✅ No errors in browser console
✅ No 404 errors for certificates
✅ Network tab shows successful POST and GET requests
✅ Response contains `profile_image_url` with data URL format
✅ Data URL starts with `data:image/jpeg;base64,` or similar

## If Still Not Working

1. **Clear all caches**:
```bash
cd backend
./vendor/bin/sail artisan cache:clear
./vendor/bin/sail artisan config:clear
./vendor/bin/sail artisan route:clear
./vendor/bin/sail restart
```

2. **Clear browser cache**:
- Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
- Or clear browser cache completely

3. **Restart Flutter app**:
```bash
# Stop the app
# Then run:
flutter clean
flutter pub get
flutter run -d chrome
```

4. **Check database directly**:
```bash
./vendor/bin/sail mysql
USE gharsewa;
SELECT id, name, LENGTH(profile_image_data), profile_image_mime_type FROM users WHERE id = 'your_user_id';
```

5. **Enable verbose logging**:
Add to `.env`:
```
LOG_LEVEL=debug
APP_DEBUG=true
```

Then check logs:
```bash
tail -f backend/storage/logs/laravel.log
```
