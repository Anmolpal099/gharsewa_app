# Debug Image Upload - Enhanced Logging

## Changes Made

### Added Detailed Logging
Both `ProviderController` and `CustomerController` now have enhanced logging for image uploads:

1. **Upload Start**: Logs when upload begins with user ID and request size
2. **Validation**: Logs validation errors if any
3. **Data Extraction**: Logs MIME type and data length after extraction
4. **Database Update**: Logs success/failure of database update
5. **Error Details**: Logs full exception details including file and line number

### Error Message Improvement
- Now returns actual error message to frontend: `"Failed to upload profile image: {actual_error}"`
- This helps identify the exact problem

## How to Debug

### Step 1: Try Uploading Again
1. Open the app
2. Try uploading a profile photo (provider or customer)
3. Watch for the error message

### Step 2: Check Laravel Logs
```bash
# Watch logs in real-time
Get-Content backend\storage\logs\laravel.log -Tail 50 -Wait
```

Or after upload:
```bash
Get-Content backend\storage\logs\laravel.log -Tail 100
```

### Step 3: Look for These Log Entries

**Success Flow**:
```
[INFO] Profile image upload started
[INFO] Image data extracted
[INFO] Provider/Customer profile image uploaded to database
```

**Error Flow**:
```
[INFO] Profile image upload started
[ERROR] Profile image validation failed
OR
[ERROR] Failed to update user with image data
OR
[ERROR] Failed to upload provider/customer profile image
```

### Step 4: Check Error Message in Frontend
The error message now shows the actual problem, for example:
- "Failed to upload profile image: Column 'profile_image_data' not found"
- "Failed to upload profile image: SQLSTATE[42S22]: Column not found"
- "Failed to upload profile image: Validation failed"

## Common Issues & Solutions

### Issue 1: Column Not Found
**Error**: `Column 'profile_image_data' not found`

**Solution**:
```bash
cd backend
./vendor/bin/sail artisan migrate:fresh --seed
# OR
./vendor/bin/sail artisan migrate --force
```

### Issue 2: Mass Assignment Error
**Error**: `Add [profile_image_data] to fillable property`

**Solution**: Already fixed - added to User model's `$fillable` array

### Issue 3: Validation Failed
**Error**: `The image field is required` or `Invalid base64 image`

**Solution**: Check frontend is sending correct format:
```json
{
  "image": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
}
```

### Issue 4: Database Connection
**Error**: `SQLSTATE[HY000] [2002] Connection refused`

**Solution**:
```bash
./vendor/bin/sail up -d
./vendor/bin/sail restart
```

### Issue 5: Permission Denied
**Error**: `Permission denied` or `Access denied`

**Solution**:
```bash
./vendor/bin/sail artisan cache:clear
./vendor/bin/sail artisan config:clear
```

## Test Upload Now

1. **Clear browser cache**: Ctrl+Shift+R
2. **Try uploading** a small image (< 1MB)
3. **Check the error message** - it will now show the actual problem
4. **Check Laravel logs** - detailed logging will show where it fails

## If Still Failing

### Get Detailed Error
1. Upload an image
2. Copy the exact error message from the frontend
3. Check Laravel logs:
```bash
Get-Content backend\storage\logs\laravel.log -Tail 100 | Select-String -Pattern "ERROR|exception"
```

### Verify Database Columns
```bash
cd backend
./vendor/bin/sail mysql
```
Then in MySQL:
```sql
USE gharsewa;
DESCRIBE users;
```
Look for:
- `profile_image_data` (longtext)
- `profile_image_mime_type` (varchar)

### Check User Model
Verify `backend/app/Models/User.php` has:
```php
protected $fillable = [
    // ...
    'profile_image_data',
    'profile_image_mime_type',
    // ...
];
```

### Force Migration
```bash
cd backend
./vendor/bin/sail artisan migrate:fresh
# WARNING: This will delete all data!
```

Or safer:
```bash
./vendor/bin/sail artisan migrate --force
```

## Next Steps

After trying to upload:
1. **Copy the error message** from the frontend
2. **Check Laravel logs** for detailed error
3. **Share the error** so I can provide specific fix

The enhanced logging will now show exactly what's failing!
