<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationSchedule extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'notification_type',
        'optimal_time',
        'confidence_score',
        'reasoning',
        'alternative_times',
        'engagement_prediction',
        'status',
        'sent_at',
        'opened',
        'opened_at',
        'clicked',
        'clicked_at',
        'dismissed',
        'dismissed_at',
        'ab_test_group',
        'ab_test_variant'
    ];

    protected $casts = [
        'optimal_time' => 'datetime',
        'alternative_times' => 'array',
        'engagement_prediction' => 'array',
        'confidence_score' => 'float',
        'sent_at' => 'datetime',
        'opened' => 'boolean',
        'opened_at' => 'datetime',
        'clicked' => 'boolean',
        'clicked_at' => 'datetime',
        'dismissed' => 'boolean',
        'dismissed_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];

    /**
     * Get the user that owns the notification schedule
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope for scheduled notifications
     */
    public function scopeScheduled($query)
    {
        return $query->where('status', 'scheduled');
    }

    /**
     * Scope for sent notifications
     */
    public function scopeSent($query)
    {
        return $query->where('status', 'sent');
    }

    /**
     * Scope for pending notifications (scheduled but not yet sent)
     */
    public function scopePending($query)
    {
        return $query->where('status', 'scheduled')
                     ->where('optimal_time', '>', now());
    }

    /**
     * Scope for due notifications (scheduled and time has passed)
     */
    public function scopeDue($query)
    {
        return $query->where('status', 'scheduled')
                     ->where('optimal_time', '<=', now());
    }

    /**
     * Check if notification was engaged with
     */
    public function wasEngaged(): bool
    {
        return $this->opened || $this->clicked;
    }

    /**
     * Get engagement rate
     */
    public function getEngagementRate(): float
    {
        if (!$this->sent_at) {
            return 0;
        }

        if ($this->clicked) {
            return 100;
        }

        if ($this->opened) {
            return 50;
        }

        return 0;
    }

    /**
     * Scope for control group notifications
     */
    public function scopeControlGroup($query)
    {
        return $query->where('ab_test_variant', 'control');
    }

    /**
     * Scope for test group notifications
     */
    public function scopeTestGroup($query)
    {
        return $query->where('ab_test_variant', 'test');
    }

    /**
     * Scope for A/B test participants
     */
    public function scopeAbTestParticipants($query)
    {
        return $query->whereNotNull('ab_test_variant');
    }
}
