<?php

namespace App\Http\Controllers\API\V1\AI;

use App\Http\Controllers\Controller;
use App\Services\AI\AIService;
use App\Models\AIRequest;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Log;
use Exception;

class AIHealthController extends Controller
{
    protected AIService $aiService;

    public function __construct(AIService $aiService)
    {
        $this->aiService = $aiService;
        
        // Apply authentication middleware
        $this->middleware('auth:api');
        
        // Only admins can access health endpoints
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
     * Get AI system health status
     * 
     * @OA\Get(
     *     path="/api/v1/admin/ai/health",
     *     tags={"AI Health"},
     *     summary="Get AI system health status",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Health status retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function health(Request $request): JsonResponse
    {
        try {
            $health = [
                'status' => 'healthy',
                'timestamp' => now()->toIso8601String(),
                'components' => []
            ];

            // Check Ollama connectivity
            $ollamaHealthy = $this->aiService->healthCheck();
            $health['components']['ollama'] = [
                'status' => $ollamaHealthy ? 'healthy' : 'unhealthy',
                'message' => $ollamaHealthy ? 'Ollama is responding' : 'Ollama is not responding'
            ];

            // Check Redis connectivity
            try {
                Redis::ping();
                $health['components']['redis'] = [
                    'status' => 'healthy',
                    'message' => 'Redis is responding'
                ];
            } catch (Exception $e) {
                $health['components']['redis'] = [
                    'status' => 'unhealthy',
                    'message' => 'Redis is not responding',
                    'error' => $e->getMessage()
                ];
            }

            // Check database connectivity
            try {
                DB::connection()->getPdo();
                $health['components']['database'] = [
                    'status' => 'healthy',
                    'message' => 'Database is responding'
                ];
            } catch (Exception $e) {
                $health['components']['database'] = [
                    'status' => 'unhealthy',
                    'message' => 'Database is not responding',
                    'error' => $e->getMessage()
                ];
            }

            // Check model availability
            $modelValid = $this->aiService->validateModel();
            $health['components']['model'] = [
                'status' => $modelValid ? 'healthy' : 'unhealthy',
                'message' => $modelValid ? 'Model is available' : 'Model is not available',
                'model_name' => config('services.ollama.model')
            ];

            // Check queue health
            try {
                $failedJobs = DB::table('failed_jobs')->count();
                $health['components']['queue'] = [
                    'status' => $failedJobs < 10 ? 'healthy' : 'degraded',
                    'message' => "Failed jobs: {$failedJobs}",
                    'failed_jobs' => $failedJobs
                ];
            } catch (Exception $e) {
                $health['components']['queue'] = [
                    'status' => 'unknown',
                    'message' => 'Unable to check queue status'
                ];
            }

            // Determine overall status
            $unhealthyComponents = collect($health['components'])
                ->filter(fn($component) => $component['status'] === 'unhealthy')
                ->count();

            if ($unhealthyComponents > 0) {
                $health['status'] = 'unhealthy';
            } elseif (collect($health['components'])->contains('status', 'degraded')) {
                $health['status'] = 'degraded';
            }

            $statusCode = $health['status'] === 'healthy' ? 200 : 503;

            return response()->json([
                'success' => $health['status'] !== 'unhealthy',
                'data' => $health
            ], $statusCode);

        } catch (Exception $e) {
            Log::error('Failed to get AI health status', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve health status',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Get AI system metrics
     * 
     * @OA\Get(
     *     path="/api/v1/admin/ai/metrics",
     *     tags={"AI Health"},
     *     summary="Get AI system metrics",
     *     security={{"bearerAuth":{}}},
     *     @OA\Parameter(
     *         name="period",
     *         in="query",
     *         description="Time period for metrics",
     *         required=false,
     *         @OA\Schema(type="string", enum={"1h", "24h", "7d", "30d"}, default="24h")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Metrics retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function metrics(Request $request): JsonResponse
    {
        try {
            $period = $request->input('period', '24h');
            
            // Calculate time range
            $since = match($period) {
                '1h' => now()->subHour(),
                '24h' => now()->subDay(),
                '7d' => now()->subDays(7),
                '30d' => now()->subDays(30),
                default => now()->subDay()
            };

            // Get AI request metrics
            $totalRequests = AIRequest::where('created_at', '>=', $since)->count();
            $successfulRequests = AIRequest::where('created_at', '>=', $since)
                ->where('success', true)
                ->count();
            $failedRequests = AIRequest::where('created_at', '>=', $since)
                ->where('success', false)
                ->count();

            $successRate = $totalRequests > 0 
                ? round(($successfulRequests / $totalRequests) * 100, 2) 
                : 0;

            // Get average response time
            $avgResponseTime = AIRequest::where('created_at', '>=', $since)
                ->where('success', true)
                ->avg('response_time_ms');

            // Get requests by type
            $requestsByType = AIRequest::where('created_at', '>=', $since)
                ->select('request_type', DB::raw('count(*) as count'))
                ->groupBy('request_type')
                ->get()
                ->pluck('count', 'request_type');

            // Get error distribution
            $errorDistribution = AIRequest::where('created_at', '>=', $since)
                ->where('success', false)
                ->select('error_message', DB::raw('count(*) as count'))
                ->groupBy('error_message')
                ->orderBy('count', 'desc')
                ->limit(5)
                ->get();

            // Get response time percentiles
            $responseTimes = AIRequest::where('created_at', '>=', $since)
                ->where('success', true)
                ->orderBy('response_time_ms')
                ->pluck('response_time_ms')
                ->toArray();

            $percentiles = $this->calculatePercentiles($responseTimes);

            // Get cache hit rate (estimated)
            $cacheHits = AIRequest::where('created_at', '>=', $since)
                ->where('response_time_ms', '<', 1000) // Assume < 1s is cache hit
                ->count();
            
            $cacheHitRate = $totalRequests > 0 
                ? round(($cacheHits / $totalRequests) * 100, 2) 
                : 0;

            // Get Ollama uptime (estimated)
            $ollamaHealthy = $this->aiService->healthCheck();
            $ollamaUptime = $ollamaHealthy ? 100 : 0;

            $metrics = [
                'period' => $period,
                'since' => $since->toIso8601String(),
                'requests' => [
                    'total' => $totalRequests,
                    'successful' => $successfulRequests,
                    'failed' => $failedRequests,
                    'success_rate' => $successRate
                ],
                'performance' => [
                    'avg_response_time_ms' => round($avgResponseTime ?? 0, 2),
                    'p50_response_time_ms' => $percentiles['p50'] ?? 0,
                    'p95_response_time_ms' => $percentiles['p95'] ?? 0,
                    'p99_response_time_ms' => $percentiles['p99'] ?? 0
                ],
                'cache' => [
                    'estimated_hit_rate' => $cacheHitRate,
                    'estimated_hits' => $cacheHits
                ],
                'requests_by_type' => $requestsByType,
                'top_errors' => $errorDistribution->map(function ($error) {
                    return [
                        'message' => $error->error_message,
                        'count' => $error->count
                    ];
                }),
                'ollama' => [
                    'status' => $ollamaHealthy ? 'healthy' : 'unhealthy',
                    'estimated_uptime' => $ollamaUptime,
                    'model' => config('services.ollama.model')
                ]
            ];

            return response()->json([
                'success' => true,
                'message' => 'Metrics retrieved successfully',
                'data' => $metrics
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get AI metrics', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve metrics',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Get available models
     * 
     * @OA\Get(
     *     path="/api/v1/admin/ai/models",
     *     tags={"AI Health"},
     *     summary="Get available AI models",
     *     security={{"bearerAuth":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Models retrieved successfully"
     *     ),
     *     @OA\Response(response=401, description="Unauthorized"),
     *     @OA\Response(response=403, description="Forbidden")
     * )
     */
    public function models(Request $request): JsonResponse
    {
        try {
            $models = $this->aiService->listModels();
            $currentModel = config('services.ollama.model');

            return response()->json([
                'success' => true,
                'message' => 'Models retrieved successfully',
                'data' => [
                    'current_model' => $currentModel,
                    'available_models' => $models,
                    'total' => count($models)
                ]
            ]);

        } catch (Exception $e) {
            Log::error('Failed to get AI models', [
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve models',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }

    /**
     * Calculate percentiles from array of values
     */
    private function calculatePercentiles(array $values): array
    {
        if (empty($values)) {
            return ['p50' => 0, 'p95' => 0, 'p99' => 0];
        }

        sort($values);
        $count = count($values);

        return [
            'p50' => $values[(int)($count * 0.50)] ?? 0,
            'p95' => $values[(int)($count * 0.95)] ?? 0,
            'p99' => $values[(int)($count * 0.99)] ?? 0
        ];
    }
}
