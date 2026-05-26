<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Ollama Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for the Ollama AI service running locally in Docker.
    |
    */

    'ollama_host' => env('OLLAMA_HOST', 'http://localhost:11434'),
    'ollama_model' => env('OLLAMA_MODEL', 'qwen2.5:3b'),

    /*
    |--------------------------------------------------------------------------
    | AI Request Configuration
    |--------------------------------------------------------------------------
    |
    | Settings for AI request behavior and performance.
    |
    */

    'timeout' => env('OLLAMA_TIMEOUT', 30),
    'max_tokens' => env('OLLAMA_MAX_TOKENS', 2048),
    'temperature' => env('OLLAMA_TEMPERATURE', 0.7),
    'top_p' => env('OLLAMA_TOP_P', 0.9),

    /*
    |--------------------------------------------------------------------------
    | Retry and Caching Configuration
    |--------------------------------------------------------------------------
    |
    | Settings for retry logic and response caching.
    |
    */

    'max_retries' => env('AI_MAX_RETRIES', 3),
    'retry_delay' => env('AI_RETRY_DELAY', 1000), // milliseconds
    'cache_ttl' => env('AI_CACHE_TTL', 3600), // seconds

    /*
    |--------------------------------------------------------------------------
    | Prompt Templates Directory
    |--------------------------------------------------------------------------
    |
    | Directory where AI prompt templates are stored.
    |
    */

    'prompts_path' => resource_path('prompts'),
];
