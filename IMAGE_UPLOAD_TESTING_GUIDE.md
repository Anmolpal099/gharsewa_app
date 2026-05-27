# Image Upload Testing Guide
**Quick Reference for Testing Image Upload Fixes**

---

## Quick Test Commands

### 1. Verify PHP Configuration
```bash
cd backend
php -i | grep -E "upload_max_filesize|post_max_size|memory_limit|max_execution_time"
```

**Expected Output:**
```
upload_max_filesize => 50M => 50M
post_max_size => 50M => 50M
memory_limit => 256M => 256M
max_execution_time => 300 => 300
```

### 2. Check Storage Permissions
```bash
cd backend
ls -la storage/app/public/
```

**Expected:** Directories should be writable (775 or 777)

### 3. Clear Laravel Cache
```bash
cd backend
php artisan config:clear
php artisan cache:clear
php artisan route:clear
```

---

## Manual Testing Checklist

### AI Visual Assistant (Customer Panel)

#### Test 1: Standard JPEG Upload
- [ ] Open AI Visual Assistant
- [ ] Click "Take Photo" or "Select from Gallery"
- [ ] Select a JPEG image (< 5MB)
- [ ] Verify image loads in annotation screen
- [ ] Add markers and submit
- [ ] Verify consultation is created successfully

#### Test 2: Large Image Upload
- [ ] Select a large image (10-20MB)
- [ ] Verify upload progress shows
- [ ] Verify image is compressed automatically
- [ ] Verify consultation is created

#### Test 3: Alternative Formats
- [ ] Test PNG image
- [ ] Test HEIC image (iPhone photo)
- [ ] Test WebP image
- [ ] Test BMP image
- [ ] Verify all formats work

#### Test 4: Error Handling
- [ ] Try uploading a non-image file (should fail gracefully)
- [ ] Try uploading on slow connection (should show progress)
- [ ] Verify error messages are clear

---

### Profile Photo Upload (Provider Panel)

#### Test 1: Standard Upload
- [ ] Go to Provider Profile
- [ ] Click profile photo area
- [ ] Select an image from gallery
- [ ] Verify upload progress shows
- [ ] Verify photo updates successfully

#### Test 2: Large Photo
- [ ] Select a large photo (> 5MB)
- [ ] Verify compression works
- [ ] Verify upload completes
- [ ] Verify photo displays correctly

#### Test 3: Different Formats
- [ ] Test JPEG
- [ ] Test PNG with transparency
- [ ] Test HEIC
- [ ] Test WebP

---

### Certification Upload (Provider Panel)

#### Test 1: PDF Upload
- [ ] Go to Provider Profile
- [ ] Click "Add Certification"
- [ ] Enter certification name
- [ ] Select a PDF file
- [ ] Verify upload progress
- [ ] Verify certification appears in list

#### Test 2: Image Certificate
- [ ] Upload PNG certificate
- [ ] Upload JPEG certificate
- [ ] Verify both work

#### Test 3: Large File
- [ ] Upload a large PDF (> 10MB)
- [ ] Verify upload completes
- [ ] Verify file is accessible

---

## API Testing with cURL

### Test AI Consultation Upload

```bash
# 1. Login and get JWT token
TOKEN=$(curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.com","password":"password"}' \
  | jq -r '.data.access_token')

# 2. Convert image to base64
BASE64_IMAGE=$(base64 -w 0 test-image.jpg)

# 3. Create consultation
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"image\": \"$BASE64_IMAGE\",
    \"markers\": [
      {\"x\": 100, \"y\": 100, \"label\": \"Test\", \"description\": \"Test marker\"}
    ]
  }" | jq
```

### Test Profile Photo Upload

```bash
# 1. Login
TOKEN=$(curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{"email":"provider@example.com","password":"password"}' \
  | jq -r '.data.access_token')

# 2. Upload profile photo
curl -X POST http://localhost:8000/api/v1/profile/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@test-photo.jpg" | jq
```

### Test Certification Upload

```bash
# 1. Login as provider
TOKEN=$(curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{"email":"provider@example.com","password":"password"}' \
  | jq -r '.data.access_token')

# 2. Upload certification
curl -X POST http://localhost:8000/api/v1/provider/certifications/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "name=Test Certification" \
  -F "document=@certificate.pdf" | jq
```

---

## Monitoring During Tests

### Watch Laravel Logs
```bash
# Terminal 1: Watch logs in real-time
cd backend
tail -f storage/logs/laravel.log
```

### Monitor Storage Usage
```bash
# Terminal 2: Watch storage size
watch -n 5 'du -sh backend/storage/app/public/*'
```

### Check PHP Errors
```bash
# Check PHP error log
tail -f /var/log/php-fpm/error.log
# or
tail -f /var/log/apache2/error.log
```

---

## Expected Results

### Successful Upload Response (AI Consultation)
```json
{
  "success": true,
  "message": "Consultation created successfully",
  "data": {
    "consultation": {
      "id": "uuid-here",
      "image_url": "http://localhost:8000/storage/consultations/user-id/filename.jpg",
      "diagnosis": "AI diagnosis text",
      "recommended_service_type": "plumbing",
      "cost_min": 50,
      "cost_max": 150,
      "processing_time_ms": 1234
    }
  }
}
```

### Successful Upload Response (Profile Photo)
```json
{
  "success": true,
  "message": "Profile image uploaded successfully",
  "data": {
    "image_url": "/storage/profile-images/filename.jpg",
    "path": "profile-images/filename.jpg"
  }
}
```

### Successful Upload Response (Certification)
```json
{
  "success": true,
  "message": "Certification uploaded successfully",
  "data": {
    "id": "uuid-here",
    "name": "Test Certification",
    "document_url": "http://localhost:8000/storage/certifications/user-id/filename.pdf",
    "file_type": "PDF",
    "is_verified": false,
    "uploaded_at": "2024-01-01T00:00:00Z"
  }
}
```

---

## Troubleshooting Quick Fixes

### Issue: 413 Request Entity Too Large
```bash
# Check Nginx config
sudo nginx -t
# Edit config
sudo nano /etc/nginx/sites-available/default
# Add: client_max_body_size 50M;
sudo systemctl reload nginx
```

### Issue: 500 Internal Server Error
```bash
# Check Laravel logs
tail -n 50 backend/storage/logs/laravel.log

# Check permissions
cd backend
chmod -R 775 storage bootstrap/cache
```

### Issue: Image Not Displaying
```bash
# Create storage symlink
cd backend
php artisan storage:link

# Verify symlink
ls -la public/storage
```

### Issue: Compression Fails
```bash
# Check GD library
php -m | grep -i gd

# If missing, install:
# Ubuntu/Debian:
sudo apt-get install php-gd
# CentOS/RHEL:
sudo yum install php-gd

# Restart PHP-FPM
sudo systemctl restart php-fpm
```

---

## Performance Benchmarks

Record these metrics during testing:

| Test Case | File Size | Upload Time | Compression | Status |
|-----------|-----------|-------------|-------------|--------|
| JPEG < 5MB | 2.3 MB | 1.2s | No | ✅ |
| PNG < 5MB | 4.1 MB | 1.8s | No | ✅ |
| HEIC < 5MB | 3.5 MB | 1.5s | No | ✅ |
| Large JPEG | 12 MB | 4.2s | Yes | ✅ |
| Large PNG | 18 MB | 6.1s | Yes | ✅ |
| WebP | 1.8 MB | 0.9s | No | ✅ |

**Target Metrics:**
- Upload time < 5s for files < 10MB
- Upload time < 10s for files < 50MB
- Compression success rate > 95%
- Overall success rate > 99%

---

## Sign-Off Checklist

Before marking as complete:

- [ ] All test scenarios passed
- [ ] No errors in Laravel logs
- [ ] Storage permissions correct
- [ ] PHP configuration verified
- [ ] Server configuration updated
- [ ] Performance benchmarks acceptable
- [ ] Error messages are user-friendly
- [ ] Documentation updated
- [ ] Team notified of changes

---

**Testing Date:** _____________  
**Tested By:** _____________  
**Status:** ⬜ Pass ⬜ Fail ⬜ Needs Review  
**Notes:** _____________________________________________
