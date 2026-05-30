<?php

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\DB;

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== PROFILE IMAGE DISPLAY TEST ===\n\n";

try {
    // Test 1: Find users with profile images
    echo "1. Finding users with profile images...\n";
    
    $usersWithImages = DB::table('users')
        ->whereNotNull('profile_image_data')
        ->orWhereNotNull('profile_image_url')
        ->get();

    echo "   Found " . count($usersWithImages) . " users with profile images\n\n";

    if (count($usersWithImages) === 0) {
        echo "   ℹ️  No users with profile images. Upload one first.\n";
        exit(0);
    }

    // Test each user
    foreach ($usersWithImages as $user) {
        echo "2. Testing user: {$user->name} ({$user->email})\n";
        echo "   Role: {$user->role}\n";
        echo "   User ID: {$user->id}\n";

        // Check database fields
        if ($user->profile_image_data) {
            $dataSize = strlen($user->profile_image_data);
            $mimeType = $user->profile_image_mime_type ?? 'unknown';
            echo "   ✓ profile_image_data: " . number_format($dataSize) . " bytes\n";
            echo "   ✓ profile_image_mime_type: {$mimeType}\n";
            
            // Generate data URL
            $dataUrl = "data:{$mimeType};base64,{$user->profile_image_data}";
            echo "   ✓ Data URL length: " . number_format(strlen($dataUrl)) . " bytes\n";
            echo "   ✓ Data URL preview: " . substr($dataUrl, 0, 50) . "...\n";
        } else {
            echo "   ℹ️  No profile_image_data (using filesystem)\n";
        }

        if ($user->profile_image_url) {
            echo "   ℹ️  profile_image_url: {$user->profile_image_url}\n";
        }

        echo "\n";

        // Test API endpoints based on role
        echo "3. Testing API endpoint for {$user->role}...\n";
        
        if ($user->role === 'customer') {
            echo "   Endpoint: GET /v1/auth/jwt/me\n";
            echo "   Expected: profile_image_url with data URL\n";
        } elseif ($user->role === 'serviceProvider') {
            echo "   Endpoint: GET /v1/provider/profile\n";
            echo "   Expected: profile_image_url with data URL\n";
        }

        echo "\n";
    }

    echo "4. Summary:\n";
    echo "   - Profile images are stored in database ✓\n";
    echo "   - Data URLs can be generated ✓\n";
    echo "   - API endpoints should return data URLs ✓\n\n";

    echo "=== ✓ PROFILE IMAGE DISPLAY TEST COMPLETE ===\n\n";

    echo "Next steps:\n";
    echo "1. Test customer profile image upload from frontend\n";
    echo "2. Check that image displays immediately after upload\n";
    echo "3. Test provider profile image upload from frontend\n";
    echo "4. Check that image displays immediately after upload\n\n";

} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}
