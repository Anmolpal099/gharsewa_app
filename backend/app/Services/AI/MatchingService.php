<?php

namespace App\Services\AI;

use App\Models\Booking;
use App\Models\User;
use App\Models\AIMatchScore;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;
use Exception;

class MatchingService extends AIService
{
    /**
     * Calculate match scores for a booking
     */
    public function calculateMatchScores(Booking $booking): array
    {
        try {
            Log::info('Calculating match scores', ['booking_id' => $booking->id]);

            // Get eligible providers
            $providers = $this->getEligibleProviders($booking);
            
            if ($providers->isEmpty()) {
                Log::warning('No eligible providers found', ['booking_id' => $booking->id]);
                return [];
            }

            // Build prompt
            $prompt = $this->buildMatchingPrompt($booking, $providers);
            
            // Generate AI response
            $response = $this->generate($prompt, 'matching', $booking->customer_id);
            
            if (!$response->success) {
                throw new Exception('AI generation failed: ' . $response->error);
            }

            // Parse match scores
            $matchScores = $this->parseMatchScores($response->content);
            
            // Store match scores in database
            $this->storeMatchScores($booking, $matchScores);
            
            Log::info('Match scores calculated successfully', [
                'booking_id' => $booking->id,
                'providers_scored' => count($matchScores)
            ]);

            return $matchScores;
        } catch (Exception $e) {
            Log::error('Failed to calculate match scores', [
                'booking_id' => $booking->id,
                'error' => $e->getMessage()
            ]);
            
            throw $e;
        }
    }

    /**
     * Get eligible providers for a booking
     */
    private function getEligibleProviders(Booking $booking): Collection
    {
        // Get providers who offer the same service category
        return User::where('role', 'serviceProvider')
            ->where('is_active', true)
            ->whereHas('services', function ($query) use ($booking) {
                $query->where('category', $booking->service->category)
                      ->where('status', 'active');
            })
            ->with(['services', 'providerProfile'])
            ->limit(10)
            ->get();
    }

    /**
     * Build matching prompt
     */
    private function buildMatchingPrompt(Booking $booking, Collection $providers): string
    {
        $providersData = $providers->map(function ($provider) {
            $profile = $provider->providerProfile;
            $services = $provider->services;
            
            return [
                'id' => $provider->id,
                'name' => $provider->name,
                'rating' => $profile->average_rating ?? 0,
                'total_jobs' => $profile->total_jobs ?? 0,
                'years_experience' => $profile->years_experience ?? 0,
                'location' => $profile->location ?? 'Unknown',
                'services' => $services->pluck('name')->toArray(),
                'hourly_rate' => $profile->hourly_rate ?? 0
            ];
        })->toArray();

        $customerMetadata = $booking->customer->metadata ?? [];
        $customerLocation = $customerMetadata['location'] ?? 'Not specified';

        $builder = PromptBuilder::fromTemplate('matching.txt');
        
        return $builder->setVariables([
            'service_name' => $booking->service->name,
            'customer_location' => $customerLocation,
            'scheduled_time' => $booking->scheduled_at->format('Y-m-d H:i:s'),
            'special_requirements' => $booking->metadata['requirements'] ?? 'None',
            'budget' => 'NPR ' . $booking->total_price,
            'providers' => json_encode($providersData, JSON_PRETTY_PRINT)
        ])->build();
    }

    /**
     * Parse AI match scores response
     */
    private function parseMatchScores(string $content): array
    {
        $parsed = $this->parser->parseJson($content);
        
        if ($parsed === null) {
            Log::warning('Failed to parse match scores JSON', ['content' => substr($content, 0, 200)]);
            return [];
        }

        // Validate and normalize scores
        $matchScores = [];
        foreach ($parsed as $item) {
            if (isset($item['provider_id'], $item['overall_score'])) {
                $matchScores[] = [
                    'provider_id' => $item['provider_id'],
                    'provider_name' => $item['provider_name'] ?? 'Unknown',
                    'overall_score' => $this->normalizeScore($item['overall_score']),
                    'skill_match_score' => $this->normalizeScore($item['skill_match_score'] ?? 0),
                    'availability_score' => $this->normalizeScore($item['availability_score'] ?? 0),
                    'location_score' => $this->normalizeScore($item['location_score'] ?? 0),
                    'rating_score' => $this->normalizeScore($item['rating_score'] ?? 0),
                    'price_score' => $this->normalizeScore($item['price_score'] ?? 0),
                    'experience_score' => $this->normalizeScore($item['experience_score'] ?? 0),
                    'reasoning' => $item['reasoning'] ?? ''
                ];
            }
        }

        // Sort by overall score
        usort($matchScores, fn($a, $b) => $b['overall_score'] <=> $a['overall_score']);

        return $matchScores;
    }

    /**
     * Normalize score to 0-100 range
     */
    private function normalizeScore($score): float
    {
        $score = (float) $score;
        return max(0, min(100, $score));
    }

    /**
     * Store match scores in database
     */
    private function storeMatchScores(Booking $booking, array $matchScores): void
    {
        foreach ($matchScores as $score) {
            $factorBreakdown = [
                'skill_match' => $score['skill_match_score'],
                'availability' => $score['availability_score'],
                'location' => $score['location_score'],
                'rating' => $score['rating_score'],
                'price' => $score['price_score'],
                'experience' => $score['experience_score']
            ];

            AIMatchScore::updateOrCreate(
                [
                    'booking_id' => $booking->id,
                    'provider_id' => $score['provider_id']
                ],
                [
                    'overall_score' => $score['overall_score'],
                    'skill_match_score' => $score['skill_match_score'],
                    'availability_score' => $score['availability_score'],
                    'location_score' => $score['location_score'],
                    'rating_score' => $score['rating_score'],
                    'price_score' => $score['price_score'],
                    'experience_score' => $score['experience_score'],
                    'reasoning' => $score['reasoning'],
                    'factor_breakdown' => $factorBreakdown
                ]
            );
        }
    }

    /**
     * Get match scores for a booking
     */
    public function getMatchScores(Booking $booking): Collection
    {
        return AIMatchScore::where('booking_id', $booking->id)
            ->with('provider')
            ->orderBy('overall_score', 'desc')
            ->get();
    }

    /**
     * Get best match for a booking
     */
    public function getBestMatch(Booking $booking): ?AIMatchScore
    {
        return AIMatchScore::where('booking_id', $booking->id)
            ->orderBy('overall_score', 'desc')
            ->first();
    }
}
