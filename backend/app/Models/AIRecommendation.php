<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AIRecommendation extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'service_id',
        'confidence_score',
        'reasoning',
        'clicked',
        'clicked_at',
        'booked',
        'booked_at',
        'expires_at'
    ];

    protected $casts = [
        'confidence_score' => 'float',
        'clicked' => 'boolean',
        'clicked_at' => 'datetime',
        'booked' => 'boolean',
        'booked_at' => 'datetime',
        'expires_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime'
    ];

    /**
     * Get the user that owns the recommendation
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the service that was recommended
     */
    public function service(): BelongsTo
    {
        return $this->belongsTo(Service::class);
    }

    /**
     * Scope for active recommendations (not expired)
     */
    public function scopeActive($query)
    {
        return $query->where('expires_at', '>', now());
    }

    /**
     * Scope for expired recommendations
     */
    public function scopeExpired($query)
    {
        return $query->where('expires_at', '<=', now());
    }

    /**
     * Scope for clicked recommendations
     */
    public function scopeClicked($query)
    {
        return $query->where('clicked', true);
    }

    /**
     * Scope for booked recommendations
     */
    public function scopeBooked($query)
    {
        return $query->where('booked', true);
    }

    /**
     * Scope for recommendations by user
     */
    public function scopeForUser($query, string $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope for high confidence recommendations
     */
    public function scopeHighConfidence($query, float $threshold = 70.0)
    {
        return $query->where('confidence_score', '>=', $threshold);
    }

    /**
     * Check if recommendation is still valid
     */
    public function isValid(): bool
    {
        return $this->expires_at > now();
    }

    /**
     * Check if recommendation was engaged with
     */
    public function wasEngaged(): bool
    {
        return $this->clicked || $this->booked;
    }

    /**
     * Get engagement rate (0-100)
     */
    public function getEngagementRate(): float
    {
        if ($this->booked) {
            return 100.0;
        }

        if ($this->clicked) {
            return 50.0;
        }

        return 0.0;
    }

    /**
     * Mark as clicked
     */
    public function markAsClicked(): void
    {
        $this->clicked = true;
        $this->clicked_at = now();
        $this->save();
    }

    /**
     * Mark as booked
     */
    public function markAsBooked(): void
    {
        $this->booked = true;
        $this->booked_at = now();
        $this->save();
    }
}
