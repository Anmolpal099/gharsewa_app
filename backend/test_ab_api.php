<?php

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "=== A/B Testing API Endpoint Test ===\n\n";

// Get or create an admin user
echo "Step 1: Getting admin user...\n";
$admin = \App\Models\User::where('role', 'admin')->first();

if (!$admin) {
    echo "Creating admin user...\n";
    $admin = \App\Models\User::create([
        'id' => \Illuminate\Support\Str::uuid(),
        'name' => 'Admin User',
        'email' => 'admin@gharsewa.com',
        'password' => bcrypt('password'),
        'role' => 'admin',
        'email_verified_at' => now()
    ]);
}

echo "✓ Admin user: {$admin->email}\n";

// Generate JWT token for admin
echo "\nStep 2: Generating JWT token...\n";
try {
    $token = auth()->guard('api')->login($admin);
    echo "✓ JWT token generated\n";
} catch (Exception $e) {
    echo "✗ Error generating token: " . $e->getMessage() . "\n";
    exit(1);
}

// Create more sample data for better A/B test results
echo "\nStep 3: Creating additional sample data...\n";
try {
    // Create 10 control group notifications
    for ($i = 0; $i < 10; $i++) {
        DB::table('notification_schedules')->insert([
            'user_id' => $admin->id,
            'notification_type' => 'booking_reminder',
            'optimal_time' => Carbon::now()->subDays(rand(1, 7)),
            'scheduled_at' => Carbon::now()->subDays(rand(1, 7)),
            'sent_at' => Carbon::now()->subDays(rand(1, 7)),
            'opened' => (bool)rand(0, 1),
            'opened_at' => rand(0, 1) ? Carbon::now()->subDays(rand(1, 7)) : null,
            'clicked' => (bool)rand(0, 1),
            'clicked_at' => rand(0, 1) ? Carbon::now()->subDays(rand(1, 7)) : null,
            'ab_test_variant' => 'control',
            'status' => 'sent',
            'created_at' => now(),
            'updated_at' => now()
        ]);
    }
    
    // Create 10 test group notifications
    for ($i = 0; $i < 10; $i++) {
        DB::table('notification_schedules')->insert([
            'user_id' => $admin->id,
            'notification_type' => 'booking_reminder',
            'optimal_time' => Carbon::now()->subDays(rand(1, 7)),
            'scheduled_at' => Carbon::now()->subDays(rand(1, 7)),
            'sent_at' => Carbon::now()->subDays(rand(1, 7)),
            'opened' => (bool)rand(0, 1),
            'opened_at' => rand(0, 1) ? Carbon::now()->subDays(rand(1, 7)) : null,
            'clicked' => (bool)rand(0, 1),
            'clicked_at' => rand(0, 1) ? Carbon::now()->subDays(rand(1, 7)) : null,
            'ab_test_variant' => 'test',
            'status' => 'sent',
            'created_at' => now(),
            'updated_at' => now()
        ]);
    }
    
    echo "✓ Created 20 additional notification schedules (10 control, 10 test)\n";
} catch (Exception $e) {
    echo "✗ Error creating sample data: " . $e->getMessage() . "\n";
    exit(1);
}

// Test the API endpoint
echo "\nStep 4: Testing API endpoint...\n";
try {
    $url = 'http://localhost:8000/api/v1/admin/ai/notifications/ab-test-results';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'Accept: application/json',
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200) {
        echo "✓ API endpoint returned 200 OK\n";
        
        $data = json_decode($response, true);
        
        if ($data['success']) {
            echo "✓ Response indicates success\n";
            echo "\nA/B Test Results from API:\n";
            echo "  - Total notifications: {$data['data']['summary']['total_notifications']}\n";
            echo "  - Control group count: {$data['data']['summary']['control_count']}\n";
            echo "  - Test group count: {$data['data']['summary']['test_count']}\n";
            echo "  - Control open rate: {$data['data']['control_group']['open_rate']}%\n";
            echo "  - Test open rate: {$data['data']['test_group']['open_rate']}%\n";
            echo "  - Control click rate: {$data['data']['control_group']['click_rate']}%\n";
            echo "  - Test click rate: {$data['data']['test_group']['click_rate']}%\n";
            echo "  - Winner: {$data['data']['comparison']['winner']}\n";
            echo "  - Open rate improvement: {$data['data']['comparison']['open_rate_improvement']}%\n";
            echo "  - Click rate improvement: {$data['data']['comparison']['click_rate_improvement']}%\n";
            echo "  - Statistical significance: " . ($data['data']['comparison']['statistical_significance']['is_significant'] ? 'Yes' : 'No') . "\n";
            echo "  - Recommendation: {$data['data']['comparison']['recommendation']}\n";
        } else {
            echo "✗ API returned success=false\n";
            echo "Response: " . json_encode($data, JSON_PRETTY_PRINT) . "\n";
            exit(1);
        }
    } else {
        echo "✗ API endpoint returned HTTP {$httpCode}\n";
        echo "Response: {$response}\n";
        exit(1);
    }
} catch (Exception $e) {
    echo "✗ Error testing API: " . $e->getMessage() . "\n";
    exit(1);
}

// Test with filters
echo "\nStep 5: Testing API endpoint with filters...\n";
try {
    $url = 'http://localhost:8000/api/v1/admin/ai/notifications/ab-test-results?notification_type=booking_reminder';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'Accept: application/json',
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200) {
        echo "✓ API endpoint with filters returned 200 OK\n";
        
        $data = json_decode($response, true);
        
        if ($data['success']) {
            echo "✓ Filtered results retrieved successfully\n";
            echo "  - Filtered by notification_type: booking_reminder\n";
            echo "  - Total notifications: {$data['data']['summary']['total_notifications']}\n";
        } else {
            echo "✗ API returned success=false\n";
            exit(1);
        }
    } else {
        echo "✗ API endpoint returned HTTP {$httpCode}\n";
        exit(1);
    }
} catch (Exception $e) {
    echo "✗ Error testing API with filters: " . $e->getMessage() . "\n";
    exit(1);
}

echo "\n=== All API Tests Passed ===\n";
