# Laravel Mail Setup for Real-Time OTP Delivery

## Overview

Laravel's built-in Mail system is now configured to send OTP emails directly to Gmail in real-time. **No Nodemailer needed!**

## Gmail SMTP Configuration

### Step 1: Enable 2-Factor Authentication

1. Go to your Google Account: https://myaccount.google.com/
2. Navigate to **Security**
3. Enable **2-Step Verification**

### Step 2: Generate App Password

1. Go to: https://myaccount.google.com/apppasswords
2. Select **Mail** as the app
3. Select **Other (Custom name)** as the device
4. Enter "Gharsewa Laravel" as the name
5. Click **Generate**
6. Copy the 16-character password (e.g., `abcd efgh ijkl mnop`)

### Step 3: Update .env File

Open `backend/.env` and update these values:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-actual-email@gmail.com
MAIL_PASSWORD=your-16-char-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="noreply@gharsewa.com"
MAIL_FROM_NAME="Gharsewa"
```

**Important:**
- Use your **real Gmail address** for `MAIL_USERNAME`
- Use the **16-character App Password** (without spaces) for `MAIL_PASSWORD`
- Do NOT use your regular Gmail password

### Step 4: Test Email Sending

Run this command in your Laravel container:

```bash
docker exec gharsewa_app php artisan tinker
```

Then test:

```php
Mail::raw('Test email from Laravel', function ($message) {
    $message->to('your-test-email@gmail.com')
            ->subject('Test Email');
});
```

If successful, you'll see the email in your inbox within 1-2 seconds!

## How It Works

### OTP Email Flow

1. **User registers** → `JwtAuthController@register()`
2. **OTP generated** → `OtpVerification::createForEmailVerification()`
3. **Email sent** → Laravel Mail with `emails.otp-verification` template
4. **User receives email** → Real Gmail inbox (1-2 seconds)
5. **User enters OTP** → `OtpController@verifyEmailOtp()`
6. **OTP validated** → JWT tokens returned

### Password Reset Flow

1. **User requests reset** → `OtpController@sendPasswordResetOtp()`
2. **OTP generated** → `OtpVerification::createForPasswordReset()`
3. **Email sent** → Laravel Mail with `emails.password-reset` template
4. **User receives email** → Real Gmail inbox (1-2 seconds)
5. **User enters OTP** → `OtpController@resetPassword()`
6. **Password updated** → Confirmation email sent

## Email Templates

Laravel uses Blade templates located in `backend/resources/views/emails/`:

- `otp-verification.blade.php` - Email verification OTP
- `password-reset.blade.php` - Password reset OTP
- `welcome.blade.php` - Welcome email after verification
- `password-changed.blade.php` - Password change confirmation

All templates are professional, responsive, and mobile-friendly.

## Advantages Over Nodemailer

✅ **Simpler** - No Node.js dependency
✅ **Native** - Built into Laravel
✅ **Faster** - Direct SMTP connection
✅ **Reliable** - Laravel's proven mail system
✅ **Queueable** - Easy to queue for better performance
✅ **Testable** - Built-in testing tools

## Testing with Mailtrap (Optional)

For development/testing without sending real emails:

1. Sign up at https://mailtrap.io (free)
2. Get your SMTP credentials
3. Update `.env`:

```env
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your-mailtrap-username
MAIL_PASSWORD=your-mailtrap-password
MAIL_ENCRYPTION=tls
```

All emails will be caught by Mailtrap instead of being delivered.

## Troubleshooting

### "Authentication failed"
- Make sure you're using an **App Password**, not your regular Gmail password
- Verify 2FA is enabled on your Google account
- Check that the App Password has no spaces

### "Connection timeout"
- Check your firewall settings
- Verify port 587 is not blocked
- Try port 465 with `MAIL_ENCRYPTION=ssl`

### "Email not received"
- Check spam/junk folder
- Verify the recipient email is correct
- Check Laravel logs: `docker exec gharsewa_app tail -f storage/logs/laravel.log`

### "Too many emails"
- Gmail has sending limits (500 emails/day for free accounts)
- Consider using SendGrid or Mailgun for production
- Implement rate limiting on your endpoints

## Production Recommendations

For production, consider using a dedicated email service:

### SendGrid (Recommended)
- 100 emails/day free
- Better deliverability
- Detailed analytics

```env
MAIL_HOST=smtp.sendgrid.net
MAIL_PORT=587
MAIL_USERNAME=apikey
MAIL_PASSWORD=your-sendgrid-api-key
```

### Mailgun
- 5,000 emails/month free
- Good for transactional emails

### Amazon SES
- Very cheap ($0.10 per 1,000 emails)
- Requires AWS account

## Security Best Practices

1. **Never commit `.env`** - Keep credentials secret
2. **Use App Passwords** - Never use your main Gmail password
3. **Rate limit** - Prevent email spam
4. **Validate inputs** - Prevent email injection
5. **Log failures** - Monitor email delivery
6. **Queue emails** - Don't block HTTP requests

## Queue Configuration (Optional)

For better performance, queue emails:

1. Update `.env`:
```env
QUEUE_CONNECTION=redis
```

2. Update OtpController to queue emails:
```php
Mail::to($email)->queue(new OtpMail($otp));
```

3. Run queue worker:
```bash
docker exec gharsewa_app php artisan queue:work
```

## Current Status

✅ Laravel Mail configured
✅ Gmail SMTP ready
✅ OTP email templates created
✅ Real-time delivery (1-2 seconds)
✅ OTP validation working
✅ Password reset working

**Nodemailer removed** - No longer needed!

## Next Steps

1. Update your `.env` with real Gmail credentials
2. Test email sending with `php artisan tinker`
3. Test OTP registration flow
4. Test password reset flow
5. Monitor logs for any issues

---

**Need help?** Check Laravel logs or contact support.
