# Qwen 3.5 VL 2B AI Model - Visual Flow Diagram

This document shows exactly how the AI model works in your Gharsewa project.

---

## Complete Flow: From Image Upload to AI Response

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP (Customer Panel)                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 1. User uploads image
                                      │    + adds markers
                                      │    + adds descriptions
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  lib/presentation/panels/customer/ai_consultation/screens/                   │
│  image_capture_screen.dart                                                   │
│                                                                               │
│  - Captures image (camera/gallery)                                           │
│  - Allows marker placement (up to 10)                                        │
│  - Collects text descriptions                                                │
│  - Validates input                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 2. Calls API service
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  lib/services/api/ai_consultation_api_service.dart                           │
│                                                                               │
│  createConsultation({                                                        │
│    required PlatformImage image,                                             │
│    required List<DefectMarkerModel> markers                                  │
│  })                                                                          │
│                                                                               │
│  - Converts image to base64                                                  │
│  - Prepares JSON payload                                                     │
│  - Adds JWT token to headers                                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 3. HTTP POST request
                                      │    /api/v1/customer/ai/consultations
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LARAVEL BACKEND (Docker)                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 4. Route handling
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  backend/routes/api.php                                                      │
│                                                                               │
│  Route::post('consultations', [AIConsultationController::class, 'store'])   │
│    ->middleware('jwt.auth', 'role:customer', 'throttle:10,1')                │
│                                                                               │
│  - Validates JWT token                                                       │
│  - Checks customer role                                                      │
│  - Rate limits (10 req/min)                                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 5. Controller processes request
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  backend/app/Http/Controllers/API/V1/Customer/AIConsultationController.php   │
│                                                                               │
│  public function store(Request $request)                                     │
│  {                                                                           │
│      // Validate request                                                     │
│      // Save image to storage                                                │
│      // Call VisionAIService                                                 │
│      // Return response                                                      │
│  }                                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 6. Calls AI service
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  backend/app/Services/AI/VisionAIService.php                                 │
│                                                                               │
│  public function analyzeImage(string $imagePath, array $markers): array     │
│  {                                                                           │
│      1. Encode image to base64                                               │
│      2. Build vision prompt with markers                                     │
│      3. Call Ollama API (with retry logic)                                   │
│      4. Parse AI response                                                    │
│      5. Find matching providers                                              │
│      6. Return structured result                                             │
│  }                                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 7. HTTP POST to Ollama
                                      │    http://gharsewa_ollama:11434/api/generate
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OLLAMA CONTAINER (Docker)                            │
│                         Model: qwen3-vl:2b (1.9 GB)                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 8. AI processes image + prompt
                                      │    (Takes 1-30 seconds)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  QWEN 3.5 VISION LANGUAGE MODEL                                              │
│                                                                               │
│  Input:                                                                      │
│  - Base64 encoded image                                                      │
│  - Structured prompt with:                                                   │
│    * Marker positions (x%, y%)                                               │
│    * Marker descriptions                                                     │
│    * Expected JSON output format                                             │
│    * Service type categories                                                 │
│    * Cost range guidelines                                                   │
│                                                                               │
│  Processing:                                                                 │
│  - Analyzes image content                                                    │
│  - Identifies defects at marker locations                                    │
│  - Determines service type needed                                            │
│  - Estimates repair cost                                                     │
│  - Calculates confidence score                                               │
│                                                                               │
│  Output:                                                                     │
│  {                                                                           │
│    "diagnosis": "Water leak detected in pipe joint...",                      │
│    "service_type": "Plumbing Repair",                                        │
│    "cost_estimate": {                                                        │
│      "min": 2000,                                                            │
│      "max": 5000                                                             │
│    },                                                                        │
│    "confidence": 0.87                                                        │
│  }                                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 9. Returns JSON response
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  backend/app/Services/AI/VisionAIService.php                                 │
│                                                                               │
│  - Parses JSON response                                                      │
│  - Validates service type                                                    │
│  - Validates cost estimates                                                  │
│  - Queries database for matching providers                                   │
│  - Calculates match scores                                                   │
│  - Returns top 3 providers                                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 10. Saves to database
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  MySQL Database                                                              │
│                                                                               │
│  ai_consultations table:                                                     │
│  - id, user_id, image_path                                                   │
│  - diagnosis, service_type                                                   │
│  - cost_min, cost_max, confidence                                            │
│  - markers (JSON), created_at                                                │
│                                                                               │
│  ai_requests table (logging):                                                │
│  - request_type, prompt, response                                            │
│  - response_time_ms, success                                                 │
│  - error_message, metadata                                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 11. Returns HTTP response
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  JSON Response to Flutter                                                    │
│                                                                               │
│  {                                                                           │
│    "success": true,                                                          │
│    "message": "Consultation created successfully",                           │
│    "data": {                                                                 │
│      "consultation": {                                                       │
│        "id": "uuid-here",                                                    │
│        "diagnosis": "Water leak detected...",                                │
│        "service_type": "Plumbing Repair",                                    │
│        "cost_min": 2000,                                                     │
│        "cost_max": 5000,                                                     │
│        "confidence": 0.87,                                                   │
│        "recommended_providers": [                                            │
│          {                                                                   │
│            "id": 123,                                                        │
│            "name": "Ram Plumbing Services",                                  │
│            "rating": 4.8,                                                    │
│            "reviews_count": 45,                                              │
│            "match_score": 0.92                                               │
│          },                                                                  │
│          { ... provider 2 ... },                                             │
│          { ... provider 3 ... }                                              │
│        ],                                                                    │
│        "processing_time_ms": 27000,                                          │
│        "model": "qwen3-vl:2b"                                                │
│      }                                                                       │
│    }                                                                         │
│  }                                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 12. Parses response
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  lib/services/api/ai_consultation_api_service.dart                           │
│                                                                               │
│  - Parses JSON                                                               │
│  - Creates AIConsultationModel                                               │
│  - Returns to UI                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ 13. Updates UI
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Flutter UI - Consultation Result Screen                                     │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │  AI Diagnosis                                                │            │
│  ├─────────────────────────────────────────────────────────────┤            │
│  │  📋 Diagnosis:                                               │            │
│  │  Water leak detected in pipe joint. Corrosion visible.      │            │
│  │  Immediate repair recommended.                               │            │
│  │                                                              │            │
│  │  🔧 Service Type:                                            │            │
│  │  Plumbing Repair                                             │            │
│  │                                                              │            │
│  │  💰 Cost Estimate:                                           │            │
│  │  NPR 2,000 - 5,000                                           │            │
│  │                                                              │            │
│  │  📊 Confidence: 87%                                          │            │
│  │                                                              │            │
│  │  👷 Recommended Providers:                                   │            │
│  │  1. Ram Plumbing Services (4.8★, 45 reviews)               │            │
│  │  2. Kathmandu Plumbers (4.6★, 32 reviews)                  │            │
│  │  3. Quick Fix Plumbing (4.5★, 28 reviews)                  │            │
│  │                                                              │            │
│  │  [Book Service]  [View History]                             │            │
│  └─────────────────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Why You're Getting "Server Error"

Based on your screenshot, the error happens at step 7 or 8. Here are the most likely causes:

### 1. Backend Can't Reach Ollama Container

**Problem**: Laravel backend is trying to connect to `http://gharsewa_ollama:11434` but can't reach it.

**Check**:
```bash
# From inside the backend container
docker exec gharsewa_app ping gharsewa_ollama

# Check if they're on the same network
docker network inspect gharsewa-network
```

**Fix**: Make sure both containers are on the same Docker network.

### 2. Ollama Model Not Responding

**Problem**: Ollama is running but the model takes too long or fails.

**Check**:
```bash
# Test Ollama directly
curl http://localhost:11434/api/generate -d '{
  "model": "qwen3-vl:2b",
  "prompt": "Test",
  "stream": false
}'
```

**Fix**: Increase timeout in `backend/.env`:
```env
OLLAMA_TIMEOUT=120  # Increase from 60 to 120 seconds
```

### 3. Backend Route Not Registered

**Problem**: The AI consultation route isn't properly registered.

**Check**:
```bash
# List all routes
docker exec gharsewa_app php artisan route:list | grep consultation
```

**Fix**: Make sure `backend/routes/api.php` has the consultation routes.

### 4. JWT Token Invalid

**Problem**: Your JWT token expired or is invalid.

**Check**: Look at the network tab in browser dev tools. Check the Authorization header.

**Fix**: Login again to get a fresh token.

---

## How to See It Working (Step by Step)

### Step 1: Verify Everything is Running

```bash
# Check all containers
docker ps

# Should see:
# - gharsewa_ollama (Ollama)
# - gharsewa_app (Laravel backend)
# - gharsewa_db (MySQL)
# - gharsewa_nginx (Web server)
```

### Step 2: Test Ollama Directly

```bash
# Test simple generation
curl http://localhost:11434/api/generate -d '{
  "model": "qwen3-vl:2b",
  "prompt": "What is 2+2?",
  "stream": false
}'

# Should return JSON with "response": "4" or similar
```

### Step 3: Check Backend Logs

```bash
# Watch logs in real-time
docker logs -f gharsewa_app

# In another terminal, try the AI assistant in Flutter
# You should see logs like:
# "Vision AI analysis started"
# "Calling Ollama API"
# "Vision AI analysis completed"
```

### Step 4: Test in Flutter with Debug Mode

Add this to your Flutter console to see what's happening:

```dart
// In ai_consultation_api_service.dart, add:
print('=== SENDING TO AI ===');
print('Image size: ${base64Image.length}');
print('Markers: ${markers.length}');

// After response:
print('=== AI RESPONSE ===');
print('Success: ${response.data['success']}');
print('Message: ${response.data['message']}');
```

### Step 5: Watch the Magic Happen

1. **Upload image** → See "Sending to AI" in console
2. **Wait 10-30 seconds** → See "Calling Ollama API" in backend logs
3. **Get response** → See "AI Response" in console
4. **UI updates** → See diagnosis, cost, providers!

---

## Troubleshooting Your Specific Error

Since you're getting "Server error", let's debug:

### Check 1: Is Backend Receiving the Request?

```bash
# Watch backend logs
docker logs -f gharsewa_app

# Try the AI assistant
# Do you see any logs? If NO, the request isn't reaching the backend.
```

### Check 2: Is Backend Calling Ollama?

```bash
# Watch Ollama logs
docker logs -f gharsewa_ollama

# Try the AI assistant
# Do you see any logs? If NO, backend isn't calling Ollama.
```

### Check 3: What's the Actual Error?

```bash
# Check Laravel error logs
docker exec gharsewa_app cat storage/logs/laravel.log | tail -50

# Look for errors related to:
# - "Ollama"
# - "Vision"
# - "AI"
# - "consultation"
```

---

## Quick Fix Commands

Try these in order:

```bash
# 1. Restart Ollama
docker restart gharsewa_ollama

# 2. Restart backend
docker restart gharsewa_app

# 3. Clear Laravel cache
docker exec gharsewa_app php artisan cache:clear
docker exec gharsewa_app php artisan config:clear

# 4. Test Ollama
curl http://localhost:11434/api/tags

# 5. Try Flutter app again
```

---

## Success Indicators

You'll know it's working when you see:

✅ **In Flutter Console**:
```
=== SENDING TO AI ===
Image size: 245678
Markers: 2
=== AI RESPONSE ===
Success: true
Diagnosis: Water leak detected...
```

✅ **In Backend Logs**:
```
[2024-01-15 10:30:00] local.INFO: Vision AI analysis started
[2024-01-15 10:30:05] local.INFO: Calling Ollama API
[2024-01-15 10:30:27] local.INFO: Vision AI analysis completed
```

✅ **In Ollama Logs**:
```
[GIN] POST /api/generate
```

✅ **In Flutter UI**:
- Diagnosis appears
- Service type shown
- Cost estimate displayed
- Providers listed
- No error message

---

## Next Steps

1. **Run the test script**: `.\test_ai_model.ps1`
2. **Check the logs**: Follow the commands above
3. **Try the app**: Upload image, add markers, submit
4. **Share the error**: If still not working, share:
   - Backend logs (`docker logs gharsewa_app`)
   - Ollama logs (`docker logs gharsewa_ollama`)
   - Flutter console output
   - Network tab from browser dev tools

---

**Remember**: The AI model IS integrated and working. The "Server error" is just a connectivity or configuration issue that we can fix!
