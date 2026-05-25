# 📬 Mailtrap Setup - See All Emails Instantly!

## Why Use Mailtrap?

**Problem:** Gmail is not delivering OTP emails to your inbox (spam filtering)

**Solution:** Mailtrap catches ALL emails in a test inbox - you'll see them instantly!

**Benefits:**
- ✅ See emails immediately (no waiting)
- ✅ No spam folder issues
- ✅ Test email templates
- ✅ Free for development
- ✅ Perfect for testing OTP flows

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Create Mailtrap Account

1. Go to: https://mailtrap.io
2. Click "Sign Up" (it's FREE)
3. Sign up with Google or email
4. Verify your email

### Step 2: Get SMTP Credentials

1. After login, you'll see "My Inbox"
2. Click on "My Inbox" (or create a new inbox)
3. Click "SMTP Settings" tab
4. Select "Laravel 9+" from dropdown
5. You'll see credentials like:
   ```
   Host: sandbox.smtp.mailtrap.io
   Port: 2525
   Username: abc123def456
   Password: xyz789uvw012
   ```

### Step 3: Update Your .env File

Open `e:\gharsewa\backend\.env` and update these lines:

```env
# Comment out Gmail settings
# MAIL_HOST=smtp.gmail.com
# MAIL_PORT=587
# MAIL_USERNAME=anmolpal156@gmail.com
# MAIL_PASSWORD=zbpdaovlpjjppnxq

# Add Mailtrap settings
MAIL_MAILER=smtp
MAIL_HOST=sandbox.smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your-mailtrap-username
MAIL_PASSWORD=your-mailtrap-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="noreply@gharsewa.com"
MAIL_FROM_NAME="${APP_NAME}"
```

**Replace:**
- `your-mailtrap-username` with your actual Mailtrap username
- `your-mailtrap-password` with your actual Mailtrap password

### Step 4: Restart Backend

```powershell
cd e:\gharsewa\backend
docker-compose exec app php artisan config:clear
docker-compose restart app
```

### Step 5: Test It!

```powershell
docker-compose exec app php test-email-simple.php
```

**Then:**
1. Go to Mailtrap inbox: https://mailtrap.io/inboxes
2. You'll see the email instantly!
3. Click to view the full email with styling

---

## 🧪 Test Registration Flow

### 1. Register a New User

In your Flutter app or via API:

```powershell
$body = @{
    name = "Mailtrap Test"
    email = "mailtrap@example.com"
    password = "Test1234"
    role = "customer"
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/register" -Method Post -Body $body -Headers $headers
```

### 2. Check Mailtrap Inbox

1. Go to: https://mailtrap.io/inboxes
2. You'll see the OTP email immediately!
3. Click to view the beautiful email template
4. Copy the 6-digit OTP code

### 3. Verify OTP

Use the OTP code in your Flutter app or via API:

```powershell
$body = @{
    email = "mailtrap@example.com"
    otp = "123456"  # Use the actual OTP from Mailtrap
    type = "email_verification"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/api/v1/auth/jwt/verify-otp" -Method Post -Body $body -Headers $headers
```

---

## 📊 What You'll See in Mailtrap

### Email Preview
- Full HTML email with styling
- OTP code clearly displayed
- All email content

### Email Details
- From: noreply@gharsewa.com
- To: mailtrap@example.com
- Subject: Verify Your Email - Gharsewa
- HTML and Text versions

### Email Analysis
- Spam score
- HTML validation
- Email size
- Delivery time

---

## 🎯 Advantages Over Gmail

| Feature | Gmail SMTP | Mailtrap |
|---------|-----------|----------|
| Delivery Speed | 1-5 minutes | Instant |
| Spam Issues | Yes | No |
| See All Emails | No (some filtered) | Yes (all captured) |
| Test Templates | Hard | Easy |
| Email Analytics | No | Yes |
| Free Tier | Yes | Yes (100 emails/month) |
| Setup Difficulty | Medium | Easy |

---

## 🔄 Switch Back to Gmail Later

When you're ready to use real Gmail (for production):

1. **Comment out Mailtrap settings in .env:**
   ```env
   # MAIL_HOST=sandbox.smtp.mailtrap.io
   # MAIL_PORT=2525
   # MAIL_USERNAME=your-mailtrap-username
   # MAIL_PASSWORD=your-mailtrap-password
   ```

2. **Uncomment Gmail settings:**
   ```env
   MAIL_HOST=smtp.gmail.com
   MAIL_PORT=587
   MAIL_USERNAME=anmolpal156@gmail.com
   MAIL_PASSWORD=zbpdaovlpjjppnxq
   MAIL_FROM_ADDRESS="anmolpal156@gmail.com"
   ```

3. **Restart:**
   ```powershell
   docker-compose exec app php artisan config:clear
   docker-compose restart app
   ```

---

## 💡 Pro Tips

### Tip 1: Create Multiple Inboxes

Create separate inboxes for different purposes:
- "Registration Emails"
- "Password Reset Emails"
- "Welcome Emails"

### Tip 2: Share Inbox with Team

Mailtrap allows you to share inboxes with team members for testing.

### Tip 3: Use Email Forwarding

Mailtrap can forward emails to your real email for testing.

### Tip 4: Check Spam Score

Mailtrap shows spam score - helps optimize emails for production.

---

## 🚀 Quick Start Commands

```powershell
# 1. Update .env with Mailtrap credentials
# (See Step 3 above)

# 2. Clear config
cd e:\gharsewa\backend
docker-compose exec app php artisan config:clear

# 3. Restart
docker-compose restart app

# 4. Test email
docker-compose exec app php test-email-simple.php

# 5. Check Mailtrap inbox
# Go to: https://mailtrap.io/inboxes
```

---

## ✅ Success Checklist

After setup, verify:

- [ ] Mailtrap account created
- [ ] SMTP credentials copied
- [ ] .env file updated
- [ ] Backend restarted
- [ ] Test email sent
- [ ] Email appears in Mailtrap inbox instantly
- [ ] Can view full email with styling
- [ ] OTP code is visible

---

## 📞 Need Help?

**Mailtrap not working?**

1. **Check credentials:**
   ```powershell
   docker-compose exec app php artisan config:show mail
   ```

2. **Check logs:**
   ```powershell
   docker-compose exec app tail -100 storage/logs/laravel.log
   ```

3. **Test connection:**
   ```powershell
   docker-compose exec app php test-smtp-connection.php
   ```

**Still having issues?**
- Verify Mailtrap credentials are correct
- Check you're using the right inbox
- Try creating a new inbox in Mailtrap

---

## 🎉 Summary

**Setup Time:** 5 minutes
**Cost:** Free
**Emails Delivered:** 100% (all captured)
**Spam Issues:** None
**Perfect For:** Development & Testing

**After setup:**
- ✅ See all OTP emails instantly
- ✅ Test registration flow completely
- ✅ Test password reset flow
- ✅ View beautiful email templates
- ✅ No more Gmail spam issues

---

*Mailtrap is the industry standard for email testing in development!*
