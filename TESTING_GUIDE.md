# 🧪 Testing Guide - Gharsewa Application

**Date:** 2026-05-21  
**Firebase Project:** homeservice-bf77e

---

## 📋 Prerequisites

Before testing, ensure:
- ✅ Docker containers are running
- ✅ Flutter dependencies installed
- ✅ Firebase project exists
- ⚠️ Firebase credentials need to be replaced

---

## Step 1: Get Real Firebase Credentials

### 1.1 Go to Firebase Console

Visit: https://console.firebase.google.com/

### 1.2 Select Your Project

Select project: **homeservice-bf77e**

### 1.3 Generate Service Account Key

1. Click the gear icon (⚙️) → **Project Settings**
2. Go to **Service Accounts** tab
3. Click **Generate New Private Key**
4. Click **Generate Key** (downloads a JSON file)
5. Save the file as `firebase-credentials.json`

### 1.4 Replace Placeholder File

**Option A: Manual Copy**
```bash
# Copy the downloaded file to backend storage
copy "C:\Users\YourName\Downloads\homeservice-bf77e-*.json" "e:\gharsewa\backend\storage\app\firebase-credentials.json"
```

**Option B: Direct Placement**
1. Open File Explorer
2. Navigate to `e:\gharsewa\backend\storage\app\`
3. Replace `firebase-credentials.json` with the downloaded file
4. Rename it to `firebase-credentials.json` if needed

### 1.5 Restart Docker Containers

```bash
cd e:\gharsewa\backend
docker-compose restart app
```

**Wait 5 seconds for the container to restart**

---

## Step 2: Verify Backend is Working

### 2.1 Check Container Status

```bash
docker ps --filter "name=gharsewa_app"
```

**Expected Output:**
```
NAMES          STATUS
gharsewa_app   Up X seconds
```

### 2.2 Test Health Endpoint

```bash
curl http://localhost:8000/api/v1/health
```

**Expected Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-05-21T..."
}
```

### 2.3 Check Logs for Errors

```bash
docker-compose logs -f app
```

**Look for:**
- ✅ No Firebase credential errors
- ✅ No authentication errors
- ✅ Server started successfully

Press `Ctrl+C` to stop viewing logs.

---

## Step 3: Configure Firebase in Flutter

### 3.1 Check Android Configuration

**File:** `android/app/google-services.json`

If this file doesn't exist:

1. Go to Firebase Console → Project Settings
2. Scroll down to "Your apps"
3. Click Android icon or "Add app"
4. Enter package name: `com.gharsewa.app`
5. Download `google-services.json`
6. Place it in `android/app/google-services.json`

### 3.2 Check Web Configuration

**File:** `web/index.html`

Verify Firebase SDK is configured (should already be there from setup).

### 3.3 Enable Authentication Methods

1. Go to Firebase Console → Authentication
2. Click "Get started" (if not already enabled)
3. Go to "Sign-in method" tab
4. Enable **Email/Password**:
   - Click "Email/Password"
   - Toggle "Enable"
   - Click "Save"

---

## Step 4: Run the Flutter App

### 4.1 Get Dependencies

```bash
cd e:\gharsewa
flutter pub get
```

### 4.2 Run on Web (Recommended for Testing)

```bash
flutter run -d chrome --dart-define-from-file=.env.dev
```

**Or run on Android:**
```bash
flutter run -d android --dart-define-from-file=.env.dev
```

### 4.3 Wait for App to Load

The app should open in Chrome and show the login screen.

---

## Step 5: Test User Registration

### 5.1 Register a Test Customer

1. Click "Don't have an account? Register"
2. Enter details:
   - **Name:** Test Customer
   - **Email:** customer@test.com
   - **Password:** Test1234
3. Click "Create Account"

**Expected Result:**
- ✅ Account created in Firebase
- ✅ User record created in MySQL database
- ✅ Role set to "customer" (default)
- ✅ Redirected to Customer Dashboard

### 5.2 Verify in Firebase Console

1. Go to Firebase Console → Authentication → Users
2. You should see: `customer@test.com`
3. Click on the user
4. Check "Custom claims" → should show: `{"role": "customer"}`

### 5.3 Verify in Database

```bash
docker exec -it gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SELECT id, email, name, role, is_active FROM users;"
```

**Expected Output:**
```
+--------------------------------------+-------------------+---------------+----------+-----------+
| id                                   | email             | name          | role     | is_active |
+--------------------------------------+-------------------+---------------+----------+-----------+
| 9d4e8f2a-1234-5678-90ab-cdef12345678 | customer@test.com | Test Customer | customer |         1 |
+--------------------------------------+-------------------+---------------+----------+-----------+
```

---

## Step 6: Test Customer Features

### 6.1 Browse Services

1. Navigate to "Services" tab
2. You should see a list of services (mock data)
3. Try the search bar
4. Try the filters

### 6.2 View Service Details

1. Click on any service card
2. You should see:
   - Service name and description
   - Price and duration
   - Provider information
   - "Book Now" button

### 6.3 Create a Booking

1. Click "Book Now"
2. Select date and time
3. Click "Confirm Booking"
4. You should see success message

### 6.4 View Bookings

1. Navigate to "Bookings" tab
2. You should see your bookings
3. Try filtering by status
4. Try canceling a booking

### 6.5 View Profile

1. Navigate to "Profile" tab
2. You should see your profile information
3. Try editing your name
4. Try uploading a profile picture (if implemented)

---

## Step 7: Register a Service Provider

### 7.1 Logout

1. Click logout button (usually in profile or menu)
2. You should be redirected to login screen

### 7.2 Register as Provider

1. Click "Don't have an account? Register"
2. Enter details:
   - **Name:** Test Provider
   - **Email:** provider@test.com
   - **Password:** Test1234
3. Click "Create Account"

**Note:** By default, new users are registered as "customer". We'll change this to "serviceProvider" in the next step.

---

## Step 8: Create First Admin User

### 8.1 Register Admin Account

1. Register a new account:
   - **Name:** Admin User
   - **Email:** admin@gharsewa.com
   - **Password:** Admin1234

### 8.2 Get User ID from Database

```bash
docker exec -it gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SELECT id, email, name, role FROM users WHERE email='admin@gharsewa.com';"
```

**Copy the UUID (id) from the output.**

### 8.3 Update Role to Admin via Laravel Tinker

```bash
docker exec -it gharsewa_app php artisan tinker
```

**In Tinker, run:**
```php
// Find the user
$user = App\Models\User::where('email', 'admin@gharsewa.com')->first();

// Update role in database
$user->update(['role' => 'admin']);

// Set Firebase custom claims
$factory = (new Kreait\Firebase\Factory)->withServiceAccount(storage_path('app/firebase-credentials.json'));
$auth = $factory->createAuth();
$auth->setCustomUserClaims($user->firebase_uid, ['role' => 'admin']);

// Verify
echo "User role updated to: " . $user->role;

// Exit tinker
exit
```

### 8.4 Update Provider Role (Optional)

Repeat the same process for `provider@test.com` but set role to `serviceProvider`:

```php
$user = App\Models\User::where('email', 'provider@test.com')->first();
$user->update(['role' => 'serviceProvider']);
$factory = (new Kreait\Firebase\Factory)->withServiceAccount(storage_path('app/firebase-credentials.json'));
$auth = $factory->createAuth();
$auth->setCustomUserClaims($user->firebase_uid, ['role' => 'serviceProvider']);
exit
```

---

## Step 9: Test Admin Features

### 9.1 Login as Admin

1. Logout from current account
2. Login with:
   - **Email:** admin@gharsewa.com
   - **Password:** Admin1234
3. **Important:** Force token refresh to get new role claims:
   - Close the app completely
   - Reopen the app
   - Login again

**Expected Result:**
- ✅ Redirected to Admin Dashboard

### 9.2 View Admin Dashboard

1. You should see:
   - Total users count
   - Total bookings count
   - Total revenue
   - Platform statistics
   - Recent activities

### 9.3 Manage Users

1. Navigate to "Users" section
2. You should see all registered users
3. Try searching for a user
4. Click on a user to view details
5. Try activating/deactivating a user

### 9.4 Change User Role

1. Go to Users section
2. Select `provider@test.com`
3. Click "Change Role"
4. Select "Service Provider"
5. Click "Update"

**Verify:**
```bash
docker exec -it gharsewa_db mysql -u gharsewa_user -pgharsewa_password gharsewa -e "SELECT email, role FROM users WHERE email='provider@test.com';"
```

### 9.5 View All Bookings

1. Navigate to "Bookings" section
2. You should see all bookings from all users
3. Try filtering by status
4. Try searching by customer or provider
5. Try canceling a booking
6. Try adding a note to a booking

### 9.6 Generate Reports

1. Navigate to "Reports" section
2. Select report type (Users, Bookings, Revenue)
3. Select date range
4. Click "Generate Report"
5. Try exporting as CSV
6. Try exporting as PDF

---

## Step 10: Test Provider Features

### 10.1 Login as Provider

1. Logout from admin account
2. Login with:
   - **Email:** provider@test.com
   - **Password:** Test1234
3. Force token refresh (close and reopen app)

**Expected Result:**
- ✅ Redirected to Provider Dashboard

### 10.2 View Provider Dashboard

1. You should see:
   - Current month earnings
   - Pending bookings count
   - Confirmed bookings count
   - Completed bookings count
   - Bookings chart

### 10.3 Manage Services

1. Navigate to "Services" tab
2. Click "Add Service"
3. Fill in service details:
   - Name: "House Cleaning"
   - Description: "Professional house cleaning service"
   - Category: "Cleaning"
   - Price: 50
   - Duration: 120 minutes
4. Click "Create Service"

**Expected Result:**
- ✅ Service created
- ✅ Appears in services list

### 10.4 Manage Bookings

1. Navigate to "Bookings" tab
2. You should see booking requests
3. Try accepting a booking
4. Try rejecting a booking (with reason)
5. Try marking a booking as completed

### 10.5 View Analytics

1. Navigate to "Analytics" tab
2. You should see:
   - Revenue breakdown by service
   - Bookings over time chart
   - Top services
   - Customer ratings

---

## Step 11: Test API Endpoints Directly

### 11.1 Get Firebase ID Token

**In Flutter app (add temporary debug code):**
```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
print('ID Token: $token');
```

**Or use Firebase CLI:**
```bash
firebase login
firebase auth:export users.json --project homeservice-bf77e
```

### 11.2 Test Auth Endpoints

**Register:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "YOUR_FIREBASE_ID_TOKEN",
    "name": "API Test User",
    "role": "customer"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "id_token": "YOUR_FIREBASE_ID_TOKEN"
  }'
```

**Get Current User:**
```bash
curl -X GET http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN"
```

### 11.3 Test Protected Endpoints

**Customer Dashboard:**
```bash
curl -X GET http://localhost:8000/api/v1/customer/dashboard \
  -H "Authorization: Bearer YOUR_CUSTOMER_TOKEN"
```

**Provider Dashboard:**
```bash
curl -X GET http://localhost:8000/api/v1/provider/dashboard \
  -H "Authorization: Bearer YOUR_PROVIDER_TOKEN"
```

**Admin Dashboard:**
```bash
curl -X GET http://localhost:8000/api/v1/admin/dashboard \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### 11.4 Test Role-Based Access

**Try accessing admin endpoint as customer (should fail with 403):**
```bash
curl -X GET http://localhost:8000/api/v1/admin/dashboard \
  -H "Authorization: Bearer YOUR_CUSTOMER_TOKEN"
```

**Expected Response:**
```json
{
  "error": "Forbidden",
  "message": "Insufficient permissions"
}
```

---

## Step 12: Test Token Refresh

### 12.1 Wait for Token to Expire

Firebase tokens expire after 1 hour. To test immediately:

1. Get a fresh token
2. Make an API request (should succeed)
3. Manually expire the token (or wait 1 hour)
4. Make another API request
5. The Dio interceptor should automatically refresh the token
6. Request should succeed

### 12.2 Force Token Refresh

**In Flutter:**
```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
```

---

## 🐛 Troubleshooting

### Issue: "Firebase credentials not found"

**Solution:**
1. Verify file exists: `backend/storage/app/firebase-credentials.json`
2. Check file permissions
3. Restart Docker containers

### Issue: "Invalid token" error

**Solution:**
1. Verify Firebase project ID matches in both frontend and backend
2. Check that custom claims are set correctly
3. Force token refresh: `getIdToken(true)`

### Issue: "403 Forbidden" on protected routes

**Solution:**
1. Verify user role in Firebase Console (Custom claims)
2. Verify user role in database
3. Force token refresh to get updated claims
4. Check RoleMiddleware is applied correctly

### Issue: User not found in database

**Solution:**
1. Verify `/auth/register` was called after Firebase signup
2. Check database connection
3. Check Laravel logs: `docker-compose logs -f app`

### Issue: "CORS error" in browser

**Solution:**
1. Verify CorsMiddleware is configured
2. Check `Access-Control-Allow-Origin` header
3. Restart backend containers

---

## ✅ Testing Checklist

### Backend
- [ ] Docker containers running
- [ ] Database migrations complete
- [ ] API health check passing
- [ ] Firebase credentials replaced
- [ ] No errors in logs

### Authentication
- [ ] User registration working
- [ ] User login working
- [ ] Token verification working
- [ ] Role assignment working
- [ ] Token refresh working

### Customer Panel
- [ ] Dashboard loads
- [ ] Service browsing works
- [ ] Service details view works
- [ ] Booking creation works
- [ ] Booking management works
- [ ] Profile view/edit works

### Provider Panel
- [ ] Dashboard loads
- [ ] Service management works
- [ ] Booking management works
- [ ] Analytics view works

### Admin Panel
- [ ] Dashboard loads
- [ ] User management works
- [ ] Role management works
- [ ] Booking oversight works
- [ ] Reports generation works

### API Endpoints
- [ ] Auth endpoints working
- [ ] Customer endpoints working
- [ ] Provider endpoints working
- [ ] Admin endpoints working
- [ ] Role-based access control working

---

## 📊 Expected Test Results

### Database After Testing

```sql
-- Check users
SELECT id, email, name, role, is_active FROM users;

-- Expected: 3 users (customer, provider, admin)

-- Check bookings (if created)
SELECT id, customer_id, service_id, status FROM bookings;

-- Check services (if created)
SELECT id, provider_id, name, price, status FROM services;
```

### Firebase Console After Testing

**Authentication → Users:**
- customer@test.com (Custom claims: {"role": "customer"})
- provider@test.com (Custom claims: {"role": "serviceProvider"})
- admin@gharsewa.com (Custom claims: {"role": "admin"})

---

## 🎉 Success Criteria

Your system is working correctly if:

✅ All 3 user types can register and login
✅ Each user is redirected to their appropriate panel
✅ Role-based access control is enforced
✅ API endpoints return correct data
✅ Token refresh works automatically
✅ Database records are created correctly
✅ Firebase custom claims are set correctly

---

## 📝 Next Steps After Testing

Once testing is complete:

1. **Replace Mock Data**
   - Update controllers to use real database queries
   - Implement repository pattern
   - Add validation rules

2. **Continue with Remaining Epics**
   - Epic 9: AI Integration
   - Epic 10: Real-Time Features
   - Epic 11: Payment Integration
   - Epic 12: Notification Systems
   - Epic 13: Testing & QA
   - Epic 14: Deployment

3. **Production Preparation**
   - Set up production Firebase project
   - Configure production environment variables
   - Set up monitoring and logging
   - Prepare deployment scripts

---

**Happy Testing!** 🚀

