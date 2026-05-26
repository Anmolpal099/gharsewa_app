<?php

namespace App\Services\AI;

use App\Models\User;
use App\Models\Service;
use App\Models\AIRecommendation;
use App\Models\Booking;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;
use Exception;

class RecommendationService extends AIService
{
    /**
     * Generate personalized service recommendations for a user
     */
    public function generateRecommendations(User $user, int $limit = 5): array
    {
        try {
            Log::info('Generating recommendations', [
                'user_id' => $user->id,
                'limit' => $limit
            ]);

            // Gather customer context
            $context = $this->gatherCustomerContext($user);
            
            // Fetch available services
            $availableServices = $this->getAvailableServices($user);
            
            if ($availableServices->isEmpty()) {
                Log::warning('No available services for recommendations', ['user_id' => $user->id]);
                return [];
            }

            // Build prompt
            $prompt = $this->buildRecommendationPrompt($user, $context, $availableServices, $limit);
            
            // Generate AI response
            $response = $this->generate($prompt, 'recommendation', $user->id);
            
            if (!$response->success) {
                throw new Exception('AI generation failed: ' . $response->error);
            }

            // Parse recommendations
            $recommendations = $this->parseRecommendations($response->content);
            
            // Store recommendations in database
            $this->storeRecommendations($user, $recommendations);
            
            Log::info('Recommendations generated successfully', [
                'user_id' => $user->id,
                'count' => count($recommendations)
            ]);

            return $recommendations;
        } catch (Exception $e) {
            Log::error('Failed to generate recommendations', [
                'user_id' => $user->id,
                'error' => $e->getMessage()
            ]);
            
            throw $e;
        }
    }

    /**
     * Gather customer context for recommendations
     */
    private function gatherCustomerContext(User $user): array
    {
        // Get booking history
        $bookings = Booking::where('customer_id', $user->id)
            ->with('service')
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get();

        $bookingHistory = $bookings->map(function ($booking) {
            return [
                'service' => $booking->service->name ?? 'Unknown',
                'category' => $booking->service->category ?? 'Unknown',
                'date' => $booking->created_at->format('Y-m-d'),
                'status' => $booking->status
            ];
        })->toArray();

        // Get user preferences from metadata
        $metadata = $user->metadata ?? [];
        $preferences = $metadata['preferences'] ?? [];

        return [
            'booking_history' => $bookingHistory,
            'preferences' => $preferences,
            'location' => $metadata['location'] ?? 'Not specified',
            'total_bookings' => $bookings->count()
        ];
    }

    /**
     * Get available services for recommendations
     */
    private function getAvailableServices(User $user): Collection
    {
        return Service::where('status', 'active')
            ->with('provider')
            ->limit(20)
            ->get();
    }

    /**
     * Build recommendation prompt
     */
    private function buildRecommendationPrompt(
        User $user,
        array $context,
        Collection $services,
        int $limit
    ): string {
        $servicesData = $services->map(function ($service) {
            return [
                'id' => $service->id,
                'name' => $service->name,
                'category' => $service->category,
                'price' => $service->price,
                'description' => substr($service->description, 0, 100)
            ];
        })->toArray();

        $bookingHistoryText = empty($context['booking_history']) 
            ? 'No previous bookings' 
            : collect($context['booking_history'])->map(fn($b) => 
                "{$b['service']} ({$b['category']}) on {$b['date']}"
              )->join(', ');

        $preferencesText = empty($context['preferences']) 
            ? 'No specific preferences' 
            : json_encode($context['preferences']);

        $builder = PromptBuilder::fromTemplate('recommendation.txt');
        
        return $builder->setVariables([
            'user_name' => $user->name,
            'user_location' => $context['location'],
            'booking_history' => $bookingHistoryText,
            'user_preferences' => $preferencesText,
            'available_services' => json_encode($servicesData, JSON_PRETTY_PRINT),
            'limit' => $limit
        ])->build();
    }

    /**
     * Parse AI recommendations response
     */
    private function parseRecommendations(string $content): array
    {
        $parsed = $this->parser->parseJson($content);
        
        if ($parsed === null) {
            Log::warning('Failed to parse recommendations JSON', ['content' => substr($content, 0, 200)]);
            return [];
        }

        // Validate structure
        $recommendations = [];
        foreach ($parsed as $item) {
            if (isset($item['service_id'], $item['confidence_score'])) {
                $recommendations[] = [
                    'service_id' => $item['service_id'],
                    'service_name' => $item['service_name'] ?? 'Unknown',
                    'confidence_score' => (float) $item['confidence_score'],
                    'reasoning' => $item['reasoning'] ?? ''
                ];
            }
        }

        return $recommendations;
    }

    /**
     * Store recommendations in database
     */
    private function storeRecommendations(User $user, array $recommendations): void
    {
        $expiresAt = now()->addDays(7); // Recommendations valid for 7 days

        foreach ($recommendations as $rec) {
            AIRecommendation::create([
                'user_id' => $user->id,
                'service_id' => $rec['service_id'],
                'confidence_score' => $rec['confidence_score'],
                'reasoning' => $rec['reasoning'],
                'expires_at' => $expiresAt
            ]);
        }
    }

    /**
     * Record recommendation feedback
     */
    public function recordFeedback(string $recommendationId, string $action): void
    {
        $recommendation = AIRecommendation::find($recommendationId);
        
        if (!$recommendation) {
            return;
        }

        switch ($action) {
            case 'clicked':
                $recommendation->clicked = true;
                $recommendation->clicked_at = now();
                break;
            case 'booked':
                $recommendation->booked = true;
                $recommendation->booked_at = now();
                break;
        }

        $recommendation->save();
    }

    /**
     * Get active recommendations for a user
     */
    public function getActiveRecommendations(User $user): Collection
    {
        return AIRecommendation::where('user_id', $user->id)
            ->where('expires_at', '>', now())
            ->with('service')
            ->orderBy('confidence_score', 'desc')
            ->get();
    }
}
