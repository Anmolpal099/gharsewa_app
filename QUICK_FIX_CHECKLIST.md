# Quick Fix Checklist - Provider Upload Issues

## 🎯 Quick Summary
**Problem**: Provider profile photo and certificate uploads show "_Namespace" error on web  
**Cause**: Backend expects file uploads, frontend sends base64  
**Solution**: Update backend to accept base64 (like customer profile)

---

## ✅ 4 Files to Modify

### 1️⃣ `backend/app/Http/Controllers/API/V1/Provider/ProviderController.php`

**Action A**: Add new method `uploadProfileImage()` after line 420
- Copy the method from `CustomerController.php` line 280
- Change log messages to say "Provider" instead of "User"

**Action B**: Update `uploadCertification()` method around line 420
- Replace `'document' => 'required|file|max:51200'`
- With `'document' => ['required', new \App\Rules\Base64Image(51200)]`
- Replace file handling code with base64 decoding (see manual)

---

### 2️⃣ `backend/routes/api.php`

**Action**: Add route around line 80-100 in provider section:
```php
Route::post('/provider/profile/image', [ProviderController::class, 'uploadProfileImage']);
```

---

### 3️⃣ `lib/features/provider_panel/data/services/provider_upload_service.dart`

**Action**: Line 20, change endpoint:
- FROM: `'/v1/profile/image'`
- TO: `'/v1/provider/profile/image'`

---

### 4️⃣ Restart Everything

**Backend**:
```bash
cd backend
./vendor/bin/sail down
./vendor/bin/sail up -d
```

**Frontend**:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 🧪 Test After Fixing

- [ ] Provider profile photo upload works
- [ ] Provider certificate upload works  
- [ ] Customer profile photo still works
- [ ] No "_Namespace" errors on web

---

## 📖 Full Details
See `MANUAL_FIX_PROVIDER_UPLOADS.md` for complete code and explanations.
