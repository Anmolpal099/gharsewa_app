<?php

namespace App\Services\AI;

use App\Models\Booking;
use App\Models\User;
use App\Models\AIPrediction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Exception;

class AnalyticsService extends AIService
{
    /**
     * Predict booking volume for the next N days
     */
    public function predictBookingVolume(int $days = 7): array
    {
        try {
            Log::info('Predicting booking volume', ['days' => $days]);

            // Gather historical booking data
            $historicalData = $this->getHistoricalBookingData();
            
            // Build prompt
            $prompt = $this->buildAnalyticsPrompt('booking_volume', $historicalData, [
                'days' => $days
            ]);
            
            // Generate AI response
            $response = $this->generate($prompt, 'analytics_booking_volume', null);
            
            if (!$response->success) {
                throw new Exception('AI generation failed: ' . $response->error);
            }

            // Parse prediction
            $prediction = $this->parsePrediction($response->content);
            
            // Store prediction
            $this->storePrediction('booking_volume', $prediction);
            
            Log::info('Booking volume prediction generated', [
                'confidence' => $prediction['confidence_score'] ?? 0
            ]);

            return $prediction;
        } catch (Exception $e) {
            Log::error('Failed to predict booking volume', ['error' => $e->getMessage()]);
            throw $e;
        }
    }

    /**
     * Identify emerging trends in the platform
     */
    public function identifyTrends(): array
    {
        try {
            Log::info('Identifying trends');

            // Gather trend data
            $historicalData = $this->getTrendData();
            
            // Build prompt
            $prompt = $this->buildAnalyticsPrompt('trend', $historicalData, []);
            
            // Generate AI response
            $response = $this->generate($prompt, 'analytics_trends', null);
            
            if (!$response->success) {
                throw new Exception('AI generation failed: ' . $response->error);
            }

            // Parse prediction
            $prediction = $this->parsePrediction($response->content);
            
            // Store prediction
            $this->storePrediction('trend', $prediction);
            
            Log::info('Trends identified', [
                'count' => count($prediction['prediction_data'] ?? [])
            ]);

            return $prediction;
        } catch (Exception $e) {
            Log::error('Failed to identify trends', ['error' => $e->getMessage()]);
            throw $e;
        }
    }

    /**
     * Predict users at risk of churning
     */
    public function predictChurnRisk(): array
    {
        try {
            Log::info('Predicting churn risk');

            // Gather user engagement data
            $historicalData = $this->getChurnRiskData();
            
            // Build prompt
            $prompt = $this->buildAnalyticsPrompt('churn_risk', $historicalData, []);
            
            // Generate AI response
            $response = $this->generate($prompt, 'analytics_churn', null);
            
            if (!$response->success) {
                throw new Exception('AI generation failed: ' . $response->error);
            }

            // Parse prediction
            $prediction = $this->parsePrediction($response->content);
            
            // Store prediction
            $this->storePrediction('churn_risk', $prediction);
            
            Log::info('Churn risk prediction generated', [
                'at_risk_users' => count($prediction['prediction_data'] ?? [])
            ]);

            return $prediction;
        } catch (Exception $e) {
            Log::error('Failed to predict churn risk', ['error' => $e->getMessage()]);
            throw $e;
        }
    }

    /**
     * Forecast revenue for the next N days
     */
    public function forecastRevenue(int $days = 30): array
    {
        try {
            Log::info('Forecasting revenue', ['days' => $days]);

            // Gather revenue data
            $historicalData = $this->getRevenueData();
            
            // Build prompt
            $prompt = $this->buildAnalyticsPrompt('revenue_forecast', $historicalData, [
                'days' => $days
            ]);
            
            // Generate AI response
            $response = $this->generate($prompt, 'analytics_revenue', null);
            
            if (!$response->success) {
                throw new Exception('AI generation failed: ' . $response->error);
            }

            // Parse prediction
            $prediction = $this->parsePrediction($response->content);
            
            // Store prediction
            $this->storePrediction('revenue_forecast', $prediction);
            
            Log::info('Revenue forecast generated', [
                'confidence' => $prediction['confidence_score'] ?? 0
            ]);

            return $prediction;
        } catch (Exception $e) {
            Log::error('Failed to forecast revenue', ['error' => $e->getMessage()]);
            throw $e;
        }
    }

    /**
     * Get historical booking data
     */
    private function getHistoricalBookingData(): array
    {
        $bookings = Booking::where('created_at', '>=', now()->subDays(90))
            ->select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('COUNT(*) as count'),
                DB::raw('AVG(total_price) as avg_price')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return $bookings->map(function ($booking) {
            return [
                'date' => $booking->date,
                'bookings' => $booking->count,
                'avg_price' => round($booking->avg_price, 2)
            ];
        })->toArray();
    }

    /**
     * Get trend data
     */
    private function getTrendData(): array
    {
        // Service category trends
        $categoryTrends = Booking::where('created_at', '>=', now()->subDays(30))
            ->join('services', 'bookings.service_id', '=', 'services.id')
            ->select(
                'services.category',
                DB::raw('COUNT(*) as count'),
                DB::raw('AVG(bookings.total_price) as avg_price')
            )
            ->groupBy('services.category')
            ->orderBy('count', 'desc')
            ->get();

        // Peak booking times
        $peakTimes = Booking::where('created_at', '>=', now()->subDays(30))
            ->select(
                DB::raw('HOUR(created_at) as hour'),
                DB::raw('COUNT(*) as count')
            )
            ->groupBy('hour')
            ->orderBy('count', 'desc')
            ->limit(5)
            ->get();

        return [
            'category_trends' => $categoryTrends->toArray(),
            'peak_hours' => $peakTimes->pluck('hour')->toArray(),
            'total_bookings_last_30_days' => Booking::where('created_at', '>=', now()->subDays(30))->count()
        ];
    }

    /**
     * Get churn risk data
     */
    private function getChurnRiskData(): array
    {
        $users = User::where('role', 'customer')
            ->with(['bookings' => function ($query) {
                $query->orderBy('created_at', 'desc')->limit(5);
            }])
            ->get();

        return $users->map(function ($user) {
            $lastBooking = $user->bookings->first();
            $daysSinceLastBooking = $lastBooking 
                ? now()->diffInDays($lastBooking->created_at) 
                : 999;

            return [
                'user_id' => $user->id,
                'total_bookings' => $user->bookings->count(),
                'days_since_last_booking' => $daysSinceLastBooking,
                'avg_booking_frequency' => $user->bookings->count() > 1 
                    ? round(90 / $user->bookings->count(), 1) 
                    : 0
            ];
        })->toArray();
    }

    /**
     * Get revenue data
     */
    private function getRevenueData(): array
    {
        $revenue = Booking::where('created_at', '>=', now()->subDays(90))
            ->where('status', 'completed')
            ->select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('SUM(total_price) as revenue'),
                DB::raw('COUNT(*) as bookings')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return $revenue->map(function ($item) {
            return [
                'date' => $item->date,
                'revenue' => round($item->revenue, 2),
                'bookings' => $item->bookings
            ];
        })->toArray();
    }

    /**
     * Build analytics prompt
     */
    private function buildAnalyticsPrompt(
        string $predictionType,
        array $historicalData,
        array $params
    ): string {
        $builder = PromptBuilder::fromTemplate('analytics.txt');
        
        // Determine season
        $month = now()->month;
        $season = match(true) {
            $month >= 3 && $month <= 5 => 'Spring',
            $month >= 6 && $month <= 8 => 'Summer',
            $month >= 9 && $month <= 11 => 'Fall',
            default => 'Winter'
        };

        return $builder->setVariables([
            'prediction_type' => $predictionType,
            'historical_data' => json_encode($historicalData, JSON_PRETTY_PRINT),
            'current_date' => now()->format('Y-m-d'),
            'season' => $season,
            'market_trends' => 'Steady growth in home services demand',
            'days' => $params['days'] ?? 7
        ])->build();
    }

    /**
     * Parse AI prediction response
     */
    private function parsePrediction(string $content): array
    {
        $parsed = $this->parser->parseJson($content);
        
        if ($parsed === null) {
            Log::warning('Failed to parse prediction JSON', ['content' => substr($content, 0, 200)]);
            return [
                'prediction_type' => 'unknown',
                'prediction_data' => [],
                'confidence_score' => 0,
                'insights' => 'Failed to parse prediction',
                'factors' => []
            ];
        }

        return [
            'prediction_type' => $parsed['prediction_type'] ?? 'unknown',
            'prediction_data' => $parsed['prediction_data'] ?? [],
            'confidence_score' => (float) ($parsed['confidence_score'] ?? 0),
            'insights' => $parsed['insights'] ?? '',
            'factors' => $parsed['factors'] ?? []
        ];
    }

    /**
     * Store prediction in database
     */
    private function storePrediction(string $predictionType, array $prediction): void
    {
        AIPrediction::create([
            'prediction_type' => $predictionType,
            'prediction_data' => $prediction['prediction_data'],
            'confidence_score' => $prediction['confidence_score'],
            'insights' => $prediction['insights'],
            'factors' => $prediction['factors'],
            'valid_until' => now()->addDays(7)
        ]);
    }

    /**
     * Get latest predictions by type
     */
    public function getLatestPredictions(string $type = null): array
    {
        $query = AIPrediction::where('valid_until', '>', now())
            ->orderBy('created_at', 'desc');

        if ($type) {
            $query->where('prediction_type', $type);
        }

        return $query->limit(10)->get()->toArray();
    }
}
