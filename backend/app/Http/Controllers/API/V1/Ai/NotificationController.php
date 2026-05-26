<?php

namespace App\Http\Controllers\API\V1\AI;

use App\Http\Controllers\Controller;
use App\Services\AI\SmartNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class NotificationController extends Controller
{
    protected SmartNotificationService $smartNotificationService;

    public function __construct(SmartNotificationService $smartNotificationService)
    {
        $this->smartNotificationService = $smartNotificationService;
    }

    /**
     * Get A/B test results for notification strategies
     * 
     * GET /api/v1/admin/ai/notifications/ab-test-results
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function getAbTestResults(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'notification_type' => 'sometimes|string|max:50',
                'start_date' => 'sometimes|date',
                'end_date' => 'sometimes|date|after_or_equal:start_date'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Build filters
            $filters = [];
            if ($request->has('notification_type')) {
                $filters['notification_type'] = $request->input('notification_type');
            }
            if ($request->has('start_date')) {
                $filters['start_date'] = $request->input('start_date');
            }
            if ($request->has('end_date')) {
                $filters['end_date'] = $request->input('end_date');
            }

            // Get A/B test results
            $results = $this->smartNotificationService->getAbTestResults($filters);

            Log::info('A/B test results retrieved', [
                'filters' => $filters,
                'total_notifications' => $results['summary']['total_notifications']
            ]);

            return response()->json([
                'success' => true,
                'data' => $results,
                'message' => 'A/B test results retrieved successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get A/B test results', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve A/B test results',
                'error' => config('app.debug') ? $e->getMessage() : null
            ], 500);
        }
    }

    /**
     * Get notification performance metrics by variant
     * 
     * GET /api/v1/admin/ai/notifications/performance
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function getPerformanceMetrics(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'variant' => 'sometimes|string|in:control,test',
                'days' => 'sometimes|integer|min:1|max:90'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $days = $request->input('days', 30);
            $variant = $request->input('variant');

            $filters = [
                'start_date' => now()->subDays($days)->toDateString(),
                'end_date' => now()->toDateString()
            ];

            $results = $this->smartNotificationService->getAbTestResults($filters);

            // Filter by variant if specified
            if ($variant) {
                $data = $variant === 'control' 
                    ? $results['control_group'] 
                    : $results['test_group'];
                
                return response()->json([
                    'success' => true,
                    'data' => [
                        'variant' => $variant,
                        'metrics' => $data,
                        'period' => [
                            'days' => $days,
                            'start_date' => $filters['start_date'],
                            'end_date' => $filters['end_date']
                        ]
                    ]
                ]);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'control_group' => $results['control_group'],
                    'test_group' => $results['test_group'],
                    'comparison' => $results['comparison'],
                    'period' => [
                        'days' => $days,
                        'start_date' => $filters['start_date'],
                        'end_date' => $filters['end_date']
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get performance metrics', [
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve performance metrics'
            ], 500);
        }
    }
}
