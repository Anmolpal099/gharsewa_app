<?php

namespace App\Services\AI;

use App\DTOs\AI\AIResponse;
use App\Models\AIRequest;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class AIService
{
    protected string $ollamaHost;
    protected string $model;
    protected int $timeout;
    protected int $maxTokens;
    protected float $temperature;
    protected float $topP;
    protected int $maxRetries;
    protected int $retryDelay;

    protected ResponseParser $parser;

    public function __construct()
    {
        // Use hardcoded fallbacks for Docker environment where env vars may not load properly
        $this->ollamaHost = config('services.ollama.host') 
            ?? env('OLLAMA_HOST') 
            ?? 'http://gharsewa_ollama:11434';
        
        $this->model = config('services.ollama.model') 
            ?? env('OLLAMA_MODEL') 
            ?? 'qwen3-vl:2b';
        
        $this->timeout = (int) (config('services.ollama.timeout') 
            ?? env('OLLAMA_TIMEOUT') 
            ?? 120);
        
        $this->maxTokens = (int) (config('services.ollama.max_tokens') 
            ?? env('OLLAMA_MAX_TOKENS') 
            ?? 2048);
        
        $this->temperature = (float) (config('services.ollama.temperature') 
            ?? env('OLLAMA_TEMPERATURE') 
            ?? 0.7);
        
        $this->topP = (float) (config('services.ollama.top_p') 
            ?? env('OLLAMA_TOP_P') 
            ?? 0.9);
        
        $this->maxRetries = (int) (config('services.ollama.max_retries') 
            ?? env('AI_MAX_RETRIES') 
            ?? 3);
        
        $this->retryDelay = (int) (config('services.ollama.retry_delay') 
            ?? env('AI_RETRY_DELAY') 
            ?? 1000);

        $this->parser = new ResponseParser();
        
        // Log configuration for debugging
        Log::debug('AIService initialized', [
            'ollama_host' => $this->ollamaHost,
            'model' => $this->model,
            'timeout' => $this->timeout,
        ]);
    }

    /**
     * Generate AI response from prompt
     */
    public function generate(
        string $prompt,
        string $requestType = 'general',
        ?string $userId = null,
        bool $useCache = true
    ): AIResponse {
        $startTime = microtime(true);

        try {
            // Check cache first
            if ($useCache) {
                $cached = $this->getCachedResponse($prompt);
                if ($cached !== null) {
                    Log::info('AI cache hit', ['request_type' => $requestType]);
                    return $cached;
                }
            }

            // Generate response with retry logic
            $response = $this->generateWithRetry($prompt);

            $responseTime = (int) ((microtime(true) - $startTime) * 1000);

            // Log request
            $this->logRequest($requestType, $userId, $prompt, $response, $responseTime, true);

            // Cache response
            if ($useCache) {
                $this->cacheResponse($prompt, $response);
            }

            return $response;
        } catch (Exception $e) {
            $responseTime = (int) ((microtime(true) - $startTime) * 1000);

            Log::error('AI generation failed', [
                'request_type' => $requestType,
                'error' => $e->getMessage(),
                'prompt_length' => strlen($prompt)
            ]);

            // Log failed request
            $this->logRequest($requestType, $userId, $prompt, null, $responseTime, false, $e->getMessage());

            return AIResponse::failure($e->getMessage());
        }
    }

    /**
     * Generate with exponential backoff retry
     */
    private function generateWithRetry(string $prompt): AIResponse
    {
        $attempt = 0;
        $lastException = null;

        while ($attempt < $this->maxRetries) {
            try {
                return $this->callOllamaAPI($prompt);
            } catch (Exception $e) {
                $lastException = $e;
                $attempt++;

                if ($attempt < $this->maxRetries) {
                    $delay = $this->retryDelay * pow(2, $attempt - 1); // Exponential backoff
                    Log::warning("AI request failed, retrying in {$delay}ms", [
                        'attempt' => $attempt,
                        'error' => $e->getMessage()
                    ]);
                    usleep($delay * 1000);
                }
            }
        }

        throw $lastException ?? new Exception('AI generation failed after retries');
    }

    /**
     * Call Ollama API
     */
    private function callOllamaAPI(string $prompt): AIResponse
    {
        $response = Http::timeout($this->timeout)
            ->post("{$this->ollamaHost}/api/generate", [
                'model' => $this->model,
                'prompt' => $prompt,
                'stream' => false,
                'options' => [
                    'num_predict' => $this->maxTokens,
                    'temperature' => $this->temperature,
                    'top_p' => $this->topP,
                ],
            ]);

        if (!$response->successful()) {
            throw new Exception("Ollama API error: " . $response->body());
        }

        $data = $response->json();

        if (!isset($data['response'])) {
            throw new Exception('Invalid response from Ollama API');
        }

        return AIResponse::success(
            content: $data['response'],
            metadata: [
                'model' => $data['model'] ?? $this->model,
                'total_duration' => $data['total_duration'] ?? null,
                'load_duration' => $data['load_duration'] ?? null,
                'prompt_eval_count' => $data['prompt_eval_count'] ?? null,
                'eval_count' => $data['eval_count'] ?? null,
            ]
        );
    }

    /**
     * Check Ollama health
     */
    public function healthCheck(): bool
    {
        try {
            $response = Http::timeout(5)->get("{$this->ollamaHost}/api/tags");
            return $response->successful();
        } catch (Exception $e) {
            Log::error('Ollama health check failed', ['error' => $e->getMessage()]);
            return false;
        }
    }

    /**
     * List available models
     */
    public function listModels(): array
    {
        try {
            $response = Http::timeout(5)->get("{$this->ollamaHost}/api/tags");

            if (!$response->successful()) {
                return [];
            }

            $data = $response->json();
            return $data['models'] ?? [];
        } catch (Exception $e) {
            Log::error('Failed to list models', ['error' => $e->getMessage()]);
            return [];
        }
    }

    /**
     * Validate if model is available
     */
    public function validateModel(string $model = null): bool
    {
        $modelToCheck = $model ?? $this->model;
        $models = $this->listModels();

        foreach ($models as $availableModel) {
            if (isset($availableModel['name']) && $availableModel['name'] === $modelToCheck) {
                return true;
            }
        }

        return false;
    }

    /**
     * Get cached response
     */
    private function getCachedResponse(string $prompt): ?AIResponse
    {
        $cacheKey = $this->getCacheKey($prompt);
        $cached = Cache::get($cacheKey);

        if ($cached !== null) {
            return unserialize($cached);
        }

        return null;
    }

    /**
     * Cache response
     */
    private function cacheResponse(string $prompt, AIResponse $response): void
    {
        $cacheKey = $this->getCacheKey($prompt);
        $ttl = (int) config('services.ollama.cache_ttl', env('AI_CACHE_TTL', 3600));

        Cache::put($cacheKey, serialize($response), $ttl);
    }

    /**
     * Generate cache key
     */
    private function getCacheKey(string $prompt): string
    {
        return 'ai_response:' . md5($prompt . $this->model);
    }

    /**
     * Log AI request
     */
    private function logRequest(
        string $requestType,
        ?string $userId,
        string $prompt,
        ?AIResponse $response,
        int $responseTime,
        bool $success,
        ?string $error = null
    ): void {
        try {
            AIRequest::create([
                'request_type' => $requestType,
                'user_id' => $userId,
                'prompt' => $prompt,
                'response' => $response?->content,
                'response_time_ms' => $responseTime,
                'success' => $success,
                'error_message' => $error,
                'metadata' => $response?->metadata ?? [],
            ]);
        } catch (Exception $e) {
            Log::error('Failed to log AI request', ['error' => $e->getMessage()]);
        }
    }

    /**
     * Get response parser
     */
    public function getParser(): ResponseParser
    {
        return $this->parser;
    }
}
