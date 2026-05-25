# Quick Test Reference Card

## 🚀 Quick Start

### 1. Start Backend
```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

### 2. Get JWT Token
```bash
# Login
POST http://localhost:8000/api/v1/auth/jwt/login
Content-Type: application/json

{
  "email": "your@email.com",
  "password": "yourpassword"
}

# Copy the access_token from response
```

---

## 📝 Profile APIs (Task 15)

### Get Profile
```bash
GET http://localhost:8000/api/v1/profile
Authorization: Bearer {token}
```

### Update Profile
```bash
PUT http://localhost:8000/api/v1/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "New Name",
  "phone_number": "+1234567890",
  "address": "123 Main St"
}
```

### Upload Image
```bash
POST http://localhost:8000/api/v1/profile/image
Authorization: Bearer {token}
Content-Type: multipart/form-data

image: [select JPEG/PNG/JPG file < 2MB]
```

---

## 📊 Provider Dashboard APIs (Task 18)

**Note**: Requires serviceProvider role token

### Get Provider Profile
```bash
GET http://localhost:8000/api/v1/provider/profile
Authorization: Bearer {provider_token}
```

### Update Provider Profile
```bash
PUT http://localhost:8000/api/v1/provider/profile
Authorization: Bearer {provider_token}
Content-Type: application/json

{
  "name": "Provider Name",
  "phone_number": "+1234567890",
  "business_name": "My Business",
  "business_description": "We provide services",
  "address": "456 Business Ave"
}
```

### Get Dashboard
```bash
GET http://localhost:8000/api/v1/provider/dashboard
Authorization: Bearer {provider_token}
```

### Get Earnings (Daily)
```bash
GET http://localhost:8000/api/v1/provider/earnings?date_from=2024-01-01&date_to=2024-01-31&group_by=day
Authorization: Bearer {provider_token}
```

### Get Earnings (Weekly)
```bash
GET http://localhost:8000/api/v1/provider/earnings?date_from=2024-01-01&date_to=2024-01-31&group_by=week
Authorization: Bearer {provider_token}
```

### Get Earnings (Monthly)
```bash
GET http://localhost:8000/api/v1/provider/earnings?date_from=2024-01-01&date_to=2024-12-31&group_by=month
Authorization: Bearer {provider_token}
```

---

## ✅ Expected Responses

### Success (200)
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Validation Error (422)
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "field": ["Error message"]
  }
}
```

### Unauthorized (401)
```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

### Forbidden (403)
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

---

## 🔧 Useful Docker Commands

```powershell
# View logs
docker-compose logs -f app

# Restart app
docker-compose restart app

# Check services
docker-compose ps

# Stop all
docker-compose down
```

---

## 📋 Quick Checklist

### Task 15: Profile APIs
- [ ] Get profile works
- [ ] Update profile works
- [ ] Upload image works
- [ ] Validation errors work
- [ ] Old image deleted

### Task 18: Provider Dashboard
- [ ] Get provider profile works
- [ ] Update provider profile works
- [ ] Dashboard statistics accurate
- [ ] Earnings daily grouping works
- [ ] Earnings weekly grouping works
- [ ] Earnings monthly grouping works
- [ ] Customer token returns 403

---

## 🐛 Troubleshooting

### Issue: 401 Unauthorized
**Fix**: Get a new JWT token (login again)

### Issue: 403 Forbidden
**Fix**: Use correct role token (provider for provider endpoints)

### Issue: 422 Validation Error
**Fix**: Check error message and fix input data

### Issue: 500 Server Error
**Fix**: Check logs: `docker-compose logs -f app`

---

**For detailed testing guide, see: `TESTING_GUIDE_TASKS_15_18.md`**
