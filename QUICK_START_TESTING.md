# 🚀 Quick Start - Test OTP System

## ✅ System Status: READY

**Backend:** ✅ Working  
**Frontend:** ✅ Complete  
**OTP Endpoints:** ✅ Tested

---

## 🎯 Start Testing in 3 Steps

### Step 1: Start Flutter App

```bash
cd e:\gharsewa
flutter run
```

### Step 2: Open OTP Monitor (New Terminal)

```powershell
docker exec gharsewa_app tail -f storage/logs/laravel.log
```

### Step 3: Test Registration

1. Click "Don't have an account? Register"
2. Fill form and click "Create Account"
3. **Look at the OTP monitor terminal** for the 6-digit code
4. Enter the code in the app
5. Login → Should go directly to dashboard!

---

## 📋 What to Test

### ✅ Test 1: Registration with OTP
- Register new user
- Get OTP from logs
- Enter OTP
- Verify email
- Login (should work without asking for verification again)

### ✅ Test 2: Forgot Password
- Click "Forgot Password?" on login
- Enter email
- Get OTP from logs
- Enter OTP
- Set new password
- Login with new password

### ✅ Test 3: Unverified User Login
- Register but don't enter OTP
- Close app
- Try to login
- Should ask for OTP verification
- Enter OTP
- Should allow login

---

## 🔍 Where to Find OTPs

**In the OTP monitor terminal, look for:**
```
OTP Email - To: user@example.com, OTP: 123456, Purpose: Email Verification
```

The 6-digit code is your OTP!

---

## 🎨 UI Features to Check

### OTP Input Screen
- ✅ 6 input boxes
- ✅ Auto-focus next box
- ✅ Auto-verify when complete
- ✅ Resend button (60s cooldown)
- ✅ 10-minute timer

### New Password Screen
- ✅ Password strength indicator
- ✅ Requirements checklist
- ✅ Show/hide password

### Forgot Password Screen
- ✅ Email validation
- ✅ Send OTP button
- ✅ Back to login link

---

## 🐛 If Something Goes Wrong

### OTP endpoint returns error:
```powershell
docker exec gharsewa_app chmod -R 777 storage/logs
docker exec gharsewa_app php artisan cache:clear
```

### Can't see OTPs in logs:
```powershell
docker exec gharsewa_app tail -n 50 storage/logs/laravel.log | Select-String "OTP"
```

### Containers not running:
```powershell
cd e:\gharsewa\backend
docker-compose restart app
```

---

## ✅ Expected Results

### Registration Flow
```
Register → OTP Screen → Enter Code → "Email verified!" → Login → Dashboard
```

### Forgot Password Flow
```
Forgot Password → Enter Email → OTP Screen → Enter Code → New Password → Login
```

### Login (Verified User)
```
Login → Dashboard (direct)
```

### Login (Unverified User)
```
Login → "Verify email" message → OTP Screen → Enter Code → Dashboard
```

---

## 🎉 You're Ready!

**Everything is set up and working. Just run the app and start testing!**

```bash
flutter run
```

**Happy Testing! 🚀**
