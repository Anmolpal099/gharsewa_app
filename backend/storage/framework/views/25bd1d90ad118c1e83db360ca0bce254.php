<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Your Password - Gharsewa</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333333;
            background-color: #f4f4f4;
        }
        .email-container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 40px 20px;
            text-align: center;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            color: #ffffff;
            text-decoration: none;
        }
        .content {
            padding: 40px 30px;
        }
        .greeting {
            font-size: 24px;
            font-weight: 600;
            color: #333333;
            margin-bottom: 20px;
        }
        .message {
            font-size: 16px;
            color: #666666;
            margin-bottom: 30px;
            line-height: 1.8;
        }
        .otp-container {
            background-color: #fff3cd;
            border: 2px dashed #ffc107;
            border-radius: 8px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
        }
        .otp-label {
            font-size: 14px;
            color: #856404;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }
        .otp-code {
            font-size: 42px;
            font-weight: bold;
            color: #ffc107;
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
        }
        .expiry-notice {
            font-size: 14px;
            color: #856404;
            margin-top: 15px;
        }
        .warning {
            background-color: #f8d7da;
            border-left: 4px solid #dc3545;
            padding: 15px;
            margin: 20px 0;
            font-size: 14px;
            color: #721c24;
        }
        .info-box {
            background-color: #d1ecf1;
            border-left: 4px solid #17a2b8;
            padding: 15px;
            margin: 20px 0;
            font-size: 14px;
            color: #0c5460;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #e9ecef;
        }
        .footer-text {
            font-size: 14px;
            color: #666666;
            margin-bottom: 10px;
        }
        .footer-links {
            margin-top: 15px;
        }
        .footer-link {
            color: #667eea;
            text-decoration: none;
            margin: 0 10px;
            font-size: 14px;
        }
        .footer-link:hover {
            text-decoration: underline;
        }
        @media only screen and (max-width: 600px) {
            .content {
                padding: 30px 20px;
            }
            .otp-code {
                font-size: 36px;
                letter-spacing: 6px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <a href="<?php echo e(env('APP_URL')); ?>" class="logo">Gharsewa</a>
        </div>

        <!-- Content -->
        <div class="content">
            <div class="greeting">Hello <?php echo e($name); ?>! 🔐</div>
            
            <div class="message">
                We received a request to reset your password for your Gharsewa account. To proceed with the password reset, please use the One-Time Password (OTP) below:
            </div>

            <!-- OTP Box -->
            <div class="otp-container">
                <div class="otp-label">Your Password Reset Code</div>
                <div class="otp-code"><?php echo e($otp); ?></div>
                <div class="expiry-notice">
                    ⏱️ This code will expire in <?php echo e($expiryMinutes); ?> minutes
                </div>
            </div>

            <div class="message">
                Enter this code in the password reset screen to create a new password for your account.
            </div>

            <!-- Info Box -->
            <div class="info-box">
                <strong>💡 Password Requirements:</strong>
                <ul style="margin: 10px 0 0 20px; padding: 0;">
                    <li>Minimum 8 characters</li>
                    <li>At least one uppercase letter</li>
                    <li>At least one lowercase letter</li>
                    <li>At least one number</li>
                </ul>
            </div>

            <!-- Warning -->
            <div class="warning">
                <strong>⚠️ Security Alert:</strong> If you didn't request a password reset, please ignore this email and ensure your account is secure. Consider changing your password if you suspect unauthorized access.
            </div>
        </div>

        <!-- Footer -->
        <div class="footer">
            <div class="footer-text">
                Need help? Contact our support team
            </div>
            <div class="footer-links">
                <a href="mailto:support@gharsewa.com" class="footer-link">Support</a>
                <a href="<?php echo e(env('APP_URL')); ?>/help" class="footer-link">Help Center</a>
                <a href="<?php echo e(env('APP_URL')); ?>/privacy" class="footer-link">Privacy Policy</a>
            </div>
            <div class="footer-text" style="margin-top: 20px; color: #999999; font-size: 12px;">
                © <?php echo e(date('Y')); ?> Gharsewa. All rights reserved.
            </div>
        </div>
    </div>
</body>
</html>
<?php /**PATH /var/www/resources/views/emails/password-reset.blade.php ENDPATH**/ ?>