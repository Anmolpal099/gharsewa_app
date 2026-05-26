<?php

namespace App\Console\Commands;

use App\Services\AI\AIService;
use Illuminate\Console\Command;

class TestAIService extends Command
{
    protected $signature = 'ai:test';
    protected $description = 'Test AI service connectivity and functionality';

    public function handle(): int
    {
        $this->info('Testing AI Service...');
        $this->newLine();

        $aiService = new AIService();

        // Test 1: Health Check
        $this->info('1. Testing health check...');
        $isHealthy = $aiService->healthCheck();
        
        if ($isHealthy) {
            $this->info('✓ Ollama is healthy and accessible');
        } else {
            $this->error('✗ Ollama is not accessible');
            return 1;
        }

        $this->newLine();

        // Test 2: List Models
        $this->info('2. Listing available models...');
        $models = $aiService->listModels();
        
        if (empty($models)) {
            $this->warn('No models found');
        } else {
            foreach ($models as $model) {
                $this->line("  - {$model['name']} ({$model['size']})");
            }
        }

        $this->newLine();

        // Test 3: Validate Configured Model
        $this->info('3. Validating configured model...');
        $configuredModel = config('ai.ollama_model');
        $isValid = $aiService->validateModel($configuredModel);
        
        if ($isValid) {
            $this->info("✓ Model '{$configuredModel}' is available");
        } else {
            $this->error("✗ Model '{$configuredModel}' is not available");
            return 1;
        }

        $this->newLine();

        // Test 4: Generate Response
        $this->info('4. Testing response generation...');
        $response = $aiService->generate('Say "Hello from GharSewa AI!" in one sentence.');
        
        if ($response->isSuccess()) {
            $this->info('✓ Response generated successfully');
            $this->line('Response: ' . $response->content);
            $this->line('Duration: ' . round($response->getMetadata('duration', 0), 2) . 's');
        } else {
            $this->error('✗ Failed to generate response: ' . $response->error);
            return 1;
        }

        $this->newLine();
        $this->info('All tests passed! AI service is working correctly.');

        return 0;
    }
}
