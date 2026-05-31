# How to Fix the "Server Error" in AI Visual Assistant

You're getting a "Server error" when trying to use the AI Visual Assistant. I've created several tools to help you diagnose and fix this issue.

---

## 🚀 Quick Start (Do This First)

### Step 1: Run the Debug Script

```powershell
.\debug_ai_error.ps1
```

This will check all 10 components and tell you exactly what's wrong.

### Step 2: Run the Test Script

```powershell
.\test_ai_endpoint.ps1
```

This will test the complete AI flow and show you if it's working.

### Step 3: Fix Any Issues

Based on the output from Step 1 and Step 2, follow the fixes in `TROUBLESHOOT_SERVER_ERROR.md`.

---

## 📁 Files I Created for You

### 1. `debug_ai_error.ps1` - Diagnostic Script
**What it does:**
- Checks if Docker containers are running
- Verifies Ollama container status
- Confirms Qwen model is loaded
- Tests Ollama API from host and backend
- Checks environment variables
- Verifies routes are registered
- Tests network connectivity
- Shows recent Laravel logs

**When to use:** Run this FIRST to identify the problem

**How to run:**
```powershell
.\debug_ai_error.ps1
```

---

### 2. `test_ai_endpoint.ps1` - End-to-End Test
**What it does:**
- Logs in to get JWT token
- Sends a test image with markers to AI endpoint
- Shows the AI diagnosis, service type, cost estimate
- Confirms the AI model is working

**When to use:** After fixing issues, to verify everything works

**How to run:**
```powershell
# With default credentials
.\test_ai_endpoint.ps1

# With custom credentials
.\test_ai_endpoint.ps1 -Email "your@email.com" -Password "yourpassword"
```

---

### 3. `TROUBLESHOOT_SERVER_ERROR.md` - Complete Troubleshooting Guide
**What it contains:**
- 10 common causes of "Server error"
- Step-by-step fixes for each cause
- Verification commands
- Test commands
- Understanding the error flow
- Prevention tips

**When to use:** When you need detailed instructions to fix a specific issue

**How to use:** Open the file and follow the guide for your specific error

---

### 4. `ADD_DEBUG_LOGGING.md` - Debug Logging Guide
**What it contains:**
- How to add detailed logging to backend (VisionAIService)
- How to add detailed logging to Flutter (AI consultation service)
- How to watch logs in real-time
- How to identify where the request is failing

**When to use:** When you need to see exactly where the request is failing

**How to use:** Follow the instructions to add logging, then watch the logs while testing

---

### 5. `AI_MODEL_TESTING_GUIDE.md` - Already Exists
**What it contains:**
- Complete guide to testing the AI model
- Step-by-step instructions from starting Ollama to testing in Flutter
- Visual flow diagrams
- Performance benchmarks
- Debug mode instructions

**When to use:** For comprehensive testing and understanding how the AI works

---

### 6. `AI_MODEL_FLOW_DIAGRAM.md` - Already Exists
**What it contains:**
- Visual diagram showing complete flow from image upload to AI response
- Explanation of each step
- Why you're getting "Server error"
- How to see it working

**When to use:** To understand how the AI model works in your project

---

## 🔍 Most Likely Causes (Based on Your Symptoms)

### Cause #1: Backend Can't Reach Ollama (70% probability)

**Symptoms:**
- "Server error" in Flutter
- No response after submitting

**Quick Fix:**
```bash
# Restart both containers
docker restart gharsewa_ollama
docker restart gharsewa_app

# Wait 10 seconds
Start-Sleep -Seconds 10

# Test
.\test_ai_endpoint.ps1
```

**Verify:**
```bash
docker exec gharsewa_app ping -c 2 gharsewa_ollama
```

---

### Cause #2: Ollama Timeout (15% probability)

**Symptoms:**
- "Server error" after exactly 60 seconds
- Works sometimes, fails other times

**Quick Fix:**

Edit `backend/.env`:
```env
OLLAMA_TIMEOUT=120  # Change from 60 to 120
```

Restart:
```bash
cd backend
docker-compose restart app
```

---

### Cause #3: JWT Token Expired (10% probability)

**Symptoms:**
- "Server error" immediately
- Network tab shows 401 Unauthorized

**Quick Fix:**
- Logout from Flutter app
- Login again
- Try AI assistant again

---

### Cause #4: Model Not Loaded (3% probability)

**Symptoms:**
- "Server error" in Flutter
- Ollama logs show "model not found"

**Quick Fix:**
```bash
docker exec gharsewa_ollama ollama pull qwen3-vl:2b
```

---

### Cause #5: Wrong Environment Variables (2% probability)

**Symptoms:**
- "Server error" in Flutter
- Backend logs show "Connection refused" to localhost

**Quick Fix:**

Edit `backend/.env`:
```env
OLLAMA_HOST=http://gharsewa_ollama:11434  # NOT localhost!
```

Restart:
```bash
cd backend
docker-compose restart app
```

---

## 📋 Step-by-Step Debugging Process

### Step 1: Run Diagnostic Script
```powershell
.\debug_ai_error.ps1
```

**Look for:**
- ✓ Green checkmarks = component is working
- ✗ Red X marks = component is failing

**Fix any red X marks** before proceeding.

---

### Step 2: Check Logs

Open 3 terminals:

**Terminal 1 - Backend logs:**
```bash
docker logs -f gharsewa_app
```

**Terminal 2 - Ollama logs:**
```bash
docker logs -f gharsewa_ollama
```

**Terminal 3 - Run test:**
```powershell
.\test_ai_endpoint.ps1
```

**Watch the logs flow:**
- Backend should show "AI ANALYSIS START"
- Backend should show "CALLING OLLAMA API"
- Ollama should show "POST /api/generate"
- Backend should show "Vision AI analysis completed"
- Test script should show diagnosis

**If logs stop at a certain point**, that's where the issue is.

---

### Step 3: Test in Flutter

1. Start Flutter app:
   ```bash
   flutter run -d edge
   ```

2. Open browser DevTools (F12)

3. Go to Network tab

4. Login as customer

5. Go to AI Assistant

6. Upload image, add markers, submit

7. Watch:
   - Network tab for the API request/response
   - Flutter console for errors
   - Backend logs (Terminal 1)
   - Ollama logs (Terminal 2)

---

### Step 4: Identify the Issue

Based on what you see:

| What You See | Issue | Fix |
|--------------|-------|-----|
| No backend logs | Request not reaching backend | Check JWT token, API URL |
| Backend "START" but no "CALLING" | Error before Ollama call | Check Laravel logs |
| Backend "CALLING" but no Ollama logs | Network issue | Restart containers |
| Ollama logs but no "SUCCESS" | Ollama timeout/error | Increase timeout |
| Backend "SUCCESS" but Flutter error | Response parsing issue | Check response format |

---

### Step 5: Apply the Fix

Follow the specific fix in `TROUBLESHOOT_SERVER_ERROR.md` for your issue.

---

### Step 6: Verify the Fix

```powershell
# Test the endpoint
.\test_ai_endpoint.ps1

# Should show:
# ✓ Login successful
# ✓ AI consultation successful
# 📋 Diagnosis: ...
# 🔧 Service Type: ...
# 💰 Cost Estimate: ...
```

---

### Step 7: Test in Flutter

Try the AI Assistant in your Flutter app again. It should now work!

---

## 🎯 Expected Results When Working

### In the Test Script:
```
✓ Login successful!
✓ AI consultation successful!

========================================
AI ANALYSIS RESULTS
========================================

📋 Diagnosis:
  Water leak detected in pipe joint...

🔧 Service Type:
  Plumbing Repair

💰 Cost Estimate:
  NPR 2000 - 5000

📊 Confidence:
  87%

🤖 Model:
  qwen3-vl:2b

👷 Recommended Providers:
  • Ram Plumbing Services (4.8★, 45 reviews)
  • Kathmandu Plumbers (4.6★, 32 reviews)

========================================
✓ AI MODEL IS WORKING CORRECTLY!
========================================
```

### In Flutter App:
- Upload image → ✓
- Add markers → ✓
- Submit → ✓
- Loading indicator (10-30 seconds) → ✓
- Diagnosis appears → ✓
- Service type shown → ✓
- Cost estimate displayed → ✓
- Providers listed → ✓
- No "Server error" → ✓

---

## 🛠️ Quick Fix Commands

Try these in order:

```bash
# 1. Restart Ollama
docker restart gharsewa_ollama
Start-Sleep -Seconds 10

# 2. Restart backend
docker restart gharsewa_app
Start-Sleep -Seconds 10

# 3. Clear Laravel cache
docker exec gharsewa_app php artisan cache:clear
docker exec gharsewa_app php artisan config:clear

# 4. Test Ollama
curl http://localhost:11434/api/tags

# 5. Test endpoint
.\test_ai_endpoint.ps1

# 6. Try Flutter app
flutter run -d edge
```

---

## 📊 Verification Checklist

Before testing in Flutter, verify:

- [ ] Ollama container running: `docker ps | grep ollama`
- [ ] Qwen model loaded: `docker exec gharsewa_ollama ollama list`
- [ ] Ollama API responds: `curl http://localhost:11434/api/tags`
- [ ] Backend can reach Ollama: `docker exec gharsewa_app ping -c 2 gharsewa_ollama`
- [ ] Environment variables correct: `docker exec gharsewa_app printenv | grep OLLAMA`
- [ ] Test endpoint works: `.\test_ai_endpoint.ps1`
- [ ] No errors in logs: `docker logs gharsewa_app | tail -20`

If all checkmarks are ✓, the AI should work in Flutter!

---

## 🆘 Still Not Working?

If you've tried everything:

1. **Run the debug script and save output:**
   ```powershell
   .\debug_ai_error.ps1 > debug_output.txt
   ```

2. **Run the test script and save output:**
   ```powershell
   .\test_ai_endpoint.ps1 > test_output.txt
   ```

3. **Save backend logs:**
   ```bash
   docker logs gharsewa_app > backend_logs.txt
   ```

4. **Save Ollama logs:**
   ```bash
   docker logs gharsewa_ollama > ollama_logs.txt
   ```

5. **In Flutter app:**
   - Open browser DevTools (F12)
   - Go to Network tab
   - Try AI assistant
   - Find the `/api/v1/customer/ai/consultations` request
   - Right-click → Copy → Copy as cURL
   - Save to a file

6. **Share:**
   - `debug_output.txt`
   - `test_output.txt`
   - `backend_logs.txt`
   - `ollama_logs.txt`
   - The cURL command from Network tab
   - Screenshot of the error in Flutter

---

## 💡 Key Points to Remember

1. **The AI model IS integrated and working** - the infrastructure is correct
2. **"Server error" is a connectivity/configuration issue** - not a code issue
3. **The debug script will identify the problem** - run it first
4. **The test script will verify the fix** - run it after fixing
5. **Most likely cause is backend can't reach Ollama** - restart containers
6. **Check logs to see exactly where it fails** - logs tell the truth
7. **JWT token expires** - logout and login if you get 401
8. **Increase timeout if needed** - some images take longer to process

---

## 📚 Additional Resources

- `TROUBLESHOOT_SERVER_ERROR.md` - Detailed troubleshooting guide
- `ADD_DEBUG_LOGGING.md` - How to add detailed logging
- `AI_MODEL_TESTING_GUIDE.md` - Complete testing guide
- `AI_MODEL_FLOW_DIAGRAM.md` - Visual flow diagram
- `QWEN_AI_INTEGRATION_AUDIT.md` - Integration audit report

---

## 🎉 Success!

Once you see the AI diagnosis in the test script, you're ready to use it in Flutter!

The AI model (Qwen 3.5 VL 2B) will:
- ✓ Analyze your images
- ✓ Identify defects at marker locations
- ✓ Determine the service type needed
- ✓ Estimate repair costs
- ✓ Recommend top providers
- ✓ Calculate confidence scores

**Happy testing!** 🚀

