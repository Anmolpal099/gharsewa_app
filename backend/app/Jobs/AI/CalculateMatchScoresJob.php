<?php

namespace App\Jobs\AI;

use App\Models\Booking;
use App\Services\AI\MatchingService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Exception;

class CalculateMatchScoresJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $timeout = 180;
    public int $backoff = 60;

    /**
     * Create a new job instance.
     */
    public function __construct(
        public string $bookingId
    ) {
        $this->onQueue('ai-processing');
    }

    /**
     * Execute the job.
     */
    public function handle(MatchingService $service): void
    {
        try {
            Log::info('Calculating AI match scores', [
                'booking_id' => $this->bookingId
            ]);

            $booking = Booking::findOrFail($this->bookingId);
            
            $matchScores = $service->calculateMatchScores($booking);

            Log::info('AI match scores calculated successfully', [
                'booking_id' => $this->bookingId,
                'providers_scored' => count($matchScores)
            ]);
        } catch (Exception $e) {
            Log::error('Failed to calculate AI match scores', [
                'booking_id' => $this->bookingId,
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
        Log::error('CalculateMatchScoresJob failed permanently', [
            'booking_id' => $this->bookingId,
            'error' => $exception->getMessage()
        ]);
    }
}
