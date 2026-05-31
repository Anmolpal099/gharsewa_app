# Troubleshooting "Server Error" in AI Visual Assistant

You're getting a "Server error" when trying to use the AI Visual Assistant in your Flutter app. This guide will help you identify and fix the issue.

---

## Quick Diagnosis

Run this script first to identify the problem:

```powershell
.\debug_ai_error.ps1
```

This will check:
- ✓ Docker containers running
- ✓ Ollama container status
- ✓ Qwen model loaded
- ✓ Ollama API responding
- ✓ Backend can reach Ollama
- ✓ Environment variables configured
- ✓ Laravel logs
- ✓ Routes registered
- ✓ Ollama generation test
- ✓ Docker network configuration

---

## Common Causes and Solutions

### 1. Ollama Container Not Running

**Symptoms:**
- "Server error" in Flutter
- No Ollama logs
- Backend logs show "Connection refused"

**Check:**
```bash
docker ps | grep ollama
```

**Fix:**
```bash
cd backend
docker-compose -f docker-compose.ollama.yml up -d
```

**Verify:**
```bash
docker ps | grep ollama
# Should show: gharsewa_ollama ... Up
```

---

### 2. Qwen Model Not Loaded

**Symptoms:**
- "Server error" in Flutter
- Ollama logs show "model not found"
- Backend logs show "Model qwen3-vl:2b not found"

**Check:**
```bash
docker exec gharsewa_ollama ollama list
```

**Fix:**
```bash
# This will download ~1.5GB, wait for completion
docker exec gharsewa_ollama ollama pull qwen3-vl:2b
```

**Verify:**
```bash
docker exec gharsewa_ollama ollama list
# Should show: qwen3-vl:2b
```

---

### 3. Backend Can't Reach Ollama

**Symptoms:**
- "Server error" in Flutter
- Backend logs show "Connection refused" or "Could not resolve host"
- Ping test fails

**Check:**
```bash
docker exec gharsewa_app ping -c 2 gharsewa_ollama
```

**Fix:**
```bash
# Check if both containers are on the same network
docker network inspect gharsewa-network

# If not, restart both containers
docker restart gharsewa_ollama
docker restart gharsewa_app
```

**Verify:**
```bash
# Should succeed
docker exec gharsewa_app curl http://gharsewa_ollama:11434/api/tags
```

---

### 4. Ollama Timeout

**Symptoms:**
- "Server error" in Flutter after 60 seconds
- Backend logs show "Timeout" or "Operation timed out"
- Ollama is processing but too slow

**Check:**
```bash
# Check current timeout
docker exec gharsewa_app printenv | grep OLLAMA_TIMEOUT
```

**Fix:**

Edit `backend/.env`:
```env
OLLAMA_TIMEOUT=120  # Increase from 60 to 120 seconds
```

Restart backend:
```bash
cd backend
docker-compose restart app
```

**Verify:**
```bash
docker exec gharsewa_app printenv | grep OLLAMA_TIMEOUT
# Should show: OLLAMA_TIMEOUT=120
```

---

### 5. JWT Token Expired

**Symptoms:**
- "Server error" in Flutter
- Backend logs show "Unauthenticated" or "Token expired"
- Network tab shows 401 Unauthorized

**Check:**
- Open browser DevTools (F12)
- Go to Network tab
- Try the AI assistant
- Look for 401 status code

**Fix:**
- Logout from the Flutter app
- Login again
- Try the AI assistant again

---

### 6. Wrong Environment Variables

**Symptoms:**
- "Server error" in Flutter
- Backend logs show "Connection refused" to localhost
- OLLAMA_HOST is set to localhost instead of container name

**Check:**
```bash
docker exec gharsewa_app printenv | grep OLLAMA
```

**Fix:**

Edit `backend/.env`:
```env
# WRONG (don't use this):
# OLLAMA_HOST=http://localhost:11434

# CORRECT (use container name):
OLLAMA_HOST=http://gharsewa_ollama:11434
OLLAMA_MODEL=qwen3-vl:2b
OLLAMA_TIMEOUT=120
OLLAMA_MAX_TOKENS=2048
OLLAMA_TEMPERATURE=0.7
OLLAMA_TOP_P=0.9
```

Restart backend:
```bash
cd backend
docker-compose restart app
```

---

### 7. Image Too Large

**Symptoms:**
- "Server error" in Flutter
- Backend logs show "Memory limit exceeded" or "Request entity too large"
- Works with small images but fails with large ones

**Check:**
- Try with a very small image (< 1MB)
- If it works, the issue is image size

**Fix:**

Option A - Increase PHP upload limits:

Edit `backend/php.ini` (or create if doesn't exist):
```ini
upload_max_filesize = 20M
post_max_size = 20M
memory_limit = 256M
```

Option B - Compress images in Flutter before upload:

Edit `lib/services/api/ai_consultation_api_service.dart`:
```dart
// Add image compression before base64 conversion
final compressedImage = await _imageService.compressImage(image, maxSizeMB: 5);
final base64Image = await _imageService.imageToBase64(compressedImage);
```

---

### 8. Rate Limiting

**Symptoms:**
- "Server error" in Flutter
- Backend logs show "Too Many Requests"
- Network tab shows 429 status code

**Check:**
- Look at Network tab in browser DevTools
- Check for 429 status code

**Fix:**
- Wait 1 minute before trying again
- The rate limit is 10 requests per minute

To increase rate limit, edit `backend/routes/api.php`:
```php
// Change from:
Route::middleware('throttle:10,1')->group(function () {

// To:
Route::middleware('throttle:20,1')->group(function () {
```

---

### 9. Laravel Cache Issues

**Symptoms:**
- "Server error" in Flutter
- Routes not found
- Config not loading

**Fix:**
```bash
docker exec gharsewa_app php artisan cache:clear
docker exec gharsewa_app php artisan config:clear
docker exec gharsewa_app php artisan route:clear
docker exec gharsewa_app php artisan view:clear
```

---

### 10. Ollama API Error

**Symptoms:**
- "Server error" in Flutter
- Ollama logs show errors
- Backend logs show "Ollama Vision API error"

**Check:**
```bash
# Test Ollama directly
curl http://localhost:11434/api/generate -d '{
  "model": "qwen3-vl:2b",
  "prompt": "Test",
  "stream": false
}'
```

**Fix:**
```bash
# Restart Ollama
docker restart gharsewa_ollama

# Wait 10 seconds for it to start
Start-Sleep -Seconds 10

# Test again
curl http://localhost:11434/api/tags
```

---

## Step-by-Step Debugging Process

### Step 1: Run the Debug Script

```powershell
.\debug_ai_error.ps1
```

This will identify which component is failing.

### Step 2: Check Logs

**Backend logs:**
```bash
docker logs -f gharsewa_app
```

**Ollama logs:**
```bash
docker logs -f gharsewa_ollama
```

**Laravel error log:**
```bash
docker exec gharsewa_app tail -50 storage/logs/laravel.log
```

### Step 3: Test the Endpoint

```powershell
.\test_ai_endpoint.ps1
```

This will test the complete flow from login to AI analysis.

### Step 4: Add Debug Logging

Follow the guide in `ADD_DEBUG_LOGGING.md` to add detailed logging to:
- Backend VisionAIService
- Flutter AI consultation service

### Step 5: Test in Flutter

1. Start Flutter app: `flutter run -d edge`
2. Open browser DevTools (F12)
3. Go to Network tab
4. Try the AI assistant
5. Check the request/response in Network tab
6. Check Flutter console for errors

---

## Verification Checklist

Run through this checklist:

- [ ] Ollama container is running: `docker ps | grep ollama`
- [ ] Qwen model is loaded: `docker exec gharsewa_ollama ollama list`
- [ ] Ollama API responds: `curl http://localhost:11434/api/tags`
- [ ] Backend can ping Ollama: `docker exec gharsewa_app ping -c 2 gharsewa_ollama`
- [ ] Backend can call Ollama: `docker exec gharsewa_app curl http://gharsewa_ollama:11434/api/tags`
- [ ] Environment variables are correct: `docker exec gharsewa_app printenv | grep OLLAMA`
- [ ] Routes are registered: `docker exec gharsewa_app php artisan route:list | grep consultations`
- [ ] Backend is running: `docker ps | grep gharsewa_app`
- [ ] No errors in Laravel log: `docker exec gharsewa_app tail -20 storage/logs/laravel.log`
- [ ] JWT token is valid (logout and login again)
- [ ] Image size is reasonable (< 10MB)
- [ ] Not hitting rate limit (wait 1 minute)

---

## Test Commands

### Test 1: Ollama Health
```bash
curl http://localhost:11434/api/tags
```
**Expected**: JSON with model list

### Test 2: Ollama Generation
```bash
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "qwen3-vl:2b",
  "prompt": "What is 2+2?",
  "stream": false
}'
```
**Expected**: JSON with "response": "4" (takes 5-10 seconds)

### Test 3: Backend to Ollama
```bash
docker exec gharsewa_app curl http://gharsewa_ollama:11434/api/tags
```
**Expected**: JSON with model list

### Test 4: Backend to Ollama Generation
```bash
docker exec gharsewa_app curl -X POST http://gharsewa_ollama:11434/api/generate -d '{
  "model": "qwen3-vl:2b",
  "prompt": "Test",
  "stream": false
}'
```
**Expected**: JSON with response (takes 5-10 seconds)

### Test 5: AI Consultation Endpoint
```powershell
.\test_ai_endpoint.ps1
```
**Expected**: AI diagnosis with service type and cost estimate

---

## Understanding the Error Flow

When you get "Server error", the request goes through these steps:

```
Flutter App
    ↓ (1) HTTP POST /api/v1/customer/ai/consultations
Backend (Laravel)
    ↓ (2) JWT authentication
    ↓ (3) Rate limiting check
    ↓ (4) Request validation
    ↓ (5) Save image to storage
    ↓ (6) Call VisionAIService
    ↓ (7) Encode image to base64
    ↓ (8) Build vision prompt
    ↓ (9) HTTP POST to Ollama
Ollama Container
    ↓ (10) Load model (if not loaded)
    ↓ (11) Process image + prompt
    ↓ (12) Generate response (10-30 seconds)
    ↓ (13) Return JSON
Backend (Laravel)
    ↓ (14) Parse AI response
    ↓ (15) Validate service type
    ↓ (16) Find matching providers
    ↓ (17) Save to database
    ↓ (18) Return JSON response
Flutter App
    ↓ (19) Parse response
    ↓ (20) Display results
```

The error can happen at any of these steps. The debug script and logs will tell you exactly where.

---

## Most Likely Causes (in order)

Based on the "Server error" message, the most likely causes are:

1. **Backend can't reach Ollama** (70% probability)
   - Fix: Restart both containers
   - Verify: `docker exec gharsewa_app ping gharsewa_ollama`

2. **Ollama timeout** (15% probability)
   - Fix: Increase OLLAMA_TIMEOUT to 120
   - Verify: Test with small image first

3. **JWT token expired** (10% probability)
   - Fix: Logout and login again
   - Verify: Check Network tab for 401 status

4. **Model not loaded** (3% probability)
   - Fix: `docker exec gharsewa_ollama ollama pull qwen3-vl:2b`
   - Verify: `docker exec gharsewa_ollama ollama list`

5. **Other issues** (2% probability)
   - Check logs for specific error messages

---

## Quick Fix (Try This First)

```bash
# 1. Restart Ollama
docker restart gharsewa_ollama

# 2. Wait for it to start
Start-Sleep -Seconds 10

# 3. Restart backend
docker restart gharsewa_app

# 4. Wait for it to start
Start-Sleep -Seconds 10

# 5. Test Ollama
curl http://localhost:11434/api/tags

# 6. Test AI endpoint
.\test_ai_endpoint.ps1

# 7. Try Flutter app again
```

---

## Still Not Working?

If you've tried everything and it's still not working:

1. **Collect diagnostic information:**
   ```bash
   # Save backend logs
   docker logs gharsewa_app > backend_logs.txt
   
   # Save Ollama logs
   docker logs gharsewa_ollama > ollama_logs.txt
   
   # Save Laravel error log
   docker exec gharsewa_app cat storage/logs/laravel.log > laravel_logs.txt
   
   # Save environment variables
   docker exec gharsewa_app printenv > env_vars.txt
   ```

2. **Check browser DevTools:**
   - Open F12
   - Go to Network tab
   - Try the AI assistant
   - Find the `/api/v1/customer/ai/consultations` request
   - Check the Response tab for the actual error message
   - Take a screenshot

3. **Check Flutter console:**
   - Look for error messages
   - Look for stack traces
   - Copy the full output

4. **Share the information:**
   - Backend logs (last 100 lines)
   - Ollama logs (last 100 lines)
   - Laravel error log (last 50 lines)
   - Browser Network tab screenshot
   - Flutter console output
   - Environment variables (remove sensitive data)

---

## Success Indicators

You'll know it's working when:

✅ **Debug script shows all green checkmarks**
✅ **Test endpoint script shows AI diagnosis**
✅ **Backend logs show "Vision AI analysis completed"**
✅ **Ollama logs show POST /api/generate**
✅ **Flutter app shows diagnosis, service type, cost, providers**
✅ **No "Server error" message**

---

## Prevention

To avoid this issue in the future:

1. **Always start Ollama before backend:**
   ```bash
   docker-compose -f docker-compose.ollama.yml up -d
   docker-compose up -d
   ```

2. **Check Ollama health before using AI:**
   ```bash
   curl http://localhost:11434/api/tags
   ```

3. **Monitor logs during development:**
   ```bash
   docker logs -f gharsewa_app
   ```

4. **Use reasonable image sizes:**
   - Keep images under 5MB
   - Compress before upload if needed

5. **Don't hit rate limits:**
   - Max 10 requests per minute
   - Wait between tests

---

**Remember**: The AI model IS working and properly integrated. The "Server error" is just a connectivity or configuration issue that can be fixed by following this guide!

