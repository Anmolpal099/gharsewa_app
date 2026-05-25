# 🎯 How to See the Role Selector

## Issue
"I can't see service provider how to register or login"

## Solution
The role selector is in the code but you need to restart the app to see it.

---

## 📱 Steps to See the Role Selector

### **Step 1: Stop the App**
If the app is currently running, stop it:
- Press `Ctrl + C` in the terminal where `flutter run` is running
- Or click the Stop button in your IDE

### **Step 2: Restart the App**
```bash
flutter run -d chrome
# or
flutter run -d android
```

### **Step 3: Navigate to Registration**
1. Open the app
2. You'll see the login screen
3. Click **"Don't have an account? Register"** at the bottom

### **Step 4: You Should See**
```
┌─────────────────────────────────────┐
│         Gharsewa                    │
│    Create your account              │
├─────────────────────────────────────┤
│                                     │
│  Full Name: [________________]      │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Register as                   │ │
│  │                               │ │
│  │ ⦿ Customer                    │ │  ← You should see this!
│  │   Book services from providers│ │
│  │                               │ │
│  │ ○ Service Provider            │ │  ← And this!
│  │   Offer services to customers │ │
│  └───────────────────────────────┘ │
│                                     │
│  Email: [________________]          │
│                                     │
│  Password: [________________]       │
│                                     │
│  [    Create Account    ]           │
│                                     │
│  Already have an account? Sign In   │
└─────────────────────────────────────┘
```

---

## 🔧 If You Still Don't See It

### **Option 1: Clear Build Cache**
```bash
# Stop the app first, then:
flutter clean
flutter pub get
flutter run -d chrome
```

### **Option 2: Check File Changes**
Make sure the file was saved:
```bash
# Check if the file has the role selector
type lib\presentation\shared\screens\login_screen.dart | findstr "Register as"
```

You should see: `"Register as",`

### **Option 3: Force Hot Restart**
If app is running:
1. Press `R` (capital R) in the terminal to hot restart
2. Or press `Shift + R` in VS Code

---

## 📸 What the Role Selector Looks Like

### **Customer Selected (Default)**:
```
┌─────────────────────────────────┐
│ Register as                     │
│                                 │
│ ⦿ Customer                      │  ← Selected (filled circle)
│   Book services from providers  │
│                                 │
│ ○ Service Provider              │  ← Not selected (empty circle)
│   Offer services to customers   │
└─────────────────────────────────┘
```

### **Service Provider Selected**:
```
┌─────────────────────────────────┐
│ Register as                     │
│                                 │
│ ○ Customer                      │  ← Not selected
│   Book services from providers  │
│                                 │
│ ⦿ Service Provider              │  ← Selected (filled circle)
│   Offer services to customers   │
└─────────────────────────────────┘
```

---

## ✅ Registration Flow

### **To Register as Customer**:
1. Click "Don't have an account? Register"
2. Fill in Name, Email, Password
3. **Keep "Customer" selected** (it's default)
4. Click "Create Account"
5. Verify email with OTP
6. You'll be redirected to **Customer Dashboard**

### **To Register as Service Provider**:
1. Click "Don't have an account? Register"
2. Fill in Name, Email, Password
3. **Click on "Service Provider" radio button**
4. Click "Create Account"
5. Verify email with OTP
6. You'll be redirected to **Provider Dashboard**

---

## 🐛 Troubleshooting

### **Problem: Role selector not visible**
**Solution**: 
```bash
# 1. Stop the app
# 2. Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

### **Problem: Can't click on Service Provider**
**Solution**: Make sure you're in **Register mode**, not Login mode
- You should see "Create your account" at the top
- If you see "Welcome back", click "Don't have an account? Register"

### **Problem: Getting validation error**
**Solution**: Make sure password meets requirements:
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 digit

**Valid examples**: `Test1234`, `Password123`, `MyPass99`

---

## 🎯 Quick Test

Run this command to verify the role selector is in the file:

```powershell
# Windows PowerShell
Select-String -Path "lib\presentation\shared\screens\login_screen.dart" -Pattern "Service Provider"
```

You should see multiple matches including:
- `title: const Text('Service Provider'),`
- `subtitle: const Text('Offer services to customers'),`

---

## 📞 Still Having Issues?

If you still can't see the role selector after trying all the above:

1. **Check if you're on the right screen**:
   - You must click "Don't have an account? Register"
   - The role selector only appears in **registration mode**
   - It does NOT appear in login mode

2. **Verify the app restarted**:
   - Look for "Hot restart" or "Restarted application" in the terminal
   - If you only see "Hot reload", that's not enough - do a full restart

3. **Check browser cache** (if using web):
   - Press `Ctrl + Shift + R` to hard refresh
   - Or clear browser cache

---

**The role selector is definitely in the code and should be visible after restarting the app!** 🎉
