<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "Testing AI Integration...\n\n";

try {
    // Test 1: Check Ollama connection
    echo "1. Testing Ollama connection...\n";
    $ollamaHost = config('services.ollama.host', env('OLLAMA_HOST', 'http://gharsewa_ollama:11434'));
    echo "   Ollama Host: $ollamaHost\n";
    
    $ch = curl_init("$ollamaHost/api/tags");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200) {
        echo "   ✅ Ollama is accessible\n";
        $models = json_decode($response, true);
        echo "   Models loaded: " . count($models['models'] ?? []) . "\n";
        foreach ($models['models'] ?? [] as $model) {
            echo "     - " . $model['name'] . "\n";
        }
    } else {
        echo "   ❌ Ollama not accessible (HTTP $httpCode)\n";
    }
    
    // Test 2: Check AI Service
    echo "\n2. Testing AIService...\n";
    $aiService = app(\App\Services\AI\AIService::class);
    echo "   ✅ AIService instantiated\n";
    echo "   Model: " . config('services.ollama.model', env('OLLAMA_MODEL', 'qwen3-vl:2b')) . "\n";
    
    // Test 3: Check VisionAIService
    echo "\n3. Testing VisionAIService...\n";
    $visionService = app(\App\Services\AI\VisionAIService::class);
    echo "   ✅ VisionAIService instantiated\n";
    
    // Test 4: Check database tables
    echo "\n4. Checking database tables...\n";
    $tables = ['ai_consultations', 'ai_requests', 'ai_recommendations', 'ai_match_scores', 'ai_predictions'];
    foreach ($tables as $table) {
        $exists = \Illuminate\Support\Facades\Schema::hasTable($table);
        echo "   " . ($exists ? "✅" : "❌") . " Table '$table' " . ($exists ? "exists" : "missing") . "\n";
    }
    
    // Test 5: Check AIConsultation model
    echo "\n5. Testing AIConsultation model...\n";
    $count = \App\Models\AIConsultation::count();
    echo "   ✅ AIConsultation model works\n";
    echo "   Total consultations: $count\n";
    
    // Test 6: Test simple AI request (text only, no image)
    echo "\n6. Testing simple AI text request...\n";
    try {
        $testPrompt = "What is 2+2? Answer in one word.";
        $ch = curl_init("$ollamaHost/api/generate");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
            'model' => 'qwen3-vl:2b',
            'prompt' => $testPrompt,
            'stream' => false
        ]));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode === 200) {
            $result = json_decode($response, true);
            echo "   ✅ AI responded successfully\n";
            echo "   Response: " . substr($result['response'] ?? 'No response', 0, 100) . "\n";
        } else {
            echo "   ❌ AI request failed (HTTP $httpCode)\n";
            echo "   Response: " . substr($response, 0, 200) . "\n";
        }
    } catch (\Exception $e) {
        echo "   ❌ Error: " . $e->getMessage() . "\n";
    }
    
    echo "\n✅ All basic tests completed!\n";
    
} catch (\Exception $e) {
    echo "\n❌ Error: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
