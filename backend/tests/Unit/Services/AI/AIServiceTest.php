<?php

namespace Tests\Unit\Services\AI;

use App\DTOs\AI\AIResponse;
use App\Models\AIRequest;
use App\Services\AI\AIService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AIServiceTest extends TestCase
{
    protected AIService $aiService;

    protected function setUp(): void
    {
        parent::setUp();

        // Force in-memory SQLite database for testing
        Config::set('database.default', 'sqlite');
        Config::set('database.connections.sqlite.database', ':memory:');

        // Set up test configuration
        Config::set('services.ollama.host', 'http://localhost:11434');
        Config::set('services.ollama.model', 'qwen3-vl:2b');
        Config::set('services.ollama.timeout', 60);
        Config::set('services.ollama.max_tokens', 2048);
        Config::set('services.ollama.temperature', 0.7);
        Config::set('services.ollama.top_p', 0.9);
        Config::set('services.ollama.max_retries', 3);
        Config::set('services.ollama.retry_delay', 1000);
        Config::set('services.ollama.cache_ttl', 3600);

        // Create ai_requests table if it doesn't exist
        if (!Schema::hasTable('ai_requests')) {
            Schema::create('ai_requests', function ($table) {
                $table->uuid('id')->primary();
                $table->uuid('user_id')->nullable();
                $table->string('request_type', 50);
                $table->text('prompt');
                $table->text('response')->nullable();
                $table->integer('response_time_ms');
                $table->boolean('success');
                $table->text('error_message')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();
            });
        }

        $this->aiService = new AIService();
    }

    protected function tearDown(): void
    {
        // Clean up test data
        if (Schema::hasTable('ai_requests')) {
            DB::table('ai_requests')->truncate();
        }

        parent::tearDown();
    }

    /**
     * Test AIService can be instantiated
     */
    public function test_ai_service_can_be_instantiated(): void
    {
        $this->assertInstanceOf(AIService::class, $this->aiService);
    }

    /**
     * Test successful AI generation
     */
    public function test_generate_returns_successful_response(): void
    {
        // Mock successful Ollama response
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'This is a test AI response',
                'total_duration' => 1000000000,
                'load_duration' => 100000000,
                'prompt_eval_count' => 10,
                'eval_count' => 20,
            ], 200),
        ]);

        $response = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertInstanceOf(AIResponse::class, $response);
        $this->assertTrue($response->success);
        $this->assertEquals('This is a test AI response', $response->content);
        $this->assertArrayHasKey('model', $response->metadata);
        $this->assertEquals('qwen3-vl:2b', $response->metadata['model']);
    }

    /**
     * Test generate logs AI request to database
     */
    public function test_generate_logs_request_to_database(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'Test response',
            ], 200),
        ]);

        $this->aiService->generate('Test prompt', 'recommendation', 'user-123', false);

        $this->assertDatabaseHas('ai_requests', [
            'request_type' => 'recommendation',
            'user_id' => 'user-123',
            'success' => true,
        ]);
    }

    /**
     * Test generate with caching enabled
     */
    public function test_generate_uses_cache_when_enabled(): void
    {
        // First request - should hit API
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'Cached response',
            ], 200),
        ]);

        $response1 = $this->aiService->generate('Test prompt', 'general', null, true);

        // Second request - should use cache
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'New response',
            ], 200),
        ]);

        $response2 = $this->aiService->generate('Test prompt', 'general', null, true);

        // Both responses should be identical (from cache)
        $this->assertEquals($response1->content, $response2->content);
        $this->assertEquals('Cached response', $response2->content);
    }

    /**
     * Test generate without caching
     */
    public function test_generate_bypasses_cache_when_disabled(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::sequence()
                ->push([
                    'model' => 'qwen3-vl:2b',
                    'response' => 'First response',
                ], 200)
                ->push([
                    'model' => 'qwen3-vl:2b',
                    'response' => 'Second response',
                ], 200),
        ]);

        $response1 = $this->aiService->generate('Test prompt', 'general', null, false);
        $response2 = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertEquals('First response', $response1->content);
        $this->assertEquals('Second response', $response2->content);
    }

    /**
     * Test generate handles Ollama API errors
     */
    public function test_generate_handles_api_errors(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'error' => 'Model not found',
            ], 404),
        ]);

        $response = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertInstanceOf(AIResponse::class, $response);
        $this->assertFalse($response->success);
        $this->assertNotNull($response->error);
        $this->assertStringContainsString('Ollama API error', $response->error);
    }

    /**
     * Test generate handles connection timeout
     */
    public function test_generate_handles_connection_timeout(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => function () {
                throw new \Illuminate\Http\Client\ConnectionException('Connection timeout');
            },
        ]);

        $response = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertFalse($response->success);
        $this->assertNotNull($response->error);
    }

    /**
     * Test generate handles malformed response
     */
    public function test_generate_handles_malformed_response(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                // Missing 'response' field
            ], 200),
        ]);

        $response = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertFalse($response->success);
        $this->assertStringContainsString('Invalid response', $response->error);
    }

    /**
     * Test generate retry logic with exponential backoff
     */
    public function test_generate_retries_on_failure(): void
    {
        // First two attempts fail, third succeeds
        Http::fake([
            'localhost:11434/api/generate' => Http::sequence()
                ->push(['error' => 'Server error'], 500)
                ->push(['error' => 'Server error'], 500)
                ->push([
                    'model' => 'qwen3-vl:2b',
                    'response' => 'Success after retry',
                ], 200),
        ]);

        $response = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertTrue($response->success);
        $this->assertEquals('Success after retry', $response->content);
    }

    /**
     * Test generate fails after max retries
     */
    public function test_generate_fails_after_max_retries(): void
    {
        // All attempts fail
        Http::fake([
            'localhost:11434/api/generate' => Http::response(['error' => 'Server error'], 500),
        ]);

        $response = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertFalse($response->success);
        $this->assertNotNull($response->error);
    }

    /**
     * Test generate logs failed requests
     */
    public function test_generate_logs_failed_requests(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response(['error' => 'Server error'], 500),
        ]);

        $this->aiService->generate('Test prompt', 'general', 'user-123', false);

        $this->assertDatabaseHas('ai_requests', [
            'request_type' => 'general',
            'user_id' => 'user-123',
            'success' => false,
        ]);
    }

    /**
     * Test healthCheck returns true when Ollama is available
     */
    public function test_health_check_returns_true_when_ollama_available(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([
                'models' => [
                    ['name' => 'qwen3-vl:2b'],
                ],
            ], 200),
        ]);

        $result = $this->aiService->healthCheck();

        $this->assertTrue($result);
    }

    /**
     * Test healthCheck returns false when Ollama is unavailable
     */
    public function test_health_check_returns_false_when_ollama_unavailable(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([], 500),
        ]);

        $result = $this->aiService->healthCheck();

        $this->assertFalse($result);
    }

    /**
     * Test healthCheck handles connection errors
     */
    public function test_health_check_handles_connection_errors(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => function () {
                throw new \Illuminate\Http\Client\ConnectionException('Connection refused');
            },
        ]);

        $result = $this->aiService->healthCheck();

        $this->assertFalse($result);
    }

    /**
     * Test listModels returns available models
     */
    public function test_list_models_returns_available_models(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([
                'models' => [
                    ['name' => 'qwen3-vl:2b', 'size' => 1234567890],
                    ['name' => 'llama2:7b', 'size' => 9876543210],
                ],
            ], 200),
        ]);

        $models = $this->aiService->listModels();

        $this->assertIsArray($models);
        $this->assertCount(2, $models);
        $this->assertEquals('qwen3-vl:2b', $models[0]['name']);
        $this->assertEquals('llama2:7b', $models[1]['name']);
    }

    /**
     * Test listModels returns empty array on error
     */
    public function test_list_models_returns_empty_array_on_error(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([], 500),
        ]);

        $models = $this->aiService->listModels();

        $this->assertIsArray($models);
        $this->assertEmpty($models);
    }

    /**
     * Test listModels handles connection errors
     */
    public function test_list_models_handles_connection_errors(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => function () {
                throw new \Illuminate\Http\Client\ConnectionException('Connection refused');
            },
        ]);

        $models = $this->aiService->listModels();

        $this->assertIsArray($models);
        $this->assertEmpty($models);
    }

    /**
     * Test listModels handles malformed response
     */
    public function test_list_models_handles_malformed_response(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([
                // Missing 'models' field
                'data' => [],
            ], 200),
        ]);

        $models = $this->aiService->listModels();

        $this->assertIsArray($models);
        $this->assertEmpty($models);
    }

    /**
     * Test validateModel returns true for available model
     */
    public function test_validate_model_returns_true_for_available_model(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([
                'models' => [
                    ['name' => 'qwen3-vl:2b'],
                    ['name' => 'llama2:7b'],
                ],
            ], 200),
        ]);

        $result = $this->aiService->validateModel('qwen3-vl:2b');

        $this->assertTrue($result);
    }

    /**
     * Test validateModel returns false for unavailable model
     */
    public function test_validate_model_returns_false_for_unavailable_model(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([
                'models' => [
                    ['name' => 'qwen3-vl:2b'],
                ],
            ], 200),
        ]);

        $result = $this->aiService->validateModel('nonexistent-model');

        $this->assertFalse($result);
    }

    /**
     * Test validateModel uses default model when no model specified
     */
    public function test_validate_model_uses_default_model(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([
                'models' => [
                    ['name' => 'qwen3-vl:2b'],
                ],
            ], 200),
        ]);

        $result = $this->aiService->validateModel();

        $this->assertTrue($result);
    }

    /**
     * Test validateModel returns false when API fails
     */
    public function test_validate_model_returns_false_when_api_fails(): void
    {
        Http::fake([
            'localhost:11434/api/tags' => Http::response([], 500),
        ]);

        $result = $this->aiService->validateModel('qwen3-vl:2b');

        $this->assertFalse($result);
    }

    /**
     * Test getParser returns ResponseParser instance
     */
    public function test_get_parser_returns_response_parser(): void
    {
        $parser = $this->aiService->getParser();

        $this->assertInstanceOf(\App\Services\AI\ResponseParser::class, $parser);
    }

    /**
     * Test generate includes all metadata from Ollama response
     */
    public function test_generate_includes_all_metadata(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'Test response',
                'total_duration' => 5000000000,
                'load_duration' => 500000000,
                'prompt_eval_count' => 15,
                'eval_count' => 30,
            ], 200),
        ]);

        $response = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertTrue($response->success);
        $this->assertEquals('qwen3-vl:2b', $response->metadata['model']);
        $this->assertEquals(5000000000, $response->metadata['total_duration']);
        $this->assertEquals(500000000, $response->metadata['load_duration']);
        $this->assertEquals(15, $response->metadata['prompt_eval_count']);
        $this->assertEquals(30, $response->metadata['eval_count']);
    }

    /**
     * Test generate handles partial metadata
     */
    public function test_generate_handles_partial_metadata(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'Test response',
                // Only some metadata fields present
                'total_duration' => 5000000000,
            ], 200),
        ]);

        $response = $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertTrue($response->success);
        $this->assertEquals('qwen3-vl:2b', $response->metadata['model']);
        $this->assertEquals(5000000000, $response->metadata['total_duration']);
        $this->assertNull($response->metadata['load_duration']);
        $this->assertNull($response->metadata['prompt_eval_count']);
        $this->assertNull($response->metadata['eval_count']);
    }

    /**
     * Test cache key generation is consistent
     */
    public function test_cache_key_generation_is_consistent(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'Test response',
            ], 200),
        ]);

        // Generate with cache enabled
        $this->aiService->generate('Same prompt', 'general', null, true);

        // Check cache was set
        $cacheKey = 'ai_response:' . md5('Same prompt' . 'qwen3-vl:2b');
        $this->assertTrue(Cache::has($cacheKey));
    }

    /**
     * Test different prompts generate different cache keys
     */
    public function test_different_prompts_generate_different_cache_keys(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::sequence()
                ->push(['model' => 'qwen3-vl:2b', 'response' => 'Response 1'], 200)
                ->push(['model' => 'qwen3-vl:2b', 'response' => 'Response 2'], 200),
        ]);

        $response1 = $this->aiService->generate('Prompt 1', 'general', null, true);
        $response2 = $this->aiService->generate('Prompt 2', 'general', null, true);

        $this->assertNotEquals($response1->content, $response2->content);
    }

    /**
     * Test response time is tracked
     */
    public function test_response_time_is_tracked(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'Test response',
            ], 200),
        ]);

        $this->aiService->generate('Test prompt', 'general', 'user-123', false);

        $request = AIRequest::where('user_id', 'user-123')->first();
        $this->assertNotNull($request);
        $this->assertGreaterThan(0, $request->response_time_ms);
    }

    /**
     * Test prompt is stored in database
     */
    public function test_prompt_is_stored_in_database(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'Test response',
            ], 200),
        ]);

        $testPrompt = 'This is a test prompt for storage';
        $this->aiService->generate($testPrompt, 'general', null, false);

        $this->assertDatabaseHas('ai_requests', [
            'prompt' => $testPrompt,
        ]);
    }

    /**
     * Test response is stored in database
     */
    public function test_response_is_stored_in_database(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response([
                'model' => 'qwen3-vl:2b',
                'response' => 'Stored response content',
            ], 200),
        ]);

        $this->aiService->generate('Test prompt', 'general', null, false);

        $this->assertDatabaseHas('ai_requests', [
            'response' => 'Stored response content',
        ]);
    }

    /**
     * Test error message is stored for failed requests
     */
    public function test_error_message_is_stored_for_failed_requests(): void
    {
        Http::fake([
            'localhost:11434/api/generate' => Http::response(['error' => 'Model not loaded'], 503),
        ]);

        $this->aiService->generate('Test prompt', 'general', 'user-123', false);

        $request = AIRequest::where('user_id', 'user-123')->first();
        $this->assertNotNull($request);
        $this->assertFalse($request->success);
        $this->assertNotNull($request->error_message);
    }
}
