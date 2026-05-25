<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\Mail;
use App\Models\OtpVerification;

echo "🧪 Testing OTP Email System\n";
echo "==========================\n\n";

$testEmail = 'anmolpal156@gmail.com';

try {
    // Generate OTP
    echo "1️⃣  Generating OTP for email verification...\n";
    $otpRecord = OtpVerification::createForEmailVerification($testEmail);
    echo "   ✅ OTP Generated: {$otpRecord->otp}\n";
    echo "   ⏰ Expires in: 10 minutes\n\n";
    
    // Send OTP email
    echo "2️⃣  Sending OTP email...\n";
    Mail::send('emails.otp-verification', [
        'name' => 'Test User',
        'otp' => $otpRecord->otp,
        'expiryMinutes' => 10
    ], function ($message) use ($testEmail) {
        $message->to($testEmail)
                ->subject('Verify Your Email - Gharsewa');
    });
    
    echo "   ✅ OTP email sent successfully!\n";
    echo "   📧 Check your inbox: {$testEmail}\n";
    echo "   ⏱️  Should arrive within 1-2 seconds\n\n";
    
    echo "3️⃣  OTP Details:\n";
    echo "   Code: {$otpRecord->otp}\n";
    echo "   Type: email_verification\n";
    echo "   Expires: {$otpRecord->expires_at}\n";
    echo "   Max Attempts: 5\n\n";
    
    echo "✅ OTP Email System Test Complete!\n\n";
    echo "📝 Next Steps:\n";
    echo "   1. Check your email inbox\n";
    echo "   2. You should see a professional OTP email\n";
    echo "   3. Use the OTP code to test verification\n";
    echo "   4. Test the registration API endpoint\n\n";
    
    echo "🔗 Test Registration API:\n";
    echo "   curl -X POST http://localhost:8000/api/v1/auth/jwt/register \\\n";
    echo "     -H 'Content-Type: application/json' \\\n";
    echo "     -d '{\n";
    echo "       \"name\": \"Test User\",\n";
    echo "       \"email\": \"{$testEmail}\",\n";
    echo "       \"password\": \"Test1234\",\n";
    echo "       \"role\": \"customer\"\n";
    echo "     }'\n\n";
    
} catch (Exception $e) {
    echo "❌ Test Failed\n";
    echo "Error: " . $e->getMessage() . "\n";
    echo "\nStack Trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}
