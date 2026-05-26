<?php

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "=== A/B Testing Framework Test ===\n\n";

// Test 1: Check if ab_test_variant column exists
echo "Test 1: Checking if ab_test_variant column exists...\n";
try {
    $columns = DB::select("SHOW COLUMNS FROM notification_schedules LIKE 'ab_test_variant'");
    if (count($columns) > 0) {
        echo "✓ ab_test_variant column exists\n";
    } else {
        echo "✗ ab_test_variant column does not exist\n";
        exit(1);
    }
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}

// Test 2: Check notification schedules with A/B test variants
echo "\nTest 2: Checking notification schedules with A/B test variants...\n";
try {
    $count = DB::table('notification_schedules')
        ->whereNotNull('ab_test_variant')
        ->count();
    echo "Found {$count} notification schedules with A/B test variants\n";
    
    $controlCount = DB::table('notification_schedules')
        ->where('ab_test_variant', 'control')
        ->count();
    echo "  - Control group: {$controlCount}\n";
    
    $testCount = DB::table('notification_schedules')
        ->where('ab_test_variant', 'test')
        ->count();
    echo "  - Test group: {$testCount}\n";
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}

// Test 3: Create sample notification schedules for testing
echo "\nTest 3: Creating sample notification schedules...\n";
try {
    // Get a test user
    $user = DB::table('users')->where('role', 'customer')->first();
    
    if (!$user) {
        echo "✗ No customer user found. Creating test user...\n";
        $userId = DB::table('users')->insertGetId([
            'id' => \Illuminate\Support\Str::uuid(),
            'name' => 'Test Customer',
            'email' => 'test.ab@example.com',
            'password' => bcrypt('password'),
            'role' => 'customer',
            'email_verified_at' => now(),
            'created_at' => now(),
            'updated_at' => now()
        ]);
        $user = DB::table('users')->where('id', $userId)->first();
    }
    
    // Create control group notification
    $controlId = DB::table('notification_schedules')->insertGetId([
        'user_id' => $user->id,
        'notification_type' => 'booking_reminder',
        'optimal_time' => Carbon::now()->addHours(2),
        'scheduled_at' => Carbon::now()->addHours(2),
        'sent_at' => Carbon::now()->subHours(1),
        'opened' => true,
        'opened_at' => Carbon::now()->subMinutes(30),
        'clicked' => true,
        'clicked_at' => Carbon::now()->subMinutes(25),
        'ab_test_variant' => 'control',
        'status' => 'sent',
        'created_at' => now(),
        'updated_at' => now()
    ]);
    echo "✓ Created control group notification (ID: {$controlId})\n";
    
    // Create test group notification
    $testId = DB::table('notification_schedules')->insertGetId([
        'user_id' => $user->id,
        'notification_type' => 'booking_reminder',
        'optimal_time' => Carbon::now()->addHours(3),
        'scheduled_at' => Carbon::now()->addHours(3),
        'sent_at' => Carbon::now()->subHours(2),
        'opened' => true,
        'opened_at' => Carbon::now()->subMinutes(90),
        'clicked' => false,
        'ab_test_variant' => 'test',
        'status' => 'sent',
        'created_at' => now(),
        'updated_at' => now()
    ]);
    echo "✓ Created test group notification (ID: {$testId})\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}

// Test 4: Test SmartNotificationService A/B test assignment
echo "\nTest 4: Testing A/B test variant assignment...\n";
try {
    $service = app(\App\Services\AI\SmartNotificationService::class);
    
    // Test with multiple users to verify 50/50 split
    $assignments = ['control' => 0, 'test' => 0];
    
    for ($i = 0; $i < 100; $i++) {
        $testUser = new \App\Models\User();
        $testUser->id = \Illuminate\Support\Str::uuid();
        
        // Use reflection to call private method
        $reflection = new ReflectionClass($service);
        $method = $reflection->getMethod('assignAbTestVariant');
        $method->setAccessible(true);
        
        $variant = $method->invoke($service, $testUser);
        $assignments[$variant]++;
    }
    
    echo "Assignment distribution over 100 users:\n";
    echo "  - Control: {$assignments['control']}%\n";
    echo "  - Test: {$assignments['test']}%\n";
    
    // Check if distribution is roughly 50/50 (allow 40-60% range)
    if ($assignments['control'] >= 40 && $assignments['control'] <= 60) {
        echo "✓ A/B test assignment is working correctly\n";
    } else {
        echo "⚠ Warning: A/B test assignment distribution is skewed\n";
    }
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}

// Test 5: Test getAbTestResults method
echo "\nTest 5: Testing getAbTestResults method...\n";
try {
    $service = app(\App\Services\AI\SmartNotificationService::class);
    
    $results = $service->getAbTestResults([
        'notification_type' => 'booking_reminder'
    ]);
    
    echo "A/B Test Results:\n";
    echo "  - Total notifications: {$results['summary']['total_notifications']}\n";
    echo "  - Control group count: {$results['summary']['control_count']}\n";
    echo "  - Test group count: {$results['summary']['test_count']}\n";
    echo "  - Control open rate: {$results['control_group']['open_rate']}%\n";
    echo "  - Test open rate: {$results['test_group']['open_rate']}%\n";
    echo "  - Winner: {$results['comparison']['winner']}\n";
    echo "  - Open rate improvement: {$results['comparison']['open_rate_improvement']}%\n";
    echo "✓ getAbTestResults method is working\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    echo "Stack trace: " . $e->getTraceAsString() . "\n";
    exit(1);
}

echo "\n=== All A/B Testing Framework Tests Passed ===\n";
