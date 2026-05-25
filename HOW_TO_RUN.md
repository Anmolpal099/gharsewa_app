# 🚀 How to Run - Complete Guide

## Overview

Your Gharsewa app has two parts:
1. **Backend** - Laravel API (runs in Docker)
2. **Frontend** - Flutter app (runs on your device/emulator)

---

## Part 1: Start the Backend (Laravel)

### Step 1: Navigate to Backend Directory

```powershell
cd e:\gharsewa\backend
```

### Step 2: Start Docker Containers

```powershell
docker-compose up -d
```

**Expected Output:**
```
[+] Running 7/7
 ✔ Container gharsewa_db         Started
 ✔ Container gharsewa_redis       Started
 ✔ Container gharsewa_app         Started
 ✔ Container gharsewa_nginx       Started
 ✔ Container gharsewa_queue       Started
 ✔ Container gharsewa_scheduler   Started
 ✔ Container gharsewa_websocket   Started
```

### Step 3: Check Services are Running

```powershell
docker-compose ps
```

**Expected:** All services should show "Up" status (except queue/websocket which may be restarting - that's okay)

### Step 4: Verify Backend is Accessible

Open browser and go to: http://localhost:8000

**Expected:** You might see a 502 error or blank page - that's normal! The API endpoints work.

**Test API:**
```powershell
Invoke-WebRequest -Uri "http://localhost:8000/api/v1/auth/jwt/register" -Method Get
```

**Expected:** 405 Method Not Allowed (means backend is working!)

---

## Part 2: Start the Flutter App

### Step 1: Navigate to Project Root

```powershell
cd e:\gharsewa
```

### Step 2: Get Dependencies (First Time Only)

```powershell
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in gharsewa...
Resolving dependencies...
Got dependencies!
```

### Step 3: Check Connected Devices

```powershell
flutter devices
```

**Expected Output:**
```
3 connected devices:

Windows (desktop) • windows • windows-x64    • Microsoft Windows
Chrome (web)      • chrome  • web-javascript • Google Chrome
Edge (web)        • edge    • web-javascript • Microsoft Edge
```

### Step 4: Run the App

**Option A: Run on Windows Desktop (Recommended)**
```powershell
flutter run -d windows
```

**Option B: Run on Chrome (Web)**
```powershell
flutter run -d chrome
```

**Option C: Run on Android Emulator**
```powershell
# First, start Android emulator from Android Studio
# Then:
flutter run
```

**Expected Output:**
```
Launching lib\main.dart on Windows in debug mode...
Building Windows application...
Syncing files to device Windows...
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

An Observatory debugger and profiler on Windows is available at: http://127.0.0.1:xxxxx/
The Flutter DevTools debugger and profiler on Windows is available at: http://127.0.0.1:xxxxx/
```

---

## Part 3: Test the Authentication Flow

### Test 1: Registration

1. **In the app, click "Don't have an account? Register"**

2. **Fill the form:**
   - Name: Test User
   - Email: test@example.com
   - Password: Test1234

3. **Click "Create Account"**

4. **Get OTP from logs:**
   ```powershell
   # In a new PowerShell window:
   cd e:\gharsewa\backend
   docker-compose exec app tail -100 storage/logs/laravel.log | Select-String "otp"
   ```
   
   **Look for:** `"otp":"123456"` (your actual OTP code)

5. **Enter OTP in the app**

6. **Expected:** Navigate to customer home dashboard

### Test 2: Login

1. **In the app, enter:**
   - Email: test@example.com
   - Password: Test1234

2. **Click "Sign In"**

3. **Expected:** Navigate to customer home dashboard

### Test 3: Forgot Password

1. **Click "Forgot Password?"**

2. **Enter email:** test@example.com

3. **Click "Send OTP"**

4. **Get OTP from logs** (same command as above)

5. **Enter OTP**

6. **Set new password:** Test5678

7. **Login with new password**

8. **Expected:** Navigate to dashboard

---

## Part 4: Hot Reload & Hot Restart

### Hot Reload (r)
**When to use:** After making small UI changes

```bash
# In the Flutter terminal, press 'r'
```

**What it does:** Updates the UI without restarting the app

### Hot Restart (R)
**When to use:** After making code changes (like our navigation fix)

```bash
# In the Flutter terminal, press 'R' (capital R)
```

**What it does:** Restarts the app completely

---

## Part 5: Stop Everything

### Stop Flutter App

```bash
# In the Flutter terminal, press 'q'
```

### Stop Backend

```powershell
cd e:\gharsewa\backend
docker-compose down
```

**Expected Output:**
```
[+] Running 7/7
 ✔ Container gharsewa_websocket   Removed
 ✔ Container gharsewa_scheduler   Removed
 ✔ Container gharsewa_queue       Removed
 ✔ Container gharsewa_nginx       Removed
 ✔ Container gharsewa_app         Removed
 ✔ Container gharsewa_redis       Removed
 ✔ Container gharsewa_db          Removed
```

---

## Quick Start Commands

### Start Everything

```powershell
# Terminal 1: Start Backend
cd e:\gharsewa\backend
docker-compose up -d

# Terminal 2: Start Flutter
cd e:\gharsewa
flutter run -d windows
```

### Stop Everything

```powershell
# Terminal 1: Stop Backend
cd e:\gharsewa\backend
docker-compose down

# Terminal 2: Stop Flutter
# Press 'q' in Flutter terminal
```

---

## Troubleshooting

### Issue: "Docker daemon not running"

**Solution:** Start Docker Desktop

### Issue: "Port 8000 already in use"

**Solution:**
```powershell
cd e:\gharsewa\backend
docker-compose down
# Wait a few seconds
docker-compose up -d
```

### Issue: "Flutter command not found"

**Solution:** 
1. Install Flutter: https://docs.flutter.dev/get-started/install/windows
2. Add Flutter to PATH
3. Restart PowerShell

### Issue: "No devices found"

**Solution:**
```powershell
# Enable Windows desktop
flutter config --enable-windows-desktop

# Enable web
flutter config --enable-web

# Check again
flutter devices
```

### Issue: Backend not responding

**Solution:**
```powershell
cd e:\gharsewa\backend

# Check services
docker-compose ps

# Restart app
docker-compose restart app nginx

# Check logs
docker-compose logs -f app
```

### Issue: Flutter app shows errors

**Solution:**
```powershell
cd e:\gharsewa

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run again
flutter run -d windows
```

---

## Development Workflow

### Daily Workflow

1. **Start Backend:**
   ```powershell
   cd e:\gharsewa\backend
   docker-compose up -d
   ```

2. **Start Flutter:**
   ```powershell
   cd e:\gharsewa
   flutter run -d windows
   ```

3. **Make changes to code**

4. **Hot reload/restart:**
   - Press 'r' for hot reload (UI changes)
   - Press 'R' for hot restart (code changes)

5. **Test changes**

6. **Stop when done:**
   - Press 'q' in Flutter terminal
   - Run `docker-compose down` in backend

### After Code Changes

**Flutter changes:**
- Press 'R' in Flutter terminal (hot restart)

**Backend changes:**
```powershell
cd e:\gharsewa\backend
docker-compose restart app
```

**Environment changes (.env):**
```powershell
cd e:\gharsewa\backend
docker-compose exec app php artisan config:clear
docker-compose restart app
```

---

## Useful Commands

### Backend Commands

```powershell
# View logs
docker-compose logs -f app

# Clear cache
docker-compose exec app php artisan config:clear

# Run migrations
docker-compose exec app php artisan migrate

# Test email
docker-compose exec app php test-email-simple.php

# Access shell
docker-compose exec app bash
```

### Flutter Commands

```powershell
# Run on specific device
flutter run -d windows
flutter run -d chrome
flutter run -d <device-id>

# Build release
flutter build windows
flutter build web

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build
flutter clean
```

---

## What's Running Where

| Service | URL | Purpose |
|---------|-----|---------|
| Backend API | http://localhost:8000 | Laravel API |
| MySQL | localhost:3306 | Database |
| Redis | localhost:6379 | Cache |
| Flutter App | N/A | Desktop/Web/Mobile app |

---

## Summary

**To run everything:**

1. **Start Backend:**
   ```powershell
   cd e:\gharsewa\backend
   docker-compose up -d
   ```

2. **Start Flutter:**
   ```powershell
   cd e:\gharsewa
   flutter run -d windows
   ```

3. **Test authentication flows**

4. **Make changes and hot restart (press 'R')**

5. **Stop when done:**
   - Press 'q' in Flutter
   - Run `docker-compose down` in backend

---

*You're all set! Start the backend, run the Flutter app, and test the authentication!* 🚀
