<?php

namespace App\Jobs\AI;

use App\Services\AI\AnalyticsService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Exception;

class GenerateAnalyticsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 240;
    public int $backoff = 120;

    /**
     * Create a new job instance.
     */
    public function __construct(
        public string $predictionType,
        public int $days = 7
    ) {
        $this->onQueue('ai-processing');
    }

    /**
     * Execute the job.
     */
    public function handle(AnalyticsService $service): void
    {
        try {
            Log::info('Generating AI analytics', [
                'prediction_type' => $this->predictionType,
                'days' => $this->days
            ]);

            $result = match ($this->predictionType) {
                'booking_volume' => $service->predictBookingVolume($this->days),
                'churn_risk' => $service->identifyTrends(),
                'revenue_forecast' => $service->forecastRevenue($this->days),
                'trend' => $service->identifyTrends(),
                default => throw new Exception("Unknown prediction type: {$this->predictionType}")
            };

            Log::info('AI analytics generated successfully', [
                'prediction_type' => $this->predictionType,
                'result_count' => is_array($result) ? count($result) : 1
            ]);
        } catch (Exception $e) {
            Log::error('Failed to generate AI analytics', [
                'prediction_type' => $this->predictionType,
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
        Log::error('GenerateAnalyticsJob failed permanently', [
            'prediction_type' => $this->predictionType,
            'error' => $exception->getMessage()
        ]);
    }
}
