<?php

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Http\Request;
use App\Http\Controllers\API\V1\AI\NotificationController;
use App\Services\AI\SmartNotificationService;

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "=== A/B Testing Controller Test ===\n\n";

// Test the controller directly
echo "Step 1: Testing NotificationController::getAbTestResults()...\n";
try {
    $service = app(SmartNotificationService::class);
    $controller = new NotificationController($service);
    
    // Create a mock request
    $request = Request::create('/api/v1/admin/ai/notifications/ab-test-results', 'GET', [
        'notification_type' => 'booking_reminder'
    ]);
    
    $response = $controller->getAbTestResults($request);
    $data = json_decode($response->getContent(), true);
    
    if ($response->getStatusCode() === 200) {
        echo "✓ Controller returned 200 OK\n";
        
        if ($data['success']) {
            echo "✓ Response indicates success\n";
            echo "\nA/B Test Results:\n";
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
            
            // Display by notification type breakdown
            if (!empty($data['data']['control_group']['by_notification_type'])) {
                echo "\n  Control Group by Notification Type:\n";
                foreach ($data['data']['control_group']['by_notification_type'] as $type => $metrics) {
                    echo "    - {$type}: {$metrics['total']} notifications, {$metrics['open_rate']}% open rate\n";
                }
            }
            
            if (!empty($data['data']['test_group']['by_notification_type'])) {
                echo "\n  Test Group by Notification Type:\n";
                foreach ($data['data']['test_group']['by_notification_type'] as $type => $metrics) {
                    echo "    - {$type}: {$metrics['total']} notifications, {$metrics['open_rate']}% open rate\n";
                }
            }
        } else {
            echo "✗ Response indicates failure\n";
            echo "Message: {$data['message']}\n";
            exit(1);
        }
    } else {
        echo "✗ Controller returned HTTP {$response->getStatusCode()}\n";
        echo "Response: " . $response->getContent() . "\n";
        exit(1);
    }
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    echo "Stack trace: " . $e->getTraceAsString() . "\n";
    exit(1);
}

// Test with date filters
echo "\nStep 2: Testing with date filters...\n";
try {
    $request = Request::create('/api/v1/admin/ai/notifications/ab-test-results', 'GET', [
        'start_date' => now()->subDays(7)->toDateString(),
        'end_date' => now()->toDateString()
    ]);
    
    $response = $controller->getAbTestResults($request);
    $data = json_decode($response->getContent(), true);
    
    if ($response->getStatusCode() === 200 && $data['success']) {
        echo "✓ Date filters working correctly\n";
        echo "  - Date range: {$request->input('start_date')} to {$request->input('end_date')}\n";
        echo "  - Total notifications in range: {$data['data']['summary']['total_notifications']}\n";
    } else {
        echo "✗ Date filters test failed\n";
        exit(1);
    }
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}

// Test performance metrics endpoint
echo "\nStep 3: Testing getPerformanceMetrics()...\n";
try {
    $request = Request::create('/api/v1/admin/ai/notifications/performance', 'GET', [
        'days' => 7
    ]);
    
    $response = $controller->getPerformanceMetrics($request);
    $data = json_decode($response->getContent(), true);
    
    if ($response->getStatusCode() === 200 && $data['success']) {
        echo "✓ Performance metrics endpoint working\n";
        echo "  - Period: {$data['data']['period']['days']} days\n";
        echo "  - Control group open rate: {$data['data']['control_group']['open_rate']}%\n";
        echo "  - Test group open rate: {$data['data']['test_group']['open_rate']}%\n";
    } else {
        echo "✗ Performance metrics test failed\n";
        exit(1);
    }
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}

echo "\n=== All Controller Tests Passed ===\n";
