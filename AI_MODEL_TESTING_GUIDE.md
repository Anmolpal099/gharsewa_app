# How to Test and Visualize Qwen 3.5 VL 2B AI Model

This guide will help you get the AI model running and test it in your application.

---

## Step 1: Start the Ollama Container

First, make sure the Ollama container with Qwen model is running:

```bash
cd backend

# Start the Ollama container
docker-compose -f docker-compose.ollama.yml up -d

# Check if container is running
docker ps | grep ollama
```

**Expected output**: You should see `gharsewa_ollama` container running

---

## Step 2: Load the Qwen 3.5 VL 2B Model

```bash
# Check if model is already loaded
docker exec gharsewa_ollama ollama list

# If qwen3-vl:2b is NOT in the list, pull it:
docker exec gharsewa_ollama ollama pull qwen3-vl:2b
```

**Note**: This will download ~1.5GB. Wait for it to complete.

**Expected output**:
```
pulling manifest
pulling 8934d96d3f08... 100% ▕████████████████▏ 1.5 GB
verifying sha256 digest
writing manifest
success
```

---

## Step 3: Test Ollama API Directly

Test if Ollama is responding:

```bash
# Test 1: Check Ollama health
curl http://localhost:11434/api/tags

# Test 2: Simple text generation
curl http://localhost:11434/api/generate -d '{
  "model": "qwen3-vl:2b",
  "prompt": "What is 2+2?",
  "stream": false
}'
```

**Expected**: You should get JSON responses with model information

---

## Step 4: Check Backend Environment Variables

Make sure your backend `.env` file has the correct Ollama configuration:

```bash
cd backend
cat .env | grep OLLAMA
```

**Expected output**:
```
OLLAMA_HOST=http://gharsewa_ollama:11434
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=60
OLLAMA_MAX_TOKENS=2048
```

**If missing**, add these lines to `backend/.env`:
```env
OLLAMA_HOST=http://gharsewa_ollama:11434
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=60
OLLAMA_MAX_TOKENS=2048
OLLAMA_TEMPERATURE=0.7
OLLAMA_TOP_P=0.9
AI_MAX_RETRIES=3
AI_RETRY_DELAY=1000
AI_CACHE_TTL=3600
```

---

## Step 5: Start Laravel Backend

```bash
cd backend

# Start all backend services
docker-compose up -d

# Check logs
docker-compose logs -f app
```

**Expected**: Backend should start without errors

---

## Step 6: Test Backend AI Endpoint

Test the AI consultation endpoint from command line:

```bash
# First, login to get JWT token
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-customer-email@example.com",
    "password": "your-password"
  }'
```

**Copy the `access_token` from the response**, then test the AI endpoint:

```bash
# Replace YOUR_JWT_TOKEN with the actual token
curl -X POST http://localhost:8000/api/v1/customer/ai/consultations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "markers": [
      {
        "x": 0.5,
        "y": 0.5,
        "description": "Test marker"
      }
    ]
  }'
```

**Expected**: You should get a JSON response with AI diagnosis, service type, cost estimate, and provider recommendations.

---

## Step 7: Check Backend Logs for AI Requests

```bash
cd backend

# Watch Laravel logs
tail -f storage/logs/laravel.log

# Watch Ollama container logs
docker logs -f gharsewa_ollama
```

**Look for**:
- "Vision AI analysis completed"
- "AI generation failed" (if there are errors)
- Model loading messages

---

## Step 8: Test in Flutter App

Now test in your Flutter application:

### 8.1 Start Flutter App

```bash
# Make sure backend is running first
cd backend
docker-compose up -d

# In another terminal, start Flutter
cd ..
flutter run -d edge  # or chrome, windows, etc.
```

### 8.2 Navigate to AI Assistant

1. **Login** as a customer
2. Go to **AI Assistant** section (usually in customer panel)
3. **Upload an image** (camera or gallery)
4. **Add markers** by tapping on the image
5. **Add descriptions** for each marker
6. Click **"Submit"** or **"Analyze"** button

### 8.3 What Should Happen

**Loading State** (1-30 seconds):
- You should see a loading indicator
- Message: "Analyzing image..." or similar

**Success Response**:
- **Diagnosis**: AI-generated description of the problem
- **Service Type**: One of the 10 categories (Plumbing, Electrical, etc.)
- **Cost Estimate**: Min and max cost in NPR
- **Confidence Score**: 0.0 to 1.0
- **Recommended Providers**: Top 3 providers with ratings

**Example Response**:
```
Diagnosis: "Water leak detected in pipe joint. Corrosion visible on metal surface. Immediate repair recommended."

Service Type: Plumbing Repair

Cost Estimate: NPR 2,000 - 5,000

Confidence: 87%

Recommended Providers:
1. Ram Plumbing Services (4.8★, 45 reviews)
2. Kathmandu Plumbers (4.6★, 32 reviews)
3. Quick Fix Plumbing (4.5★, 28 reviews)
```

---

## Step 9: Troubleshooting Common Issues

### Issue 1: "Server error" in Flutter app

**Cause**: Backend can't reach Ollama

**Solution**:
```bash
# Check if Ollama container is running
docker ps | grep ollama

# Check if model is loaded
docker exec gharsewa_ollama ollama list

# Check backend logs
cd backend
docker-compose logs app | grep -i ollama
```

### Issue 2: "Model not found"

**Cause**: Qwen model not loaded

**Solution**:
```bash
# Pull the model
docker exec gharsewa_ollama ollama pull qwen3-vl:2b

# Verify it's loaded
docker exec gharsewa_ollama ollama list
```

### Issue 3: "Connection timeout"

**Cause**: Ollama taking too long to respond

**Solution**:
```bash
# Increase timeout in backend/.env
OLLAMA_TIMEOUT=120  # Increase from 60 to 120 seconds

# Restart backend
cd backend
docker-compose restart app
```

### Issue 4: "Invalid response from Ollama"

**Cause**: Model returning unexpected format

**Solution**:
```bash
# Check Ollama logs
docker logs gharsewa_ollama

# Test model directly
docker exec -it gharsewa_ollama ollama run qwen3-vl:2b "Hello, test"
```

### Issue 5: Backend can't connect to Ollama

**Cause**: Network configuration issue

**Solution**:
```bash
# Check if containers are on same network
docker network inspect gharsewa-network

# Verify OLLAMA_HOST in .env
# Should be: http://gharsewa_ollama:11434 (container name)
# NOT: http://localhost:11434
```

---

## Step 10: Monitor AI Performance

### Check AI Request Logs in Database

```bash
cd backend

# Connect to MySQL
docker-compose exec db mysql -u root -p gharsewa

# View recent AI requests
SELECT 
  id,
  request_type,
  success,
  response_time_ms,
  created_at
FROM ai_requests
ORDER BY created_at DESC
LIMIT 10;

# View failed requests
SELECT 
  id,
  request_type,
  error_message,
  created_at
FROM ai_requests
WHERE success = 0
ORDER BY created_at DESC
LIMIT 10;
```

### Check AI Consultation Records

```sql
SELECT 
  id,
  user_id,
  diagnosis,
  service_type,
  cost_min,
  cost_max,
  confidence,
  created_at
FROM ai_consultations
ORDER BY created_at DESC
LIMIT 5;
```

---

## Step 11: Visual Testing Checklist

Test these scenarios to see the AI model in action:

### Scenario 1: Plumbing Issue
- **Image**: Photo of a leaking pipe
- **Marker**: Point to the leak
- **Description**: "Water dripping from here"
- **Expected**: Service Type = "Plumbing Repair", Cost ~2000-5000 NPR

### Scenario 2: Electrical Problem
- **Image**: Photo of damaged electrical outlet
- **Marker**: Point to the damage
- **Description**: "Outlet not working, sparks visible"
- **Expected**: Service Type = "Electrical Work", Cost ~1500-4000 NPR

### Scenario 3: Wall Damage
- **Image**: Photo of cracked wall
- **Marker**: Point to the crack
- **Description**: "Large crack in wall"
- **Expected**: Service Type = "Carpentry" or "General Maintenance", Cost ~3000-8000 NPR

### Scenario 4: Multiple Issues
- **Image**: Photo with multiple problems
- **Markers**: Add 3-5 markers
- **Descriptions**: Describe each issue
- **Expected**: AI should identify the most critical issue

---

## Step 12: Performance Benchmarks

Expected performance metrics:

| Metric | Target | Actual |
|--------|--------|--------|
| Model load time | < 5s | Check logs |
| Image analysis time | < 30s | Check response |
| API response time | < 35s | Check network tab |
| Confidence score | > 0.5 | Check response |
| Provider matches | 3 | Check response |

---

## Step 13: Debug Mode

Enable detailed logging to see what's happening:

### Backend Debug Logs

Edit `backend/app/Services/AI/VisionAIService.php`:

```php
// Add at the top of analyzeImage() method
Log::info('=== AI ANALYSIS START ===', [
    'image_path' => $imagePath,
    'markers_count' => count($markers),
    'model' => $this->model,
]);

// Add before calling Ollama
Log::info('Calling Ollama API', [
    'host' => $this->ollamaHost,
    'model' => $this->model,
    'prompt_length' => strlen($prompt),
]);

// Add after receiving response
Log::info('Ollama response received', [
    'response_length' => strlen($aiResponse->content),
    'metadata' => $aiResponse->metadata,
]);
```

### Flutter Debug Logs

Edit `lib/services/api/ai_consultation_api_service.dart`:

```dart
// Add before API call
print('=== AI CONSULTATION REQUEST ===');
print('Image size: ${base64Image.length} bytes');
print('Markers: ${markers.length}');

// Add after API call
print('=== AI CONSULTATION RESPONSE ===');
print('Success: ${response.data['success']}');
print('Diagnosis: ${consultationData['diagnosis']}');
print('Service Type: ${consultationData['service_type']}');
```

---

## Quick Start Command Sequence

If you just want to get it running quickly:

```bash
# 1. Start Ollama
cd backend
docker-compose -f docker-compose.ollama.yml up -d

# 2. Load model (wait for download)
docker exec gharsewa_ollama ollama pull qwen3-vl:2b

# 3. Start backend
docker-compose up -d

# 4. Test Ollama
curl http://localhost:11434/api/tags

# 5. Start Flutter
cd ..
flutter run -d edge

# 6. Test in app:
#    - Login as customer
#    - Go to AI Assistant
#    - Upload image
#    - Add markers
#    - Submit
#    - Wait 10-30 seconds
#    - See AI response!
```

---

## Expected Visual Flow

Here's what you should see in the Flutter app:

### 1. AI Assistant Home Screen
```
┌─────────────────────────────────────┐
│  AI Visual Assistant                │
├─────────────────────────────────────┤
│                                     │
│  [Camera Icon]  [Gallery Icon]     │
│                                     │
│  Capture or select an image to     │
│  get AI-powered diagnosis          │
│                                     │
└─────────────────────────────────────┘
```

### 2. Image with Markers
```
┌─────────────────────────────────────┐
│  [< Back]              [Submit]     │
├─────────────────────────────────────┤
│                                     │
│     [Image with markers]            │
│        ⦿ Marker 1                   │
│           ⦿ Marker 2                │
│                                     │
│  Marker 1: "Water leak here"       │
│  Marker 2: "Rust visible"          │
│                                     │
└─────────────────────────────────────┘
```

### 3. Loading State
```
┌─────────────────────────────────────┐
│  Analyzing Image...                 │
├─────────────────────────────────────┤
│                                     │
│         [Spinner Animation]         │
│                                     │
│  AI is analyzing your image         │
│  This may take up to 30 seconds     │
│                                     │
└─────────────────────────────────────┘
```

### 4. AI Response
```
┌─────────────────────────────────────┐
│  AI Diagnosis                       │
├─────────────────────────────────────┤
│  📋 Diagnosis:                      │
│  Water leak detected in pipe joint. │
│  Corrosion visible. Immediate       │
│  repair recommended.                │
│                                     │
│  🔧 Service Type:                   │
│  Plumbing Repair                    │
│                                     │
│  💰 Cost Estimate:                  │
│  NPR 2,000 - 5,000                  │
│                                     │
│  📊 Confidence: 87%                 │
│                                     │
│  👷 Recommended Providers:          │
│  1. Ram Plumbing (4.8★)            │
│  2. Kathmandu Plumbers (4.6★)      │
│  3. Quick Fix Plumbing (4.5★)      │
│                                     │
│  [Book Service] [View History]     │
└─────────────────────────────────────┘
```

---

## Success Indicators

You'll know the AI model is working when you see:

✅ **Backend Logs**:
```
[2024-01-15 10:30:00] local.INFO: Vision AI analysis completed {"model":"qwen3-vl:2b","response_length":450}
```

✅ **Flutter Console**:
```
AI CONSULTATION RESPONSE
Success: true
Diagnosis: Water leak detected...
Service Type: Plumbing Repair
```

✅ **Database**:
```sql
-- New record in ai_consultations table
-- New record in ai_requests table with success=1
```

✅ **UI**:
- Diagnosis text appears
- Service type displayed
- Cost range shown
- Provider list populated
- No error messages

---

## Still Not Working?

If you've followed all steps and it's still not working, check:

1. **Docker containers running**: `docker ps`
2. **Model loaded**: `docker exec gharsewa_ollama ollama list`
3. **Backend logs**: `docker-compose logs app`
4. **Ollama logs**: `docker logs gharsewa_ollama`
5. **Network connectivity**: `docker network inspect gharsewa-network`
6. **Environment variables**: `cat backend/.env | grep OLLAMA`
7. **Flutter console**: Check for API errors

Share the error messages and I'll help you debug further!

---

**Last Updated**: January 2024  
**Model**: Qwen 3.5 VL 2B (qwen3-vl:2b)  
**Status**: Ready for testing
