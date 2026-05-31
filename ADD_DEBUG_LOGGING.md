# How to Add Debug Logging to Trace the "Server Error"

This guide shows you how to add detailed logging to identify exactly where the AI request is failing.

---

## Option 1: Enable Laravel Debug Mode (Quick)

Edit `backend/.env`:

```env
# Change this line:
APP_DEBUG=true

# And set log level to debug:
LOG_LEVEL=debug
```

Then restart the backend:

```bash
cd backend
docker-compose restart app
```

Now all errors will be logged with full stack traces.

---

## Option 2: Add Detailed Logging to VisionAIService (Recommended)

Edit `backend/app/Services/AI/VisionAIService.php` and add these log statements:

### At the start of `analyzeImage()` method (line ~25):

```php
public function analyzeImage(string $imagePath, array $markers): array
{
    $startTime = microtime(true);

    // ADD THIS:
    Log::info('=== AI ANALYSIS START ===', [
        'image_path' => $imagePath,
        'markers_count' => count($markers),
        'model' => $this->model,
        'ollama_host' => $this->ollamaHost,
        'timeout' => $this->timeout,
    ]);

    try {
        // ... rest of the code
```

### Before calling Ollama API (in `callVisionAPI()` method, line ~320):

```php
private function callVisionAPI(string $imageBase64, string $prompt): AIResponse
{
    try {
        // ADD THIS:
        Log::info('=== CALLING OLLAMA API ===', [
            'host' => $this->ollamaHost,
            'model' => $this->model,
            'timeout' => $this->timeout,
            'image_size_bytes' => strlen($imageBase64),
            'prompt_length' => strlen($prompt),
        ]);

        $response = Http::timeout($this->timeout)
            ->post("{$this->ollamaHost}/api/generate", [
                // ... rest of the code
```

### After receiving Ollama response (in `callVisionAPI()` method, line ~340):

```php
        if (!$response->successful()) {
            // ADD THIS:
            Log::error('=== OLLAMA API ERROR ===', [
                'status_code' => $response->status(),
                'body' => $response->body(),
                'headers' => $response->headers(),
            ]);
            
            throw new Exception("Ollama Vision API error: " . $response->body());
        }

        $data = $response->json();

        // ADD THIS:
        Log::info('=== OLLAMA API SUCCESS ===', [
            'response_length' => strlen($data['response'] ?? ''),
            'model' => $data['model'] ?? 'unknown',
            'total_duration_ms' => isset($data['total_duration']) ? round($data['total_duration'] / 1000000) : null,
        ]);
```

### In the catch block (line ~50):

```php
    } catch (Exception $e) {
        // ADD THIS:
        Log::error('=== AI ANALYSIS FAILED ===', [
            'error_message' => $e->getMessage(),
            'error_class' => get_class($e),
            'error_code' => $e->getCode(),
            'error_file' => $e->getFile(),
            'error_line' => $e->getLine(),
            'image_path' => $imagePath,
            'markers_count' => count($markers),
            'stack_trace' => $e->getTraceAsString(),
        ]);

        throw $e;
    }
```

---

## Option 3: Add Logging to Flutter API Service

Edit `lib/services/api/ai_consultation_api_service.dart`:

### In `createConsultation()` method (line ~40):

```dart
Future<AIConsultationModel> createConsultation({
  required PlatformImage image,
  required List<DefectMarkerModel> markers,
}) async {
  try {
    // ADD THIS:
    print('=== AI CONSULTATION REQUEST START ===');
    print('Markers count: ${markers.length}');
    
    // Convert platform image to base64
    final base64Image = await _imageService.imageToBase64(image);
    
    // ADD THIS:
    print('Image converted to base64: ${base64Image.length} bytes');

    // Prepare request data
    final requestData = {
      'image': base64Image,
      'markers': markers.map((m) => m.toJson()).toList(),
    };
    
    // ADD THIS:
    print('Sending request to: /v1/customer/ai/consultations');
    print('Request data size: ${requestData.toString().length} bytes');

    // Make API request
    final response = await _apiClient.post(
      '/v1/customer/ai/consultations',
      data: requestData,
    );
    
    // ADD THIS:
    print('=== AI CONSULTATION RESPONSE ===');
    print('Status code: ${response.statusCode}');
    print('Success: ${response.data['success']}');
    print('Message: ${response.data['message']}');

    // Parse response
    if (response.data['success'] == true) {
      final consultationData = response.data['data']['consultation'];
      
      // ADD THIS:
      print('Diagnosis: ${consultationData['diagnosis']}');
      print('Service type: ${consultationData['service_type']}');
      print('Cost: ${consultationData['cost_min']} - ${consultationData['cost_max']}');
      
      return AIConsultationModel.fromJson(consultationData);
    } else {
      // ADD THIS:
      print('=== AI CONSULTATION FAILED ===');
      print('Error message: ${response.data['message']}');
      
      throw ApiException(
        message: response.data['message'] ?? 'Failed to create consultation',
        type: ApiExceptionType.server,
        statusCode: response.statusCode,
      );
    }
  } on ApiException {
    rethrow;
  } catch (e) {
    // ADD THIS:
    print('=== AI CONSULTATION EXCEPTION ===');
    print('Error: ${e.toString()}');
    print('Error type: ${e.runtimeType}');
    
    throw ApiException(
      message: 'Failed to create consultation: ${e.toString()}',
      type: ApiExceptionType.unknown,
      statusCode: null,
    );
  }
}
```

---

## How to Use the Debug Logs

### 1. Start watching logs in real-time:

**Terminal 1 - Backend logs:**
```bash
docker logs -f gharsewa_app
```

**Terminal 2 - Ollama logs:**
```bash
docker logs -f gharsewa_ollama
```

**Terminal 3 - Flutter console:**
```bash
# Just watch the Flutter console output
```

### 2. Try the AI Assistant in your Flutter app

Upload an image, add markers, and submit.

### 3. Watch the logs flow through:

You should see this sequence:

**Flutter Console:**
```
=== AI CONSULTATION REQUEST START ===
Markers count: 2
Image converted to base64: 245678 bytes
Sending request to: /v1/customer/ai/consultations
```

**Backend Logs:**
```
[INFO] === AI ANALYSIS START ===
[INFO] === CALLING OLLAMA API ===
```

**Ollama Logs:**
```
[GIN] POST /api/generate
```

**Backend Logs:**
```
[INFO] === OLLAMA API SUCCESS ===
[INFO] Vision AI analysis completed
```

**Flutter Console:**
```
=== AI CONSULTATION RESPONSE ===
Status code: 200
Success: true
Diagnosis: Water leak detected...
```

### 4. Identify where it fails

If you see:
- ✓ Flutter logs but NO backend logs → **Backend not receiving request** (check JWT token, API URL)
- ✓ Backend "START" but NO "CALLING OLLAMA" → **Error before Ollama call** (check image encoding)
- ✓ Backend "CALLING OLLAMA" but NO Ollama logs → **Network issue** (backend can't reach Ollama)
- ✓ Ollama logs but NO "SUCCESS" → **Ollama timeout or error** (increase timeout, check model)
- ✓ Backend "SUCCESS" but Flutter shows error → **Response parsing issue** (check JSON format)

---

## Quick Test Commands

### Test 1: Check if backend can reach Ollama
```bash
docker exec gharsewa_app curl -v http://gharsewa_ollama:11434/api/tags
```

**Expected**: JSON response with model list

### Test 2: Test Ollama generation from backend
```bash
docker exec gharsewa_app curl -X POST http://gharsewa_ollama:11434/api/generate \
  -d '{"model":"qwen3-vl:2b","prompt":"Test","stream":false}'
```

**Expected**: JSON response with "response" field (takes 5-10 seconds)

### Test 3: Check Laravel error logs
```bash
docker exec gharsewa_app tail -50 storage/logs/laravel.log
```

**Look for**: "AI ANALYSIS", "OLLAMA", "Vision", "error", "exception"

### Test 4: Test AI endpoint with curl
```bash
# First, get JWT token by logging in
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.com","password":"password"}'

# Copy the access_token, then test AI endpoint
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "markers": [{"x": 0.5, "y": 0.5, "description": "Test"}]
  }'
```

**Expected**: JSON response with diagnosis, service_type, cost_min, cost_max

---

## Common Issues and Solutions

### Issue 1: "Connection refused" in backend logs

**Cause**: Backend can't reach Ollama container

**Solution**:
```bash
# Check if both containers are on same network
docker network inspect gharsewa-network

# Restart both containers
docker restart gharsewa_ollama
docker restart gharsewa_app
```

### Issue 2: "Timeout" in backend logs

**Cause**: Ollama taking too long (>60 seconds)

**Solution**: Edit `backend/.env`:
```env
OLLAMA_TIMEOUT=120  # Increase from 60 to 120
```

Then restart:
```bash
cd backend
docker-compose restart app
```

### Issue 3: "Model not found" in Ollama logs

**Cause**: Qwen model not loaded

**Solution**:
```bash
docker exec gharsewa_ollama ollama pull qwen3-vl:2b
```

### Issue 4: "Unauthorized" in Flutter

**Cause**: JWT token expired or invalid

**Solution**: Logout and login again in the Flutter app

### Issue 5: "Invalid JSON" in backend logs

**Cause**: Ollama returning unexpected format

**Solution**: Check Ollama logs for the actual response:
```bash
docker logs gharsewa_ollama | tail -50
```

---

## After Adding Logs

1. **Restart backend** to load the new code:
   ```bash
   cd backend
   docker-compose restart app
   ```

2. **Clear Laravel cache**:
   ```bash
   docker exec gharsewa_app php artisan cache:clear
   docker exec gharsewa_app php artisan config:clear
   ```

3. **Try the AI Assistant again** and watch the logs

4. **Share the logs** if you still have issues:
   - Backend logs (last 50 lines)
   - Ollama logs (last 50 lines)
   - Flutter console output
   - Browser Network tab (F12 → Network → find the consultations request)

---

## Expected Log Flow (Success Case)

```
[Flutter] === AI CONSULTATION REQUEST START ===
[Flutter] Markers count: 2
[Flutter] Image converted to base64: 245678 bytes
[Flutter] Sending request to: /v1/customer/ai/consultations

[Backend] === AI ANALYSIS START ===
[Backend] image_path: /var/www/storage/app/consultations/abc123.jpg
[Backend] markers_count: 2
[Backend] model: qwen3-vl:2b

[Backend] === CALLING OLLAMA API ===
[Backend] host: http://gharsewa_ollama:11434
[Backend] timeout: 60
[Backend] image_size_bytes: 245678

[Ollama] [GIN] POST /api/generate

[Backend] === OLLAMA API SUCCESS ===
[Backend] response_length: 450
[Backend] total_duration_ms: 27000

[Backend] Vision AI analysis completed

[Flutter] === AI CONSULTATION RESPONSE ===
[Flutter] Status code: 200
[Flutter] Success: true
[Flutter] Diagnosis: Water leak detected in pipe joint...
[Flutter] Service type: Plumbing Repair
[Flutter] Cost: 2000 - 5000
```

---

**Remember**: The logs will tell you EXACTLY where the request is failing. Follow the log flow and you'll find the issue!

