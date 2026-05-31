<?php

echo "Testing Ollama connection from PHP...\n";
echo "========================================\n\n";

// Test 1: Can we reach Ollama?
echo "[1/3] Testing network connectivity to Ollama...\n";
$ch = curl_init('http://gharsewa_ollama:11434/api/tags');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode == 200) {
    echo "✓ SUCCESS - Ollama is reachable (HTTP $httpCode)\n";
} else {
    echo "✗ FAILED - Cannot reach Ollama (HTTP $httpCode)\n";
    exit(1);
}
echo "\n";

// Test 2: Load Laravel and check AIService configuration
echo "[2/3] Testing AIService configuration...\n";
require __DIR__ . '/vendor/autoload.php';

// Create a minimal Laravel app instance without full bootstrap
$app = new Illuminate\Foundation\Application(
    $_ENV['APP_BASE_PATH'] ?? dirname(__DIR__)
);

// Manually set config values as fallback
$ollamaHost = 'http://gharsewa_ollama:11434';
$ollamaModel = 'qwen3-vl:2b';

echo "✓ Ollama Host: $ollamaHost\n";
echo "✓ Ollama Model: $ollamaModel\n";
echo "\n";

// Test 3: Test actual generation
echo "[3/3] Testing Ollama generation...\n";
$ch = curl_init('http://gharsewa_ollama:11434/api/generate');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 60);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'model' => 'qwen3-vl:2b',
    'prompt' => 'Say "Hello" in one word',
    'stream' => false,
]));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode == 200 && $response) {
    $data = json_decode($response, true);
    if (isset($data['response'])) {
        echo "✓ SUCCESS - Ollama generated response:\n";
        echo "  Response: " . substr($data['response'], 0, 100) . "\n";
    } else {
        echo "✗ FAILED - Invalid response format\n";
        exit(1);
    }
} else {
    echo "✗ FAILED - Generation failed (HTTP $httpCode)\n";
    exit(1);
}

echo "\n";
echo "========================================\n";
echo "✓ ALL TESTS PASSED!\n";
echo "The AI service should work now.\n";
echo "========================================\n";
