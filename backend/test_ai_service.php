<?php

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\Facade;

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Test AI Service
echo "Testing AI Service...\n\n";

try {
    $aiService = new App\Services\AI\AIService();
    
    // Test 1: Health Check
    echo "1. Testing Ollama health check...\n";
    $isHealthy = $aiService->healthCheck();
    echo "   Health: " . ($isHealthy ? "✓ OK" : "✗ FAILED") . "\n\n";
    
    // Test 2: List Models
    echo "2. Listing available models...\n";
    $models = $aiService->listModels();
    if (!empty($models)) {
        foreach ($models as $model) {
            echo "   - " . ($model['name'] ?? 'Unknown') . "\n";
        }
    } else {
        echo "   No models found\n";
    }
    echo "\n";
    
    // Test 3: Validate Model
    echo "3. Validating configured model...\n";
    $isValid = $aiService->validateModel();
    echo "   Model valid: " . ($isValid ? "✓ YES" : "✗ NO") . "\n\n";
    
    // Test 4: Simple Generation
    echo "4. Testing AI generation (simple prompt)...\n";
    $response = $aiService->generate(
        prompt: "Respond with just the word 'SUCCESS' if you can understand this.",
        requestType: 'test',
        useCache: false
    );
    
    echo "   Success: " . ($response->success ? "✓ YES" : "✗ NO") . "\n";
    if ($response->success) {
        echo "   Response: " . substr($response->content, 0, 100) . "\n";
        echo "   Response time: " . ($response->getMetadata('total_duration') / 1000000) . "ms\n";
    } else {
        echo "   Error: " . $response->error . "\n";
    }
    echo "\n";
    
    // Test 5: JSON Response Parsing
    echo "5. Testing JSON response parsing...\n";
    $jsonPrompt = 'Return a JSON object with two fields: "status" set to "ok" and "message" set to "test successful". Return ONLY the JSON, no other text.';
    $response = $aiService->generate($jsonPrompt, 'test', null, false);
    
    if ($response->success) {
        $parser = $aiService->getParser();
        $parsed = $parser->parseJson($response->content);
        
        if ($parsed !== null) {
            echo "   ✓ JSON parsed successfully\n";
            echo "   Data: " . json_encode($parsed) . "\n";
        } else {
            echo "   ✗ Failed to parse JSON\n";
            echo "   Raw response: " . substr($response->content, 0, 200) . "\n";
        }
    } else {
        echo "   ✗ Generation failed: " . $response->error . "\n";
    }
    echo "\n";
    
    // Test 6: Cache Test
    echo "6. Testing cache functionality...\n";
    $cachePrompt = "Say 'cached' in one word.";
    
    $start1 = microtime(true);
    $response1 = $aiService->generate($cachePrompt, 'test', null, true);
    $time1 = (microtime(true) - $start1) * 1000;
    
    $start2 = microtime(true);
    $response2 = $aiService->generate($cachePrompt, 'test', null, true);
    $time2 = (microtime(true) - $start2) * 1000;
    
    echo "   First call: {$time1}ms\n";
    echo "   Second call (cached): {$time2}ms\n";
    echo "   Cache working: " . ($time2 < $time1 / 2 ? "✓ YES" : "✗ NO") . "\n\n";
    
    echo "✓ All tests completed!\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}
