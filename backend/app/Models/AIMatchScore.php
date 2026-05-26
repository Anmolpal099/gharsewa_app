<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AIMatchScore extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_id',
        'provider_id',
        'overall_score',
        'skill_match_score',
        'availability_score',
        'location_score',
        'rating_score',
        'price_score',
        'experience_score',
        'reasoning',
        'factor_breakdown',
    ];

    protected $casts = [
        'overall_score' => 'float',
        'skill_match_score' => 'float',
        'availability_score' => 'float',
        'location_score' => 'float',
        'rating_score' => 'float',
        'price_score' => 'float',
        'experience_score' => 'float',
        'factor_breakdown' => 'array',
    ];

    /**
     * Get the booking
     */
    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    /**
     * Get the provider
     */
    public function provider(): BelongsTo
    {
        return $this->belongsTo(User::class, 'provider_id');
    }

    /**
     * Scope for high scores
     */
    public function scopeHighScore($query, float $threshold = 80.0)
    {
        return $query->where('overall_score', '>=', $threshold);
    }

    /**
     * Get average match score for a provider
     */
    public static function averageScoreForProvider(string $providerId): float
    {
        return static::where('provider_id', $providerId)->avg('overall_score') ?? 0;
    }
}
