<?php

namespace App\Services\Notification;

use App\Models\User;
use App\Models\NotificationSchedule;
use App\Services\AI\SmartNotificationService;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use Exception;

class NotificationService
{
    protected SmartNotificationService $smartNotificationService;

    public function __construct(SmartNotificationService $smartNotificationService)
    {
        $this->smartNotificationService = $smartNotificationService;
    }

    /**
     * Schedule a notification with AI-optimized timing
     */
    public function scheduleNotification(
        User $user,
        string $notificationType,
        array $notificationData,
        bool $useAI = true,
        bool $urgent = false
    ): ?NotificationSchedule {
        try {
            $scheduledTime = null;

            // Use AI to determine optimal time if enabled
            if ($useAI) {
                try {
                    $timing = $this->smartNotificationService->determineOptimalTime($user, $notificationType, $urgent);
                    $scheduledTime = Carbon::parse($timing['optimal_time']);
                    
                    Log::info('AI notification timing determined', [
                        'user_id' => $user->id,
                        'notification_type' => $notificationType,
                        'optimal_time' => $scheduledTime->toDateTimeString(),
                        'confidence' => $timing['confidence_score'],
                        'urgent' => $urgent
                    ]);
                } catch (Exception $e) {
                    Log::warning('AI notification timing failed, using default', [
                        'user_id' => $user->id,
                        'notification_type' => $notificationType,
                        'error' => $e->getMessage()
                    ]);
                    
                    // Fall back to default timing
                    $scheduledTime = $this->getDefaultNotificationTime($user, $notificationType);
                }
            } else {
                // Use default timing
                $scheduledTime = $this->getDefaultNotificationTime($user, $notificationType);
            }

            // Get the notification schedule from database
            $schedule = NotificationSchedule::where('user_id', $user->id)
                ->where('notification_type', $notificationType)
                ->where('status', 'scheduled')
                ->where('optimal_time', $scheduledTime)
                ->first();

            if ($schedule) {
                Log::info('Notification scheduled', [
                    'user_id' => $user->id,
                    'notification_type' => $notificationType,
                    'scheduled_time' => $scheduledTime->toDateTimeString(),
                    'schedule_id' => $schedule->id
                ]);

                return $schedule;
            }

            return null;

        } catch (Exception $e) {
            Log::error('Failed to schedule notification', [
                'user_id' => $user->id,
                'notification_type' => $notificationType,
                'error' => $e->getMessage()
            ]);

            return null;
        }
    }

    /**
     * Send notification immediately
     */
    public function sendNotification(User $user, string $notificationType, array $data): bool
    {
        try {
            // Placeholder for actual notification sending logic
            // This would integrate with Firebase, email, SMS, etc.
            
            Log::info('Notification sent', [
                'user_id' => $user->id,
                'notification_type' => $notificationType,
                'sent_at' => now()->toDateTimeString()
            ]);

            return true;

        } catch (Exception $e) {
            Log::error('Failed to send notification', [
                'user_id' => $user->id,
                'notification_type' => $notificationType,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Record notification engagement
     */
    public function recordEngagement(string $scheduleId, string $action): void
    {
        try {
            $this->smartNotificationService->recordEngagement($scheduleId, $action);
            
            Log::info('Notification engagement recorded', [
                'schedule_id' => $scheduleId,
                'action' => $action
            ]);
        } catch (Exception $e) {
            Log::error('Failed to record notification engagement', [
                'schedule_id' => $scheduleId,
                'action' => $action,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Get default notification time based on type
     */
    private function getDefaultNotificationTime(User $user, string $notificationType): Carbon
    {
        $timezone = $user->metadata['timezone'] ?? 'UTC';
        $now = now($timezone);

        // Default times based on notification type
        return match($notificationType) {
            'booking_reminder' => $now->addDay()->setTime(9, 0, 0),
            'booking_confirmation' => $now->addMinutes(5),
            'payment_reminder' => $now->addHours(2),
            'service_update' => $now->addHours(1),
            'promotional' => $now->addDay()->setTime(10, 0, 0),
            default => $now->addHours(1)
        };
    }

    /**
     * Get scheduled notifications for user
     */
    public function getScheduledNotifications(User $user): array
    {
        return $this->smartNotificationService->getScheduledNotifications($user);
    }

    /**
     * Cancel scheduled notification
     */
    public function cancelNotification(string $scheduleId): bool
    {
        try {
            $schedule = NotificationSchedule::find($scheduleId);
            
            if ($schedule) {
                $schedule->status = 'cancelled';
                $schedule->save();
                
                Log::info('Notification cancelled', ['schedule_id' => $scheduleId]);
                return true;
            }

            return false;
        } catch (Exception $e) {
            Log::error('Failed to cancel notification', [
                'schedule_id' => $scheduleId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Send booking-related notification with AI timing
     */
    public function sendBookingNotification(
        User $user,
        string $bookingEvent,
        array $bookingData,
        bool $urgent = false
    ): void {
        try {
            $notificationType = $this->getNotificationTypeForBookingEvent($bookingEvent);
            
            // Urgent notifications (booking confirmations, cancellations) are sent immediately
            if ($urgent) {
                $this->sendNotification($user, $notificationType, $bookingData);
                
                Log::info('Urgent booking notification sent', [
                    'user_id' => $user->id,
                    'booking_event' => $bookingEvent,
                    'notification_type' => $notificationType
                ]);
            } else {
                // Non-urgent notifications use AI timing optimization
                $this->scheduleNotification($user, $notificationType, $bookingData, true);
                
                Log::info('Booking notification scheduled with AI timing', [
                    'user_id' => $user->id,
                    'booking_event' => $bookingEvent,
                    'notification_type' => $notificationType
                ]);
            }
        } catch (Exception $e) {
            Log::error('Failed to send booking notification', [
                'user_id' => $user->id,
                'booking_event' => $bookingEvent,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Map booking events to notification types
     */
    private function getNotificationTypeForBookingEvent(string $bookingEvent): string
    {
        return match($bookingEvent) {
            'booking_created' => 'booking_confirmation',
            'booking_accepted' => 'booking_accepted',
            'booking_rejected' => 'booking_rejected',
            'booking_completed' => 'booking_completed',
            'booking_cancelled' => 'booking_cancelled',
            'booking_reminder' => 'booking_reminder',
            'payment_due' => 'payment_reminder',
            'service_update' => 'service_update',
            default => 'general_notification'
        };
    }

    /**
     * Batch schedule multiple notifications with AI timing
     */
    public function batchScheduleNotifications(array $notifications): array
    {
        $results = [];
        
        foreach ($notifications as $notification) {
            try {
                $user = $notification['user'];
                $type = $notification['type'];
                $data = $notification['data'];
                $useAI = $notification['use_ai'] ?? true;
                
                $schedule = $this->scheduleNotification($user, $type, $data, $useAI);
                
                $results[] = [
                    'success' => true,
                    'user_id' => $user->id,
                    'schedule_id' => $schedule?->id,
                    'notification_type' => $type
                ];
            } catch (Exception $e) {
                $results[] = [
                    'success' => false,
                    'user_id' => $notification['user']->id ?? null,
                    'error' => $e->getMessage()
                ];
            }
        }
        
        Log::info('Batch notification scheduling completed', [
            'total' => count($notifications),
            'successful' => count(array_filter($results, fn($r) => $r['success']))
        ]);
        
        return $results;
    }

    /**
     * Get notification engagement metrics for a user
     */
    public function getEngagementMetrics(User $user): array
    {
        $schedules = NotificationSchedule::where('user_id', $user->id)
            ->where('status', 'sent')
            ->get();

        $total = $schedules->count();
        $opened = $schedules->where('opened', true)->count();
        $clicked = $schedules->where('clicked', true)->count();
        $dismissed = $schedules->where('dismissed', true)->count();

        return [
            'total_sent' => $total,
            'opened_count' => $opened,
            'clicked_count' => $clicked,
            'dismissed_count' => $dismissed,
            'open_rate' => $total > 0 ? round(($opened / $total) * 100, 2) : 0,
            'click_rate' => $total > 0 ? round(($clicked / $total) * 100, 2) : 0,
            'dismiss_rate' => $total > 0 ? round(($dismissed / $total) * 100, 2) : 0,
            'engagement_rate' => $total > 0 ? round((($opened + $clicked) / $total) * 100, 2) : 0
        ];
    }
}
