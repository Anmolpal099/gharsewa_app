<?php

namespace App\Http\Controllers\API\V1\AI;

use App\Http\Controllers\Controller;
use App\Services\AI\RecommendationService;
use App\Models\AIRecommendation;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Exception;

class RecommendationController extends Controller
{
    protected RecommendationService $recommendationService;

    public function __construct(RecommendationService $recommendationService)
    {
        $this->recommendationService = $recommendationService;
        
        // Apply authentication middleware
        $this->middleware('auth:api');
        
        // Apply rate limiting
        $this->middleware('throttle:ai-recommendations')->only(['index']);
    }

    /**
     * Get personalized recommendations for the authenticated user
     * 
     * @OA\Get(
     *     path="/api/v1/customer/recommendations",
     *     tags={"AI Recommendations"},
     *     summary="Get personalized service recommendations",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="limit",
     *         in="query",
     *         description="Number of recommendations to return",
     *         required=false,
     *         @OA\Schema(type="integer", default=5)
     *     ),
     *     @OA\Parameter(
     *         name="refresh",
     *         in="query",
     *         description="Force refresh recommendations",
     *         required=false,
     *         @OA\Schema(type="boolean", default=false)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Recommendations retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=429, description="Too many requests")
     * )
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            $limit = $request->input('limit', 5);
            $refresh = $request->boolean('refresh', false);

            // Validate limit
            if ($limit < 1 || $limit > 20) {
                return response()->json([
                    'success' => false,
                    'message' => 'Limit must be between 1 and 20'
                ], 400);
            }

            // Check rate limiting
            $key = 'recommendations:' . $user->id;
            if (!$refresh && RateLimiter::tooManyAttempts($key, 10)) {
                $seconds = RateLimiter::availableIn($key);
                return response()->json([
                    'success' => false,
                    'message' => "Too many requests. Please try again in {$seconds} seconds."
                ], 429);
            }

            // Get existing active recommendations if not refreshing
            if (!$refresh) {
                $existingRecommendations = AIRecommendation::forUser($user->id)
                    ->active()
                    ->highConfidence()
                    ->with('service')
                    ->orderBy('confidence_score', 'desc')
                    ->limit($limit)
                    ->get();

                if ($existingRecommendations->isNotEmpty()) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Recommendations retrieved from cache',
                        'data' => [
                            'recommendations' => $existingRecommendations->map(function ($rec) {
                                return [
                                    'id' => $rec->id,
                                    'service' => [
                                        'id' => $rec->service->id,
                                        'name' => $rec->service->name,
                                        'category' => $rec->service->category,
                                        'price' => $rec->service->price,
                                        'description' => $rec->service->description,
                                        'image_url' => $rec->service->image_url ?? null
                                    ],
                                    'confidence_score' => $rec->confidence_score,
                                    'reasoning' => $rec->reasoning,
                                    'expires_at' => $rec->expires_at->toIso8601String()
                                ];
                            }),
                            'cached' => true
                        ]
                    ]);
                }
            }

            // Generate new recommendations
            RateLimiter::hit($key, 60); // 1 minute cooldown
            
            $recommendations = $this->recommendationService->generateRecommendations($user, $limit);

            // Get the stored recommendations with service details
            $storedRecommendations = AIRecommendation::forUser($user->id)
                ->active()
                ->with('service')
                ->orderBy('confidence_score', 'desc')
                ->limit($limit)
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Recommendations generated successfully',
                'data' => [
                    'recommendations' => $storedRecommendations->map(function ($rec) {
                        return [
                            'id' => $rec->id,
                            'service' => [
                                'id' => $rec->service->id,
                                'name' => $rec->service->name,
                                'category' => $rec->service->category,
                                'price' => $rec->service->price,
                                'description' => $rec->service->description,
                                'image_url' => $rec->service->image_url ?? null
                            ],
                            'confidence_score' => $rec->confidence_score,
                            'reasoning' => $rec->reasoning,
                            'expires_at' => $rec->expires_at->toIso8601String()
                        ];
                    }),
                    'cached' => false
                ]
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get recommendations', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to generate recommendations',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Record feedback on a recommendation
     * 
     * @OA\Post(
     *     path="/api/v1/customer/recommendations/feedback",
     *     tags={"AI Recommendations"},
     *     summary="Record feedback on a recommendation",
     *     security={{"bearerAuth":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"recommendation_id", "action"},
     *             @OA\Property(property="recommendation_id", type="string", format="uuid"),
     *             @OA\Property(property="action", type="string", enum={"clicked", "booked"})
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Feedback recorded successfully"
     *     ),
     *     @OA\Response(response=400, description="Invalid input"),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=404, description="Recommendation not found")
     * )
     */
    public function feedback(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'recommendation_id' => 'required|uuid|exists:ai_recommendations,id',
                'action' => 'required|in:clicked,booked'
            ]);

            $user = $request->user();
            $recommendation = AIRecommendation::find($validated['recommendation_id']);

            // Verify the recommendation belongs to the user
            if ($recommendation->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized access to recommendation'
                ], 403);
            }

            // Record feedback
            $this->recommendationService->recordFeedback(
                $validated['recommendation_id'],
                $validated['action']
            );

            return response()->json([
                'success' => true,
                'message' => 'Feedback recorded successfully',
                'data' => [
                    'recommendation_id' => $recommendation->id,
                    'action' => $validated['action'],
                    'recorded_at' => now()->toIso8601String()
                ]
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (Exception $e) {
            Log::error('Failed to record recommendation feedback', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to record feedback',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Get recommendation statistics for the user
     * 
     * @OA\Get(
     *     path="/api/v1/customer/recommendations/stats",
     *     tags={"AI Recommendations"},
     *     summary="Get recommendation statistics",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Statistics retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized")
     * )
     */
    public function stats(Request $request): JsonResponse
    {
        try {
            $user = $request->user();

            $totalRecommendations = AIRecommendation::forUser($user->id)->count();
            $activeRecommendations = AIRecommendation::forUser($user->id)->active()->count();
            $clickedRecommendations = AIRecommendation::forUser($user->id)->clicked()->count();
            $bookedRecommendations = AIRecommendation::forUser($user->id)->booked()->count();

            $clickRate = $totalRecommendations > 0 
                ? round(($clickedRecommendations / $totalRecommendations) * 100, 2) 
                : 0;

            $conversionRate = $totalRecommendations > 0 
                ? round(($bookedRecommendations / $totalRecommendations) * 100, 2) 
                : 0;

            return response()->json([
                'success' => true,
                'data' => [
                    'total_recommendations' => $totalRecommendations,
                    'active_recommendations' => $activeRecommendations,
                    'clicked_recommendations' => $clickedRecommendations,
                    'booked_recommendations' => $bookedRecommendations,
                    'click_rate' => $clickRate,
                    'conversion_rate' => $conversionRate
                ]
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get recommendation stats', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve statistics',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }
}
