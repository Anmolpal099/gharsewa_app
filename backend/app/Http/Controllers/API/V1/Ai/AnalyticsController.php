<?php

namespace App\Http\Controllers\API\V1\AI;

use App\Http\Controllers\Controller;
use App\Services\AI\AnalyticsService;
use App\Models\AIPrediction;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Exception;

class AnalyticsController extends Controller
{
    protected AnalyticsService $analyticsService;

    public function __construct(AnalyticsService $analyticsService)
    {
        $this->analyticsService = $analyticsService;
        
        // Apply authentication middleware
        $this->middleware('auth:api');
        
        // Only admins can access analytics
        $this->middleware(function ($request, $next) {
            if ($request->user()->role !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized. Admin access required.'
                ], 403);
            }
            return $next($request);
        });
    }

    /**
     * Get predictions (booking volume, revenue forecast, etc.)
     * 
     * @OA\Get(
     *     path="/api/v1/admin/analytics/predictions",
     *     tags={"AI Analytics"},
     *     summary="Get AI predictions",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="type",
     *         in="query",
     *         description="Prediction type",
     *         required=false,
     *         @OA\Schema(type="string", enum={"booking_volume", "revenue_forecast", "churn_risk", "trend"})
     *     ),
     *     @OA\Parameter(
     *         name="days",
     *         in="query",
     *         description="Number of days for forecast",
     *         required=false,
     *         @OA\Schema(type="integer", default=7)
     *     ),
     *     @OA\Parameter(
     *         name="refresh",
     *         in="query",
     *         description="Force refresh predictions",
     *         required=false,
     *         @OA\Schema(type="boolean", default=false)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Predictions retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function predictions(Request $request): JsonResponse
    {
        try {
            $type = $request->input('type');
            $days = $request->input('days', 7);
            $refresh = $request->boolean('refresh', false);

            // Validate days
            if ($days < 1 || $days > 90) {
                return response()->json([
                    'success' => false,
                    'message' => 'Days must be between 1 and 90'
                ], 400);
            }

            // Check cache first if not refreshing
            if (!$refresh && $type) {
                $cacheKey = "analytics:predictions:{$type}:{$days}";
                $cached = Cache::get($cacheKey);
                
                if ($cached) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Predictions retrieved from cache',
                        'data' => $cached,
                        'cached' => true
                    ]);
                }
            }

            // Generate predictions based on type
            $predictions = [];
            
            if (!$type || $type === 'booking_volume') {
                $predictions['booking_volume'] = $this->analyticsService->predictBookingVolume($days);
            }
            
            if (!$type || $type === 'revenue_forecast') {
                $predictions['revenue_forecast'] = $this->analyticsService->forecastRevenue($days);
            }
            
            if (!$type || $type === 'churn_risk') {
                $predictions['churn_risk'] = $this->analyticsService->predictChurnRisk();
            }
            
            if (!$type || $type === 'trend') {
                $predictions['trend'] = $this->analyticsService->identifyTrends();
            }

            // Cache the results
            if ($type) {
                $cacheKey = "analytics:predictions:{$type}:{$days}";
                Cache::put($cacheKey, $predictions, 3600); // Cache for 1 hour
            }

            return response()->json([
                'success' => true,
                'message' => 'Predictions generated successfully',
                'data' => $predictions,
                'cached' => false
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get predictions', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to generate predictions',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Get trend analysis
     * 
     * @OA\Get(
     *     path="/api/v1/admin/analytics/trends",
     *     tags={"AI Analytics"},
     *     summary="Get trend analysis",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="refresh",
     *         in="query",
     *         description="Force refresh trends",
     *         required=false,
     *         @OA\Schema(type="boolean", default=false)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Trends retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function trends(Request $request): JsonResponse
    {
        try {
            $refresh = $request->boolean('refresh', false);

            // Check cache first
            if (!$refresh) {
                $cached = Cache::get('analytics:trends');
                
                if ($cached) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Trends retrieved from cache',
                        'data' => $cached,
                        'cached' => true
                    ]);
                }
            }

            // Generate trends
            $trends = $this->analyticsService->identifyTrends();

            // Cache the results
            Cache::put('analytics:trends', $trends, 3600); // Cache for 1 hour

            return response()->json([
                'success' => true,
                'message' => 'Trends identified successfully',
                'data' => $trends,
                'cached' => false
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get trends', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to identify trends',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Get actionable insights
     * 
     * @OA\Get(
     *     path="/api/v1/admin/analytics/insights",
     *     tags={"AI Analytics"},
     *     summary="Get actionable insights",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Insights retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function insights(Request $request): JsonResponse
    {
        try {
            // Get latest predictions
            $latestPredictions = AIPrediction::active()
                ->orderBy('created_at', 'desc')
                ->limit(10)
                ->get();

            // Group by type
            $insights = [
                'booking_volume' => [],
                'revenue_forecast' => [],
                'churn_risk' => [],
                'trend' => []
            ];

            foreach ($latestPredictions as $prediction) {
                $type = $prediction->prediction_type;
                if (isset($insights[$type])) {
                    $insights[$type][] = [
                        'insights' => $prediction->insights,
                        'confidence_score' => $prediction->confidence_score,
                        'factors' => $prediction->factors,
                        'created_at' => $prediction->created_at->toIso8601String()
                    ];
                }
            }

            // Generate summary insights
            $summary = $this->generateSummaryInsights($latestPredictions);

            return response()->json([
                'success' => true,
                'message' => 'Insights retrieved successfully',
                'data' => [
                    'insights' => $insights,
                    'summary' => $summary,
                    'total_predictions' => $latestPredictions->count()
                ]
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get insights', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve insights',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Get prediction history
     * 
     * @OA\Get(
     *     path="/api/v1/admin/analytics/history",
     *     tags={"AI Analytics"},
     *     summary="Get prediction history",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="type",
     *         in="query",
     *         description="Prediction type",
     *         required=false,
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Parameter(
     *         name="limit",
     *         in="query",
     *         description="Number of records to return",
     *         required=false,
     *         @OA\Schema(type="integer", default=20)
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="History retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function history(Request $request): JsonResponse
    {
        try {
            $type = $request->input('type');
            $limit = $request->input('limit', 20);

            // Validate limit
            if ($limit < 1 || $limit > 100) {
                return response()->json([
                    'success' => false,
                    'message' => 'Limit must be between 1 and 100'
                ], 400);
            }

            $query = AIPrediction::orderBy('created_at', 'desc');

            if ($type) {
                $query->where('prediction_type', $type);
            }

            $predictions = $query->limit($limit)->get();

            return response()->json([
                'success' => true,
                'message' => 'History retrieved successfully',
                'data' => [
                    'predictions' => $predictions->map(function ($prediction) {
                        return [
                            'id' => $prediction->id,
                            'type' => $prediction->prediction_type,
                            'confidence_score' => $prediction->confidence_score,
                            'insights' => $prediction->insights,
                            'factors' => $prediction->factors,
                            'valid_until' => $prediction->valid_until->toIso8601String(),
                            'created_at' => $prediction->created_at->toIso8601String()
                        ];
                    }),
                    'total' => $predictions->count()
                ]
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get prediction history', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve history',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Generate summary insights from predictions
     */
    private function generateSummaryInsights($predictions): array
    {
        $summary = [
            'total_predictions' => $predictions->count(),
            'average_confidence' => 0,
            'high_confidence_count' => 0,
            'key_insights' => []
        ];

        if ($predictions->isEmpty()) {
            return $summary;
        }

        // Calculate average confidence
        $totalConfidence = $predictions->sum('confidence_score');
        $summary['average_confidence'] = round($totalConfidence / $predictions->count(), 2);

        // Count high confidence predictions
        $summary['high_confidence_count'] = $predictions->where('confidence_score', '>=', 80)->count();

        // Extract key insights
        $summary['key_insights'] = $predictions
            ->where('confidence_score', '>=', 70)
            ->pluck('insights')
            ->take(5)
            ->toArray();

        return $summary;
    }
}
