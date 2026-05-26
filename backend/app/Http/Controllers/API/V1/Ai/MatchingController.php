<?php

namespace App\Http\Controllers\API\V1\AI;

use App\Http\Controllers\Controller;
use App\Services\AI\MatchingService;
use App\Models\Booking;
use App\Models\AIMatchScore;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Exception;

class MatchingController extends Controller
{
    protected MatchingService $matchingService;

    public function __construct(MatchingService $matchingService)
    {
        $this->matchingService = $matchingService;
        
        // Apply authentication middleware
        $this->middleware('auth:api');
    }

    /**
     * Get match score for a specific booking (Provider view)
     * 
     * @OA\Get(
     *     path="/api/v1/provider/bookings/{id}/match-score",
     *     tags={"AI Matching"},
     *     summary="Get match score for a booking",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         description="Booking ID",
     *         required=true,
     *         @OA\Schema(type="string", format="uuid")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Match score retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=404, description="Booking not found")
     * )
     */
    public function getMatchScore(Request $request, string $bookingId): JsonResponse
    {
        try {
            $user = $request->user();
            $booking = Booking::with(['service', 'customer'])->find($bookingId);

            if (!$booking) {
                return response()->json([
                    'success' => false,
                    'message' => 'Booking not found'
                ], 404);
            }

            // Get match score for this provider and booking
            $matchScore = AIMatchScore::where('booking_id', $booking->id)
                ->where('provider_id', $user->id)
                ->with('provider')
                ->first();

            if (!$matchScore) {
                // Calculate match score if not exists
                try {
                    $this->matchingService->calculateMatchScores($booking);
                    
                    $matchScore = AIMatchScore::where('booking_id', $booking->id)
                        ->where('provider_id', $user->id)
                        ->with('provider')
                        ->first();
                } catch (Exception $e) {
                    Log::error('Failed to calculate match score', [
                        'booking_id' => $booking->id,
                        'provider_id' => $user->id,
                        'error' => $e->getMessage()
                    ]);
                }
            }

            if (!$matchScore) {
                return response()->json([
                    'success' => false,
                    'message' => 'Match score not available for this booking'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'booking_id' => $booking->id,
                    'match_score' => $matchScore->match_score,
                    'factors' => $matchScore->factors,
                    'reasoning' => $matchScore->reasoning,
                    'calculated_at' => $matchScore->created_at->toIso8601String(),
                    'booking_details' => [
                        'service' => $booking->service->name,
                        'category' => $booking->service->category,
                        'scheduled_date' => $booking->scheduled_date,
                        'location' => $booking->location
                    ]
                ]
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get match score', [
                'booking_id' => $bookingId,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve match score',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Find best matching providers for a service (Customer view)
     * 
     * @OA\Get(
     *     path="/api/v1/customer/providers/matches",
     *     tags={"AI Matching"},
     *     summary="Find best matching providers",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="service_id",
     *         in="query",
     *         description="Service ID",
     *         required=true,
     *         @OA\Schema(type="string", format="uuid")
     *     ),
     *     @OA\Parameter(
     *         name="location",
     *         in="query",
     *         description="Service location",
     *         required=false,
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="limit",
     *         in="query",
     *         description="Number of providers to return",
     *         required=false,
     *         @OA\Schema(type="integer", default=10)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Matching providers retrieved successfully"
     *     ),
     *     @OA\Response(response=400, description="Invalid input"),
     *     @OA\Response(response=401, description="Unauthorized")
     * )
     */
    public function findMatches(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'service_id' => 'required|uuid|exists:services,id',
                'location' => 'nullable|string|max:255',
                'limit' => 'nullable|integer|min:1|max:20'
            ]);

            $limit = $validated['limit'] ?? 10;

            // Get providers who offer this service
            $providers = User::where('role', 'provider')
                ->where('status', 'active')
                ->whereHas('services', function ($query) use ($validated) {
                    $query->where('services.id', $validated['service_id']);
                })
                ->with(['services', 'profile'])
                ->limit($limit)
                ->get();

            if ($providers->isEmpty()) {
                return response()->json([
                    'success' => true,
                    'message' => 'No providers found for this service',
                    'data' => [
                        'providers' => []
                    ]
                ]);
            }

            // Format provider data with basic matching info
            $matchingProviders = $providers->map(function ($provider) use ($validated) {
                // Calculate basic match score based on available data
                $matchScore = $this->calculateBasicMatchScore($provider, $validated);

                return [
                    'provider_id' => $provider->id,
                    'name' => $provider->name,
                    'email' => $provider->email,
                    'phone' => $provider->phone ?? null,
                    'rating' => $provider->rating ?? 0,
                    'total_reviews' => $provider->total_reviews ?? 0,
                    'completed_bookings' => $provider->completed_bookings ?? 0,
                    'match_score' => $matchScore,
                    'profile' => [
                        'bio' => $provider->profile->bio ?? null,
                        'experience_years' => $provider->profile->experience_years ?? 0,
                        'specializations' => $provider->profile->specializations ?? []
                    ]
                ];
            })->sortByDesc('match_score')->values();

            return response()->json([
                'success' => true,
                'message' => 'Matching providers retrieved successfully',
                'data' => [
                    'providers' => $matchingProviders,
                    'total' => $matchingProviders->count()
                ]
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (Exception $e) {
            Log::error('Failed to find matching providers', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to find matching providers',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Get all match scores for a booking (Admin view)
     * 
     * @OA\Get(
     *     path="/api/v1/admin/bookings/{id}/match-scores",
     *     tags={"AI Matching"},
     *     summary="Get all match scores for a booking",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         description="Booking ID",
     *         required=true,
     *         @OA\Schema(type="string", format="uuid")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Match scores retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=403, description="Forbidden"),
     *     @OA\Response(response=404, description="Booking not found")
     * )
     */
    public function getAllMatchScores(Request $request, string $bookingId): JsonResponse
    {
        try {
            // Check if user is admin
            if ($request->user()->role !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Admin access required.'
                ], 403);
            }

            $booking = Booking::find($bookingId);

            if (!$booking) {
                return response()->json([
                    'success' => false,
                    'message' => 'Booking not found'
                ], 404);
            }

            $matchScores = AIMatchScore::where('booking_id', $booking->id)
                ->with('provider')
                ->orderBy('match_score', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'booking_id' => $booking->id,
                    'match_scores' => $matchScores->map(function ($score) {
                        return [
                            'provider_id' => $score->provider_id,
                            'provider_name' => $score->provider->name,
                            'match_score' => $score->match_score,
                            'factors' => $score->factors,
                            'reasoning' => $score->reasoning,
                            'calculated_at' => $score->created_at->toIso8601String()
                        ];
                    }),
                    'total' => $matchScores->count()
                ]
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get all match scores', [
                'booking_id' => $bookingId,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve match scores',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Calculate basic match score based on available data
     */
    private function calculateBasicMatchScore(User $provider, array $criteria): float
    {
        $score = 50.0; // Base score

        // Rating factor (0-25 points)
        if ($provider->rating) {
            $score += ($provider->rating / 5) * 25;
        }

        // Experience factor (0-15 points)
        if ($provider->completed_bookings) {
            $experienceScore = min($provider->completed_bookings / 100, 1) * 15;
            $score += $experienceScore;
        }

        // Availability factor (0-10 points)
        if ($provider->status === 'active') {
            $score += 10;
        }

        return round(min($score, 100), 2);
    }
}
