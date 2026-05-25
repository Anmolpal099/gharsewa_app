# 🚀 Quick Test Start Guide

**5-Minute Setup to Start Testing**

---

## Step 1: Get Firebase Credentials (2 minutes)

1. **Go to:** https://console.firebase.google.com/
2. **Select project:** homeservice-bf77e
3. **Click:** ⚙️ (Settings) → Project Settings
4. **Go to:** Service Accounts tab
5. **Click:** "Generate New Private Key"
6. **Download** the JSON file

---

## Step 2: Replace Credentials (1 minute)

**Copy the downloaded file:**

```powershell
# Replace with your actual download path
copy "C:\Users\YourName\Downloads\homeservice-bf77e-*.json" "e:\gharsewa\backend\storage\app\firebase-credentials.json"
```

**Or manually:**
1. Open File Explorer
2. Go to `e:\gharsewa\backend\storage\app\`
3. Replace `firebase-credentials.json` with downloaded file

---

## Step 3: Restart Backend (30 seconds)

```powershell
cd e:\gharsewa\backend
docker-compose restart app
```

Wait 5 seconds, then verify:

```powershell
curl http://localhost:8000/api/v1/health
```

**Expected:** `{"status":"ok","timestamp":"..."}`

---

## Step 4: Enable Firebase Authentication (1 minute)

1. **Go to:** https://console.firebase.google.com/
2. **Select:** homeservice-bf77e
3. **Click:** Authentication → Get started
4. **Click:** Sign-in method tab
5. **Enable:** Email/Password
   - Toggle "Enable"
   - Click "Save"

---

## Step 5: Run Flutter App (30 seconds)

```powershell
cd e:\gharsewa
flutter run -d chrome --dart-define-from-file=.env.dev
```

**Wait for app to open in Chrome**

---

## Step 6: Test Registration (1 minute)

1. **Click:** "Don't have an account? Register"
2. **Enter:**
   - Name: Test User
   - Email: test@example.com
   - Password: Test1234
3. **Click:** "Create Account"

**Expected:** Redirected to Customer Dashboard ✅

---

## Step 7: Create Admin User (2 minutes)

### 7.1 Register Admin Account

1. **Logout** from current account
2. **Register** new account:
   - Name: Admin User
   - Email: admin@gharsewa.com
   - Password: Admin1234

### 7.2 Update Role to Admin

```powershell
docker exec -it gharsewa_app php artisan tinker
```

**In Tinker:**
```php
$user = App\Models\User::where('email', 'admin@gharsewa.com')->first();
$user->update(['role' => 'admin']);
$factory = (new Kreait\Firebase\Factory)->withServiceAccount(storage_path('app/firebase-credentials.json'));
$auth = $factory->createAuth();
$auth->setCustomUserClaims($user->firebase_uid, ['role' => 'admin']);
echo "Admin role set!";
exit
```

### 7.3 Login as Admin

1. **Logout** from app
2. **Close** the app completely
3. **Reopen** the app
4. **Login** with admin@gharsewa.com / Admin1234

**Expected:** Redirected to Admin Dashboard ✅

---

## ✅ You're Ready!

You now have:
- ✅ Backend running with real Firebase credentials
- ✅ Test customer account
- ✅ Admin account with full access
- ✅ Authentication working end-to-end

---

## 🎯 What to Test Next

### Test Customer Features
- Browse services
- View service details
- Create bookings
- View bookings
- Edit profile

### Test Admin Features
- View dashboard
- Manage users
- Change user roles
- View all bookings
- Generate reports

---

## 🐛 Quick Troubleshooting

**App won't start?**
```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

**Backend not responding?**
```powershell
docker-compose restart
docker-compose logs -f app
```

**Login not working?**
- Check Firebase Console → Authentication → Users
- Verify email/password is correct
- Try registering a new account

---

## 📚 Full Documentation

For detailed testing instructions, see:
- `TESTING_GUIDE.md` - Complete testing guide
- `ROLE_MANAGEMENT_SETUP.md` - Role management details
- `EPIC_4_COMPLETE.md` - Authentication details

---

**Happy Testing!** 🚀

