<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Gharsewa</title>
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
        .welcome-icon {
            text-align: center;
            font-size: 64px;
            margin: 30px 0;
        }
        .features {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 25px;
            margin: 30px 0;
        }
        .feature-item {
            display: flex;
            align-items: flex-start;
            margin-bottom: 15px;
        }
        .feature-item:last-child {
            margin-bottom: 0;
        }
        .feature-icon {
            font-size: 24px;
            margin-right: 15px;
            flex-shrink: 0;
        }
        .feature-text {
            font-size: 14px;
            color: #666666;
        }
        .feature-title {
            font-weight: 600;
            color: #333333;
            margin-bottom: 5px;
        }
        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
            text-decoration: none;
            padding: 15px 40px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            margin: 20px 0;
            text-align: center;
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
            .cta-button {
                display: block;
                width: 100%;
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
            <div class="welcome-icon">🎉</div>
            
            <div class="greeting">Welcome to Gharsewa, <?php echo e($name); ?>!</div>
            
            <div class="message">
                Your email has been verified successfully! We're thrilled to have you join our community of homeowners and service providers.
            </div>

            <div class="message">
                Gharsewa connects you with trusted professionals for all your home service needs. Whether you're looking for cleaning, repairs, maintenance, or any other home service, we've got you covered.
            </div>

            <!-- Features -->
            <div class="features">
                <div class="feature-item">
                    <div class="feature-icon">🔍</div>
                    <div>
                        <div class="feature-title">Find Services</div>
                        <div class="feature-text">Browse and book from hundreds of verified service providers in your area</div>
                    </div>
                </div>
                <div class="feature-item">
                    <div class="feature-icon">⭐</div>
                    <div>
                        <div class="feature-title">Trusted Reviews</div>
                        <div class="feature-text">Read genuine reviews from other customers to make informed decisions</div>
                    </div>
                </div>
                <div class="feature-item">
                    <div class="feature-icon">💳</div>
                    <div>
                        <div class="feature-title">Secure Payments</div>
                        <div class="feature-text">Pay safely through our platform with multiple payment options</div>
                    </div>
                </div>
                <div class="feature-item">
                    <div class="feature-icon">🛡️</div>
                    <div>
                        <div class="feature-title">Service Guarantee</div>
                        <div class="feature-text">All services are backed by our satisfaction guarantee</div>
                    </div>
                </div>
            </div>

            <div style="text-align: center;">
                <a href="<?php echo e(env('APP_URL')); ?>/dashboard" class="cta-button">Get Started</a>
            </div>

            <div class="message">
                If you have any questions or need assistance, our support team is always here to help.
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
<?php /**PATH /var/www/resources/views/emails/welcome.blade.php ENDPATH**/ ?>