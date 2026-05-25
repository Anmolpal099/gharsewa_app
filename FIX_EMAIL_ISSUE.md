# Fix Email Not Sending Issue

## Problem
OTP emails are not being received in Gmail inbox.

## Root Cause
The `MAIL_FROM_ADDRESS` in `.env` was set to `noreply@gharsewa.com` but Gmail requires the FROM address to match the authenticated Gmail account.

## Fix Applied

### Changed in `backend/.env`:
```env
# Before:
MAIL_FROM_ADDRESS="noreply@gharsewa.com"

# After:
MAIL_FROM_ADDRESS="anmolpal156@gmail.com"
```

---

## Steps to Fix

### 1. Restart Laravel Server
After changing `.env`, you MUST restart the Laravel server:

```bash
# Stop the current server (Ctrl+C)
# Then start it again:
cd e:\gharsewa\backend
php artisan serve
```

### 2. Clear Laravel Cache
```bash
cd e:\gharsewa\backend
php artisan config:clear
php artisan cache:clear
```

### 3. Generate APP_KEY (if empty)
If `APP_KEY` in `.env` is empty, generate it:
```bash
php artisan key:generate
```

### 4. Test Email Sending

#### Option A: Use Laravel Tinker
```bash
php artisan tinker
```

Then run:
```php
Mail::raw('Test email from Gharsewa', function ($message) {
    $message->to('anmolpal156@gmail.com')
            ->subject('Test Email');
});
```

Press Ctrl+C to exit tinker.

#### Option B: Use the Test Script
```bash
php backend/test-otp-email.php
```

### 5. Check Gmail Inbox
- Check inbox: anmolpal156@gmail.com
- Check spam folder
- Wait 1-2 minutes for delivery

---

## Verify Gmail SMTP Settings

Your current settings in `.env`:
```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=anmolpal156@gmail.com
MAIL_PASSWORD=zbpdaovlpjjppnxq
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="anmolpal156@gmail.com"  ← FIXED
MAIL_FROM_NAME="Gharsewa"
```

### Verify App Password
The Gmail App Password should be: `zbpd aovl pjjp pnxq` (with spaces) or `zbpdaovlpjjppnxq` (without spaces).

In `.env` it should be **without spaces**: `zbpdaovlpjjppnxq` ✅

---

## Common Email Issues

### Issue 1: "Failed to authenticate"
**Cause:** Wrong Gmail password or App Password
**Solution:** 
1. Go to Google Account → Security → 2-Step Verification → App Passwords
2. Generate new App Password
3. Update `MAIL_PASSWORD` in `.env`
4. Restart Laravel server

### Issue 2: "Connection refused"
**Cause:** Firewall blocking port 587
**Solution:** 
- Check firewall settings
- Try port 465 with SSL:
  ```env
  MAIL_PORT=465
  MAIL_ENCRYPTION=ssl
  ```

### Issue 3: "FROM address mismatch"
**Cause:** `MAIL_FROM_ADDRESS` doesn't match `MAIL_USERNAME`
**Solution:** Already fixed! Both are now `anmolpal156@gmail.com`

### Issue 4: Emails go to spam
**Cause:** Gmail spam filters
**Solution:** 
- Check spam folder
- Mark as "Not Spam"
- Add sender to contacts

### Issue 5: "Less secure app access"
**Cause:** Using regular password instead of App Password
**Solution:** 
- Enable 2-Step Verification on Google Account
- Generate App Password
- Use App Password in `.env`

---

## Test Registration Flow Again

After fixing and restarting:

1. **Start Laravel Server:**
   ```bash
   cd e:\gharsewa\backend
   php artisan serve
   ```

2. **Run Flutter App:**
   ```bash
   cd e:\gharsewa
   flutter run
   ```

3. **Try Registration:**
   - Name: Test User
   - Email: test@example.com (or any email)
   - Password: Test1234

4. **Check Laravel Logs:**
   ```bash
   tail -f e:\gharsewa\backend\storage\logs\laravel.log
   ```
   
   Or on Windows PowerShell:
   ```powershell
   Get-Content e:\gharsewa\backend\storage\logs\laravel.log -Wait -Tail 50
   ```

5. **Check Gmail Inbox:**
   - Login to anmolpal156@gmail.com
   - Check inbox and spam folder
   - Look for email from "Gharsewa"

---

## Debug Email Sending

### Check Laravel Logs
Look for email-related errors:
```bash
# Linux/Mac:
tail -f backend/storage/logs/laravel.log | grep -i mail

# Windows PowerShell:
Get-Content backend\storage\logs\laravel.log -Wait -Tail 50 | Select-String -Pattern "mail"
```

### Enable Mail Logging
Add to `.env` for debugging:
```env
LOG_LEVEL=debug
```

### Test with Mailtrap (Alternative)
If Gmail continues to have issues, use Mailtrap for testing:

1. Sign up at https://mailtrap.io (free)
2. Get SMTP credentials
3. Update `.env`:
   ```env
   MAIL_HOST=smtp.mailtrap.io
   MAIL_PORT=2525
   MAIL_USERNAME=your-mailtrap-username
   MAIL_PASSWORD=your-mailtrap-password
   MAIL_ENCRYPTION=tls
   MAIL_FROM_ADDRESS="noreply@gharsewa.com"
   ```
4. Restart Laravel server
5. Emails will appear in Mailtrap inbox (not real email)

---

## Verification Checklist

After applying fixes:

- [ ] `.env` has `MAIL_FROM_ADDRESS="anmolpal156@gmail.com"`
- [ ] Laravel server restarted
- [ ] Config cache cleared (`php artisan config:clear`)
- [ ] Test email sent successfully
- [ ] Registration OTP received in Gmail
- [ ] Password reset OTP received in Gmail
- [ ] Welcome email received after verification
- [ ] Password changed email received after reset

---

## Quick Test Command

Run this to test email immediately:
```bash
cd e:\gharsewa\backend
php artisan tinker
```

Then:
```php
use Illuminate\Support\Facades\Mail;

Mail::raw('Test from Gharsewa - ' . now(), function ($message) {
    $message->to('anmolpal156@gmail.com')
            ->subject('Test Email - ' . now());
});

echo "Email sent! Check inbox.\n";
exit;
```

---

## If Still Not Working

1. **Check Gmail Account:**
   - Login to anmolpal156@gmail.com
   - Go to Settings → Forwarding and POP/IMAP
   - Ensure IMAP is enabled

2. **Check Google Account Security:**
   - Go to https://myaccount.google.com/security
   - Ensure 2-Step Verification is ON
   - Check App Passwords section

3. **Try Different Port:**
   Update `.env`:
   ```env
   MAIL_PORT=465
   MAIL_ENCRYPTION=ssl
   ```

4. **Check Server Time:**
   Gmail may reject if server time is wrong:
   ```bash
   date
   ```

5. **Share Laravel Logs:**
   If still not working, share the output of:
   ```bash
   tail -100 backend/storage/logs/laravel.log
   ```

---

*After applying these fixes, restart Laravel server and try registration again!*
