<?php

namespace App\Services\AI;

use App\Models\User;
use App\Models\NotificationSchedule;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use Exception;

class SmartNotificationService extends AIService
{
    /**
     * Determine optimal time to send notification
     */
    public function determineOptimalTime(User $user, string $notificationType, bool $urgent = false): array
    {
        try {
            Log::info('Determining optimal notification time', [
                'user_id' => $user->id,
                'notification_type' => $notificationType,
                'urgent' => $urgent
            ]);

            // Urgent notifications should be sent immediately
            if ($urgent) {
                return $this->getImmediateTiming($user);
            }

            // Check user notification preferences
            $preferences = $this->getUserNotificationPreferences($user);
            
            // If user has disabled this notification type, return null
            if (!$this->isNotificationTypeEnabled($preferences, $notificationType)) {
                Log::info('Notification type disabled by user', [
                    'user_id' => $user->id,
                    'notification_type' => $notificationType
                ]);
                throw new Exception('Notification type disabled by user');
            }

            // Assign user to A/B test group
            $abTestVariant = $this->assignAbTestVariant($user);
            
            Log::info('User assigned to A/B test variant', [
                'user_id' => $user->id,
                'variant' => $abTestVariant
            ]);

            // Determine timing based on A/B test variant
            if ($abTestVariant === 'control') {
                // Control group: use default timing without AI
                $timing = $this->getDefaultTiming($user, $notificationType);
                $timing['ab_test_variant'] = 'control';
            } else {
                // Test group: use AI-optimized timing
                // Analyze user engagement history
                $engagementData = $this->analyzeEngagementHistory($user);
                
                // Build prompt
                $prompt = $this->buildNotificationPrompt($user, $notificationType, $engagementData);
                
                // Generate AI response
                $response = $this->generate($prompt, 'notification_timing', $user->id);
                
                if (!$response->success) {
                    throw new Exception('AI generation failed: ' . $response->error);
                }

                // Parse optimal time
                $timing = $this->parseNotificationTiming($response->content);
                $timing['ab_test_variant'] = 'test';
            }
            
            // Apply user preferences and quiet hours
            $timing = $this->applyUserPreferences($timing, $preferences, $user);
            
            // Store schedule with A/B test variant
            $this->storeNotificationSchedule($user, $notificationType, $timing);
            
            Log::info('Optimal notification time determined', [
                'user_id' => $user->id,
                'optimal_time' => $timing['optimal_time'],
                'confidence' => $timing['confidence_score'],
                'ab_test_variant' => $timing['ab_test_variant']
            ]);

            return $timing;
        } catch (Exception $e) {
            Log::error('Failed to determine optimal notification time', [
                'user_id' => $user->id,
                'error' => $e->getMessage()
            ]);
            
            // Return default timing as fallback
            return $this->getDefaultTiming($user, $notificationType);
        }
    }

    /**
     * Assign user to A/B test variant
     * 50% control (default timing), 50% test (AI timing)
     */
    private function assignAbTestVariant(User $user): string
    {
        // Use user ID hash for consistent assignment
        // This ensures the same user always gets the same variant
        $hash = crc32($user->id);
        
        // 50/50 split between control and test
        return ($hash % 2 === 0) ? 'control' : 'test';
    }

    /**
     * Get user notification preferences
     */
    private function getUserNotificationPreferences(User $user): array
    {
        $metadata = $user->metadata ?? [];
        
        return [
            'enabled_types' => $metadata['notification_preferences']['enabled_types'] ?? [
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
            'quiet_hours' => $metadata['notification_preferences']['quiet_hours'] ?? [
                'enabled' => false,
                'start' => '22:00',
                'end' => '08:00'
            ],
            'timezone' => $metadata['timezone'] ?? 'UTC',
            'max_daily_notifications' => $metadata['notification_preferences']['max_daily_notifications'] ?? 10
        ];
    }

    /**
     * Check if notification type is enabled for user
     */
    private function isNotificationTypeEnabled(array $preferences, string $notificationType): bool
    {
        return in_array($notificationType, $preferences['enabled_types']);
    }

    /**
     * Apply user preferences to timing
     */
    private function applyUserPreferences(array $timing, array $preferences, User $user): array
    {
        $optimalTime = Carbon::parse($timing['optimal_time']);
        $timezone = $preferences['timezone'];
        
        // Convert to user's timezone
        $optimalTime->setTimezone($timezone);
        
        // Check if time falls within quiet hours
        if ($this->isInQuietHours($optimalTime, $preferences['quiet_hours'])) {
            Log::info('Optimal time falls in quiet hours, adjusting', [
                'user_id' => $user->id,
                'original_time' => $optimalTime->toDateTimeString(),
                'quiet_hours' => $preferences['quiet_hours']
            ]);
            
            // Move to end of quiet hours
            $optimalTime = $this->moveOutOfQuietHours($optimalTime, $preferences['quiet_hours']);
            
            $timing['optimal_time'] = $optimalTime->format('Y-m-d H:i:s');
            $timing['adjusted_for_quiet_hours'] = true;
            $timing['reasoning'] .= ' (Adjusted to respect quiet hours)';
        }
        
        // Check daily notification limit
        $dailyCount = $this->getDailyNotificationCount($user, $optimalTime);
        if ($dailyCount >= $preferences['max_daily_notifications']) {
            Log::warning('Daily notification limit reached', [
                'user_id' => $user->id,
                'daily_count' => $dailyCount,
                'limit' => $preferences['max_daily_notifications']
            ]);
            
            // Move to next day
            $optimalTime->addDay()->setTime(9, 0, 0);
            $timing['optimal_time'] = $optimalTime->format('Y-m-d H:i:s');
            $timing['adjusted_for_limit'] = true;
            $timing['reasoning'] .= ' (Moved to next day due to daily limit)';
        }
        
        return $timing;
    }

    /**
     * Check if time is in quiet hours
     */
    private function isInQuietHours(Carbon $time, array $quietHours): bool
    {
        if (!$quietHours['enabled']) {
            return false;
        }
        
        $startTime = Carbon::parse($quietHours['start'], $time->timezone);
        $endTime = Carbon::parse($quietHours['end'], $time->timezone);
        
        // Handle quiet hours that span midnight
        if ($startTime->greaterThan($endTime)) {
            return $time->greaterThanOrEqualTo($startTime) || $time->lessThan($endTime);
        }
        
        return $time->greaterThanOrEqualTo($startTime) && $time->lessThan($endTime);
    }

    /**
     * Move time out of quiet hours
     */
    private function moveOutOfQuietHours(Carbon $time, array $quietHours): Carbon
    {
        $endTime = Carbon::parse($quietHours['end'], $time->timezone);
        
        // If quiet hours span midnight and we're before end time, use today's end time
        if ($time->lessThan($endTime)) {
            return $time->setTimeFrom($endTime);
        }
        
        // Otherwise, move to next day's end time
        return $time->addDay()->setTimeFrom($endTime);
    }

    /**
     * Get daily notification count for user
     */
    private function getDailyNotificationCount(User $user, Carbon $date): int
    {
        return NotificationSchedule::where('user_id', $user->id)
            ->whereDate('optimal_time', $date->toDateString())
            ->count();
    }

    /**
     * Get immediate timing for urgent notifications
     */
    private function getImmediateTiming(User $user): array
    {
        return [
            'optimal_time' => now()->format('Y-m-d H:i:s'),
            'confidence_score' => 100.0,
            'reasoning' => 'Urgent notification - sent immediately',
            'alternative_times' => [],
            'engagement_prediction' => [
                'open_rate_estimate' => 80.0,
                'action_rate_estimate' => 60.0,
                'best_day' => now()->format('l'),
                'best_hour' => now()->hour
            ],
            'urgent' => true
        ];
    }

    /**
     * Analyze user engagement history
     */
    private function analyzeEngagementHistory(User $user): array
    {
        // Get notification engagement data (simulated for now)
        // In production, this would query actual notification engagement logs
        $engagementHistory = $this->getEngagementHistory($user);
        
        // Calculate engagement patterns
        $patterns = $this->calculateEngagementPatterns($engagementHistory);
        
        return [
            'history' => $engagementHistory,
            'patterns' => $patterns
        ];
    }

    /**
     * Get engagement history for user
     */
    private function getEngagementHistory(User $user): array
    {
        // Get user's booking activity as proxy for engagement
        $bookings = DB::table('bookings')
            ->where('customer_id', $user->id)
            ->where('created_at', '>=', now()->subDays(90))
            ->select(
                DB::raw('HOUR(created_at) as hour'),
                DB::raw('DAYOFWEEK(created_at) as day_of_week'),
                DB::raw('COUNT(*) as count')
            )
            ->groupBy('hour', 'day_of_week')
            ->get();

        return $bookings->map(function ($item) {
            return [
                'hour' => $item->hour,
                'day' => $this->getDayName($item->day_of_week),
                'engagement_count' => $item->count
            ];
        })->toArray();
    }

    /**
     * Calculate engagement patterns
     */
    private function calculateEngagementPatterns(array $history): array
    {
        if (empty($history)) {
            return [
                'most_active_hours' => '9-17',
                'most_active_days' => 'Monday-Friday',
                'avg_response_time' => '2 hours',
                'open_rate_by_time' => []
            ];
        }

        // Find most active hours
        $hourCounts = [];
        foreach ($history as $item) {
            $hour = $item['hour'];
            $hourCounts[$hour] = ($hourCounts[$hour] ?? 0) + $item['engagement_count'];
        }
        arsort($hourCounts);
        $topHours = array_slice(array_keys($hourCounts), 0, 3);
        
        // Find most active days
        $dayCounts = [];
        foreach ($history as $item) {
            $day = $item['day'];
            $dayCounts[$day] = ($dayCounts[$day] ?? 0) + $item['engagement_count'];
        }
        arsort($dayCounts);
        $topDays = array_slice(array_keys($dayCounts), 0, 3);
        
        // Get actual engagement metrics from notification schedules
        $engagementMetrics = $this->getEngagementMetrics($history);

        return [
            'most_active_hours' => implode(', ', $topHours),
            'most_active_days' => implode(', ', $topDays),
            'avg_response_time' => '2 hours',
            'open_rate_by_time' => $hourCounts,
            'engagement_metrics' => $engagementMetrics
        ];
    }

    /**
     * Get engagement metrics from notification history
     */
    private function getEngagementMetrics(array $history): array
    {
        // Get notification engagement data for pattern analysis
        $schedules = NotificationSchedule::whereIn('user_id', array_column($history, 'user_id'))
            ->where('status', 'sent')
            ->where('sent_at', '>=', now()->subDays(90))
            ->get();
        
        if ($schedules->isEmpty()) {
            return [
                'overall_open_rate' => 0,
                'overall_click_rate' => 0,
                'best_performing_hours' => [],
                'worst_performing_hours' => []
            ];
        }
        
        $total = $schedules->count();
        $opened = $schedules->where('opened', true)->count();
        $clicked = $schedules->where('clicked', true)->count();
        
        // Calculate performance by hour
        $performanceByHour = [];
        foreach ($schedules as $schedule) {
            if ($schedule->sent_at) {
                $hour = $schedule->sent_at->hour;
                if (!isset($performanceByHour[$hour])) {
                    $performanceByHour[$hour] = ['total' => 0, 'opened' => 0, 'clicked' => 0];
                }
                $performanceByHour[$hour]['total']++;
                if ($schedule->opened) $performanceByHour[$hour]['opened']++;
                if ($schedule->clicked) $performanceByHour[$hour]['clicked']++;
            }
        }
        
        // Calculate rates by hour
        $ratesByHour = [];
        foreach ($performanceByHour as $hour => $data) {
            $ratesByHour[$hour] = [
                'open_rate' => $data['total'] > 0 ? ($data['opened'] / $data['total']) * 100 : 0,
                'click_rate' => $data['total'] > 0 ? ($data['clicked'] / $data['total']) * 100 : 0
            ];
        }
        
        // Sort by open rate to find best/worst hours
        uasort($ratesByHour, fn($a, $b) => $b['open_rate'] <=> $a['open_rate']);
        $bestHours = array_slice(array_keys($ratesByHour), 0, 3, true);
        $worstHours = array_slice(array_keys($ratesByHour), -3, 3, true);
        
        return [
            'overall_open_rate' => $total > 0 ? round(($opened / $total) * 100, 2) : 0,
            'overall_click_rate' => $total > 0 ? round(($clicked / $total) * 100, 2) : 0,
            'best_performing_hours' => $bestHours,
            'worst_performing_hours' => $worstHours,
            'rates_by_hour' => $ratesByHour
        ];
    }

    /**
     * Build notification timing prompt
     */
    private function buildNotificationPrompt(
        User $user,
        string $notificationType,
        array $engagementData
    ): string {
        $builder = PromptBuilder::fromTemplate('notification.txt');
        
        $timezone = $user->metadata['timezone'] ?? 'UTC';
        $userType = $user->role ?? 'customer';
        
        // Include engagement metrics in the prompt
        $engagementMetrics = $engagementData['patterns']['engagement_metrics'] ?? [];
        
        return $builder->setVariables([
            'user_id' => $user->id,
            'user_name' => $user->name,
            'timezone' => $timezone,
            'user_type' => $userType,
            'notification_type' => $notificationType,
            'engagement_history' => json_encode($engagementData['history'], JSON_PRETTY_PRINT),
            'active_hours' => $engagementData['patterns']['most_active_hours'],
            'active_days' => $engagementData['patterns']['most_active_days'],
            'avg_response_time' => $engagementData['patterns']['avg_response_time'],
            'open_rate_by_time' => json_encode($engagementData['patterns']['open_rate_by_time']),
            'overall_open_rate' => $engagementMetrics['overall_open_rate'] ?? 0,
            'overall_click_rate' => $engagementMetrics['overall_click_rate'] ?? 0,
            'best_performing_hours' => json_encode($engagementMetrics['best_performing_hours'] ?? []),
            'worst_performing_hours' => json_encode($engagementMetrics['worst_performing_hours'] ?? []),
            'rates_by_hour' => json_encode($engagementMetrics['rates_by_hour'] ?? [])
        ])->build();
    }

    /**
     * Parse notification timing response
     */
    private function parseNotificationTiming(string $content): array
    {
        $parsed = $this->parser->parseJson($content);
        
        if ($parsed === null) {
            Log::warning('Failed to parse notification timing JSON', ['content' => substr($content, 0, 200)]);
            return $this->getDefaultTimingData();
        }

        return [
            'optimal_time' => $parsed['optimal_time'] ?? now()->addHours(2)->format('Y-m-d H:i:s'),
            'confidence_score' => (float) ($parsed['confidence_score'] ?? 50),
            'reasoning' => $parsed['reasoning'] ?? 'Default timing',
            'alternative_times' => $parsed['alternative_times'] ?? [],
            'engagement_prediction' => $parsed['engagement_prediction'] ?? [
                'open_rate_estimate' => 50,
                'action_rate_estimate' => 30,
                'best_day' => 'Monday',
                'best_hour' => 10
            ]
        ];
    }

    /**
     * Store notification schedule
     */
    private function storeNotificationSchedule(
        User $user,
        string $notificationType,
        array $timing
    ): void {
        NotificationSchedule::create([
            'user_id' => $user->id,
            'notification_type' => $notificationType,
            'optimal_time' => Carbon::parse($timing['optimal_time']),
            'confidence_score' => $timing['confidence_score'],
            'reasoning' => $timing['reasoning'],
            'alternative_times' => $timing['alternative_times'],
            'engagement_prediction' => $timing['engagement_prediction'],
            'status' => 'scheduled',
            'ab_test_variant' => $timing['ab_test_variant'] ?? null
        ]);
    }

    /**
     * Get default timing as fallback
     */
    private function getDefaultTiming(User $user, string $notificationType): array
    {
        // Default to 10 AM next day in user's timezone
        $timezone = $user->metadata['timezone'] ?? 'UTC';
        $optimalTime = now($timezone)->addDay()->setTime(10, 0, 0);

        return [
            'optimal_time' => $optimalTime->format('Y-m-d H:i:s'),
            'confidence_score' => 50.0,
            'reasoning' => 'Default timing (10 AM)',
            'alternative_times' => [
                [
                    'time' => $optimalTime->copy()->setTime(14, 0, 0)->format('Y-m-d H:i:s'),
                    'score' => 45.0,
                    'reason' => 'Afternoon alternative'
                ],
                [
                    'time' => $optimalTime->copy()->setTime(18, 0, 0)->format('Y-m-d H:i:s'),
                    'score' => 40.0,
                    'reason' => 'Evening alternative'
                ]
            ],
            'engagement_prediction' => [
                'open_rate_estimate' => 50.0,
                'action_rate_estimate' => 30.0,
                'best_day' => 'Monday',
                'best_hour' => 10
            ]
        ];
    }

    /**
     * Get default timing data structure
     */
    private function getDefaultTimingData(): array
    {
        return [
            'optimal_time' => now()->addHours(2)->format('Y-m-d H:i:s'),
            'confidence_score' => 50.0,
            'reasoning' => 'Default timing',
            'alternative_times' => [],
            'engagement_prediction' => [
                'open_rate_estimate' => 50.0,
                'action_rate_estimate' => 30.0,
                'best_day' => 'Monday',
                'best_hour' => 10
            ]
        ];
    }

    /**
     * Get day name from day of week number
     */
    private function getDayName(int $dayOfWeek): string
    {
        return match($dayOfWeek) {
            1 => 'Sunday',
            2 => 'Monday',
            3 => 'Tuesday',
            4 => 'Wednesday',
            5 => 'Thursday',
            6 => 'Friday',
            7 => 'Saturday',
            default => 'Unknown'
        };
    }

    /**
     * Get scheduled notifications for user
     */
    public function getScheduledNotifications(User $user): array
    {
        return NotificationSchedule::where('user_id', $user->id)
            ->where('status', 'scheduled')
            ->where('optimal_time', '>', now())
            ->orderBy('optimal_time')
            ->get()
            ->toArray();
    }

    /**
     * Mark notification as sent
     */
    public function markAsSent(string $scheduleId): void
    {
        $schedule = NotificationSchedule::find($scheduleId);
        
        if ($schedule) {
            $schedule->status = 'sent';
            $schedule->sent_at = now();
            $schedule->save();
        }
    }

    /**
     * Record notification engagement
     */
    public function recordEngagement(string $scheduleId, string $action): void
    {
        $schedule = NotificationSchedule::find($scheduleId);
        
        if (!$schedule) {
            return;
        }

        switch ($action) {
            case 'opened':
                $schedule->opened = true;
                $schedule->opened_at = now();
                break;
            case 'clicked':
                $schedule->clicked = true;
                $schedule->clicked_at = now();
                break;
            case 'dismissed':
                $schedule->dismissed = true;
                $schedule->dismissed_at = now();
                break;
        }

        $schedule->save();
    }

    /**
     * Get A/B test results comparing control vs test groups
     */
    public function getAbTestResults(array $filters = []): array
    {
        $query = NotificationSchedule::abTestParticipants()
            ->where('status', 'sent');

        // Apply filters
        if (!empty($filters['notification_type'])) {
            $query->where('notification_type', $filters['notification_type']);
        }

        if (!empty($filters['start_date'])) {
            $query->where('sent_at', '>=', Carbon::parse($filters['start_date']));
        }

        if (!empty($filters['end_date'])) {
            $query->where('sent_at', '<=', Carbon::parse($filters['end_date']));
        }

        // Get all notifications
        $notifications = $query->get();

        // Calculate metrics for control group
        $controlGroup = $notifications->where('ab_test_variant', 'control');
        $controlMetrics = $this->calculateGroupMetrics($controlGroup);

        // Calculate metrics for test group
        $testGroup = $notifications->where('ab_test_variant', 'test');
        $testMetrics = $this->calculateGroupMetrics($testGroup);

        // Calculate statistical significance and improvements
        $comparison = $this->compareGroups($controlMetrics, $testMetrics);

        return [
            'summary' => [
                'total_notifications' => $notifications->count(),
                'control_count' => $controlGroup->count(),
                'test_count' => $testGroup->count(),
                'date_range' => [
                    'start' => $notifications->min('sent_at'),
                    'end' => $notifications->max('sent_at')
                ]
            ],
            'control_group' => $controlMetrics,
            'test_group' => $testMetrics,
            'comparison' => $comparison,
            'filters_applied' => $filters
        ];
    }

    /**
     * Calculate metrics for a group of notifications
     */
    private function calculateGroupMetrics($notifications): array
    {
        $total = $notifications->count();

        if ($total === 0) {
            return [
                'total' => 0,
                'open_rate' => 0,
                'click_rate' => 0,
                'engagement_rate' => 0,
                'avg_time_to_open' => null,
                'avg_time_to_click' => null,
                'by_notification_type' => []
            ];
        }

        $opened = $notifications->where('opened', true)->count();
        $clicked = $notifications->where('clicked', true)->count();

        // Calculate average time to open (in minutes)
        $timesToOpen = $notifications->filter(function ($n) {
            return $n->opened && $n->sent_at && $n->opened_at;
        })->map(function ($n) {
            return $n->sent_at->diffInMinutes($n->opened_at);
        });

        // Calculate average time to click (in minutes)
        $timesToClick = $notifications->filter(function ($n) {
            return $n->clicked && $n->sent_at && $n->clicked_at;
        })->map(function ($n) {
            return $n->sent_at->diffInMinutes($n->clicked_at);
        });

        // Group by notification type
        $byType = $notifications->groupBy('notification_type')->map(function ($group) {
            $groupTotal = $group->count();
            $groupOpened = $group->where('opened', true)->count();
            $groupClicked = $group->where('clicked', true)->count();

            return [
                'total' => $groupTotal,
                'open_rate' => $groupTotal > 0 ? round(($groupOpened / $groupTotal) * 100, 2) : 0,
                'click_rate' => $groupTotal > 0 ? round(($groupClicked / $groupTotal) * 100, 2) : 0
            ];
        });

        return [
            'total' => $total,
            'opened' => $opened,
            'clicked' => $clicked,
            'open_rate' => round(($opened / $total) * 100, 2),
            'click_rate' => round(($clicked / $total) * 100, 2),
            'engagement_rate' => round((($opened + $clicked) / ($total * 2)) * 100, 2),
            'avg_time_to_open' => $timesToOpen->count() > 0 ? round($timesToOpen->avg(), 2) : null,
            'avg_time_to_click' => $timesToClick->count() > 0 ? round($timesToClick->avg(), 2) : null,
            'by_notification_type' => $byType->toArray()
        ];
    }

    /**
     * Compare control and test groups
     */
    private function compareGroups(array $control, array $test): array
    {
        // Calculate improvements
        $openRateImprovement = $control['open_rate'] > 0 
            ? (($test['open_rate'] - $control['open_rate']) / $control['open_rate']) * 100 
            : 0;

        $clickRateImprovement = $control['click_rate'] > 0 
            ? (($test['click_rate'] - $control['click_rate']) / $control['click_rate']) * 100 
            : 0;

        $engagementRateImprovement = $control['engagement_rate'] > 0 
            ? (($test['engagement_rate'] - $control['engagement_rate']) / $control['engagement_rate']) * 100 
            : 0;

        // Determine winner
        $winner = 'none';
        if ($test['open_rate'] > $control['open_rate'] && $test['click_rate'] > $control['click_rate']) {
            $winner = 'test';
        } elseif ($control['open_rate'] > $test['open_rate'] && $control['click_rate'] > $test['click_rate']) {
            $winner = 'control';
        }

        // Calculate statistical significance (simplified chi-square test)
        $significance = $this->calculateStatisticalSignificance($control, $test);

        return [
            'winner' => $winner,
            'open_rate_improvement' => round($openRateImprovement, 2),
            'click_rate_improvement' => round($clickRateImprovement, 2),
            'engagement_rate_improvement' => round($engagementRateImprovement, 2),
            'statistical_significance' => $significance,
            'recommendation' => $this->getRecommendation($winner, $significance, $openRateImprovement, $clickRateImprovement)
        ];
    }

    /**
     * Calculate statistical significance using chi-square test
     */
    private function calculateStatisticalSignificance(array $control, array $test): array
    {
        // Simplified chi-square test for open rate
        $controlTotal = $control['total'];
        $testTotal = $test['total'];
        $controlOpened = $control['opened'];
        $testOpened = $test['opened'];

        if ($controlTotal === 0 || $testTotal === 0) {
            return [
                'is_significant' => false,
                'confidence_level' => 0,
                'p_value' => 1.0
            ];
        }

        // Calculate expected values
        $totalNotifications = $controlTotal + $testTotal;
        $totalOpened = $controlOpened + $testOpened;
        $expectedControlOpened = ($controlTotal * $totalOpened) / $totalNotifications;
        $expectedTestOpened = ($testTotal * $totalOpened) / $totalNotifications;

        // Calculate chi-square statistic
        $chiSquare = 0;
        if ($expectedControlOpened > 0) {
            $chiSquare += pow($controlOpened - $expectedControlOpened, 2) / $expectedControlOpened;
        }
        if ($expectedTestOpened > 0) {
            $chiSquare += pow($testOpened - $expectedTestOpened, 2) / $expectedTestOpened;
        }

        // Determine significance (chi-square critical value for 95% confidence with 1 df is 3.841)
        $isSignificant = $chiSquare > 3.841;
        $confidenceLevel = $isSignificant ? 95 : 0;

        // Approximate p-value (simplified)
        $pValue = $chiSquare > 3.841 ? 0.05 : 0.5;

        return [
            'is_significant' => $isSignificant,
            'confidence_level' => $confidenceLevel,
            'p_value' => $pValue,
            'chi_square' => round($chiSquare, 4)
        ];
    }

    /**
     * Get recommendation based on A/B test results
     */
    private function getRecommendation(
        string $winner,
        array $significance,
        float $openRateImprovement,
        float $clickRateImprovement
    ): string {
        if (!$significance['is_significant']) {
            return 'Continue testing - results are not statistically significant yet. Collect more data before making a decision.';
        }

        if ($winner === 'test') {
            $avgImprovement = ($openRateImprovement + $clickRateImprovement) / 2;
            return sprintf(
                'Implement AI-optimized timing for all users. Test group shows %.1f%% average improvement with %d%% confidence.',
                $avgImprovement,
                $significance['confidence_level']
            );
        }

        if ($winner === 'control') {
            return 'Keep default timing strategy. Control group performs better than AI-optimized timing.';
        }

        return 'Results are mixed. Consider testing with different notification types or user segments.';
    }
}
