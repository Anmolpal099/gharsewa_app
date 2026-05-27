# AI Visual Assistant - Troubleshooting Guide

## Overview

This guide provides solutions to common issues encountered with the AI Visual Assistant feature.

## Quick Diagnostics

### Health Check Commands

```bash
# Check all services
docker ps

# Check Laravel application
curl http://localhost:8000/api/health

# Check Ollama service
curl http://localhost:11434/api/tags

# Check database connection
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password -e "SELECT 1"

# Check storage permissions
ls -la backend/storage/app/public/consultations
```

## Backend Issues

### Issue 1: Consultation Creation Fails

**Symptoms**:
- 500 Internal Server Error
- "Failed to create consultation" message
- No consultation record in database

**Diagnosis**:

```bash
# Check Laravel logs
tail -f backend/storage/logs/laravel.log

# Check PHP-FPM logs
tail -f /var/log/php8.2-fpm.log

# Check Nginx error logs
tail -f /var/log/nginx/error.log
```

**Common Causes & Solutions**:

#### Cause 1: Ollama Service Not Running

```bash
# Check Ollama status
docker ps | grep ollama

# If not running, start it
docker-compose -f docker-compose.ollama.yml up -d

# Verify model is loaded
docker exec gharsewa_ollama ollama list
```

#### Cause 2: Database Connection Failed

```bash
# Test database connection
php artisan tinker
>>> DB::connection()->getPdo();

# If fails, check .env settings
cat backend/.env | grep DB_

# Test MySQL directly
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SHOW TABLES;"
```

#### Cause 3: Storage Permission Issues

```bash
# Fix storage permissions
cd backend
chmod -R 775 storage
chown -R www-data:www-data storage

# Recreate storage link
php artisan storage:link
```

#### Cause 4: Image Too Large

**Error**: "The image must not be greater than 10240 kilobytes"

**Solution**:
- Increase `upload_max_filesize` in php.ini
- Increase `post_max_size` in php.ini
- Increase `client_max_body_size` in nginx.conf

```bash
# Edit PHP configuration
sudo nano /etc/php/8.2/fpm/php.ini

# Set values
upload_max_filesize = 15M
post_max_size = 15M

# Restart PHP-FPM
sudo systemctl restart php8.2-fpm

# Edit Nginx configuration
sudo nano /etc/nginx/sites-available/gharsewa

# Add in server block
client_max_body_size 15M;

# Restart Nginx
sudo systemctl restart nginx
```

### Issue 2: AI Analysis Timeout

**Symptoms**:
- Request takes > 30 seconds
- "AI service timeout" error
- Ollama logs show slow processing

**Diagnosis**:

```bash
# Check Ollama logs
docker logs gharsewa_ollama --tail 100

# Check system resources
top
free -h
df -h

# Check GPU usage (if applicable)
nvidia-smi
```


**Solutions**:

#### Solution 1: Increase Timeout

```bash
# Edit .env
OLLAMA_TIMEOUT=90

# Clear config cache
php artisan config:clear
php artisan config:cache
```

#### Solution 2: Optimize Ollama

```bash
# Use GPU if available
docker-compose -f docker-compose.ollama.yml down
# Edit docker-compose.ollama.yml to enable GPU
docker-compose -f docker-compose.ollama.yml up -d

# Reduce concurrent requests
# Add rate limiting in Laravel
```

#### Solution 3: Reduce Image Size

Images > 5MB are automatically compressed, but you can adjust:

```php
// In VisionAIService.php
private function compressImage($imagePath) {
    // Reduce max dimensions
    $maxWidth = 1280;  // Instead of 1920
    $maxHeight = 1280;
    // Reduce quality
    $quality = 75;  // Instead of 85
}
```

### Issue 3: Provider Recommendations Empty

**Symptoms**:
- AI analysis succeeds
- No providers in `recommended_providers` array
- "No providers available" message

**Diagnosis**:

```bash
# Check if providers exist
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa \
  -e "SELECT COUNT(*) FROM users WHERE role='provider' AND status='active';"

# Check service types
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa \
  -e "SELECT DISTINCT service_type FROM provider_services;"
```

**Solutions**:

#### Solution 1: Add Test Providers

```bash
# Create test provider
php artisan tinker
>>> $user = User::create([
    'name' => 'Test Provider',
    'email' => 'provider@test.com',
    'password' => Hash::make('password'),
    'role' => 'provider',
    'status' => 'active',
]);
>>> $user->providerProfile()->create([
    'service_types' => ['Plumbing Repair', 'Electrical Work'],
    'rating' => 4.5,
]);
```

#### Solution 2: Fix Service Type Matching

Check that AI returns valid service types:

```php
// Valid service types
$validTypes = [
    'Plumbing Repair',
    'Electrical Work',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Appliance Repair',
    'HVAC',
    'Pest Control',
    'Landscaping',
    'General Maintenance',
];
```

### Issue 4: Images Not Displaying

**Symptoms**:
- Consultation created successfully
- `image_url` is null or broken
- 404 error when accessing image URL

**Diagnosis**:

```bash
# Check if image file exists
ls -la backend/storage/app/public/consultations/

# Check storage link
ls -la backend/public/storage

# Check image URL in database
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa \
  -e "SELECT id, image_path FROM ai_consultations LIMIT 5;"
```

**Solutions**:

#### Solution 1: Recreate Storage Link

```bash
cd backend
rm public/storage
php artisan storage:link
```

#### Solution 2: Fix Image Path Generation

```php
// In AIConsultation model
public function getImageUrlAttribute() {
    if (!$this->image_path) {
        return null;
    }
    return Storage::disk('public')->url($this->image_path);
}
```

#### Solution 3: Check File Permissions

```bash
chmod -R 775 backend/storage/app/public/consultations
chown -R www-data:www-data backend/storage/app/public/consultations
```

### Issue 5: Rate Limiting Too Strict

**Symptoms**:
- 429 Too Many Requests error
- Users blocked after few requests
- "Too many requests" message

**Diagnosis**:

```bash
# Check rate limit configuration
grep -r "throttle" backend/routes/api.php

# Check Redis (if using Redis for rate limiting)
redis-cli
> KEYS *throttle*
```

**Solutions**:

#### Solution 1: Adjust Rate Limit

```php
// In routes/api.php
Route::middleware(['auth:api', 'throttle:20,1'])->group(function () {
    // Changed from 10 to 20 requests per minute
});
```

#### Solution 2: Clear Rate Limit Cache

```bash
# If using Redis
redis-cli FLUSHDB

# If using file cache
php artisan cache:clear
```

## Flutter Issues

### Issue 6: Camera Not Opening

**Symptoms**:
- "Take Photo" button does nothing
- Camera permission denied
- App crashes when accessing camera

**Diagnosis**:

Check device logs:

```bash
# Android
adb logcat | grep -i camera

# iOS
# Check Xcode console
```

**Solutions**:

#### Solution 1: Grant Permissions

**Android**:
```
Settings → Apps → Gharsewa → Permissions → Camera → Allow
```

**iOS**:
```
Settings → Gharsewa → Camera → Enable
```

#### Solution 2: Check Manifest/Info.plist

Ensure permissions are declared (see Deployment Guide).

#### Solution 3: Request Permissions Programmatically

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isDenied) {
    // Show dialog to open settings
    await openAppSettings();
  }
  return status.isGranted;
}
```

### Issue 7: Image Upload Fails

**Symptoms**:
- "Failed to upload image" error
- Network error during submission
- Timeout during upload

**Diagnosis**:

```dart
// Add logging in API service
print('Image size: ${imageBase64.length} bytes');
print('Markers count: ${markers.length}');
```

**Solutions**:

#### Solution 1: Check Network Connection

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> checkConnectivity() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}
```

#### Solution 2: Reduce Image Size

```dart
// Compress more aggressively
final compressed = await FlutterImageCompress.compressWithFile(
  imageFile.path,
  quality: 70,  // Reduce from 85
  minWidth: 1280,  // Reduce from 1920
  minHeight: 1280,
);
```

#### Solution 3: Increase Timeout

```dart
// In ApiClient
final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 60),
  receiveTimeout: Duration(seconds: 60),
  sendTimeout: Duration(seconds: 60),
));
```


### Issue 8: Markers Not Appearing on Canvas

**Symptoms**:
- Tapping image doesn't add markers
- Markers added but not visible
- Canvas not responding to touch

**Diagnosis**:

```dart
// Add debug logging
void _handleTap(TapDownDetails details) {
  print('Tap detected at: ${details.globalPosition}');
  print('Local position: ${details.localPosition}');
  print('Current markers: ${widget.markers.length}');
}
```

**Solutions**:

#### Solution 1: Check Marker Limit

```dart
void _handleTap(TapDownDetails details) {
  if (widget.markers.length >= 10) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Maximum 10 markers allowed')),
    );
    return;
  }
  // Add marker logic
}
```

#### Solution 2: Verify Coordinate Normalization

```dart
void _handleTap(TapDownDetails details) {
  final RenderBox box = context.findRenderObject() as RenderBox;
  final localPosition = box.globalToLocal(details.globalPosition);
  final size = box.size;
  
  final x = (localPosition.dx / size.width).clamp(0.0, 1.0);
  final y = (localPosition.dy / size.height).clamp(0.0, 1.0);
  
  print('Normalized: x=$x, y=$y');
  widget.onTap(x, y);
}
```

#### Solution 3: Ensure Image is Loaded

```dart
@override
Widget build(BuildContext context) {
  if (_image == null) {
    return Center(child: CircularProgressIndicator());
  }
  return GestureDetector(
    onTapDown: _handleTap,
    child: CustomPaint(
      painter: AnnotationPainter(image: _image, markers: widget.markers),
    ),
  );
}
```

### Issue 9: State Not Updating

**Symptoms**:
- Markers added but UI doesn't update
- Consultation submitted but results don't show
- History doesn't refresh

**Diagnosis**:

```dart
// Check if provider is being watched
final state = ref.watch(currentConsultationProvider);
print('Current state: ${state.markers.length} markers');
```

**Solutions**:

#### Solution 1: Use Proper State Updates

```dart
// Wrong
state.markers.add(marker);

// Correct
state = state.copyWith(
  markers: [...state.markers, marker],
);
```

#### Solution 2: Ensure Provider is Watched

```dart
// In widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(currentConsultationProvider);
  // Use state
}
```

#### Solution 3: Refresh Provider

```dart
// Force refresh
ref.invalidate(consultationHistoryProvider);
```

### Issue 10: Memory Leaks

**Symptoms**:
- App becomes slow over time
- Increased memory usage
- App crashes after multiple consultations

**Diagnosis**:

```dart
// Use Flutter DevTools
// Check memory usage in Memory tab
// Look for growing heap size
```

**Solutions**:

#### Solution 1: Dispose Controllers

```dart
@override
void dispose() {
  _scrollController.dispose();
  _textController.dispose();
  super.dispose();
}
```

#### Solution 2: Clean Up Temporary Files

```dart
Future<void> _cleanupTempFiles() async {
  final tempDir = await getTemporaryDirectory();
  final files = tempDir.listSync();
  for (final file in files) {
    if (file.path.endsWith('.jpg') || file.path.endsWith('.png')) {
      await file.delete();
    }
  }
}
```

#### Solution 3: Use AutoDispose Providers

```dart
final consultationHistoryProvider = 
  StateNotifierProvider.autoDispose<ConsultationHistoryNotifier, ConsultationHistoryState>((ref) {
    return ConsultationHistoryNotifier(ref.watch(aiConsultationApiServiceProvider));
  });
```

## Database Issues

### Issue 11: Migration Fails

**Symptoms**:
- "Table already exists" error
- Migration rollback fails
- Foreign key constraint errors

**Diagnosis**:

```bash
# Check migration status
php artisan migrate:status

# Check if table exists
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa \
  -e "SHOW TABLES LIKE 'ai_consultations';"
```

**Solutions**:

#### Solution 1: Fresh Migration

```bash
# Rollback all migrations
php artisan migrate:rollback --step=100

# Re-run migrations
php artisan migrate
```

#### Solution 2: Drop and Recreate

```bash
# Drop table manually
docker exec gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa \
  -e "DROP TABLE IF EXISTS ai_consultations;"

# Run migration
php artisan migrate
```

### Issue 12: Slow Queries

**Symptoms**:
- History loading takes > 5 seconds
- Database CPU usage high
- Timeout errors

**Diagnosis**:

```bash
# Enable slow query log
docker exec gharsewa_db mysql -u root -p -e "SET GLOBAL slow_query_log = 'ON';"
docker exec gharsewa_db mysql -u root -p -e "SET GLOBAL long_query_time = 2;"

# Check slow queries
docker exec gharsewa_db tail -f /var/log/mysql/slow-query.log
```

**Solutions**:

#### Solution 1: Add Missing Indexes

```bash
php artisan tinker
>>> DB::statement('CREATE INDEX idx_customer_created ON ai_consultations(customer_id, created_at DESC)');
>>> DB::statement('CREATE INDEX idx_service_type ON ai_consultations(recommended_service_type)');
```

#### Solution 2: Optimize Queries

```php
// Use eager loading
$consultations = AIConsultation::with('customer')
    ->where('customer_id', $customerId)
    ->orderBy('created_at', 'desc')
    ->paginate(20);
```

#### Solution 3: Add Database Caching

```php
$consultations = Cache::remember(
    "consultations_{$customerId}_page_{$page}",
    300, // 5 minutes
    function () use ($customerId, $page) {
        return AIConsultation::forCustomer($customerId)
            ->paginate(20, ['*'], 'page', $page);
    }
);
```

## Performance Issues

### Issue 13: High Server Load

**Symptoms**:
- Server CPU > 80%
- Response times > 5 seconds
- Ollama consuming excessive resources

**Diagnosis**:

```bash
# Check system resources
top
htop
iostat

# Check Ollama resource usage
docker stats gharsewa_ollama

# Check concurrent requests
netstat -an | grep :8000 | wc -l
```

**Solutions**:

#### Solution 1: Limit Concurrent AI Requests

```php
// Use queue for AI processing
dispatch(new ProcessConsultationJob($consultation));
```

#### Solution 2: Scale Ollama

```bash
# Use multiple Ollama instances with load balancer
# Or upgrade to GPU-enabled server
```

#### Solution 3: Implement Caching

```php
// Cache provider recommendations
$providers = Cache::remember(
    "providers_{$serviceType}",
    300,
    fn() => $this->findMatchingProviders($serviceType)
);
```

### Issue 14: Storage Space Running Out

**Symptoms**:
- "No space left on device" error
- Image upload fails
- Disk usage > 90%

**Diagnosis**:

```bash
# Check disk usage
df -h

# Check consultation images size
du -sh backend/storage/app/public/consultations/

# Count images
find backend/storage/app/public/consultations/ -type f | wc -l
```

**Solutions**:

#### Solution 1: Run Cleanup Command

```bash
# Manually run cleanup
php artisan ai:cleanup-consultations

# Check if scheduled
php artisan schedule:list
```

#### Solution 2: Reduce Retention Period

```bash
# Edit .env
AI_CONSULTATION_RETENTION_DAYS=180  # Reduce from 365

# Run cleanup
php artisan ai:cleanup-consultations
```

#### Solution 3: Compress Old Images

```bash
# Compress images older than 30 days
find backend/storage/app/public/consultations/ -name "*.jpg" -mtime +30 -exec jpegoptim --max=70 {} \;
```

## Common Error Messages

### "Unauthenticated"

**Cause**: JWT token missing or expired

**Solution**:
```dart
// Refresh token or redirect to login
if (error.statusCode == 401) {
  await ref.read(authProvider.notifier).logout();
  Navigator.pushReplacementNamed(context, '/login');
}
```

### "Validation failed"

**Cause**: Invalid request data

**Solution**: Check validation rules and fix request data

### "AI service unavailable"

**Cause**: Ollama service down or not responding

**Solution**: Restart Ollama service

### "Consultation not found"

**Cause**: Invalid consultation ID or deleted consultation

**Solution**: Verify ID and check if consultation exists

### "Too Many Requests"

**Cause**: Rate limit exceeded

**Solution**: Wait 1 minute or adjust rate limit

## Getting Help

### Log Collection

When reporting issues, collect these logs:

```bash
# Laravel logs
tail -n 100 backend/storage/logs/laravel.log > laravel.log

# Ollama logs
docker logs gharsewa_ollama --tail 100 > ollama.log

# Nginx logs
tail -n 100 /var/log/nginx/error.log > nginx.log

# System info
uname -a > system_info.txt
docker ps >> system_info.txt
df -h >> system_info.txt
free -h >> system_info.txt
```

### Support Channels

- **Email**: support@gharsewa.com
- **GitHub Issues**: [Repository URL]
- **Slack**: #ai-visual-assistant channel
- **Documentation**: https://docs.gharsewa.com

### Escalation Path

1. Check this troubleshooting guide
2. Search existing GitHub issues
3. Check Laravel logs for errors
4. Contact support with logs
5. Escalate to development team if needed

---

**Version**: 1.0  
**Last Updated**: January 2024  
**For**: Gharsewa - AI Visual Assistant Feature
