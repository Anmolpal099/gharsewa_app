<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\Mail;

try {
    Mail::raw('🎉 Test email from Gharsewa Laravel!

This is a test to verify that your Gmail SMTP configuration is working correctly.

If you received this email, your OTP system is ready to send real-time verification codes!

Configuration:
- SMTP Host: smtp.gmail.com
- Port: 587
- Encryption: TLS
- From: noreply@gharsewa.com

Next steps:
1. Test user registration with OTP
2. Test password reset with OTP
3. Verify OTP validation works

---
Gharsewa Home Services Platform', function ($message) {
        $message->to('anmolpal156@gmail.com')
                ->subject('✅ Gharsewa Email Test - Configuration Successful!');
    });
    
    echo "✅ Email sent successfully to anmolpal156@gmail.com!\n";
    echo "📧 Check your inbox (and spam folder if needed)\n";
    echo "⏱️  Email should arrive within 1-2 seconds\n";
    
} catch (Exception $e) {
    echo "❌ Failed to send email\n";
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
