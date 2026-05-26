<?php

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Foundation\Application;
use App\Services\AI\AIService;
use App\Services\AI\PromptBuilder;
use App\Services\AI\ResponseParser;
use App\Models\AIRequest;

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "=================================================\n";
echo "  AI Integration Test Suite (Waves 1-3)\n";
echo "=================================================\n\n";

$results = [
    'passed' => 0,
    'failed' => 0,
    'tests' => []
];

function test($name, $callback) {
    global $results;
    echo "Testing: {$name}...\n";
    try {
        $result = $callback();
        if ($result) {
            echo "  ✓ PASSED\n\n";
            $results['passed']++;
            $results['tests'][$name] = 'PASSED';
        } else {
            echo "  ✗ FAILED\n\n";
            $results['failed']++;
            $results['tests'][$name] = 'FAILED';
        }
    } catch (Exception $e) {
        echo "  ✗ FAILED: " . $e->getMessage() . "\n\n";
        $results['failed']++;
        $results['tests'][$name] = 'FAILED: ' . $e->getMessage();
    }
}

// ============================================
// WAVE 1: Database Tests
// ============================================
echo "--- WAVE 1: Database Tests ---\n\n";

test("Database: ai_requests table exists", function() {
    return Schema::hasTable('ai_requests');
});

test("Database: ai_recommendations table exists", function() {
    return Schema::hasTable('ai_recommendations');
});

test("Database: ai_match_scores table exists", function() {
    return Schema::hasTable('ai_match_scores');
});

test("Database: ai_predictions table exists", function() {
    return Schema::hasTable('ai_predictions');
});

test("Database: notification_schedules table exists", function() {
    return Schema::hasTable('notification_schedules');
});

test("Model: AIRequest can be instantiated", function() {
    $request = new AIRequest();
    return $request instanceof AIRequest;
});

// ============================================
// WAVE 2: AI Infrastructure Tests
// ============================================
echo "--- WAVE 2: AI Infrastructure Tests ---\n\n";

test("AIService: Can be instantiated", function() {
    $service = new AIService();
    return $service instanceof AIService;
});

test("AIService: Health check works", function() {
    $service = new AIService();
    return $service->healthCheck();
});

test("AIService: Can list models", function() {
    $service = new AIService();
    $models = $service->listModels();
    echo "  Found " . count($models) . " models\n";
    return count($models) > 0;
});

test("AIService: Can validate configured model", function() {
    $service = new AIService();
    return $service->validateModel();
});

test("PromptBuilder: Can load template", function() {
    $builder = PromptBuilder::fromTemplate('recommendation.txt');
    $template = $builder->getTemplate();
    return !empty($template) && str_contains($template, '{{user_name}}');
});

test("PromptBuilder: Can substitute variables", function() {
    $builder = PromptBuilder::fromString('Hello {{name}}, you are {{age}} years old.');
    $result = $builder->setVariables([
        'name' => 'John',
        'age' => 25
    ])->build();
    return $result === 'Hello John, you are 25 years old.';
});

test("PromptBuilder: Detects unreplaced variables", function() {
    try {
        $builder = PromptBuilder::fromString('Hello {{name}}, you are {{age}} years old.');
        $builder->setVariable('name', 'John')->build();
        return false; // Should have thrown exception
    } catch (InvalidArgumentException $e) {
        return str_contains($e->getMessage(), 'Unreplaced variable');
    }
});

test("ResponseParser: Can parse JSON", function() {
    $parser = new ResponseParser();
    $json = '{"status": "ok", "message": "test"}';
    $parsed = $parser->parseJson($json);
    return $parsed !== null && $parsed['status'] === 'ok';
});

test("ResponseParser: Can extract JSON from mixed text", function() {
    $parser = new ResponseParser();
    $mixed = 'Here is the result: {"status": "ok", "value": 42} and some more text';
    $parsed = $parser->parseJson($mixed);
    return $parsed !== null && $parsed['value'] === 42;
});

test("ResponseParser: Sanitizes data", function() {
    $parser = new ResponseParser();
    $json = '{"html": "<script>alert(1)</script>"}';
    $parsed = $parser->parseJson($json);
    return $parsed !== null && !str_contains($parsed['html'], '<script>');
});

test("Cache: Redis is configured", function() {
    return config('cache.default') === 'redis';
});

test("Cache: Can store and retrieve", function() {
    Cache::put('test_key', 'test_value', 60);
    $value = Cache::get('test_key');
    Cache::forget('test_key');
    return $value === 'test_value';
});

// ============================================
// WAVE 3: Prompt Templates Tests
// ============================================
echo "--- WAVE 3: Prompt Templates Tests ---\n\n";

test("Template: recommendation.txt exists", function() {
    return file_exists(base_path('resources/prompts/recommendation.txt'));
});

test("Template: matching.txt exists", function() {
    return file_exists(base_path('resources/prompts/matching.txt'));
});

test("Template: analytics.txt exists", function() {
    return file_exists(base_path('resources/prompts/analytics.txt'));
});

test("Template: notification.txt exists", function() {
    return file_exists(base_path('resources/prompts/notification.txt'));
});

test("Template: recommendation.txt has required variables", function() {
    $content = file_get_contents(base_path('resources/prompts/recommendation.txt'));
    return str_contains($content, '{{user_name}}') &&
           str_contains($content, '{{available_services}}') &&
           str_contains($content, '{{limit}}');
});

test("Template: matching.txt has required variables", function() {
    $content = file_get_contents(base_path('resources/prompts/matching.txt'));
    return str_contains($content, '{{service_name}}') &&
           str_contains($content, '{{providers}}') &&
           str_contains($content, '{{customer_location}}');
});

test("Job: GenerateRecommendationsJob exists", function() {
    return class_exists('App\Jobs\AI\GenerateRecommendationsJob');
});

test("Job: CalculateMatchScoresJob exists", function() {
    return class_exists('App\Jobs\AI\CalculateMatchScoresJob');
});

test("Job: GenerateAnalyticsJob exists", function() {
    return class_exists('App\Jobs\AI\GenerateAnalyticsJob');
});

// ============================================
// Integration Tests
// ============================================
echo "--- Integration Tests ---\n\n";

test("Integration: Can build recommendation prompt", function() {
    $builder = PromptBuilder::fromTemplate('recommendation.txt');
    $prompt = $builder->setVariables([
        'user_name' => 'Test User',
        'user_location' => 'Kathmandu',
        'booking_history' => 'Plumbing service (2 times)',
        'user_preferences' => 'Prefers morning appointments',
        'available_services' => json_encode([
            ['id' => '1', 'name' => 'Plumbing'],
            ['id' => '2', 'name' => 'Electrical']
        ]),
        'limit' => 5
    ])->build();
    
    echo "  Prompt length: " . strlen($prompt) . " chars\n";
    return strlen($prompt) > 100 && str_contains($prompt, 'Test User');
});

test("Integration: Can build matching prompt", function() {
    $builder = PromptBuilder::fromTemplate('matching.txt');
    $prompt = $builder->setVariables([
        'service_name' => 'Plumbing',
        'customer_location' => 'Kathmandu',
        'scheduled_time' => '2026-05-27 10:00:00',
        'special_requirements' => 'None',
        'budget' => 'NPR 5000',
        'providers' => json_encode([
            ['id' => '1', 'name' => 'Provider A', 'rating' => 4.5],
            ['id' => '2', 'name' => 'Provider B', 'rating' => 4.8]
        ])
    ])->build();
    
    echo "  Prompt length: " . strlen($prompt) . " chars\n";
    return strlen($prompt) > 100 && str_contains($prompt, 'Plumbing');
});

// ============================================
// Performance Tests
// ============================================
echo "--- Performance Tests ---\n\n";

test("Performance: PromptBuilder is fast", function() {
    $start = microtime(true);
    for ($i = 0; $i < 100; $i++) {
        $builder = PromptBuilder::fromString('Hello {{name}}');
        $builder->setVariable('name', 'Test')->build();
    }
    $time = (microtime(true) - $start) * 1000;
    echo "  100 builds took {$time}ms\n";
    return $time < 100; // Should be under 100ms
});

test("Performance: ResponseParser is fast", function() {
    $parser = new ResponseParser();
    $json = '{"status": "ok", "data": [1,2,3,4,5]}';
    
    $start = microtime(true);
    for ($i = 0; $i < 100; $i++) {
        $parser->parseJson($json);
    }
    $time = (microtime(true) - $start) * 1000;
    echo "  100 parses took {$time}ms\n";
    return $time < 100; // Should be under 100ms
});

// ============================================
// Summary
// ============================================
echo "=================================================\n";
echo "  Test Results Summary\n";
echo "=================================================\n\n";

echo "Total Tests: " . ($results['passed'] + $results['failed']) . "\n";
echo "✓ Passed: " . $results['passed'] . "\n";
echo "✗ Failed: " . $results['failed'] . "\n";
echo "Success Rate: " . round(($results['passed'] / ($results['passed'] + $results['failed'])) * 100, 2) . "%\n\n";

if ($results['failed'] > 0) {
    echo "Failed Tests:\n";
    foreach ($results['tests'] as $name => $status) {
        if (str_starts_with($status, 'FAILED')) {
            echo "  - {$name}: {$status}\n";
        }
    }
    echo "\n";
}

echo ($results['failed'] === 0 ? "✓ All tests passed!" : "✗ Some tests failed") . "\n";
exit($results['failed'] === 0 ? 0 : 1);
