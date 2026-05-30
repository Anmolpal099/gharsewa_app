# Database Image Storage Implementation

## Overview
Images (profile photos and certificates) are now stored **directly in the database** as base64-encoded data instead of on the filesystem. This ensures images are always available and display immediately after upload.

## Changes Made

### 1. Database Migration
Created migration to add columns to `users` table:
- `profile_image_data` (LONGTEXT) - Stores base64-encoded image data
- `profile_image_mime_type` (VARCHAR) - Stores MIME type (e.g., 'image/jpeg', 'image/png')

**File**: `backend/database/migrations/2026_05_30_163622_add_profile_image_data_to_users_table.php`

### 2. Profile Image Upload (Provider & Customer)

**Endpoints**:
- `POST /api/v1/provider/profile/image` (Provider)
- `POST /api/v1/profile/image` (Customer)

**How it works**:
1. Receives base64 image from frontend
2. Extracts MIME type from data URI (e.g., `data:image/jpeg;base64,...`)
3. Stores base64 data in `profile_image_data` column
4. Stores MIME type in `profile_image_mime_type` column
5. Clears old `profile_image_url` (filesystem path)
6. Returns data URL: `data:image/jpeg;base64,{base64_data}`

**Response**:
```json
{
  "success": true,
  "data": {
    "image_url": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "url": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  },
  "message": "Profile image uploaded successfully"
}
```

### 3. Certificate Upload (Provider)

**Endpoint**: `POST /api/v1/provider/certifications/upload`

**How it works**:
1. Receives base64 image + certificate name
2. Extracts MIME type from data URI
3. Stores in `metadata.certifications` array with:
   - `document_data`: base64 image data
   - `mime_type`: MIME type
   - `document_url`: data URL for immediate display
   - `is_verified`: false (pending admin approval)
4. Returns certificate object with data URL

**Metadata Structure**:
```json
{
  "certifications": [
    {
      "id": "uuid",
      "name": "Certificate Name",
      "document_url": "data:image/jpeg;base64,...",
      "document_data": "base64_string",
      "mime_type": "image/jpeg",
      "file_type": "JPG",
      "is_verified": false,
      "uploaded_at": "2026-05-30T16:36:22.000000Z",
      "verified_at": null
    }
  ]
}
```

### 4. Profile Retrieval (Provider & Customer)

**Endpoints**:
- `GET /api/v1/provider/profile` (Provider)
- `GET /api/v1/profile` (Customer)

**How it works**:
1. Checks if `profile_image_data` exists in database
2. If yes: Returns data URL: `data:{mime_type};base64,{data}`
3. If no: Falls back to old `profile_image_url` (filesystem) for backward compatibility
4. For certificates: Converts all `document_data` to data URLs

**Response**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "profile_image_url": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "metadata": {
      "certifications": [
        {
          "document_url": "data:image/jpeg;base64,..."
        }
      ]
    }
  }
}
```

## Helper Methods

### ProviderController & CustomerController

**`getProfileImageUrl($user)`**:
- Priority 1: Returns data URL from `profile_image_data` if exists
- Priority 2: Returns filesystem URL from `profile_image_url` (legacy)
- Returns null if no image

**`processCertificationUrls($metadata)`** (Provider only):
- Converts all certificate `document_data` to data URLs
- Handles legacy filesystem-based certificates
- Ensures all certificates have valid `document_url`

## Data Flow

### Upload Flow:
```
Frontend (base64) 
  → Backend Controller
  → Database (profile_image_data column)
  → Response (data URL)
  → Frontend displays immediately
```

### Retrieval Flow:
```
Frontend requests profile
  → Backend reads from database
  → Converts base64 to data URL
  → Response with data URL
  → Frontend displays image
```

## Advantages

✅ **Images always available** - No filesystem dependencies
✅ **Immediate display** - No need to wait for file writes
✅ **No 404 errors** - Images are in database, always accessible
✅ **Automatic refresh** - Profile updates include latest image data
✅ **Cross-platform** - Works on web and desktop without filesystem access
✅ **Backup friendly** - Images backed up with database
✅ **No symlink issues** - No need for storage:link command

## Database Storage

### Profile Images
- Stored in: `users.profile_image_data` (LONGTEXT)
- MIME type: `users.profile_image_mime_type` (VARCHAR)
- Format: Base64-encoded string
- Max size: ~50MB (configurable in validation)

### Certificates
- Stored in: `users.metadata.certifications[].document_data` (JSON)
- MIME type: `users.metadata.certifications[].mime_type` (JSON)
- Format: Base64-encoded string
- Max size: ~50MB per certificate

## Backward Compatibility

The system maintains backward compatibility with old filesystem-based images:
- If `profile_image_data` exists → Use database image (new)
- If `profile_image_url` exists → Use filesystem image (old)
- Both can coexist during migration period

## Frontend Integration

No changes needed in frontend! The frontend already:
- Sends base64 images via `ImageService`
- Receives data URLs in responses
- Displays images using `Image.network()` or `ImageDisplayWidget`
- Handles data URLs natively (browsers support `data:` URIs)

## Testing Checklist

✅ Upload profile photo (customer) - should display immediately
✅ Upload profile photo (provider) - should display immediately
✅ Refresh page - images should persist
✅ Upload certificate - should display in list
✅ Click certificate - should open/display (no 404)
✅ Multiple uploads - should replace old image
✅ Large images - should handle up to 50MB
✅ Different formats - JPG, PNG, WebP, etc.

## Performance Considerations

**Pros**:
- No filesystem I/O during retrieval
- No symlink management
- Atomic operations (database transactions)
- Easier to scale (database replication)

**Cons**:
- Larger database size
- Slightly larger API responses (base64 is ~33% larger than binary)
- Database backup size increases

**Mitigation**:
- Use database compression (InnoDB compression)
- Consider CDN for frequently accessed images (future)
- Implement image optimization before storage (future)

## Files Modified

1. `backend/database/migrations/2026_05_30_163622_add_profile_image_data_to_users_table.php` (NEW)
2. `backend/app/Http/Controllers/API/V1/Provider/ProviderController.php`
3. `backend/app/Http/Controllers/API/V1/Customer/CustomerController.php`

## Database Schema

```sql
ALTER TABLE users 
ADD COLUMN profile_image_data LONGTEXT NULL AFTER profile_image_url,
ADD COLUMN profile_image_mime_type VARCHAR(50) NULL AFTER profile_image_data;
```

## Next Steps

1. ✅ Test profile photo upload/display (customer & provider)
2. ✅ Test certificate upload/display
3. ✅ Verify images persist after page refresh
4. ✅ Test on both web and desktop platforms
5. 🔄 Optional: Migrate existing filesystem images to database
6. 🔄 Optional: Add image compression before storage
7. 🔄 Optional: Implement certificate approval workflow

## Migration Script (Optional)

To migrate existing filesystem images to database:

```php
// Run this artisan command to migrate old images
php artisan tinker

$users = \App\Models\User::whereNotNull('profile_image_url')->get();
foreach ($users as $user) {
    $path = storage_path('app/public/' . $user->profile_image_url);
    if (file_exists($path)) {
        $imageData = base64_encode(file_get_contents($path));
        $mimeType = mime_content_type($path);
        $user->update([
            'profile_image_data' => $imageData,
            'profile_image_mime_type' => $mimeType,
        ]);
        echo "Migrated: {$user->name}\n";
    }
}
```

## Troubleshooting

**Issue**: Images not displaying after upload
**Solution**: Check browser console for errors, verify data URL format

**Issue**: "Payload too large" error
**Solution**: Increase `upload_max_filesize` and `post_max_size` in php.ini

**Issue**: Database size growing too large
**Solution**: Enable InnoDB compression or implement image optimization

**Issue**: Old images still showing
**Solution**: Clear browser cache and refresh profile
