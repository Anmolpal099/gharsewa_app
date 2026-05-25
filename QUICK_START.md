# ⚡ Quick Start Guide

## 🚀 Run the App (2 Commands)

### 1. Start Backend
```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

### 2. Start Flutter
```powershell
cd e:\gharsewa
flutter run -d windows
```

**That's it!** Your app is now running.

---

## 🧪 Test Authentication

### Get OTP from Logs
```powershell
cd e:\gharsewa\backend
docker-compose exec app tail -100 storage/logs/laravel.log | Select-String "otp"
```

Look for: `"otp":"123456"`

---

## 🔄 After Code Changes

### Flutter Changes
Press **`R`** in Flutter terminal (hot restart)

### Backend Changes
```powershell
cd e:\gharsewa\backend
docker-compose restart app
```

---

## 🛑 Stop Everything

### Stop Flutter
Press **`q`** in Flutter terminal

### Stop Backend
```powershell
cd e:\gharsewa\backend
docker-compose down
```

---

## 📚 Full Documentation

- **HOW_TO_RUN.md** - Complete guide
- **WORK_COMPLETED_SUMMARY.md** - What's been done
- **NAVIGATION_FINAL_FIX.md** - Navigation troubleshooting
- **EMAIL_NOT_RECEIVED_FIX.md** - Email issues

---

## ✅ What's Working

- ✅ Registration with OTP
- ✅ Email verification
- ✅ Login with JWT
- ✅ Password reset
- ✅ Role-based navigation

---

**Ready to code!** 🎉
