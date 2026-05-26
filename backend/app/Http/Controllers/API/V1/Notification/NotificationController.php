<?php

namespace App\Http\Controllers\API\V1\Notification;

use App\Http\Controllers\Controller;
use App\Services\Notification\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class NotificationController extends Controller
{
    protected NotificationService $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Get scheduled notifications for authenticated user
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function getScheduled(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            
            $notifications = $this->notificationService->getScheduledNotifications($user);
            
            return response()->json([
                'success' => true,
                'data' => [
                    'notifications' => $notifications,
                    'count' => count($notifications)
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to get scheduled notifications', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve scheduled notifications'
            ], 500);
        }
    }

    /**
     * Schedule a notification with AI-optimized timing
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function schedule(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'notification_type' => 'required|string|max:50',
                'notification_data' => 'required|array',
                'use_ai' => 'boolean'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = Auth::user();
            $notificationType = $request->input('notification_type');
            $notificationData = $request->input('notification_data');
            $useAI = $request->input('use_ai', true);

            $schedule = $this->notificationService->scheduleNotification(
                $user,
                $notificationType,
                $notificationData,
                $useAI
            );

            if ($schedule) {
                return response()->json([
                    'success' => true,
                    'message' => 'Notification scheduled successfully',
                    'data' => [
                        'schedule_id' => $schedule->id,
                        'optimal_time' => $schedule->optimal_time,
                        'confidence_score' => $schedule->confidence_score,
                        'reasoning' => $schedule->reasoning
                    ]
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to schedule notification'
            ], 500);

        } catch (\Exception $e) {
            Log::error('Failed to schedule notification', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to schedule notification'
            ], 500);
        }
    }

    /**
     * Record notification engagement (open, click, dismiss)
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function recordEngagement(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'schedule_id' => 'required|uuid|exists:notification_schedules,id',
                'action' => 'required|string|in:opened,clicked,dismissed'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $scheduleId = $request->input('schedule_id');
            $action = $request->input('action');

            $this->notificationService->recordEngagement($scheduleId, $action);

            return response()->json([
                'success' => true,
                'message' => 'Engagement recorded successfully',
                'data' => [
                    'schedule_id' => $scheduleId,
                    'action' => $action,
                    'recorded_at' => now()->toIso8601String()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to record notification engagement', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to record engagement'
            ], 500);
        }
    }

    /**
     * Cancel a scheduled notification
     * 
     * @param Request $request
     * @param string $scheduleId
     * @return JsonResponse
     */
    public function cancel(Request $request, string $scheduleId): JsonResponse
    {
        try {
            $success = $this->notificationService->cancelNotification($scheduleId);

            if ($success) {
                return response()->json([
                    'success' => true,
                    'message' => 'Notification cancelled successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Notification not found or already cancelled'
            ], 404);

        } catch (\Exception $e) {
            Log::error('Failed to cancel notification', [
                'user_id' => Auth::id(),
                'schedule_id' => $scheduleId,
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to cancel notification'
            ], 500);
        }
    }

    /**
     * Send notification immediately (bypass AI timing)
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function sendImmediate(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'notification_type' => 'required|string|max:50',
                'notification_data' => 'required|array'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = Auth::user();
            $notificationType = $request->input('notification_type');
            $notificationData = $request->input('notification_data');

            $success = $this->notificationService->sendNotification(
                $user,
                $notificationType,
                $notificationData
            );

            if ($success) {
                return response()->json([
                    'success' => true,
                    'message' => 'Notification sent successfully'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Failed to send notification'
            ], 500);

        } catch (\Exception $e) {
            Log::error('Failed to send immediate notification', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to send notification'
            ], 500);
        }
    }

    /**
     * Get notification engagement metrics for authenticated user
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function getEngagementMetrics(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            
            $metrics = $this->notificationService->getEngagementMetrics($user);
            
            return response()->json([
                'success' => true,
                'data' => $metrics
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to get engagement metrics', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve engagement metrics'
            ], 500);
        }
    }

    /**
     * Get notification preferences for authenticated user
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function getPreferences(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            $metadata = $user->metadata ?? [];
            
            $preferences = $metadata['notification_preferences'] ?? [
                'enabled_types' => [
                    'booking_confirmation',
                    'booking_reminder',
                    'booking_accepted',
                    'booking_rejected',
                    'booking_completed',
                    'booking_cancelled',
                    'payment_reminder',
                    'service_update',
                    'promotional'
                ],
                'quiet_hours' => [
                    'enabled' => false,
                    'start' => '22:00',
                    'end' => '08:00'
                ],
                'max_daily_notifications' => 10
            ];
            
            return response()->json([
                'success' => true,
                'data' => [
                    'preferences' => $preferences,
                    'timezone' => $metadata['timezone'] ?? 'UTC'
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to get notification preferences', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve notification preferences'
            ], 500);
        }
    }

    /**
     * Update notification preferences for authenticated user
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function updatePreferences(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'enabled_types' => 'sometimes|array',
                'enabled_types.*' => 'string|in:booking_confirmation,booking_reminder,booking_accepted,booking_rejected,booking_completed,booking_cancelled,payment_reminder,service_update,promotional',
                'quiet_hours.enabled' => 'sometimes|boolean',
                'quiet_hours.start' => 'sometimes|date_format:H:i',
                'quiet_hours.end' => 'sometimes|date_format:H:i',
                'max_daily_notifications' => 'sometimes|integer|min:1|max:50',
                'timezone' => 'sometimes|string|timezone'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $user = Auth::user();
            $metadata = $user->metadata ?? [];
            
            // Update notification preferences
            if (!isset($metadata['notification_preferences'])) {
                $metadata['notification_preferences'] = [];
            }
            
            if ($request->has('enabled_types')) {
                $metadata['notification_preferences']['enabled_types'] = $request->input('enabled_types');
            }
            
            if ($request->has('quiet_hours')) {
                $quietHours = $request->input('quiet_hours');
                $metadata['notification_preferences']['quiet_hours'] = array_merge(
                    $metadata['notification_preferences']['quiet_hours'] ?? [],
                    $quietHours
                );
            }
            
            if ($request->has('max_daily_notifications')) {
                $metadata['notification_preferences']['max_daily_notifications'] = $request->input('max_daily_notifications');
            }
            
            if ($request->has('timezone')) {
                $metadata['timezone'] = $request->input('timezone');
            }
            
            $user->metadata = $metadata;
            $user->save();
            
            Log::info('Notification preferences updated', [
                'user_id' => $user->id,
                'preferences' => $metadata['notification_preferences']
            ]);
            
            return response()->json([
                'success' => true,
                'message' => 'Notification preferences updated successfully',
                'data' => [
                    'preferences' => $metadata['notification_preferences'],
                    'timezone' => $metadata['timezone'] ?? 'UTC'
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update notification preferences', [
                'user_id' => Auth::id(),
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to update notification preferences'
            ], 500);
        }
    }
}
