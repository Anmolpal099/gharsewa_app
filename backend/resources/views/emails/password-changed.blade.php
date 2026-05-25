<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Changed - Gharsewa</title>
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
            margin-bottom: 20px;
            line-height: 1.8;
        }
        .success-icon {
            text-align: center;
            font-size: 64px;
            margin: 30px 0;
        }
        .success-box {
            background-color: #d4edda;
            border-left: 4px solid #28a745;
            border-radius: 8px;
            padding: 20px;
            margin: 30px 0;
            text-align: center;
        }
        .success-title {
            font-size: 18px;
            font-weight: 600;
            color: #155724;
            margin-bottom: 10px;
        }
        .success-text {
            font-size: 14px;
            color: #155724;
        }
        .info-box {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin: 30px 0;
        }
        .info-item {
            display: flex;
            align-items: center;
            margin-bottom: 12px;
            font-size: 14px;
            color: #666666;
        }
        .info-item:last-child {
            margin-bottom: 0;
        }
        .info-icon {
            font-size: 20px;
            margin-right: 12px;
        }
        .warning {
            background-color: #f8d7da;
            border-left: 4px solid #dc3545;
            padding: 15px;
            margin: 20px 0;
            font-size: 14px;
            color: #721c24;
        }
        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
            text-decoration: none;
            padding: 12px 30px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 14px;
            margin: 10px 0;
        }
        .cta-button:hover {
            opacity: 0.9;
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
        }
    </style>
</head>
<body>
    <div class="email-container">
        <!-- Header -->
        <div class="header">
            <a href="{{ env('APP_URL') }}" class="logo">Gharsewa</a>
        </div>

        <!-- Content -->
        <div class="content">
            <div class="success-icon">✅</div>
            
            <div class="greeting">Hello {{ $name }}!</div>
            
            <!-- Success Box -->
            <div class="success-box">
                <div class="success-title">Password Changed Successfully</div>
                <div class="success-text">Your Gharsewa account password has been updated</div>
            </div>

            <div class="message">
                This email confirms that your password was changed successfully. You can now use your new password to log in to your account.
            </div>

            <!-- Info Box -->
            <div class="info-box">
                <div class="info-item">
                    <span class="info-icon">📅</span>
                    <span><strong>Date:</strong> {{ date('F j, Y') }}</span>
                </div>
                <div class="info-item">
                    <span class="info-icon">⏰</span>
                    <span><strong>Time:</strong> {{ date('g:i A') }}</span>
                </div>
                <div class="info-item">
                    <span class="info-icon">🔐</span>
                    <span><strong>Action:</strong> Password Reset</span>
                </div>
            </div>

            <div class="message">
                For your security, all active sessions on other devices have been logged out. You'll need to log in again with your new password.
            </div>

            <!-- Warning -->
            <div class="warning">
                <strong>⚠️ Didn't make this change?</strong><br>
                If you didn't change your password, your account may be compromised. Please contact our support team immediately at <a href="mailto:support@gharsewa.com" style="color: #721c24; font-weight: 600;">support@gharsewa.com</a>
            </div>

            <div style="text-align: center; margin-top: 30px;">
                <a href="{{ env('APP_URL') }}/login" class="cta-button">Log In to Your Account</a>
            </div>

            <div class="message" style="margin-top: 30px;">
                <strong>Security Tips:</strong>
                <ul style="margin: 10px 0 0 20px; padding: 0; color: #666666;">
                    <li>Never share your password with anyone</li>
                    <li>Use a unique password for each online account</li>
                    <li>Enable two-factor authentication when available</li>
                    <li>Change your password regularly</li>
                </ul>
            </div>
        </div>

        <!-- Footer -->
        <div class="footer">
            <div class="footer-text">
                Need help? Contact our support team
            </div>
            <div class="footer-links">
                <a href="mailto:support@gharsewa.com" class="footer-link">Support</a>
                <a href="{{ env('APP_URL') }}/help" class="footer-link">Help Center</a>
                <a href="{{ env('APP_URL') }}/privacy" class="footer-link">Privacy Policy</a>
            </div>
            <div class="footer-text" style="margin-top: 20px; color: #999999; font-size: 12px;">
                © {{ date('Y') }} Gharsewa. All rights reserved.
            </div>
        </div>
    </div>
</body>
</html>
