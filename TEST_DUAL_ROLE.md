# 🧪 Testing Dual Role Support

## Quick Test Guide

### **Method 1: Using PowerShell/curl**

```powershell
# 1. Register as Customer
$registerResponse = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/register" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"name":"Test User","email":"testdual@example.com","password":"Test1234","role":"customer"}'

# 2. Get OTP from backend logs
docker-compose -f backend/docker-compose.yml logs -f app | Select-String "OTP"

# 3. Verify Email (replace OTP_CODE with actual OTP)
$verifyResponse = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/otp/verify-email" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"email":"testdual@example.com","otp":"OTP_CODE"}'

$accessToken = $verifyResponse.data.access_token

# 4. Check Current Roles
$meResponse = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/me" `
  -Method GET `
  -Headers @{"Authorization"="Bearer $accessToken"}

Write-Host "Current Roles:" $meResponse.data.roles

# 5. Become Service Provider
$upgradeResponse = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/become-service-provider" `
  -Method POST `
  -Headers @{"Authorization"="Bearer $accessToken"}

Write-Host "Upgrade Response:" $upgradeResponse.message

# 6. Check Updated Roles
$meResponse2 = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/me" `
  -Method GET `
  -Headers @{"Authorization"="Bearer $accessToken"}

Write-Host "Updated Roles:" $meResponse2.data.roles
```

---

### **Method 2: Using Database Query**

```sql
-- Connect to MySQL
docker-compose -f backend/docker-compose.yml exec db mysql -u root -proot gharsewa

-- Check user roles
SELECT id, name, email, role, roles 
FROM users 
WHERE email = 'testdual@example.com';

-- Expected result after upgrade:
-- role: "serviceProvider"
-- roles: ["customer", "serviceProvider"]
```

---

### **Method 3: Using Postman**

#### **Step 1: Register**
```
POST http://localhost:8000/api/v1/auth/jwt/register
Content-Type: application/json

{
  "name": "Test User",
  "email": "testdual@example.com",
  "password": "Test1234",
  "role": "customer"
}
```

#### **Step 2: Verify Email**
```
POST http://localhost:8000/api/v1/auth/otp/verify-email
Content-Type: application/json

{
  "email": "testdual@example.com",
  "otp": "123456"
}

Save the access_token from response
```

#### **Step 3: Check Current Roles**
```
GET http://localhost:8000/api/v1/auth/jwt/me
Authorization: Bearer {access_token}

Response should show:
{
  "data": {
    "role": "customer",
    "roles": ["customer"]
  }
}
```

#### **Step 4: Become Service Provider**
```
POST http://localhost:8000/api/v1/auth/jwt/become-service-provider
Authorization: Bearer {access_token}

Response:
{
  "success": true,
  "message": "Successfully upgraded to service provider. You can now offer services!",
  "data": {
    "role": "serviceProvider",
    "roles": ["customer", "serviceProvider"]
  }
}
```

#### **Step 5: Verify Updated Roles**
```
GET http://localhost:8000/api/v1/auth/jwt/me
Authorization: Bearer {access_token}

Response should show:
{
  "data": {
    "role": "serviceProvider",
    "roles": ["customer", "serviceProvider"]
  }
}
```

---

## ✅ Expected Results

### **After Registration (Customer)**:
- `role`: `"customer"`
- `roles`: `["customer"]`

### **After Becoming Service Provider**:
- `role`: `"serviceProvider"`
- `roles`: `["customer", "serviceProvider"]`

### **User Can Now**:
- ✅ Access customer panel (book services)
- ✅ Access provider panel (offer services)
- ✅ Switch between both roles

---

## 🐛 Troubleshooting

### **Error: "You are already a service provider"**
- User already has serviceProvider role
- Check roles with `/me` endpoint

### **Error: "Unauthenticated"**
- Access token expired or invalid
- Login again to get new token

### **Error: "Email already registered"**
- Use different email or delete existing user:
  ```sql
  DELETE FROM users WHERE email = 'testdual@example.com';
  ```

---

## 📊 Verification Checklist

- [ ] User can register as customer
- [ ] User can verify email with OTP
- [ ] User can login successfully
- [ ] `/me` endpoint shows single role initially
- [ ] User can call `/become-service-provider` endpoint
- [ ] `/me` endpoint shows dual roles after upgrade
- [ ] Database shows correct `roles` JSON array
- [ ] User cannot become provider twice (error message)

---

**Ready to test!** 🚀
