<?php

echo "🧪 Testing Gmail SMTP Connection\n";
echo "==================================\n\n";

// Test 1: Can we connect to Gmail SMTP?
echo "Test 1: Connecting to smtp.gmail.com:587...\n";
$smtp = @fsockopen('smtp.gmail.com', 587, $errno, $errstr, 10);
if ($smtp) {
    echo "✅ Successfully connected to Gmail SMTP\n";
    fclose($smtp);
} else {
    echo "❌ Failed to connect: $errstr ($errno)\n";
    echo "This means your Docker container cannot reach Gmail's servers.\n";
}

echo "\n";

// Test 2: Check environment variables
echo "Test 2: Checking email configuration...\n";
$config = [
    'MAIL_HOST' => getenv('MAIL_HOST') ?: 'Not set',
    'MAIL_PORT' => getenv('MAIL_PORT') ?: 'Not set',
    'MAIL_USERNAME' => getenv('MAIL_USERNAME') ?: 'Not set',
    'MAIL_FROM_ADDRESS' => getenv('MAIL_FROM_ADDRESS') ?: 'Not set',
    'MAIL_ENCRYPTION' => getenv('MAIL_ENCRYPTION') ?: 'Not set',
];

foreach ($config as $key => $value) {
    $status = ($value !== 'Not set') ? '✅' : '❌';
    echo "$status $key: $value\n";
}

echo "\n";

// Test 3: Try to send via SwiftMailer directly
echo "Test 3: Attempting to send test email via SMTP...\n";

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

try {
    Mail::raw('Test email from Gharsewa SMTP test at ' . now(), function ($message) {
        $message->to('anmolpal156@gmail.com')
                ->subject('SMTP Connection Test - ' . now());
    });
    
    echo "✅ Email sent successfully via Laravel Mail!\n";
    echo "📬 Check Gmail inbox: anmolpal156@gmail.com\n";
    echo "📁 Also check spam/junk folder\n";
    echo "⏱️  Wait 1-2 minutes for delivery\n";
    
} catch (Exception $e) {
    echo "❌ Failed to send email!\n";
    echo "Error: " . $e->getMessage() . "\n\n";
    
    // Show more details
    if (strpos($e->getMessage(), 'authentication') !== false) {
        echo "💡 This looks like an authentication error.\n";
        echo "   Check your Gmail App Password is correct.\n";
    } elseif (strpos($e->getMessage(), 'Connection') !== false) {
        echo "💡 This looks like a connection error.\n";
        echo "   Your server might not be able to reach Gmail's SMTP.\n";
    }
}

echo "\n";
echo "==================================\n";
echo "Test complete!\n";
