<?php

// Simple email test script
// Run with: docker-compose exec app php test-email-simple.php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\Mail;

echo "🧪 Testing Email Configuration\n";
echo "================================\n\n";

echo "📧 Sending test email to: anmolpal156@gmail.com\n";

try {
    Mail::raw('This is a test email from Gharsewa at ' . now(), function ($message) {
        $message->to('anmolpal156@gmail.com')
                ->subject('Test Email from Gharsewa - ' . now());
    });
    
    echo "✅ Email sent successfully!\n";
    echo "📬 Check your Gmail inbox: anmolpal156@gmail.com\n";
    echo "📁 Also check spam folder if not in inbox\n\n";
    
} catch (Exception $e) {
    echo "❌ Failed to send email!\n";
    echo "Error: " . $e->getMessage() . "\n\n";
    echo "Stack trace:\n";
    echo $e->getTraceAsString() . "\n";
}

echo "\n";
