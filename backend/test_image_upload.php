<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\DB;

echo "=== IMAGE UPLOAD VERIFICATION TEST ===\n\n";

// Step 1: Check database columns
echo "1. Checking database columns...\n";
$columns = DB::select("SHOW COLUMNS FROM users WHERE Field LIKE 'profile_image%'");
foreach ($columns as $column) {
    echo "   ✓ {$column->Field} ({$column->Type})\n";
}

// Step 2: Check User model fillable
echo "\n2. Checking User model fillable array...\n";
$user = new User();
$fillable = $user->getFillable();
$hasData = in_array('profile_image_data', $fillable);
$hasMime = in_array('profile_image_mime_type', $fillable);
echo "   profile_image_data in fillable: " . ($hasData ? '✓ YES' : '✗ NO') . "\n";
echo "   profile_image_mime_type in fillable: " . ($hasMime ? '✓ YES' : '✗ NO') . "\n";

// Step 3: Find a test user
echo "\n3. Finding test user...\n";
$testUser = User::where('role', 'serviceProvider')->orWhere('role', 'customer')->first();
if (!$testUser) {
    echo "   ✗ No test user found!\n";
    exit(1);
}
echo "   ✓ Found user: {$testUser->name} ({$testUser->email})\n";
echo "   User ID: {$testUser->id}\n";
echo "   Role: {$testUser->role}\n";

// Step 4: Test image upload simulation
echo "\n4. Testing image upload simulation...\n";

// Create a tiny 1x1 red pixel PNG in base64
$testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';
$mimeType = 'image/png';

echo "   Test image size: " . strlen($testImageBase64) . " bytes\n";
echo "   MIME type: {$mimeType}\n";

try {
    // Attempt to update user with image data
    $updated = $testUser->update([
        'profile_image_data' => $testImageBase64,
        'profile_image_mime_type' => $mimeType,
    ]);
    
    if ($updated) {
        echo "   ✓ Image data saved to database!\n";
        
        // Verify it was saved
        $testUser->refresh();
        $savedDataLength = strlen($testUser->profile_image_data ?? '');
        $savedMime = $testUser->profile_image_mime_type;
        
        echo "   ✓ Saved data length: {$savedDataLength} bytes\n";
        echo "   ✓ Saved MIME type: {$savedMime}\n";
        
        // Generate data URL
        $dataUrl = "data:{$savedMime};base64,{$testUser->profile_image_data}";
        echo "   ✓ Data URL generated (length: " . strlen($dataUrl) . ")\n";
        echo "   ✓ Data URL preview: " . substr($dataUrl, 0, 80) . "...\n";
        
    } else {
        echo "   ✗ Failed to save image data!\n";
        exit(1);
    }
    
} catch (\Exception $e) {
    echo "   ✗ ERROR: " . $e->getMessage() . "\n";
    echo "   File: " . $e->getFile() . ":" . $e->getLine() . "\n";
    exit(1);
}

// Step 5: Test retrieval
echo "\n5. Testing image retrieval...\n";
try {
    $retrievedUser = User::find($testUser->id);
    
    if ($retrievedUser->profile_image_data) {
        echo "   ✓ Image data retrieved from database\n";
        echo "   ✓ Data length: " . strlen($retrievedUser->profile_image_data) . " bytes\n";
        echo "   ✓ MIME type: {$retrievedUser->profile_image_mime_type}\n";
        
        // Generate data URL as the API would
        $apiDataUrl = "data:{$retrievedUser->profile_image_mime_type};base64,{$retrievedUser->profile_image_data}";
        echo "   ✓ API would return data URL of length: " . strlen($apiDataUrl) . "\n";
        
    } else {
        echo "   ✗ No image data found!\n";
        exit(1);
    }
    
} catch (\Exception $e) {
    echo "   ✗ ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

// Step 6: Clean up test data
echo "\n6. Cleaning up test data...\n";
$testUser->update([
    'profile_image_data' => null,
    'profile_image_mime_type' => null,
]);
echo "   ✓ Test data cleaned up\n";

echo "\n=== ✓ ALL TESTS PASSED! ===\n";
echo "\nThe image upload system is ready to use!\n";
echo "You can now upload images from the frontend.\n\n";
