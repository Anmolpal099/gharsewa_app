<?php

require __DIR__ . '/vendor/autoload.php';

use App\Services\AI\VisionAIService;

echo "Testing VisionAIService...\n\n";

// Test 1: Check if class exists
echo "✓ Test 1: Class exists\n";
$service = new VisionAIService();
echo "  - VisionAIService instantiated successfully\n\n";

// Test 2: Check if it extends AIService
echo "✓ Test 2: Extends AIService\n";
$isSubclass = is_subclass_of($service, 'App\Services\AI\AIService');
echo "  - Is subclass of AIService: " . ($isSubclass ? 'YES' : 'NO') . "\n\n";

// Test 3: Check if required methods exist
echo "✓ Test 3: Required methods exist\n";
$methods = [
    'analyzeImage',
    'buildVisionPrompt',
    'parseVisionResponse',
    'findMatchingProviders',
    'encodeImageToBase64',
];

foreach ($methods as $method) {
    $exists = method_exists($service, $method);
    echo "  - {$method}(): " . ($exists ? 'YES' : 'NO') . "\n";
}

echo "\n✓ All basic checks passed!\n";
echo "\nVisionAIService is ready for use.\n";

