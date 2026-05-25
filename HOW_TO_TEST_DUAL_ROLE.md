# 🧪 How to Test Dual Role Support

**Feature**: Users can now have both Customer and Service Provider roles

---

## ✅ Prerequisites

1. **Backend running**: `docker-compose up -d`
2. **Flutter app running**: `flutter run` or use your IDE
3. **Database migrated**: Migration already applied (adds `roles` column)

---

## 🎯 Test Scenario 1: Customer → Service Provider Upgrade

### Step 1: Register as Customer

1. Open the app
2. Click "Register" (or "Don't have an account? Register")
3. Fill in the form:
   - **Name**: Test User
   - **Email**: test@example.com
   - **Password**: Test1234
   - **Role**: Select "Customer" (should be default)
4. Click "Register"

### Step 2: Verify Email

1. Check your email for OTP code
2. Enter the 6-digit OTP
3. Click "Verify"
4. You should be automatically logged in to the **Customer Panel**

### Step 3: Explore Customer Panel

1. You should see bottom navigation with 5 tabs:
   - 🏠 Home
   - 📖 Bookings
   - ✨ AI Assistant
   - 🛒 Store
   - 👤 Profile
2. **Notice**: No AppBar at the top (you only have customer role)

### Step 4: Become Service Provider

1. Go to **Profile** tab (bottom right)
2. Scroll down
3. You should see a green button: **"Become a Service Provider"**
4. Click the button
5. A confirmation dialog appears:
   ```
   Become a Service Provider
   
   Would you like to upgrade your account to offer services?
   You'll be able to access both customer and provider features.
   
   [Cancel]  [Upgrade]
   ```
6. Click **"Upgrade"**
7. Loading indicator appears
8. Success message: "🎉 You are now a service provider!"
9. **Automatically navigates to Provider Dashboard**

### Step 5: Explore Provider Panel

1. You should now be on the **Provider Dashboard**
2. Bottom navigation shows 4 tabs:
   - 📊 Dashboard
   - 📖 Bookings
   - 🛠️ Services
   - 📈 Analytics
3. **Notice**: AppBar at the top shows:
   ```
   Provider Panel  [Switch to Customer] ⇄
   ```

### Step 6: Test Role Switcher

1. Click **"Switch to Customer"** in the AppBar
2. You should navigate to **Customer Home**
3. **Notice**: AppBar now shows:
   ```
   Customer Panel  [Switch to Provider] ⇄
   ```
4. Click **"Switch to Provider"** in the AppBar
5. You should navigate back to **Provider Dashboard**

### Step 7: Verify Button Hidden

1. Switch back to Customer Panel
2. Go to **Profile** tab
3. Scroll down
4. **Notice**: "Become a Service Provider" button is **HIDDEN**
5. (You already have provider role, so button doesn't show)

---

## 🎯 Test Scenario 2: Direct Service Provider Registration

### Step 1: Register as Service Provider

1. Open the app (or logout if already logged in)
2. Click "Register"
3. Fill in the form:
   - **Name**: Provider User
   - **Email**: provider@example.com
   - **Password**: Test1234
   - **Role**: Select **"Service Provider"**
4. Click "Register"

### Step 2: Verify Email

1. Check your email for OTP code
2. Enter the 6-digit OTP
3. Click "Verify"
4. You should be automatically logged in to the **Provider Panel**

### Step 3: Check Role Switcher

1. You should be on **Provider Dashboard**
2. **Notice**: **NO AppBar** at the top
3. (You only have provider role, not customer role)
4. You cannot switch to customer panel

---

## 🎯 Test Scenario 3: Error Handling

### Test 3.1: Network Error

1. Turn off your internet connection
2. Go to Customer Profile
3. Click "Become a Service Provider"
4. Click "Upgrade" in dialog
5. Loading indicator appears
6. Error message appears: "Error: Failed to become service provider"
7. You should **stay on Customer Profile** (not navigate away)

### Test 3.2: Already Provider

1. User with both roles (completed Scenario 1)
2. Go to Customer Profile
3. Scroll down
4. **Notice**: "Become a Service Provider" button is **HIDDEN**
5. (Cannot become provider if already provider)

---

## 🎯 Test Scenario 4: Backend Verification

### Check User Roles in Database

```bash
# Connect to database
docker-compose exec db mysql -u root -p
# Password: root

# Use database
USE gharsewa;

# Check user roles
SELECT id, name, email, role, roles FROM users WHERE email = 'test@example.com';
```

**Expected Result**:
```
+------+-----------+-------------------+----------------+-------------------------------+
| id   | name      | email             | role           | roles                         |
+------+-----------+-------------------+----------------+-------------------------------+
| uuid | Test User | test@example.com  | serviceProvider| ["customer","serviceProvider"]|
+------+-----------+-------------------+----------------+-------------------------------+
```

### Check API Response

```bash
# Login to get access token
curl -X POST http://localhost:8000/api/v1/auth/jwt/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234"
  }'

# Copy the access_token from response

# Get user info
curl -X GET http://localhost:8000/api/v1/auth/jwt/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Test User",
    "email": "test@example.com",
    "role": "serviceProvider",
    "roles": ["customer", "serviceProvider"],
    "phone_number": null,
    "profile_image_url": null,
    "is_active": true,
    "email_verified_at": "2026-05-25T10:00:00.000000Z"
  }
}
```

---

## ✅ Expected Behavior Summary

### Customer Only:
- ❌ No AppBar with role switcher
- ✅ "Become a Service Provider" button visible
- ❌ Cannot access provider panel

### Customer + Provider:
- ✅ AppBar with "Switch to Provider" button (in customer panel)
- ✅ AppBar with "Switch to Customer" button (in provider panel)
- ❌ "Become a Service Provider" button hidden
- ✅ Can access both panels

### Provider Only:
- ❌ No AppBar with role switcher
- ❌ Cannot access customer panel (no customer role)

---

## 🐛 Common Issues

### Issue 1: Button Not Showing
**Problem**: "Become a Service Provider" button not visible  
**Solution**: 
- Make sure you're logged in as customer
- Make sure you don't already have provider role
- Check if you're on the Profile tab

### Issue 2: Role Switcher Not Showing
**Problem**: AppBar with role switcher not visible  
**Solution**:
- Make sure you have both customer and provider roles
- Check database: `roles` should be `["customer", "serviceProvider"]`

### Issue 3: API Error
**Problem**: "Failed to become service provider"  
**Solution**:
- Check backend is running: `docker-compose ps`
- Check backend logs: `docker-compose logs -f app`
- Verify JWT token is valid (not expired)

### Issue 4: Navigation Not Working
**Problem**: Clicking role switcher doesn't navigate  
**Solution**:
- Check console for errors
- Verify routes are defined in `app_router.dart`
- Try hot restart: `r` in terminal or restart app

---

## 📊 Test Checklist

- [ ] Register as customer
- [ ] Verify email
- [ ] See customer panel (no AppBar)
- [ ] See "Become a Service Provider" button
- [ ] Click button and confirm
- [ ] See success message
- [ ] Navigate to provider dashboard
- [ ] See AppBar with "Switch to Customer"
- [ ] Click "Switch to Customer"
- [ ] Navigate to customer home
- [ ] See AppBar with "Switch to Provider"
- [ ] Click "Switch to Provider"
- [ ] Navigate back to provider dashboard
- [ ] Go to customer profile
- [ ] Verify "Become a Service Provider" button is hidden
- [ ] Register new user as service provider
- [ ] Verify no AppBar (provider only)
- [ ] Test network error handling
- [ ] Verify database has correct roles

---

## 🎉 Success Criteria

✅ Customer can upgrade to service provider  
✅ User with both roles can switch between panels  
✅ Role switcher only shows when user has multiple roles  
✅ "Become a Service Provider" button only shows for customers  
✅ Navigation works correctly  
✅ Error handling works  
✅ Database stores roles correctly  
✅ API returns correct role information

---

**Happy Testing!** 🚀

If you encounter any issues, check the logs:
- **Flutter**: Check console output
- **Backend**: `docker-compose logs -f app`
- **Database**: Connect and query users table

