<?php

namespace App\Jobs\AI;

use App\Models\User;
use App\Services\AI\RecommendationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Exception;

class GenerateRecommendationsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 120;
    public int $backoff = 60;

    /**
     * Create a new job instance.
     */
    public function __construct(
        public string $userId,
        public int $limit = 5
    ) {
        $this->onQueue('ai-processing');
    }

    /**
     * Execute the job.
     */
    public function handle(RecommendationService $service): void
    {
        try {
            Log::info('Generating AI recommendations', [
                'user_id' => $this->userId,
                'limit' => $this->limit
            ]);

            $user = User::findOrFail($this->userId);
            
            $recommendations = $service->generateRecommendations($user, $this->limit);

            Log::info('AI recommendations generated successfully', [
                'user_id' => $this->userId,
                'count' => count($recommendations)
            ]);
        } catch (Exception $e) {
            Log::error('Failed to generate AI recommendations', [
                'user_id' => $this->userId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            throw $e;
        }
    }

    /**
     * Handle a job failure.
     */
    public function failed(Exception $exception): void
    {
        Log::error('GenerateRecommendationsJob failed permanently', [
            'user_id' => $this->userId,
            'error' => $exception->getMessage()
        ]);
    }
}
