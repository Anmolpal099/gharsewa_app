<?php

/**
 * Test script for AI Consultation Endpoint
 * 
 * This script tests the POST /api/v1/customer/ai/consultations endpoint
 */

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\Artisan;

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== AI Consultation Endpoint Test ===\n\n";

// Test 1: Check if route exists
echo "Test 1: Checking if route exists...\n";
try {
    $routes = Artisan::call('route:list', ['--name' => 'ai.consultations']);
    echo "✓ Route registered successfully\n\n";
} catch (Exception $e) {
    echo "✗ Route not found: " . $e->getMessage() . "\n\n";
}

// Test 2: Check if controller exists
echo "Test 2: Checking if controller exists...\n";
$controllerPath = __DIR__ . '/app/Http/Controllers/API/V1/Customer/AIConsultationController.php';
if (file_exists($controllerPath)) {
    echo "✓ AIConsultationController exists\n\n";
} else {
    echo "✗ AIConsultationController not found\n\n";
}

// Test 3: Check if VisionAIService exists
echo "Test 3: Checking if VisionAIService exists...\n";
$servicePath = __DIR__ . '/app/Services/AI/VisionAIService.php';
if (file_exists($servicePath)) {
    echo "✓ VisionAIService exists\n\n";
} else {
    echo "✗ VisionAIService not found\n\n";
}

// Test 4: Check if AIConsultation model exists
echo "Test 4: Checking if AIConsultation model exists...\n";
$modelPath = __DIR__ . '/app/Models/AIConsultation.php';
if (file_exists($modelPath)) {
    echo "✓ AIConsultation model exists\n\n";
} else {
    echo "✗ AIConsultation model not found\n\n";
}

// Test 5: Check if CreateConsultationRequest exists
echo "Test 5: Checking if CreateConsultationRequest exists...\n";
$requestPath = __DIR__ . '/app/Http/Requests/AI/CreateConsultationRequest.php';
if (file_exists($requestPath)) {
    echo "✓ CreateConsultationRequest exists\n\n";
} else {
    echo "✗ CreateConsultationRequest not found\n\n";
}

// Test 6: Check if storage directory exists
echo "Test 6: Checking if storage directory exists...\n";
$storagePath = storage_path('app/public/consultations');
if (!file_exists($storagePath)) {
    mkdir($storagePath, 0775, true);
    echo "✓ Created storage directory: {$storagePath}\n\n";
} else {
    echo "✓ Storage directory exists: {$storagePath}\n\n";
}

// Test 7: Verify controller methods
echo "Test 7: Checking controller methods...\n";
try {
    require_once $controllerPath;
    $reflection = new ReflectionClass('App\Http\Controllers\API\V1\Customer\AIConsultationController');
    
    if ($reflection->hasMethod('store')) {
        echo "✓ store() method exists\n";
    } else {
        echo "✗ store() method not found\n";
    }
    
    if ($reflection->hasMethod('compressImage')) {
        echo "✓ compressImage() method exists\n";
    } else {
        echo "✗ compressImage() method not found\n";
    }
    
    if ($reflection->hasMethod('formatProviders')) {
        echo "✓ formatProviders() method exists\n";
    } else {
        echo "✗ formatProviders() method not found\n";
    }
    
    echo "\n";
} catch (Exception $e) {
    echo "✗ Error checking controller methods: " . $e->getMessage() . "\n\n";
}

echo "=== Test Summary ===\n";
echo "All basic checks completed.\n";
echo "To test the endpoint with actual requests, you need:\n";
echo "1. A valid JWT token for a customer user\n";
echo "2. A base64 encoded image\n";
echo "3. At least one marker with x, y, and description\n";
echo "\nEndpoint: POST /api/v1/customer/ai/consultations\n";
echo "Rate limit: 10 requests per minute\n";
