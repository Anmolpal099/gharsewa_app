<?php

namespace Tests\Feature\AI;

use App\Services\AI\AIService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AIServiceTest extends TestCase
{
    protected AIService $aiService;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Use file cache for testing
        config(['cache.default' => 'file']);
        
        $this->aiService = new AIService();
    }

    public function test_health_check_returns_true_when_ollama_is_running(): void
    {
        $isHealthy = $this->aiService->healthCheck();

        $this->assertTrue($isHealthy, 'Ollama service should be healthy');
    }

    public function test_list_models_returns_array(): void
    {
        $models = $this->aiService->listModels();

        $this->assertIsArray($models);
        $this->assertNotEmpty($models, 'At least one model should be available');
    }

    public function test_validate_model_returns_true_for_existing_model(): void
    {
        $modelName = config('ai.ollama_model');
        $isValid = $this->aiService->validateModel($modelName);

        $this->assertTrue($isValid, "Model {$modelName} should be available");
    }

    public function test_generate_returns_successful_response(): void
    {
        $response = $this->aiService->generate('Say hello in one word.');

        $this->assertTrue($response->isSuccess(), 'Response should be successful');
        $this->assertNotEmpty($response->content, 'Response content should not be empty');
        $this->assertIsArray($response->metadata);
    }

    public function test_generate_with_empty_prompt_returns_error(): void
    {
        $response = $this->aiService->generate('');

        $this->assertTrue($response->isError());
        $this->assertStringContainsString('empty', strtolower($response->error));
    }

    public function test_generate_caches_responses(): void
    {
        $prompt = 'Test prompt for caching: ' . time();

        // First call
        $response1 = $this->aiService->generate($prompt);
        $duration1 = $response1->getMetadata('duration', 0);

        // Second call (should be cached)
        $response2 = $this->aiService->generate($prompt);
        $duration2 = $response2->getMetadata('duration', 0);

        $this->assertEquals($response1->content, $response2->content);
        // Cached response should be faster (or have same duration if from cache)
        $this->assertLessThanOrEqual($duration1, $duration2);
    }
}
